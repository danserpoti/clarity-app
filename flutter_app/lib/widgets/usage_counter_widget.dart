// lib/widgets/usage_counter_widget.dart
// 使用量制限表示ウィジェット - Material Design 3準拠

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/usage_info.dart';

/// 使用量表示ウィジェットの表示サイズ
enum UsageCounterSize {
  compact,    // 小さい表示（思考記録画面用）
  standard,   // 標準表示（ホーム画面用）
  detailed,   // 詳細表示（設定画面用）
}

/// 使用量制限表示ウィジェット
/// Material Design 3準拠の美しい使用量表示
class UsageCounterWidget extends StatelessWidget {
  final UsageInfo? usageInfo;
  final UsageCounterSize size;
  final VoidCallback? onUpgrade;
  final bool showUpgradeButton;
  final EdgeInsets? padding;

  const UsageCounterWidget({
    super.key,
    required this.usageInfo,
    this.size = UsageCounterSize.standard,
    this.onUpgrade,
    this.showUpgradeButton = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (usageInfo == null) {
      return _buildLoadingState(context);
    }

    switch (size) {
      case UsageCounterSize.compact:
        return _buildCompactView(context, usageInfo!);
      case UsageCounterSize.standard:
        return _buildStandardView(context, usageInfo!);
      case UsageCounterSize.detailed:
        return _buildDetailedView(context, usageInfo!);
    }
  }

  /// 読み込み中状態
  Widget _buildLoadingState(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '使用量確認中...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// コンパクト表示（思考記録画面用）
  Widget _buildCompactView(BuildContext context, UsageInfo usage) {
    final colors = _getUsageColors(context, usage);
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              value: usage.usagePercentage,
              strokeWidth: 2.5,
              backgroundColor: colors.progressBackground,
              valueColor: AlwaysStoppedAnimation<Color>(colors.progressColor),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${usage.used}/${usage.limit}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (usage.isNearLimit) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.warning_rounded,
              size: 14,
              color: colors.warningColor,
            ),
          ],
        ],
      ),
    );
  }

  /// 標準表示（ホーム画面用）
  Widget _buildStandardView(BuildContext context, UsageInfo usage) {
    final colors = _getUsageColors(context, usage);
    
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colors.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'AI分析使用量',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              // 円形プログレスバー
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: usage.usagePercentage,
                      strokeWidth: 6,
                      backgroundColor: colors.progressBackground,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.progressColor),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: Text(
                          '${usage.usagePercent}%',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.textColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 20),
              
              // 使用量情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${usage.used} / ${usage.limit} 回',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '残り ${usage.remaining} 回',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildResetInfo(context, usage),
                  ],
                ),
              ),
            ],
          ),
          
          if (usage.isNearLimit) ...[
            const SizedBox(height: 16),
            _buildWarningMessage(context, usage),
          ],
        ],
      ),
    );
  }

  /// 詳細表示（設定画面用）
  Widget _buildDetailedView(BuildContext context, UsageInfo usage) {
    final colors = _getUsageColors(context, usage);
    
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colors.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI分析プラン',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'フリープラン',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 使用量表示
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                children: [
                  CircularProgressIndicator(
                    value: usage.usagePercentage,
                    strokeWidth: 8,
                    backgroundColor: colors.progressBackground,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.progressColor),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${usage.used}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.textColor,
                            ),
                          ),
                          Text(
                            '/ ${usage.limit}',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 詳細情報
          _buildDetailedInfo(context, usage),
          
          if (usage.isNearLimit) ...[
            const SizedBox(height: 16),
            _buildWarningMessage(context, usage),
          ],
          
          if (showUpgradeButton) ...[
            const SizedBox(height: 20),
            _buildUpgradeButton(context),
          ],
        ],
      ),
    );
  }

  /// リセット情報表示
  Widget _buildResetInfo(BuildContext context, UsageInfo usage) {
    final resetDate = DateFormat('M月d日').format(usage.resetDate);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.refresh,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            '$resetDateにリセット',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 詳細情報表示
  Widget _buildDetailedInfo(BuildContext context, UsageInfo usage) {
    return Column(
      children: [
        _buildInfoRow(context, '使用済み', '${usage.used} 回'),
        const SizedBox(height: 8),
        _buildInfoRow(context, '残り回数', '${usage.remaining} 回'),
        const SizedBox(height: 8),
        _buildInfoRow(context, 'リセット日', DateFormat('yyyy年M月d日').format(usage.resetDate)),
        const SizedBox(height: 8),
        _buildInfoRow(context, '使用率', '${usage.usagePercent}%'),
      ],
    );
  }

  /// 情報行表示
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// 警告メッセージ表示
  Widget _buildWarningMessage(BuildContext context, UsageInfo usage) {
    String message;
    IconData icon;
    Color color;

    if (usage.isLimitReached) {
      message = '月間使用量上限に達しました';
      icon = Icons.block;
      color = Theme.of(context).colorScheme.error;
    } else if (usage.usagePercentage >= 0.9) {
      message = '使用量が上限に近づいています';
      icon = Icons.warning;
      color = Colors.orange;
    } else {
      message = '使用量をお気をつけください';
      icon = Icons.info;
      color = Colors.amber;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// アップグレードボタン
  Widget _buildUpgradeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        onPressed: onUpgrade,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upgrade,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'プレミアムプランにアップグレード',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 使用量に応じた色を取得
  _UsageColors _getUsageColors(BuildContext context, UsageInfo usage) {
    if (usage.isLimitReached) {
      // 制限到達 - 赤
      return _UsageColors(
        progressColor: Theme.of(context).colorScheme.error,
        progressBackground: Theme.of(context).colorScheme.error.withOpacity(0.2),
        backgroundColor: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
        borderColor: Theme.of(context).colorScheme.error.withOpacity(0.3),
        textColor: Theme.of(context).colorScheme.error,
        warningColor: Theme.of(context).colorScheme.error,
      );
    } else if (usage.usagePercentage >= 0.8) {
      // 80%以上 - オレンジ
      const orange = Colors.orange;
      return _UsageColors(
        progressColor: orange,
        progressBackground: orange.withOpacity(0.2),
        backgroundColor: orange.withOpacity(0.1),
        borderColor: orange.withOpacity(0.3),
        textColor: orange.shade800,
        warningColor: orange,
      );
    } else {
      // 通常 - プライマリカラー
      return _UsageColors(
        progressColor: Theme.of(context).colorScheme.primary,
        progressBackground: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        backgroundColor: Theme.of(context).colorScheme.surface,
        borderColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        textColor: Theme.of(context).colorScheme.onSurface,
        warningColor: Theme.of(context).colorScheme.primary,
      );
    }
  }
}

/// 使用量表示の色情報
class _UsageColors {
  final Color progressColor;
  final Color progressBackground;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color warningColor;

  const _UsageColors({
    required this.progressColor,
    required this.progressBackground,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.warningColor,
  });
}