// lib/models/usage_info.dart
// 使用量情報モデル - バックエンドAPIの使用量制限管理

/// API使用量情報
class UsageInfo {
  final int used;           // 使用済み回数
  final int limit;          // 制限回数
  final int remaining;      // 残り回数
  final DateTime resetDate; // リセット日
  final UsageWarning? warning; // 警告情報（オプション）

  const UsageInfo({
    required this.used,
    required this.limit,
    required this.remaining,
    required this.resetDate,
    this.warning,
  });

  /// 使用率（0.0-1.0）
  double get usagePercentage => limit > 0 ? used / limit : 0.0;

  /// 使用率（パーセント表示用）
  int get usagePercent => (usagePercentage * 100).round();

  /// 制限に到達しているか
  bool get isLimitReached => remaining <= 0;

  /// 制限に近づいているか（90%以上）
  bool get isNearLimit => usagePercentage >= 0.9;

  /// リセットまでの日数
  int get daysUntilReset {
    final now = DateTime.now();
    final difference = resetDate.difference(now);
    return difference.inDays;
  }

  /// JSONからの変換
  factory UsageInfo.fromJson(Map<String, dynamic> json) {
    return UsageInfo(
      used: json['used'] as int? ?? 0,
      limit: json['limit'] as int? ?? 30,
      remaining: json['remaining'] as int? ?? 0,
      resetDate: DateTime.parse(json['resetDate'] as String? ?? DateTime.now().toIso8601String()),
      warning: json['warning'] != null 
          ? UsageWarning.fromJson(json['warning'] as Map<String, dynamic>)
          : null,
    );
  }

  /// JSONへの変換
  Map<String, dynamic> toJson() {
    return {
      'used': used,
      'limit': limit,
      'remaining': remaining,
      'resetDate': resetDate.toIso8601String(),
      'warning': warning?.toJson(),
    };
  }

  /// コピーメソッド
  UsageInfo copyWith({
    int? used,
    int? limit,
    int? remaining,
    DateTime? resetDate,
    UsageWarning? warning,
  }) {
    return UsageInfo(
      used: used ?? this.used,
      limit: limit ?? this.limit,
      remaining: remaining ?? this.remaining,
      resetDate: resetDate ?? this.resetDate,
      warning: warning ?? this.warning,
    );
  }

  @override
  String toString() {
    return 'UsageInfo(used: $used, limit: $limit, remaining: $remaining, resetDate: $resetDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsageInfo &&
        other.used == used &&
        other.limit == limit &&
        other.remaining == remaining &&
        other.resetDate == resetDate &&
        other.warning == warning;
  }

  @override
  int get hashCode {
    return Object.hash(used, limit, remaining, resetDate, warning);
  }
}

/// 使用量警告情報
class UsageWarning {
  final bool nearLimit;     // 制限に近いか
  final String message;     // 警告メッセージ
  final int usagePercentage; // 使用率（パーセント）

  const UsageWarning({
    required this.nearLimit,
    required this.message,
    required this.usagePercentage,
  });

  /// JSONからの変換
  factory UsageWarning.fromJson(Map<String, dynamic> json) {
    return UsageWarning(
      nearLimit: json['nearLimit'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      usagePercentage: json['usagePercentage'] as int? ?? 0,
    );
  }

  /// JSONへの変換
  Map<String, dynamic> toJson() {
    return {
      'nearLimit': nearLimit,
      'message': message,
      'usagePercentage': usagePercentage,
    };
  }

  @override
  String toString() {
    return 'UsageWarning(nearLimit: $nearLimit, message: $message, usagePercentage: $usagePercentage)';
  }
}

/// アップグレード情報
class UpgradeInfo {
  final bool recommended;   // アップグレード推奨か
  final String url;         // アップグレードURL
  final String message;     // アップグレードメッセージ
  final List<String> benefits; // 特典リスト

  const UpgradeInfo({
    required this.recommended,
    required this.url,
    required this.message,
    required this.benefits,
  });

  /// JSONからの変換
  factory UpgradeInfo.fromJson(Map<String, dynamic> json) {
    return UpgradeInfo(
      recommended: json['recommended'] as bool? ?? false,
      url: json['url'] as String? ?? '',
      message: json['message'] as String? ?? '',
      benefits: (json['benefits'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }

  /// JSONへの変換
  Map<String, dynamic> toJson() {
    return {
      'recommended': recommended,
      'url': url,
      'message': message,
      'benefits': benefits,
    };
  }

  @override
  String toString() {
    return 'UpgradeInfo(recommended: $recommended, url: $url, message: $message, benefits: $benefits)';
  }
}

/// API分析レスポンス（使用量情報付き）
class AnalysisResponse {
  final bool success;
  final AnalysisResult? analysis;
  final UsageInfo? usage;
  final String? error;
  final String? message;
  final UpgradeInfo? upgrade;
  final Map<String, dynamic>? metadata;

  const AnalysisResponse({
    required this.success,
    this.analysis,
    this.usage,
    this.error,
    this.message,
    this.upgrade,
    this.metadata,
  });

  /// 使用量制限エラーかどうか
  bool get isUsageLimitError => error == 'USAGE_LIMIT_EXCEEDED';

  /// レート制限エラーかどうか
  bool get isRateLimitError => error == 'RATE_LIMIT_EXCEEDED';

  /// サービス利用不可エラーかどうか
  bool get isServiceUnavailable => error == 'SERVICE_UNAVAILABLE';

  /// JSONからの変換
  factory AnalysisResponse.fromJson(Map<String, dynamic> json) {
    return AnalysisResponse(
      success: json['success'] as bool? ?? false,
      analysis: json['analysis'] != null
          ? AnalysisResult.fromJson(json['analysis'] as Map<String, dynamic>)
          : null,
      usage: json['usage'] != null
          ? UsageInfo.fromJson(json['usage'] as Map<String, dynamic>)
          : null,
      error: json['error'] as String?,
      message: json['message'] as String?,
      upgrade: json['upgrade'] != null
          ? UpgradeInfo.fromJson(json['upgrade'] as Map<String, dynamic>)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// JSONへの変換
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'analysis': analysis?.toJson(),
      'usage': usage?.toJson(),
      'error': error,
      'message': message,
      'upgrade': upgrade?.toJson(),
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'AnalysisResponse(success: $success, error: $error, hasAnalysis: ${analysis != null}, hasUsage: ${usage != null})';
  }
}

// 既存のAnalysisResultモデルをインポート（互換性のため）
import 'analysis_result.dart';