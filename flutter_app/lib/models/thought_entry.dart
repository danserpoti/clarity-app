// lib/models/thought_entry.dart
// 思考記録のデータモデル - Next.js版との互換性を保持

import 'dart:convert';

/// 思考記録のカテゴリ
enum ThoughtCategory {
  work('仕事'),
  relationships('人間関係'), 
  goals('目標管理'),
  learning('学習'),
  emotions('感情'),
  other('その他');

  const ThoughtCategory(this.displayName);
  final String displayName;

  static ThoughtCategory fromString(String value) {
    switch (value) {
      case '仕事':
        return ThoughtCategory.work;
      case '人間関係':
        return ThoughtCategory.relationships;
      case '目標管理':
        return ThoughtCategory.goals;
      case '学習':
        return ThoughtCategory.learning;
      case '感情':
        return ThoughtCategory.emotions;
      case 'その他':
      default:
        return ThoughtCategory.other;
    }
  }
}

/// AI分析による感情タイプ
enum EmotionType {
  positive('positive'),
  negative('negative'),
  neutral('neutral'),
  mixed('mixed');

  const EmotionType(this.value);
  final String value;

  static EmotionType? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'positive':
        return EmotionType.positive;
      case 'negative':
        return EmotionType.negative;
      case 'neutral':
        return EmotionType.neutral;
      case 'mixed':
        return EmotionType.mixed;
      default:
        return null;
    }
  }
}

/// 思考記録エントリー
/// Next.js版のThoughtEntryインターフェースと完全互換
class ThoughtEntry {
  final String id;
  final String content;
  final ThoughtCategory category;
  final String entryDate; // YYYY-MM-DD形式
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // AI分析結果（オプション）
  final EmotionType? aiEmotion;
  final double? aiEmotionScore; // 0.0-1.0の範囲
  final List<String>? aiThemes;
  final List<String>? aiKeywords;
  final String? aiSummary;
  final String? aiSuggestion;
  final DateTime? aiAnalyzedAt;

  const ThoughtEntry({
    required this.id,
    required this.content,
    required this.category,
    required this.entryDate,
    required this.createdAt,
    required this.updatedAt,
    this.aiEmotion,
    this.aiEmotionScore,
    this.aiThemes,
    this.aiKeywords,
    this.aiSummary,
    this.aiSuggestion,
    this.aiAnalyzedAt,
  });

  /// AI分析済みかどうか
  bool get hasAiAnalysis => aiEmotion != null;

  /// 感情スコアの百分率表示
  int? get emotionScorePercentage => 
      aiEmotionScore != null ? (aiEmotionScore! * 100).round() : null;

  /// JSONへの変換（Next.js版との互換性）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'category': category.displayName,
      'entry_date': entryDate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'ai_emotion': aiEmotion?.value,
      'ai_emotion_score': aiEmotionScore,
      'ai_themes': aiThemes,
      'ai_keywords': aiKeywords,
      'ai_summary': aiSummary,
      'ai_suggestion': aiSuggestion,
      'ai_analyzed_at': aiAnalyzedAt?.toIso8601String(),
    };
  }

  /// JSONからの変換
  factory ThoughtEntry.fromJson(Map<String, dynamic> json) {
    return ThoughtEntry(
      id: json['id'] as String,
      content: json['content'] as String,
      category: ThoughtCategory.fromString(json['category'] as String),
      entryDate: json['entry_date'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      aiEmotion: EmotionType.fromString(json['ai_emotion'] as String?),
      aiEmotionScore: json['ai_emotion_score'] as double?,
      aiThemes: json['ai_themes'] != null 
          ? List<String>.from(json['ai_themes'] as List)
          : null,
      aiKeywords: json['ai_keywords'] != null
          ? List<String>.from(json['ai_keywords'] as List)
          : null,
      aiSummary: json['ai_summary'] as String?,
      aiSuggestion: json['ai_suggestion'] as String?,
      aiAnalyzedAt: json['ai_analyzed_at'] != null
          ? DateTime.parse(json['ai_analyzed_at'] as String)
          : null,
    );
  }

  /// SQLite用のMap変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'category': category.displayName,
      'entry_date': entryDate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'ai_emotion': aiEmotion?.value,
      'ai_emotion_score': aiEmotionScore,
      'ai_themes': aiThemes != null ? jsonEncode(aiThemes) : null,
      'ai_keywords': aiKeywords != null ? jsonEncode(aiKeywords) : null,
      'ai_summary': aiSummary,
      'ai_suggestion': aiSuggestion,
      'ai_analyzed_at': aiAnalyzedAt?.toIso8601String(),
    };
  }

  /// SQLiteのMapから変換
  factory ThoughtEntry.fromMap(Map<String, dynamic> map) {
    return ThoughtEntry(
      id: map['id'] as String,
      content: map['content'] as String,
      category: ThoughtCategory.fromString(map['category'] as String),
      entryDate: map['entry_date'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      aiEmotion: EmotionType.fromString(map['ai_emotion'] as String?),
      aiEmotionScore: map['ai_emotion_score'] as double?,
      aiThemes: map['ai_themes'] != null
          ? List<String>.from(jsonDecode(map['ai_themes'] as String))
          : null,
      aiKeywords: map['ai_keywords'] != null
          ? List<String>.from(jsonDecode(map['ai_keywords'] as String))
          : null,
      aiSummary: map['ai_summary'] as String?,
      aiSuggestion: map['ai_suggestion'] as String?,
      aiAnalyzedAt: map['ai_analyzed_at'] != null
          ? DateTime.parse(map['ai_analyzed_at'] as String)
          : null,
    );
  }

  /// コピーメソッド（AI分析結果の追加時に使用）
  ThoughtEntry copyWith({
    String? id,
    String? content,
    ThoughtCategory? category,
    String? entryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    EmotionType? aiEmotion,
    double? aiEmotionScore,
    List<String>? aiThemes,
    List<String>? aiKeywords,
    String? aiSummary,
    String? aiSuggestion,
    DateTime? aiAnalyzedAt,
  }) {
    return ThoughtEntry(
      id: id ?? this.id,
      content: content ?? this.content,
      category: category ?? this.category,
      entryDate: entryDate ?? this.entryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      aiEmotion: aiEmotion ?? this.aiEmotion,
      aiEmotionScore: aiEmotionScore ?? this.aiEmotionScore,
      aiThemes: aiThemes ?? this.aiThemes,
      aiKeywords: aiKeywords ?? this.aiKeywords,
      aiSummary: aiSummary ?? this.aiSummary,
      aiSuggestion: aiSuggestion ?? this.aiSuggestion,
      aiAnalyzedAt: aiAnalyzedAt ?? this.aiAnalyzedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThoughtEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ThoughtEntry(id: $id, category: ${category.displayName}, hasAiAnalysis: $hasAiAnalysis)';
  }
}