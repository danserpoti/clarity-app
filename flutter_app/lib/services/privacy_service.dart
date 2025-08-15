// lib/services/privacy_service.dart
// プライバシー設定管理サービス - セキュアな設定保存

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// プライバシー設定管理クラス
/// プライバシーファースト設計に基づく設定管理
class PrivacySettings extends ChangeNotifier {
  static const String _settingsKey = 'privacy_settings';
  static const String _notionApiKeySecureKey = 'notion_api_key';
  static const String _notionDatabaseIdSecureKey = 'notion_database_id';
  
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // AI分析設定（バックエンドAPI使用）
  bool enableAIAnalysis = true;
  bool enableDataEncryption = true;
  bool showUsageStats = true;
  
  // Notion連携設定
  bool enableNotionBackup = false;
  String? notionApiKey; // メモリ内一時保持用
  String? notionDatabaseId; // メモリ内一時保持用
  DateTime? lastBackupTime;
  bool autoBackupEnabled = false;
  int autoBackupIntervalDays = 7;
  
  // バックアップ統計
  int totalBackupsCount = 0;
  int successfulBackupsCount = 0;
  DateTime? firstBackupTime;

  /// シングルトンインスタンス
  static PrivacySettings? _instance;
  static PrivacySettings get instance {
    _instance ??= PrivacySettings._internal();
    return _instance!;
  }
  
  PrivacySettings._internal();

  /// 設定の読み込み
  static Future<PrivacySettings> load() async {
    final settings = PrivacySettings.instance;
    await settings._loadFromStorage();
    return settings;
  }

  /// 設定をストレージから読み込み
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        final data = jsonDecode(settingsJson) as Map<String, dynamic>;
        
        // 基本設定
        enableAIAnalysis = data['enableAIAnalysis'] ?? true;
        enableDataEncryption = data['enableDataEncryption'] ?? true;
        showUsageStats = data['showUsageStats'] ?? true;
        
        // Notion設定
        enableNotionBackup = data['enableNotionBackup'] ?? false;
        autoBackupEnabled = data['autoBackupEnabled'] ?? false;
        autoBackupIntervalDays = data['autoBackupIntervalDays'] ?? 7;
        
        // 日時設定
        if (data['lastBackupTime'] != null) {
          lastBackupTime = DateTime.parse(data['lastBackupTime']);
        }
        if (data['firstBackupTime'] != null) {
          firstBackupTime = DateTime.parse(data['firstBackupTime']);
        }
        
