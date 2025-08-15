// lib/services/ai_service.dart
// AI分析サービス - バックエンドAPI経由でGPT-5-mini-2025-08-07を使用

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/thought_entry.dart';
import '../models/analysis_result.dart';
import '../models/usage_info.dart';
import '../services/device_id_service.dart';

/// AI分析サービス - バックエンドAPI統合版
/// 
/// 主な変更点：
/// - OpenAI直接呼び出しを削除
/// - 独自バックエンドAPI経由でAI分析
/// - 使用量制限機能を追加
/// - APIキー設定不要（バックエンドで管理）
/// - デバイスID による匿名使用量管理
class AIService {
  // ⚠️ TODO: 実際のVercelデプロイURLに変更してください
  static const String _backendUrl = 'https://clarity-backend-api.vercel.app';
  static const String _analyzeEndpoint = '/api/analyze';
  
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const String _usageInfoKey = 'clarity_usage_info';
  
  /// シングルトンインスタンス
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();
  
  /// デバイスIDサービス
  final DeviceIdService _deviceIdService = DeviceIdService();
  
  /// 最後の使用量情報（キャッシュ用）
  UsageInfo? _lastUsageInfo;
  
  /// バックエンドAPIが利用可能かチェック
  /// 従来のhasApiKey()の代替メソッド
  Future<bool> hasApiKey() async {
    try {
      return await _checkBackendHealth();
    } catch (e) {
      debugPrint('バックエンドAPI接続確認エラー: $e');
      return false;
    }
  }
  
  /// 思考内容のAI分析（バックエンドAPI経由）
  Future<AnalysisResult?> analyzeThought(String content, ThoughtCategory category) async {
    debugPrint('AI分析開始: カテゴリ=${category.displayName}, 内容長=${content.length}');
    
    if (content.trim().isEmpty) {
      debugPrint('AI分析エラー: 内容が空');
      throw ArgumentError('分析対象の内容が空です');
    }
    
    try {
      // デバイスIDを取得
      final deviceId = await _deviceIdService.getDeviceId();
      
      // バックエンドAPIにリクエスト送信
      final response = await _callBackendAPI(
        content: content,
        category: category.displayName,
        deviceId: deviceId,
      );
      
      if (response.success && response.analysis != null) {
        // 使用量情報を保存
        if (response.usage != null) {
          await _saveUsageInfo(response.usage!);
          _lastUsageInfo = response.usage;
        }
        
        debugPrint('AI分析成功: emotion=${response.analysis!.emotion.value}');
        return response.analysis;
      } else {
        // エラーハンドリング
        _handleAnalysisError(response);
        return null;
      }
    } on SocketException {
      throw NetworkException('ネットワーク接続エラーです。インターネット接続を確認してください。');
    } on HttpException catch (e) {
      throw APIException('API呼び出しエラー: ${e.message}');
    } catch (e) {
      debugPrint('AI分析エラー: $e');
      throw AnalysisException('分析処理エラー: $e');
    }
  }
  
