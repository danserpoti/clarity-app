// lib/services/background_backup_service.dart
// バックグラウンドバックアップサービス - 自動Notion連携

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'privacy_service.dart';
import 'notion_service.dart';
import 'local_database.dart';

/// バックグラウンドバックアップサービス
/// 自動バックアップの実行とスケジューリングを管理
class BackgroundBackupService {
  static const String _lastAutoBackupKey = 'last_auto_backup_timestamp';
  static const String _backupQueueKey = 'backup_queue';
  
  /// 自動バックアップの実行チェック
  /// アプリ起動時やフォアグラウンド復帰時に呼び出し
  static Future<void> checkAndPerformAutoBackup() async {
    try {
      final settings = await PrivacySettings.load();
      
      // 自動バックアップが無効、またはNotion連携が未設定の場合はスキップ
      if (!settings.enableNotionBackup || 
          !settings.autoBackupEnabled || 
          !settings.hasNotionCredentials) {
        return;
      }

      // バックアップが必要かチェック
      if (!settings.shouldPerformAutoBackup()) {
        if (kDebugMode) {
          print('自動バックアップ: まだ実行タイミングではありません');
        }
        return;
      }

      if (kDebugMode) {
        print('自動バックアップを開始します...');
      }

      // バックアップ実行
      final result = await _performAutomaticBackup(settings);
      
      if (result.isSuccess) {
        // 成功通知（実装予定）
        await _showBackupNotification(
          success: true, 
          count: result.backedUpCount,
        );
        
        if (kDebugMode) {
          print('自動バックアップ成功: ${result.backedUpCount}件');
        }
      } else {
        // エラー通知（実装予定）
        await _showBackupNotification(
          success: false, 
          error: result.errorMessage,
        );
        
        if (kDebugMode) {
          print('自動バックアップ失敗: ${result.errorMessage}');
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('自動バックアップエラー: $e');
      }
      
      await _showBackupNotification(
        success: false, 
        error: e.toString(),
      );
    }
  }

  /// 手動バックアップの実行
  /// UI画面から呼び出される場合
  static Future<BackupResult> performManualBackup() async {
    try {
      final settings = await PrivacySettings.load();
      
      if (!settings.enableNotionBackup || !settings.hasNotionCredentials) {
        return BackupResult.error('Notion連携が設定されていません');
      }

      if (kDebugMode) {
        print('手動バックアップを開始します...');
      }

      return await _performAutomaticBackup(settings);
      
    } catch (e) {
      if (kDebugMode) {
        print('手動バックアップエラー: $e');
      }
      return BackupResult.error('バックアップエラー: ${e.toString()}');
    }
  }

  /// バックアップの実際の実行処理
  static Future<BackupResult> _performAutomaticBackup(PrivacySettings settings) async {
    try {
      // 思考記録を取得
      final database = LocalDatabase.instance;
      final thoughts = await database.getAllThoughts();
      
      if (thoughts.isEmpty) {
        return BackupResult.success(
          backedUpCount: 0,
          pageIds: [],
          timestamp: DateTime.now(),
        );
      }

      // Notionサービスでバックアップ実行
      final notionService = NotionService(
        apiKey: settings.notionApiKey!,
        databaseId: settings.notionDatabaseId!,
      );

      final result = await notionService.backupThoughts(thoughts);
      
      // 統計更新
      await settings.updateBackupStats(
        success: result.isSuccess,
        backupTime: result.timestamp,
      );

      // 最終実行時刻を記録
      if (result.isSuccess) {
        await _recordLastBackupTime(result.timestamp);
      }

      return result;
      
    } catch (e) {
      if (kDebugMode) {
        print('バックアップ実行エラー: $e');
      }
      return BackupResult.error('バックアップ実行エラー: ${e.toString()}');
    }
  }

  /// 最終バックアップ時刻の記録
  static Future<void> _recordLastBackupTime(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastAutoBackupKey, timestamp.toIso8601String());
    } catch (e) {
      if (kDebugMode) {
        print('最終バックアップ時刻の記録エラー: $e');
      }
    }
  }

  /// 最終バックアップ時刻の取得
  static Future<DateTime?> getLastAutoBackupTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString(_lastAutoBackupKey);
      return timeString != null ? DateTime.parse(timeString) : null;
    } catch (e) {
      if (kDebugMode) {
        print('最終バックアップ時刻の取得エラー: $e');
      }
      return null;
    }
  }

  /// バックアップキューの管理
  /// ネットワークエラー時などに使用（将来の機能）
  static Future<void> addToBackupQueue(String thoughtId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> queue = prefs.getStringList(_backupQueueKey) ?? [];
      
      if (!queue.contains(thoughtId)) {
        queue.add(thoughtId);
        await prefs.setStringList(_backupQueueKey, queue);
      }
    } catch (e) {
      if (kDebugMode) {
        print('バックアップキューへの追加エラー: $e');
      }
    }
  }

  /// バックアップキューの処理
  /// ネットワーク復旧時などに使用（将来の機能）
  static Future<void> processBackupQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> queue = prefs.getStringList(_backupQueueKey) ?? [];
      
      if (queue.isEmpty) return;

      final settings = await PrivacySettings.load();
      if (!settings.enableNotionBackup || !settings.hasNotionCredentials) {
        return;
      }

      final database = LocalDatabase.instance;
      final notionService = NotionService(
        apiKey: settings.notionApiKey!,
        databaseId: settings.notionDatabaseId!,
      );

      List<String> processedIds = [];
      
      for (String thoughtId in queue) {
        try {
          final thought = await database.getThought(thoughtId);
          if (thought != null) {
            final result = await notionService.backupSingleThought(thought);
            if (result.isSuccess) {
              processedIds.add(thoughtId);
            }
          } else {
            // 思考記録が見つからない場合はキューから削除
            processedIds.add(thoughtId);
          }
          
          // API制限を考慮して少し待機
          await Future.delayed(const Duration(milliseconds: 500));
          
        } catch (e) {
          if (kDebugMode) {
            print('キュー処理エラー ($thoughtId): $e');
          }
        }
      }

      // 処理済みのアイテムをキューから削除
      if (processedIds.isNotEmpty) {
        queue.removeWhere((id) => processedIds.contains(id));
        await prefs.setStringList(_backupQueueKey, queue);
      }

    } catch (e) {
      if (kDebugMode) {
        print('バックアップキュー処理エラー: $e');
      }
    }
  }

  /// バックアップ通知の表示
  /// 将来的にはFlutter Local Notificationsを使用
  static Future<void> _showBackupNotification({
    required bool success,
    int? count,
    String? error,
  }) async {
    // 現在はコンソール出力のみ
    // 将来的にはローカル通知を実装
    if (kDebugMode) {
      if (success) {
        print('🔄 バックアップ完了通知: ${count ?? 0}件の記録をバックアップしました');
      } else {
        print('❌ バックアップエラー通知: ${error ?? "不明なエラー"}');
      }
    }
    
    // TODO: Flutter Local Notifications実装
    // final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    // await flutterLocalNotificationsPlugin.show(
    //   DateTime.now().millisecondsSinceEpoch.remainder(100000),
    //   success ? 'バックアップ完了' : 'バックアップエラー',
    //   success 
    //     ? '${count ?? 0}件の記録をNotionにバックアップしました'
    //     : 'バックアップに失敗しました: ${error ?? "不明なエラー"}',
    //   NotificationDetails(
    //     android: AndroidNotificationDetails(
    //       'backup_channel',
    //       'バックアップ通知',
    //       importance: Importance.low,
    //       priority: Priority.low,
    //     ),
    //   ),
    // );
  }

  /// バックアップスケジュールの確認
  /// 次回バックアップ予定時刻を計算
  static Future<DateTime?> getNextScheduledBackup() async {
    try {
      final settings = await PrivacySettings.load();
      
      if (!settings.enableNotionBackup || 
          !settings.autoBackupEnabled || 
          !settings.hasNotionCredentials) {
        return null;
      }

      if (settings.lastBackupTime == null) {
        // 初回バックアップの場合、現在時刻から設定間隔後
        return DateTime.now().add(Duration(days: settings.autoBackupIntervalDays));
      }

      return settings.lastBackupTime!.add(Duration(days: settings.autoBackupIntervalDays));
      
    } catch (e) {
      if (kDebugMode) {
        print('次回バックアップ予定時刻の計算エラー: $e');
      }
      return null;
    }
  }

  /// バックアップサービスの初期化
  /// アプリ起動時に呼び出し
  static Future<void> initialize() async {
    try {
      if (kDebugMode) {
        print('バックグラウンドバックアップサービスを初期化中...');
      }

      // 未処理のキューを処理
      await processBackupQueue();
      
      // 自動バックアップのチェック
      await checkAndPerformAutoBackup();
      
      if (kDebugMode) {
        final nextBackup = await getNextScheduledBackup();
        if (nextBackup != null) {
          print('次回自動バックアップ予定: $nextBackup');
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('バックグラウンドバックアップサービス初期化エラー: $e');
      }
    }
  }

  /// デバッグ情報の出力
  static Future<void> printDebugInfo() async {
    if (kDebugMode) {
      print('=== バックグラウンドバックアップ情報 ===');
      
      final settings = await PrivacySettings.load();
      print('Notion連携: ${settings.enableNotionBackup}');
      print('自動バックアップ: ${settings.autoBackupEnabled}');
      print('認証情報設定済み: ${settings.hasNotionCredentials}');
      print('バックアップ間隔: ${settings.autoBackupIntervalDays}日');
      
      final lastBackup = await getLastAutoBackupTime();
      print('最終自動バックアップ: $lastBackup');
      
      final nextBackup = await getNextScheduledBackup();
      print('次回予定: $nextBackup');
      
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_backupQueueKey) ?? [];
      print('バックアップキュー: ${queue.length}件');
      
      print('==========================================');
    }
  }
}