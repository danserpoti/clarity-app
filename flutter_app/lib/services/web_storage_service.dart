// lib/services/web_storage_service.dart
// Web環境でのlocalStorage代替実装
// shared_preferencesを使用したThoughtEntryのCRUD操作

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/thought_entry.dart';
import '../models/analysis_result.dart';

/// Web環境でのローカルストレージサービス
/// SQLiteが使用できない場合のフォールバック実装
class WebStorageService {
  static WebStorageService? _instance;
  static SharedPreferences? _prefs;
  
  // シングルトンパターン
  WebStorageService._internal();
  
  static WebStorageService get instance {
    _instance ??= WebStorageService._internal();
    return _instance!;
  }
  
  // ストレージキー定数
  static const String _thoughtsKey = 'clarity_thoughts';
  static const String _metadataKey = 'clarity_metadata';
  
  /// SharedPreferencesの初期化
  Future<void> initialize() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      debugPrint('WebStorageService initialized successfully');
    } catch (e) {
      debugPrint('WebStorageService initialization error: $e');
      rethrow;
    }
  }
  
  /// SharedPreferencesインスタンスの取得
  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }
  
  // =============================================================================
  // CRUD 操作
  // =============================================================================
  
  /// 思考記録の挿入
  Future<String> insertThought(ThoughtEntry thought) async {
    final prefs = await _preferences;
    final thoughts = await getAllThoughts();
    
    // 既存の記録から同じIDのものを削除（更新の場合）
    thoughts.removeWhere((t) => t.id == thought.id);
    
    // 新しい記録を追加
    thoughts.add(thought);
    
    // JSON文字列に変換して保存
    final thoughtsJson = thoughts.map((t) => t.toMap()).toList();
    await prefs.setString(_thoughtsKey, jsonEncode(thoughtsJson));
    
    // メタデータ更新
    await _updateMetadata();
    
    return thought.id;
  }
  
  /// 全思考記録の取得（作成日時降順）
  Future<List<ThoughtEntry>> getAllThoughts() async {
    final prefs = await _preferences;
    final thoughtsJson = prefs.getString(_thoughtsKey);
    
    if (thoughtsJson == null || thoughtsJson.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> decoded = jsonDecode(thoughtsJson);
      final thoughts = decoded
          .map((json) => ThoughtEntry.fromMap(json as Map<String, dynamic>))
          .toList();
      
      // 作成日時で降順ソート
      thoughts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return thoughts;
    } catch (e) {
      debugPrint('Error parsing thoughts from localStorage: $e');
      return [];
    }
  }
  
  /// IDによる思考記録の取得
  Future<ThoughtEntry?> getThought(String id) async {
    final thoughts = await getAllThoughts();
    
    try {
      return thoughts.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// 思考記録の更新
  Future<int> updateThought(ThoughtEntry thought) async {
    await insertThought(thought);
    return 1; // SQLiteの戻り値形式に合わせる
  }
  
  /// 思考記録にAI分析結果を追加
  Future<void> updateThoughtWithAnalysis(String id, AnalysisResult result) async {
    final thought = await getThought(id);
    if (thought == null) return;
    
    final updatedThought = ThoughtEntry(
      id: thought.id,
      content: thought.content,
      category: thought.category,
      entryDate: thought.entryDate,
      createdAt: thought.createdAt,
      updatedAt: DateTime.now(),
      aiEmotion: result.emotion,
      aiEmotionScore: result.emotionScore,
      aiThemes: result.themes,
      aiKeywords: result.keywords,
      aiSummary: result.summary,
      aiSuggestion: result.suggestion,
      aiAnalyzedAt: result.analyzedAt,
    );
    
    await updateThought(updatedThought);
  }
  
  /// 思考記録の削除
  Future<int> deleteThought(String id) async {
    final thoughts = await getAllThoughts();
    final initialLength = thoughts.length;
    
    thoughts.removeWhere((t) => t.id == id);
    
    if (thoughts.length == initialLength) {
      return 0; // 削除されなかった
    }
    
    final prefs = await _preferences;
    final thoughtsJson = thoughts.map((t) => t.toMap()).toList();
    await prefs.setString(_thoughtsKey, jsonEncode(thoughtsJson));
    
    await _updateMetadata();
    return 1; // 削除成功
  }
  
  /// 全思考記録の削除（データリセット用）
  Future<int> deleteAllThoughts() async {
    final prefs = await _preferences;
    final thoughtsCount = (await getAllThoughts()).length;
    
    await prefs.remove(_thoughtsKey);
    await _updateMetadata();
    
    return thoughtsCount;
  }
  
  // =============================================================================
  // 検索・フィルタリング
  // =============================================================================
  
  /// カテゴリによる思考記録の取得
  Future<List<ThoughtEntry>> getThoughtsByCategory(ThoughtCategory category) async {
    final thoughts = await getAllThoughts();
    return thoughts.where((t) => t.category == category).toList();
  }
  
  /// 感情による思考記録の取得
  Future<List<ThoughtEntry>> getThoughtsByEmotion(EmotionType emotion) async {
    final thoughts = await getAllThoughts();
    return thoughts.where((t) => t.aiEmotion == emotion).toList();
  }
  
  /// 日付範囲による思考記録の取得
  Future<List<ThoughtEntry>> getThoughtsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final thoughts = await getAllThoughts();
    return thoughts.where((t) =>
        t.createdAt.isAfter(startDate) && t.createdAt.isBefore(endDate)
    ).toList();
  }
  
  /// キーワード検索（内容・要約・提案を対象）
  Future<List<ThoughtEntry>> searchThoughts(String keyword) async {
    final thoughts = await getAllThoughts();
    final searchPattern = keyword.toLowerCase();
    
    return thoughts.where((t) =>
        t.content.toLowerCase().contains(searchPattern) ||
        (t.aiSummary?.toLowerCase().contains(searchPattern) ?? false) ||
        (t.aiSuggestion?.toLowerCase().contains(searchPattern) ?? false)
    ).toList();
  }
  
  /// AI分析済みの思考記録の取得
  Future<List<ThoughtEntry>> getAnalyzedThoughts() async {
    final thoughts = await getAllThoughts();
    return thoughts.where((t) => t.aiEmotion != null).toList();
  }
  
  // =============================================================================
  // 統計・分析用クエリ
  // =============================================================================
  
  /// 総記録数の取得
  Future<int> getTotalThoughtsCount() async {
    final thoughts = await getAllThoughts();
    return thoughts.length;
  }
  
  /// AI分析済み記録数の取得
  Future<int> getAnalyzedThoughtsCount() async {
    final thoughts = await getAnalyzedThoughts();
    return thoughts.length;
  }
  
  /// 今日の記録数の取得
  Future<int> getTodayThoughtsCount() async {
    final thoughts = await getAllThoughts();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    
    return thoughts.where((t) =>
        t.createdAt.isAfter(todayStart) && t.createdAt.isBefore(tomorrowStart)
    ).length;
  }
  
  /// カテゴリ別統計の取得
  Future<Map<String, int>> getCategoryStats() async {
    final thoughts = await getAllThoughts();
    final Map<String, int> stats = {};
    
    for (final thought in thoughts) {
      final category = thought.category.displayName;
      stats[category] = (stats[category] ?? 0) + 1;
    }
    
    return stats;
  }
  
  /// 感情別統計の取得
  Future<Map<String, int>> getEmotionStats() async {
    final thoughts = await getAnalyzedThoughts();
    final Map<String, int> stats = {};
    
    for (final thought in thoughts) {
      if (thought.aiEmotion != null) {
        final emotion = thought.aiEmotion!.value;
        stats[emotion] = (stats[emotion] ?? 0) + 1;
      }
    }
    
    return stats;
  }
  
  /// 月別思考記録数の取得
  Future<Map<String, int>> getMonthlyStats() async {
    final thoughts = await getAllThoughts();
    final Map<String, int> stats = {};
    
    for (final thought in thoughts) {
      final month = '${thought.createdAt.year}-${thought.createdAt.month.toString().padLeft(2, '0')}';
      stats[month] = (stats[month] ?? 0) + 1;
    }
    
    return stats;
  }
  
  /// 日別思考記録数の取得（過去N日間）
  Future<Map<String, int>> getDailyStats({int days = 30}) async {
    final thoughts = await getAllThoughts();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final Map<String, int> stats = {};
    
    for (final thought in thoughts) {
      if (thought.createdAt.isAfter(cutoffDate)) {
        final date = thought.entryDate.substring(0, 10); // YYYY-MM-DD
        stats[date] = (stats[date] ?? 0) + 1;
      }
    }
    
    return stats;
  }
  
  /// 平均感情スコアの取得
  Future<double> getAverageEmotionScore() async {
    final thoughts = await getAnalyzedThoughts();
    final scoresWithValues = thoughts
        .where((t) => t.aiEmotionScore != null)
        .map((t) => t.aiEmotionScore!)
        .toList();
    
    if (scoresWithValues.isEmpty) return 0.0;
    
    final sum = scoresWithValues.reduce((a, b) => a + b);
    return sum / scoresWithValues.length;
  }
  
  /// 分析統計情報の取得
  Future<AnalysisStats> getAnalysisStats() async {
    final totalAnalyzed = await getAnalyzedThoughtsCount();
    final emotionStatsMap = await getEmotionStats();
    
    // String -> EmotionType 変換
    final Map<EmotionType, int> emotionDistribution = {};
    for (final entry in emotionStatsMap.entries) {
      final emotion = EmotionType.fromString(entry.key);
      if (emotion != null) {
        emotionDistribution[emotion] = entry.value;
      }
    }
    
    // テーマ頻度の計算
    final thoughts = await getAnalyzedThoughts();
    final Map<String, int> themeFrequency = {};
    for (final thought in thoughts) {
      if (thought.aiThemes != null) {
        for (final theme in thought.aiThemes!) {
          themeFrequency[theme] = (themeFrequency[theme] ?? 0) + 1;
        }
      }
    }
    
    final averageScore = await getAverageEmotionScore();
    
    // 最後の分析日時を取得
    DateTime? lastAnalyzedAt;
    final analyzedThoughts = await getAnalyzedThoughts();
    if (analyzedThoughts.isNotEmpty) {
      lastAnalyzedAt = analyzedThoughts
          .where((t) => t.aiAnalyzedAt != null)
          .map((t) => t.aiAnalyzedAt!)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }
    
    return AnalysisStats(
      totalAnalyzed: totalAnalyzed,
      emotionDistribution: emotionDistribution,
      themeFrequency: themeFrequency,
      averageEmotionScore: averageScore,
      lastAnalyzedAt: lastAnalyzedAt,
    );
  }
  
  // =============================================================================
  // ストレージ管理
  // =============================================================================
  
  /// メタデータの更新
  Future<void> _updateMetadata() async {
    final prefs = await _preferences;
    final metadata = {
      'lastModified': DateTime.now().toIso8601String(),
      'version': 1,
    };
    await prefs.setString(_metadataKey, jsonEncode(metadata));
  }
  
  /// ストレージサイズの取得（概算、KB単位）
  Future<double> getStorageSize() async {
    final prefs = await _preferences;
    final thoughtsJson = prefs.getString(_thoughtsKey) ?? '';
    final metadataJson = prefs.getString(_metadataKey) ?? '';
    
    // 文字列のバイト数を概算（UTF-8想定）
    final totalBytes = thoughtsJson.length + metadataJson.length;
    return totalBytes / 1024.0; // KB単位
  }
  
  /// ストレージの最適化（不要なデータの削除）
  Future<void> optimize() async {
    // SharedPreferencesでは特別な最適化は不要
    // メタデータの更新のみ実行
    await _updateMetadata();
    debugPrint('WebStorageService optimization completed');
  }
  
  /// ストレージのクリア（全データ削除）
  Future<void> clear() async {
    final prefs = await _preferences;
    await prefs.remove(_thoughtsKey);
    await prefs.remove(_metadataKey);
    debugPrint('WebStorageService cleared');
  }
}