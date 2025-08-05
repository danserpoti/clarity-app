// lib/services/notion_service.dart
// Notion API統合サービス - プライバシー重視のバックアップ機能

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/thought_entry.dart';

/// Notion API連携サービス
/// プライバシーファースト設計：
/// - ユーザー制御下でのオプション機能
/// - 必要最小限のデータのみ送信
/// - セキュアなAPI認証
class NotionService {
  final String _apiKey;
  final String _databaseId;
  final Dio _dio;
  
  NotionService({
    required String apiKey,
    required String databaseId,
  }) : _apiKey = apiKey,
       _databaseId = databaseId,
       _dio = Dio() {
    _dio.options.headers = {
      'Authorization': 'Bearer $_apiKey',
      'Notion-Version': '2022-06-28',
      'Content-Type': 'application/json',
    };
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  /// 複数の思考記録をNotionにバックアップ
  Future<BackupResult> backupThoughts(List<ThoughtEntry> thoughts) async {
    if (thoughts.isEmpty) {
      return BackupResult.success(
        backedUpCount: 0,
        pageIds: [],
        timestamp: DateTime.now(),
      );
    }

    try {
      final results = <String>[];
      int successCount = 0;
      final errors = <String>[];
      
      // バッチ処理でページを作成（レート制限を考慮）
      for (int i = 0; i < thoughts.length; i++) {
        try {
          final thought = thoughts[i];
          final pageData = _thoughtToNotionPage(thought);
          
          final response = await _dio.post(
            'https://api.notion.com/v1/pages',
            data: pageData,
          );
          
          if (response.statusCode == 200) {
            results.add(response.data['id']);
            successCount++;
          }
          
          // API制限を避けるため少し待機
          if (i < thoughts.length - 1) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
          
        } catch (e) {
          errors.add('思考記録 ${i + 1}: ${e.toString()}');
          if (kDebugMode) {
            print('Notion backup error for thought ${thoughts[i].id}: $e');
          }
        }
      }
      
      if (successCount > 0) {
        return BackupResult.success(
          backedUpCount: successCount,
          pageIds: results,
          timestamp: DateTime.now(),
          partialErrors: errors.isNotEmpty ? errors : null,
        );
      } else {
        return BackupResult.error(
          'バックアップに失敗しました: ${errors.join(', ')}',
        );
      }
      
    } on DioException catch (e) {
      return BackupResult.error(_handleDioError(e));
    } catch (e) {
      return BackupResult.error('予期しないエラーが発生しました: ${e.toString()}');
    }
  }

  /// 単一の思考記録をNotionにバックアップ
  Future<BackupResult> backupSingleThought(ThoughtEntry thought) async {
    return backupThoughts([thought]);
  }

  /// Notion接続テスト
  Future<bool> testConnection() async {
    try {
      // データベース情報を取得して接続テスト
      final response = await _dio.get(
        'https://api.notion.com/v1/databases/$_databaseId',
      );
      
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Notion connection test failed: ${_handleDioError(e)}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Notion connection test error: $e');
      }
      return false;
    }
  }

