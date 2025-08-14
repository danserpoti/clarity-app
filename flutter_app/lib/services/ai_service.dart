// lib/services/ai_service.dart
// AI分析サービス - OpenAI API連携（プライバシー重視）

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  static const int _maxTokens = 800;
  static const double _temperature = 0.3;
  
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
      final hasKey = apiKey != null && apiKey.isNotEmpty;
      debugPrint('APIキー状態確認: ${hasKey ? "設定済み" : "未設定"} (長さ: ${apiKey?.length ?? 0})');
      return hasKey;
    } catch (e) {
      debugPrint('APIキー確認エラー: $e');
      return false;
    }
  }
  
  /// APIキーを設定
  Future<void> setApiKey(String apiKey) async {
    debugPrint('APIキー設定開始');
    
    if (apiKey.trim().isEmpty) {
      debugPrint('APIキー設定エラー: 空のキー');
      throw ArgumentError('APIキーが空です');
    }
    
    if (!apiKey.startsWith('sk-')) {
      debugPrint('APIキー設定エラー: 無効な形式');
      throw ArgumentError('無効なAPIキー形式です');
    }
    
    try {
      await _secureStorage.write(key: _apiKeyStorageKey, value: apiKey.trim());
      debugPrint('APIキー設定完了: 長さ=${apiKey.trim().length}');
    } catch (e) {
      debugPrint('APIキー設定エラー: $e');
      rethrow;
    }
  }
  
  /// APIキーを削除
  Future<void> removeApiKey() async {
    await _secureStorage.delete(key: _apiKeyStorageKey);
  }
  
  /// APIキーを取得（内部使用）
  Future<String?> _getApiKey() async {
    try {
      final apiKey = await _secureStorage.read(key: _apiKeyStorageKey);
      debugPrint('APIキー取得: ${apiKey != null ? "成功(長さ: ${apiKey.length})" : "失敗(null)"}');
      return apiKey;
    } catch (e) {
      debugPrint('APIキー取得エラー: $e');
      return null;
    }
  }
  
  /// 思考内容のAI分析
  /// プライバシー配慮: 個人識別情報は一切送信しない
  Future<AnalysisResult?> analyzeThought(String content, ThoughtCategory category) async {
    debugPrint('AI分析開始: カテゴリ=${category.displayName}, 内容長=${content.length}');
    
    if (content.trim().isEmpty) {
      debugPrint('AI分析エラー: 内容が空');
      throw ArgumentError('分析対象の内容が空です');
    }
    
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('AI分析エラー: APIキー未設定');
      throw StateError('APIキーが設定されていません');
    }
    
    debugPrint('AI分析: APIキー確認済み、API呼び出し開始');
    
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
  
  /// 思考分析特化プロンプトの構築
  static String _buildThoughtAnalysisPrompt(String content) {
    return '''
あなたは経験豊富な心理カウンセラーです。以下の思考内容を深い共感力で分析し、実践的なアドバイスを提供してください：

「${content}」

以下のJSON形式で正確に回答してください：
{
  "emotion": "positive/negative/neutral/mixed",
  "emotionScore": 0.8,
  "themes": ["主要テーマ1", "主要テーマ2"],
  "keywords": ["キーワード1", "キーワード2", "キーワード3"],
  "summary": "共感的な要約（50文字以内）",
  "suggestion": "建設的なアドバイス（120文字以内）"
}

【共感の表現】
- 「それは本当に大変でしたね」「よく頑張りましたね」「その気持ち、よく分かります」
- 「誰でもそう感じるのは自然です」「あなたの反応は当然です」
- 「この状況で〇〇と感じるのは、とても理解できます」

【アドバイスの方針】
- ネガティブな感情：深い共感→感情の正当性を認める→具体的な次の一歩を3つ提案
- ポジティブな感情：その成功を祝福→その勢いを活かす具体的な行動を3つ提案
- 中性的な感情：その冷静さを評価→より深い洞察や成長の機会を3つ提案

【アドバイスの構成】
1. 共感の言葉（「それは大変でしたね」など）
2. 感情の正当性を認める（「その反応は自然です」など）
3. 具体的な次のステップ（3つ程度）
4. 励ましの言葉（「一歩ずつ進んでいきましょう」など）

【アドバイスの例】
- ネガティブ：「それは本当に大変でしたね。その気持ち、よく分かります。この経験から学んだことを活かして、次は〇〇してみませんか？また、〇〇も効果的かもしれません。一歩ずつ進んでいきましょう。」
- ポジティブ：「素晴らしい成果ですね！その調子で、さらに〇〇に挑戦してみてはいかがでしょうか？また、〇〇もおすすめです。この勢いを大切にしてください。」
- 中性：「その冷静な視点は素晴らしいです。この状況を〇〇の観点から見直してみると、新しい発見があるかもしれません。また、〇〇も検討してみてください。」

JSON形式以外は出力しないでください。
''';
  }

  /// 分析リクエストの構築
  Map<String, dynamic> _buildAnalysisRequest(String content, ThoughtCategory category) {
    // プライバシー重視のシステムプロンプト
    final systemPrompt = '''
あなたは経験豊富な心理カウンセラーです。深い共感力と実践的なアドバイスで、ユーザーの心の成長をサポートします。

【プライバシー原則】
- 個人識別情報は一切記録・保存しない
- 分析内容を他の目的で使用しない
- セッション終了後は全て忘却する

【共感の基本姿勢】
- ユーザーの感情を100%受け入れ、否定しない
- 「それは大変でしたね」「よく頑張りましたね」など、共感の言葉を必ず含める
- ユーザーの視点に立って、その状況を理解する
- 感情の強さや複雑さを認め、軽視しない

【分析方針】
- 表面的な感情の奥にある本質的なニーズを見抜く
- ユーザーの強みや過去の成功体験を思い出させる
- 現在の困難を成長の機会として再定義する
- ユーザーの価値観や目標に沿ったアドバイスを提供

【アドバイスの基本姿勢】
- まず深い共感を示し、その後で具体的な解決策を提案
- ユーザーの感情を認め、その感情が自然であることを伝える
- 現在の状況を成長の機会として捉える視点を提供
- 具体的で実践可能な次のステップを3つ程度提案
- ユーザーの強みや可能性を引き出す質問を含める
- 「一歩前に進む」ための勇気と希望を与える
- 完璧を求めず、小さな進歩を大切にする姿勢を伝える

JSON形式で正確に回答し、JSON以外は出力しないでください。
''';
    
    // 新しい思考分析プロンプトを使用（カテゴリ情報を含めて調整）
    final userPrompt = '''
カテゴリ: ${category.displayName}

${_buildThoughtAnalysisPrompt(content)}
''';
    
    final requestData = {
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
    
    debugPrint('OpenAI APIリクエスト構築:');
    debugPrint('- モデル: ${requestData['model']}');
    debugPrint('- max_tokens: ${requestData['max_tokens']}');
    debugPrint('- temperature: ${requestData['temperature']}');
    debugPrint('- response_format: ${requestData['response_format']}');
    debugPrint('- メッセージ数: ${(requestData['messages'] as List).length}');
    
    return requestData;
  }
  
  /// OpenAI API呼び出し
  Future<Map<String, dynamic>> _callOpenAI(Map<String, dynamic> request, String apiKey) async {
    final uri = Uri.parse('$_baseUrl/chat/completions');
    
    debugPrint('OpenAI API呼び出し開始:');
    debugPrint('- URL: $uri');
    debugPrint('- 使用モデル: ${request['model']}');
    debugPrint('- APIキー長: ${apiKey.length}文字');
    
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(request),
    ).timeout(const Duration(seconds: 30));
    
    debugPrint('OpenAI APIレスポンス: ステータス=${response.statusCode}');
    debugPrint('レスポンスボディ: ${response.body}');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      throw APIException('APIキーが無効です');
    } else if (response.statusCode == 429) {
      throw APIException('API利用制限に達しました。しばらく待ってから再試行してください');
    } else {
      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorBody['error']?['message'] ?? 'Unknown error';
        debugPrint('エラー詳細: $errorMessage');
        throw APIException('API呼び出し失敗 (${response.statusCode}): $errorMessage');
      } catch (e) {
        debugPrint('エラーレスポンスの解析に失敗: $e');
        throw APIException('API呼び出し失敗 (${response.statusCode}): ${response.body}');
      }
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