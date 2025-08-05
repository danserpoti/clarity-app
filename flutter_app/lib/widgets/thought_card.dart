// lib/widgets/thought_card.dart
// 思考記録表示カード

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/thought_entry.dart';

class ThoughtCard extends StatelessWidget {
  final ThoughtEntry thought;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ThoughtCard({
    super.key,
    required this.thought,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ヘッダー（カテゴリ・日時・アクション）
                _buildHeader(context),
                
                const SizedBox(height: 16),
                
                // 思考内容
                _buildContent(context),
                
                // AI分析結果があれば表示
                if (thought.hasAiAnalysis) ...[
                  const SizedBox(height: 16),
                  _buildAnalysisResult(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ヘッダー部分
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // カテゴリバッジ
        _buildCategoryBadge(context),
        
        const Spacer(),
        
        // 作成日時
        Text(
          _formatDateTime(thought.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        
        // アクションメニュー
        if (onEdit != null || onDelete != null)
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit?.call();
                  break;
                case 'delete':
                  onDelete?.call();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (onEdit != null)
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('編集'),
                    ],
                  ),
                ),
              if (onDelete != null)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('削除', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  /// カテゴリバッジ（グラデーション版）
  Widget _buildCategoryBadge(BuildContext context) {
    final gradientColors = _getCategoryGradientColors(thought.category);
    final icon = _getCategoryIcon(thought.category);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20), // ピル型
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            thought.category.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 思考内容
  Widget _buildContent(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Text(
        thought.content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// AI分析結果表示
  Widget _buildAnalysisResult(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.08),
            Colors.purple.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI分析ヘッダー
          Row(
            children: [
              Icon(
                Icons.psychology,
                size: 16,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                'AI分析結果',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 感情分析
          if (thought.aiEmotion != null) ...[
            Row(
              children: [
                _getEmotionIcon(thought.aiEmotion!),
                const SizedBox(width: 8),
                Text(
                  _getEmotionLabel(thought.aiEmotion!),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (thought.emotionScorePercentage != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getEmotionColor(thought.aiEmotion!).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${thought.emotionScorePercentage}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: _getEmotionColor(thought.aiEmotion!),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          
          // テーマタグ
          if (thought.aiThemes != null && thought.aiThemes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: thought.aiThemes!.take(3).map((theme) =>
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    theme,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ),
              ).toList(),
            ),
          ],
          
          // 要約（短縮版）
          if (thought.aiSummary != null && thought.aiSummary!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              thought.aiSummary!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  /// 日時フォーマット
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return '昨日';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return DateFormat('M/d').format(dateTime);
    }
  }

  /// カテゴリの色を取得
  Color _getCategoryColor(ThoughtCategory category) {
    switch (category) {
      case ThoughtCategory.work:
        return Colors.blue;
      case ThoughtCategory.relationships:
        return Colors.green;
      case ThoughtCategory.goals:
        return Colors.purple;
      case ThoughtCategory.learning:
        return Colors.orange;
      case ThoughtCategory.emotions:
        return Colors.pink;
      case ThoughtCategory.other:
        return Colors.grey;
    }
  }

  /// カテゴリのグラデーション色を取得
  List<Color> _getCategoryGradientColors(ThoughtCategory category) {
    switch (category) {
      case ThoughtCategory.work:
        // 仕事: ブルー系グラデーション
        return [
          const Color(0xFF4facfe),
          const Color(0xFF00f2fe),
        ];
      case ThoughtCategory.relationships:
        // 人間関係: グリーン系グラデーション
        return [
          const Color(0xFF11998e),
          const Color(0xFF38ef7d),
        ];
      case ThoughtCategory.goals:
        // 目標: パープル系グラデーション
        return [
          const Color(0xFF667eea),
          const Color(0xFF764ba2),
        ];
      case ThoughtCategory.learning:
        // 学習: オレンジ系グラデーション
        return [
          const Color(0xFFff9a9e),
          const Color(0xFFfecfef),
        ];
      case ThoughtCategory.emotions:
        // 感情: ピンク系グラデーション
        return [
          const Color(0xFFf093fb),
          const Color(0xFFf5576c),
        ];
      case ThoughtCategory.other:
        // その他: グレー系グラデーション
        return [
          const Color(0xFF74b9ff),
          const Color(0xFF0984e3),
        ];
    }
  }

  /// カテゴリのアイコンを取得
  IconData _getCategoryIcon(ThoughtCategory category) {
    switch (category) {
      case ThoughtCategory.work:
        return Icons.work;
      case ThoughtCategory.relationships:
        return Icons.people;
      case ThoughtCategory.goals:
        return Icons.flag;
      case ThoughtCategory.learning:
        return Icons.school;
      case ThoughtCategory.emotions:
        return Icons.favorite; // ハートアイコン
      case ThoughtCategory.other:
        return Icons.more_horiz;
    }
  }

  /// 感情のアイコンを取得
  Widget _getEmotionIcon(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.positive:
        return const Text('😊', style: TextStyle(fontSize: 16));
      case EmotionType.negative:
        return const Text('😔', style: TextStyle(fontSize: 16));
      case EmotionType.neutral:
        return const Text('😌', style: TextStyle(fontSize: 16));
      case EmotionType.mixed:
        return const Text('😐', style: TextStyle(fontSize: 16));
    }
  }

  /// 感情のラベルを取得
  String _getEmotionLabel(EmotionType emotion) {
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

  /// 感情の色を取得
  Color _getEmotionColor(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.positive:
        return Colors.green;
      case EmotionType.negative:
        return Colors.red;
      case EmotionType.neutral:
        return Colors.grey;
      case EmotionType.mixed:
        return Colors.orange;
    }
  }
}