  /// ThoughtEntryをNotionページデータに変換
  /// プライバシー配慮：必要最小限の情報のみ送信
  Map<String, dynamic> _thoughtToNotionPage(ThoughtEntry thought) {
    // タイトル用のサマリー作成（100文字以内）
    String title = thought.content.length > 100 
        ? '${thought.content.substring(0, 100)}...'
        : thought.content;
    
    // 改行を削除してタイトルを清潔に
    title = title.replaceAll('\n', ' ').trim();
    
    return {
      'parent': {'database_id': _databaseId},
      'properties': {
        'タイトル': {
          'title': [
            {
              'text': {'content': title}
            }
          ]
        },
        'カテゴリ': {
          'select': {'name': thought.category.displayName}
        },
        '作成日': {
          'date': {'start': thought.createdAt.toIso8601String()}
        },
        if (thought.aiEmotion != null)
          '感情': {
            'select': {'name': _getEmotionDisplayName(thought.aiEmotion!)}
          },
        if (thought.aiEmotionScore != null)
          '感情スコア': {
            'number': thought.aiEmotionScore!
          },
        if (thought.aiThemes != null && thought.aiThemes!.isNotEmpty)
          'テーマ': {
            'multi_select': thought.aiThemes!.map((theme) => {'name': theme}).toList()
          },
      },
      'children': [
        {
          'object': 'block',
          'type': 'paragraph',
          'paragraph': {
            'rich_text': [
              {
                'type': 'text',
                'text': {'content': thought.content}
              }
            ]
          }
        },
        if (thought.aiSummary != null && thought.aiSummary!.isNotEmpty) {
          'object': 'block',
          'type': 'callout',
          'callout': {
            'rich_text': [
              {
                'type': 'text',
                'text': {'content': 'AI分析: ${thought.aiSummary}'}
              }
            ],
            'icon': {'emoji': '🤖'}
          }
        },
        if (thought.aiSuggestion != null && thought.aiSuggestion!.isNotEmpty) {
          'object': 'block',
          'type': 'callout',
          'callout': {
            'rich_text': [
              {
                'type': 'text',
                'text': {'content': '提案: ${thought.aiSuggestion}'}
              }
            ],
            'icon': {'emoji': '💡'}
          }
        },
        if (thought.aiKeywords != null && thought.aiKeywords!.isNotEmpty) {
          'object': 'block',
          'type': 'paragraph',
          'paragraph': {
            'rich_text': [
              {
                'type': 'text',
                'text': {
                  'content': 'キーワード: ${thought.aiKeywords!.join(', ')}'
                }
              }
            ]
          }
        },
      ],
    };
  }

  /// 感情タイプの表示名を取得
  String _getEmotionDisplayName(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.positive:
        return 'ポジティブ';
      case EmotionType.negative:
        return 'ネガティブ';
      case EmotionType.neutral:
        return 'ニュートラル';
      case EmotionType.mixed:
        return 'ミックス';
    }
  }

  /// DioExceptionのエラーハンドリング
  String _handleDioError(DioException error) {
    switch (error.response?.statusCode) {
      case 400:
        return 'リクエストが不正です。Database IDを確認してください。';
      case 401:
        return 'Notion APIキーが無効です。設定を確認してください。';
      case 403:
        return 'データベースへのアクセス権限がありません。';
      case 404:
        return 'データベースが見つかりません。Database IDを確認してください。';
      case 429:
        return 'API制限に達しました。しばらく待ってから再試行してください。';
      case 500:
      case 502:
      case 503:
        return 'Notionサーバーで問題が発生しています。しばらく待ってから再試行してください。';
      default:
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          return '接続がタイムアウトしました。ネットワーク接続を確認してください。';
        }
        return 'Notionとの通信でエラーが発生しました: ${error.message ?? '不明なエラー'}';
    }
  }

  /// リソースの解放
  void dispose() {
    _dio.close();
  }
}

/// バックアップ結果モデル
class BackupResult {
  final bool isSuccess;
  final String? errorMessage;
  final int backedUpCount;
  final List<String> pageIds;
  final DateTime timestamp;
  final List<String>? partialErrors; // 部分的なエラー

  BackupResult._({
    required this.isSuccess,
    this.errorMessage,
    required this.backedUpCount,
    required this.pageIds,
    required this.timestamp,
    this.partialErrors,
  });

  factory BackupResult.success({
    required int backedUpCount,
    required List<String> pageIds,
    required DateTime timestamp,
    List<String>? partialErrors,
  }) => BackupResult._(
    isSuccess: true,
    backedUpCount: backedUpCount,
    pageIds: pageIds,
    timestamp: timestamp,
    partialErrors: partialErrors,
  );

  factory BackupResult.error(String message) => BackupResult._(
    isSuccess: false,
    errorMessage: message,
    backedUpCount: 0,
    pageIds: [],
    timestamp: DateTime.now(),
  );

  /// 部分的な成功かどうか
  bool get hasPartialErrors => partialErrors != null && partialErrors!.isNotEmpty;

  /// 成功率の計算
  double get successRate {
    if (backedUpCount == 0 && (partialErrors?.isEmpty ?? true)) return 0.0;
    final totalAttempts = backedUpCount + (partialErrors?.length ?? 0);
    return totalAttempts > 0 ? backedUpCount / totalAttempts : 0.0;
  }

  @override
  String toString() {
    if (isSuccess) {
      String result = 'バックアップ成功: $backedUpCount件';
      if (hasPartialErrors) {
        result += ' (エラー: ${partialErrors!.length}件)';
      }
      return result;
    } else {
      return 'バックアップ失敗: $errorMessage';
    }
  }
}