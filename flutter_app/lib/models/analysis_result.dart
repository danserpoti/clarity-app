// lib/models/analysis_result.dart
// AI分析結果のデータモデル

import 'thought_entry.dart';

/// AI分析結果
/// OpenAI APIからの応答を構造化したもの
class AnalysisResult {
  final EmotionType emotion;
  final double emotionScore; // 0.0-1.0の信頼度
  final List<String> themes;
  final List<String> keywords;
  final String summary;
  final String suggestion;
  final DateTime analyzedAt;

  const AnalysisResult({
    required this.emotion,
    required this.emotionScore,
    required this.themes,
    required this.keywords,
    required this.summary,
    required this.suggestion,
    required this.analyzedAt,
  });

  /// 感情スコアの百分率表示
  int get emotionScorePercentage => (emotionScore * 100).round();

  /// JSONへの変換
  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion.value,
      'emotionScore': emotionScore,
      'themes': themes,
      'keywords': keywords,
      'summary': summary,
      'suggestion': suggestion,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  /// JSONからの変換
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      emotion: EmotionType.fromString(json['emotion'] as String) ?? EmotionType.neutral,
      emotionScore: (json['emotionScore'] as num).toDouble(),
      themes: List<String>.from(json['themes'] as List),
      keywords: List<String>.from(json['keywords'] as List),
      summary: json['summary'] as String,
      suggestion: json['suggestion'] as String,
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
    );
  }

  /// OpenAI APIレスポンスからの変換
  /// APIレスポンスの構造化されたJSONを期待
  factory AnalysisResult.fromOpenAIResponse(Map<String, dynamic> response) {
    // OpenAI APIからの実際のレスポンス形式に合わせて実装
    // 現在はプレースホルダー実装
    return AnalysisResult(
      emotion: EmotionType.fromString(response['emotion'] as String?) ?? EmotionType.neutral,
      emotionScore: (response['emotion_score'] as num?)?.toDouble() ?? 0.5,
      themes: response['themes'] != null 
          ? List<String>.from(response['themes'] as List)
          : [],
      keywords: response['keywords'] != null
          ? List<String>.from(response['keywords'] as List)
          : [],
      summary: response['summary'] as String? ?? '',
      suggestion: response['suggestion'] as String? ?? '',
      analyzedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AnalysisResult(emotion: ${emotion.value}, score: $emotionScorePercentage%, themes: ${themes.length})';
  }
}

/// AI分析のリクエスト情報
class AnalysisRequest {
  final String content;
  final ThoughtCategory category;
  final DateTime requestedAt;

  const AnalysisRequest({
    required this.content,
    required this.category,
    required this.requestedAt,
  });

  /// プライバシー配慮: 最小限の情報のみ送信用
  Map<String, dynamic> toMinimalJson() {
    return {
      'content': content,
      'category': category.displayName,
      // 個人識別情報は一切含めない
      // タイムスタンプも送信しない（プライバシー保護）
    };
  }
}

/// 分析統計情報
class AnalysisStats {
  final int totalAnalyzed;
  final Map<EmotionType, int> emotionDistribution;
  final Map<String, int> themeFrequency;
  final double averageEmotionScore;
  final DateTime? lastAnalyzedAt;

  const AnalysisStats({
    required this.totalAnalyzed,
    required this.emotionDistribution,
    required this.themeFrequency,
    required this.averageEmotionScore,
    this.lastAnalyzedAt,
  });

  /// 最も多い感情
  EmotionType? get mostCommonEmotion {
    if (emotionDistribution.isEmpty) return null;
    
    var maxEntry = emotionDistribution.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return maxEntry.key;
  }

  /// 最も多いテーマ（上位5つ）
  List<String> get topThemes {
    var sortedThemes = themeFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedThemes
        .take(5)
        .map((e) => e.key)
        .toList();
  }

  /// 分析カバー率（0.0-1.0）
  double getAnalysisCoverageRate(int totalThoughts) {
    if (totalThoughts == 0) return 0.0;
    return totalAnalyzed / totalThoughts;
  }
}