  /// バックエンドAPIを呼び出し
  Future<AnalysisResponse> _callBackendAPI({
    required String content,
    required String category,
    required String deviceId,
  }) async {
    final url = Uri.parse('$_backendUrl$_analyzeEndpoint');
    
    final requestBody = {
      'content': content,
      'category': category,
      'deviceId': deviceId,
    };
    
    debugPrint('バックエンドAPI呼び出し: $url');
    debugPrint('リクエストデータ: デバイスID=${deviceId.substring(0, 8)}..., カテゴリ=$category');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'ClarityApp/1.0 Flutter',
      },
      body: jsonEncode(requestBody),
    ).timeout(_requestTimeout);
    
    debugPrint('API応答: ステータス=${response.statusCode}');
    
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return AnalysisResponse.fromJson(jsonData);
    } else if (response.statusCode == 429) {
      // 使用量制限またはレート制限
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return AnalysisResponse.fromJson(jsonData);
    } else if (response.statusCode == 400) {
      // 入力エラー
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      throw ValidationException(jsonData['message'] as String? ?? '入力データが無効です');
    } else if (response.statusCode == 503) {
      // サービス利用不可
      throw ServiceUnavailableException('AI分析サービスが一時的に利用できません');
    } else {
      throw APIException('API呼び出し失敗 (${response.statusCode}): ${response.body}');
    }
  }
  
  /// 分析エラーのハンドリング
  void _handleAnalysisError(AnalysisResponse response) {
    if (response.isUsageLimitError) {
      throw UsageLimitException(
        response.message ?? '月間使用量上限に達しました',
        usageInfo: response.usage,
        upgradeInfo: response.upgrade,
      );
    } else if (response.isRateLimitError) {
      throw RateLimitException(response.message ?? 'リクエスト制限に達しました。しばらく待ってから再試行してください。');
    } else if (response.isServiceUnavailable) {
      throw ServiceUnavailableException(response.message ?? 'サービスが一時的に利用できません');
    } else {
      throw AnalysisException(response.message ?? '分析処理中にエラーが発生しました');
    }
  }
  
  /// バックエンドAPIの健全性チェック
  Future<bool> _checkBackendHealth() async {
    try {
      final url = Uri.parse('$_backendUrl$_analyzeEndpoint');
      
      // OPTIONSリクエストでCORS確認
      final response = await http.head(url).timeout(const Duration(seconds: 10));
      
      return response.statusCode < 500; // サーバーエラー以外なら利用可能
    } catch (e) {
      debugPrint('バックエンドヘルスチェック失敗: $e');
      return false;
    }
  }
  
  /// 使用量情報の取得
  Future<UsageInfo?> getUsageInfo() async {
    try {
      // キャッシュから取得
      if (_lastUsageInfo != null) {
        return _lastUsageInfo;
      }
      
      // ローカルストレージから取得
      final prefs = await SharedPreferences.getInstance();
      final usageJson = prefs.getString(_usageInfoKey);
      
      if (usageJson != null) {
        final usageData = jsonDecode(usageJson) as Map<String, dynamic>;
        _lastUsageInfo = UsageInfo.fromJson(usageData);
        return _lastUsageInfo;
      }
      
      return null;
    } catch (e) {
      debugPrint('使用量情報取得エラー: $e');
      return null;
    }
  }
  
  /// 使用量情報の保存
  Future<void> _saveUsageInfo(UsageInfo usageInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_usageInfoKey, jsonEncode(usageInfo.toJson()));
      _lastUsageInfo = usageInfo;
      debugPrint('使用量情報保存: used=${usageInfo.used}, remaining=${usageInfo.remaining}');
    } catch (e) {
      debugPrint('使用量情報保存エラー: $e');
    }
  }
  
  /// 使用量情報のクリア
  Future<void> clearUsageInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_usageInfoKey);
      _lastUsageInfo = null;
      debugPrint('使用量情報クリア完了');
    } catch (e) {
      debugPrint('使用量情報クリアエラー: $e');
    }
  }
  
  /// デバイスIDリセット（使用量もクリア）
  Future<void> resetDeviceId() async {
    try {
      await _deviceIdService.clearDeviceId();
      await clearUsageInfo();
      debugPrint('デバイスIDと使用量情報をリセット完了');
    } catch (e) {
      debugPrint('デバイスIDリセットエラー: $e');
      throw Exception('デバイスIDのリセットに失敗しました');
    }
  }
  
  /// サービス情報の取得
  Future<Map<String, dynamic>> getServiceInfo() async {
    try {
      final deviceId = await _deviceIdService.getDeviceId();
      final usageInfo = await getUsageInfo();
      final isFirstLaunch = await _deviceIdService.isFirstLaunch();
      
      return {
        'backendUrl': _backendUrl,
        'deviceId': deviceId.substring(0, 8) + '...', // 部分表示
        'hasUsageInfo': usageInfo != null,
        'usageCount': usageInfo?.used ?? 0,
        'usageLimit': usageInfo?.limit ?? 30,
        'isFirstLaunch': isFirstLaunch,
        'serviceAvailable': await _checkBackendHealth(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'backendUrl': _backendUrl,
        'serviceAvailable': false,
      };
    }
  }
  
  /// 接続テスト（従来のメソッドとの互換性）
  Future<bool> testConnection() async {
    return await _checkBackendHealth();
  }
  
  /// 利用統計の取得（従来のメソッドとの互換性）
  Future<Map<String, dynamic>> getUsageStats() async {
    final usageInfo = await getUsageInfo();
    
    return {
      'total_requests': usageInfo?.used ?? 0,
      'successful_requests': usageInfo?.used ?? 0, // バックエンドで管理
      'error_requests': 0, // バックエンドで管理
      'last_request_at': DateTime.now().toIso8601String(),
      'usage_limit': usageInfo?.limit ?? 30,
      'remaining_usage': usageInfo?.remaining ?? 30,
      'reset_date': usageInfo?.resetDate.toIso8601String(),
    };
  }
  
  // 削除されたメソッド（バックエンドで管理されるため不要）
  // - setApiKey() 
  // - removeApiKey()
  // - _getApiKey()
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

class ValidationException extends AIException {
  const ValidationException(super.message);
}

class ServiceUnavailableException extends AIException {
  const ServiceUnavailableException(super.message);
}

class RateLimitException extends AIException {
  const RateLimitException(super.message);
}

/// 使用量制限例外（詳細情報付き）
class UsageLimitException extends AIException {
  final UsageInfo? usageInfo;
  final UpgradeInfo? upgradeInfo;
  
  const UsageLimitException(
    super.message, {
    this.usageInfo,
    this.upgradeInfo,
  });
}

/// AI分析サービスの設定（バックエンド使用のため簡略化）
class AIServiceConfig {
  final bool enableAnalysis;
  final String backendUrl;
  final Duration requestTimeout;
  
  const AIServiceConfig({
    this.enableAnalysis = true,
    this.backendUrl = 'https://clarity-backend-api.vercel.app',
    this.requestTimeout = const Duration(seconds: 30),
  });
  
  /// 設定の保存（SharedPreferences使用）
  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ai_analysis_enabled', enableAnalysis);
      await prefs.setString('backend_url', backendUrl);
      debugPrint('AI設定保存完了');
    } catch (e) {
      debugPrint('AI設定保存エラー: $e');
    }
  }
  
  /// 設定の読み込み
  static Future<AIServiceConfig> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return AIServiceConfig(
        enableAnalysis: prefs.getBool('ai_analysis_enabled') ?? true,
        backendUrl: prefs.getString('backend_url') ?? 'https://clarity-backend-api.vercel.app',
      );
    } catch (e) {
      debugPrint('AI設定読み込みエラー: $e');
      return const AIServiceConfig();
    }
  }
}