        // 統計設定
        totalBackupsCount = data['totalBackupsCount'] ?? 0;
        successfulBackupsCount = data['successfulBackupsCount'] ?? 0;
      }
      
      // セキュアストレージからNotion認証情報を読み込み
      if (enableNotionBackup) {
        await _loadNotionCredentials();
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('プライバシー設定の読み込みエラー: $e');
      }
    }
  }

  /// Notion認証情報をセキュアストレージから読み込み
  Future<void> _loadNotionCredentials() async {
    try {
      notionApiKey = await _secureStorage.read(key: _notionApiKeySecureKey);
      notionDatabaseId = await _secureStorage.read(key: _notionDatabaseIdSecureKey);
    } catch (e) {
      if (kDebugMode) {
        print('Notion認証情報の読み込みエラー: $e');
      }
    }
  }

  /// 設定の保存
  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final settingsData = {
        'enableAIAnalysis': enableAIAnalysis,
        'enableDataEncryption': enableDataEncryption,
        'showUsageStats': showUsageStats,
        'enableNotionBackup': enableNotionBackup,
        'autoBackupEnabled': autoBackupEnabled,
        'autoBackupIntervalDays': autoBackupIntervalDays,
        'lastBackupTime': lastBackupTime?.toIso8601String(),
        'firstBackupTime': firstBackupTime?.toIso8601String(),
        'totalBackupsCount': totalBackupsCount,
        'successfulBackupsCount': successfulBackupsCount,
      };
      
      await prefs.setString(_settingsKey, jsonEncode(settingsData));
      notifyListeners();
      
    } catch (e) {
      if (kDebugMode) {
        print('プライバシー設定の保存エラー: $e');
      }
    }
  }

  /// Notion認証情報の設定
  Future<void> setNotionCredentials({
    required String apiKey,
    required String databaseId,
  }) async {
    try {
      // 入力値検証
      if (apiKey.trim().isEmpty || databaseId.trim().isEmpty) {
        throw ArgumentError('APIキーとDatabase IDは必須です');
      }
      
      // セキュアストレージに保存
      await _secureStorage.write(
        key: _notionApiKeySecureKey, 
        value: apiKey.trim(),
      );
      await _secureStorage.write(
        key: _notionDatabaseIdSecureKey, 
        value: databaseId.trim(),
      );
      
      // メモリ内設定更新
      notionApiKey = apiKey.trim();
      notionDatabaseId = databaseId.trim();
      enableNotionBackup = true;
      
      // 初回設定時の記録
      firstBackupTime ??= DateTime.now();
      
      await save();
      
    } catch (e) {
      if (kDebugMode) {
        print('Notion認証情報の設定エラー: $e');
      }
      rethrow;
    }
  }

  /// Notion認証情報の削除
  Future<void> clearNotionCredentials() async {
    try {
      // セキュアストレージから削除
      await _secureStorage.delete(key: _notionApiKeySecureKey);
      await _secureStorage.delete(key: _notionDatabaseIdSecureKey);
      
      // メモリ内設定クリア
      notionApiKey = null;
      notionDatabaseId = null;
      enableNotionBackup = false;
      autoBackupEnabled = false;
      
      await save();
      
    } catch (e) {
      if (kDebugMode) {
        print('Notion認証情報の削除エラー: $e');
      }
      rethrow;
    }
  }

  /// Notion認証情報が設定されているかチェック
  bool get hasNotionCredentials {
    return notionApiKey != null && 
           notionDatabaseId != null && 
           notionApiKey!.isNotEmpty && 
           notionDatabaseId!.isNotEmpty;
  }

  /// バックアップ統計の更新
  Future<void> updateBackupStats({
    required bool success,
    DateTime? backupTime,
  }) async {
    totalBackupsCount++;
    if (success) {
      successfulBackupsCount++;
      lastBackupTime = backupTime ?? DateTime.now();
    }
    
    await save();
  }

  /// バックアップ成功率の計算
  double get backupSuccessRate {
    if (totalBackupsCount == 0) return 0.0;
    return successfulBackupsCount / totalBackupsCount;
  }

  /// 自動バックアップが実行されるべきかチェック
  bool shouldPerformAutoBackup() {
    if (!enableNotionBackup || !autoBackupEnabled || !hasNotionCredentials) {
      return false;
    }
    
    if (lastBackupTime == null) {
      return true; // 初回実行
    }
    
    final now = DateTime.now();
    final daysSinceLastBackup = now.difference(lastBackupTime!).inDays;
    
    return daysSinceLastBackup >= autoBackupIntervalDays;
  }

  /// 次回自動バックアップ予定日
  DateTime? get nextAutoBackupDate {
    if (!enableNotionBackup || !autoBackupEnabled || lastBackupTime == null) {
      return null;
    }
    
    return lastBackupTime!.add(Duration(days: autoBackupIntervalDays));
  }

  /// デバッグ情報の出力
  void printDebugInfo() {
    if (kDebugMode) {
      print('=== プライバシー設定 ===');
      print('AI分析: $enableAIAnalysis');
      print('データ暗号化: $enableDataEncryption');
      print('Notion連携: $enableNotionBackup');
      print('自動バックアップ: $autoBackupEnabled');
      print('バックアップ間隔: $autoBackupIntervalDays日');
      print('認証情報設定済み: $hasNotionCredentials');
      print('総バックアップ数: $totalBackupsCount');
      print('成功バックアップ数: $successfulBackupsCount');
      print('成功率: ${(backupSuccessRate * 100).toStringAsFixed(1)}%');
      print('最終バックアップ: $lastBackupTime');
      print('========================');
    }
  }

  /// 設定のリセット（デバッグ用）
  Future<void> resetSettings() async {
    if (kDebugMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_settingsKey);
      await clearNotionCredentials();
      
      // デフォルト値に戻す
      enableAIAnalysis = true;
      enableDataEncryption = true;
      enableNotionBackup = false;
      autoBackupEnabled = false;
      autoBackupIntervalDays = 7;
      lastBackupTime = null;
      firstBackupTime = null;
      totalBackupsCount = 0;
      successfulBackupsCount = 0;
      
      notifyListeners();
    }
  }
}