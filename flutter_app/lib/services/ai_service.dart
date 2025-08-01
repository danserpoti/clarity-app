// lib/services/ai_service.dart
// AI分析サービス - OpenAI API連携（プライバシー重視）

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/thought_entry.dart';
import '../models/analysis_result.dart';

/// AI分析サービス
/// プライバシーファースト設計：
/// - データ最小化: 必要最小限の情報のみ送信
/// - 一時的処理: 永続化なし
/// - ユーザー制御: 分析のON/OFF可能
class AIService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _model = 'gpt-4o-mini';
  static const int _maxTokens = 500;
  static const double _temperature = 0.7;
  
  // セキュアストレージ
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  static const String _apiKeyStorageKey = 'openai_api_key';
  
  /// シングルトンインスタンス
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();
  
  /// APIキーが設定されているかチェック
  Future<bool> hasApiKey() async {
    try {
      final apiKey = await _secureStorage.read(key: _apiKeyStorageKey);
      return apiKey != null && apiKey.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// APIキーを設定
  Future<void> setApiKey(String apiKey) async {
    if (apiKey.trim().isEmpty) {
      throw ArgumentError('APIキーが空です');
    }
    
    if (!apiKey.startsWith('sk-')) {
      throw ArgumentError('無効なAPIキー形式です');
    }
    
    await _secureStorage.write(key: _apiKeyStorageKey, value: apiKey.trim());
  }
  
  /// APIキーを削除
  Future<void> removeApiKey() async {
    await _secureStorage.delete(key: _apiKeyStorageKey);
  }
  
  /// APIキーを取得（内部使用）
  Future<String?> _getApiKey() async {
    return await _secureStorage.read(key: _apiKeyStorageKey);
  }
  
  /// 思考内容のAI分析
  /// プライバシー配慮: 個人識別情報は一切送信しない
  Future<AnalysisResult?> analyzeThought(String content, ThoughtCategory category) async {
    if (content.trim().isEmpty) {
      throw ArgumentError('分析対象の内容が空です');
    }
    
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('APIキーが設定されていません');
    }
    
    try {
      // リクエスト準備
      final request = _buildAnalysisRequest(content, category);
      
      // API呼び出し
      final response = await _callOpenAI(request, apiKey);
      
      // レスポンス解析
      return _parseAnalysisResponse(response);
      
    } on SocketException {
      throw NetworkException('ネットワーク接続エラーです');
    } on HttpException catch (e) {
      throw APIException('API呼び出しエラー: ${e.message}');
    } catch (e) {
      throw AnalysisException('分析処理エラー: $e');
    }
  }
  
  /// 分析リクエストの構築
  Map<String, dynamic> _buildAnalysisRequest(String content, ThoughtCategory category) {
    // プライバシー重視のシステムプロンプト
    final systemPrompt = '''
あなたは思考分析の専門家です。プライバシーを最重視し、以下の原則に従ってください：

【プライバシー原則】
- 個人識別情報は一切記録・保存しない
- 分析内容を他の目的で使用しない
- セッション終了後は全て忘却する

【分析タスク】
ユーザーの思考内容を分析し、以下のJSON形式で応答してください：

{
  "emotion": "positive|negative|neutral|mixed",
  "emotion_score": 0.0-1.0の信頼度,
  "themes": ["テーマ1", "テーマ2", ...],
  "keywords": ["キーワード1", "キーワード2", ...],
  "summary": "内容の要約（50文字以内）",
  "suggestion": "建設的な提案やアドバイス（100文字以内）"
}

【注意事項】
- 感情は必ずpositive/negative/neutral/mixedのいずれか
- テーマとキーワードは日本語で5個以内
- 提案は前向きで建設的なものに
- JSON形式厳守、余計な説明は不要
''';
    
    final userPrompt = '''
カテゴリ: ${category.displayName}
思考内容: $content

上記の思考内容を分析してください。
''';
    
    return {
      'model': _model,
      'messages': [
        {
          'role': 'system',
          'content': systemPrompt,
        },
        {
          'role': 'user',
          'content': userPrompt,
        },
      ],
      'max_tokens': _maxTokens,
      'temperature': _temperature,
      'response_format': {'type': 'json_object'},
    };
  }
  
  /// OpenAI API呼び出し
  Future<Map<String, dynamic>> _callOpenAI(Map<String, dynamic> request, String apiKey) async {
    final uri = Uri.parse('$_baseUrl/chat/completions');
    
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(request),
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      throw APIException('APIキーが無効です');
    } else if (response.statusCode == 429) {
      throw APIException('API利用制限に達しました。しばらく待ってから再試行してください');
    } else {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      final errorMessage = errorBody['error']?['message'] ?? 'Unknown error';
      throw APIException('API呼び出し失敗 (${response.statusCode}): $errorMessage');
    }
  }
  
  /// API応答の解析
  AnalysisResult _parseAnalysisResponse(Map<String, dynamic> response) {
    try {
      final choices = response['choices'] as List;
      if (choices.isEmpty) {
        throw AnalysisException('API応答が空です');
      }
      
      final message = choices[0]['message'] as Map<String, dynamic>;
      final content = message['content'] as String;
      
      // JSONパース
      final analysisData = jsonDecode(content) as Map<String, dynamic>;
      
      return AnalysisResult(
        emotion: EmotionType.fromString(analysisData['emotion'] as String?) ?? EmotionType.neutral,
        emotionScore: _parseDouble(analysisData['emotion_score']) ?? 0.5,
        themes: _parseStringList(analysisData['themes']) ?? [],
        keywords: _parseStringList(analysisData['keywords']) ?? [],
        summary: analysisData['summary'] as String? ?? '',
        suggestion: analysisData['suggestion'] as String? ?? '',
        analyzedAt: DateTime.now(),
      );
      
    } catch (e) {
      throw AnalysisException('応答解析エラー: $e');
    }
  }
  
  /// 安全なdouble変換
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  /// 安全なString配列変換
  List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }
  
  /// API接続テスト
  Future<bool> testConnection() async {
    try {
      await analyzeThought('テスト', ThoughtCategory.other);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 利用統計の取得（プライバシー配慮）
  Future<Map<String, dynamic>> getUsageStats() async {
    // 実際の実装では使用量制限の確認などを行う
    // 現在はダミーデータ
    return {
      'total_requests': 0,
      'successful_requests': 0,
      'error_requests': 0,
      'last_request_at': null,
    };
  }
}

/// AI分析関連の例外クラス
abstract class AIException implements Exception {
  final String message;
  const AIException(this.message);
  
  @override
  String toString() => message;
}

class NetworkException extends AIException {
  const NetworkException(super.message);
}

class APIException extends AIException {
  const APIException(super.message);
}

class AnalysisException extends AIException {
  const AnalysisException(super.message);
}

/// AI分析サービスの設定
class AIServiceConfig {
  final bool enableAnalysis;
  final bool enableAutoAnalysis;
  final bool enableDataEncryption;
  final int maxRetries;
  final Duration requestTimeout;
  
  const AIServiceConfig({
    this.enableAnalysis = true,
    this.enableAutoAnalysis = false,
    this.enableDataEncryption = true,
    this.maxRetries = 3,
    this.requestTimeout = const Duration(seconds: 30),
  });
  
  /// 設定の保存
  Future<void> save() async {
    // SharedPreferencesを使用して設定を保存
    // 実装は簡略化
  }
  
  /// 設定の読み込み
  static Future<AIServiceConfig> load() async {
    // SharedPreferencesから設定を読み込み
    // 実装は簡略化
    return const AIServiceConfig();
  }
}