// lib/screens/add_thought_screen.dart
// 思考記録追加画面

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../models/thought_entry.dart';
import '../models/analysis_result.dart';
import '../services/local_database.dart';
import '../services/ai_service.dart';

class AddThoughtScreen extends StatefulWidget {
  final ThoughtEntry? editThought; // 編集モードの場合の既存思考

  const AddThoughtScreen({
    super.key,
    this.editThought,
  });

  @override
  State<AddThoughtScreen> createState() => _AddThoughtScreenState();
}

class _AddThoughtScreenState extends State<AddThoughtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _focusNode = FocusNode();
  
  ThoughtCategory _selectedCategory = ThoughtCategory.other;
  bool _isLoading = false;
  bool _isAnalyzing = false;
  bool _enableAiAnalysis = true;
  
  AnalysisResult? _analysisResult;
  String? _error;
  
  final AIService _aiService = AIService();
  bool _hasApiKey = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _checkAiAvailability();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// フォームの初期化
  void _initializeForm() {
    if (widget.editThought != null) {
      _contentController.text = widget.editThought!.content;
      _selectedCategory = widget.editThought!.category;
    }
    
    // フォーカスを設定（少し遅延させる）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }
  
  /// AI機能の利用可否チェック
  Future<void> _checkAiAvailability() async {
    final hasKey = await _aiService.hasApiKey();
    setState(() {
      _hasApiKey = hasKey;
      if (!hasKey) {
        _enableAiAnalysis = false;
      }
    });
  }

  /// 思考の保存
  Future<void> _saveThought() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final db = context.read<LocalDatabase>();
      final now = DateTime.now();
      final content = _contentController.text.trim();
      
      ThoughtEntry thought;
      
      if (widget.editThought != null) {
        // 編集モード
        thought = widget.editThought!.copyWith(
          content: content,
          category: _selectedCategory,
          updatedAt: now,
          // AI分析結果があれば更新
          aiEmotion: _analysisResult?.emotion,
          aiEmotionScore: _analysisResult?.emotionScore,
          aiThemes: _analysisResult?.themes,
          aiKeywords: _analysisResult?.keywords,
          aiSummary: _analysisResult?.summary,
          aiSuggestion: _analysisResult?.suggestion,
          aiAnalyzedAt: _analysisResult?.analyzedAt,
        );
        
        await db.updateThought(thought);
      } else {
        // 新規作成モード
        thought = ThoughtEntry(
          id: const Uuid().v4(),
          content: content,
          category: _selectedCategory,
          entryDate: DateFormat('yyyy-MM-dd').format(now),
          createdAt: now,
          updatedAt: now,
          // AI分析結果があれば設定
          aiEmotion: _analysisResult?.emotion,
          aiEmotionScore: _analysisResult?.emotionScore,
          aiThemes: _analysisResult?.themes,
          aiKeywords: _analysisResult?.keywords,
          aiSummary: _analysisResult?.summary,
          aiSuggestion: _analysisResult?.suggestion,
          aiAnalyzedAt: _analysisResult?.analyzedAt,
        );
        
        await db.insertThought(thought);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // 成功フラグとして true を返す
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editThought != null ? '思考記録を更新しました' : '新しい思考記録を保存しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = '保存に失敗しました: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// AI分析の実行
  Future<void> _analyzeThought() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasApiKey) {
      _showApiKeyDialog();
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _error = null;
      _analysisResult = null;
    });

    try {
      final content = _contentController.text.trim();
      final result = await _aiService.analyzeThought(content, _selectedCategory);
      
      setState(() {
        _analysisResult = result;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI分析が完了しました'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'AI分析に失敗しました: $e';
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  /// APIキー設定ダイアログ
  void _showApiKeyDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OpenAI APIキー設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI分析機能を使用するにはAPIキーが必要です。'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'APIキー',
                hintText: 'sk-...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            Text(
              '※ APIキーは端末内に安全に保存されます',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              final apiKey = controller.text.trim();
              if (apiKey.isNotEmpty) {
                try {
                  await _aiService.setApiKey(apiKey);
                  await _checkAiAvailability();
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('APIキーを設定しました'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('APIキーの設定に失敗しました: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('設定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editThought != null ? '思考記録を編集' : '新しい思考記録'),
        actions: [
          if (_hasApiKey && !_isLoading)
            IconButton(
              onPressed: _isAnalyzing ? null : _analyzeThought,
              icon: _isAnalyzing 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.psychology),
              tooltip: 'AI分析',
            ),
        ],
      ),
      
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // エラー表示
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // カテゴリ選択
                    Text(
                      'カテゴリ',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildCategorySelector(),
                    
                    const SizedBox(height: 24),
                    
                    // 思考内容入力
                    Text(
                      '思考・感情の内容',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _contentController,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: '今考えていることや感じていることを自由に記録してください...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 8,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '内容を入力してください';
                        }
                        if (value.trim().length < 10) {
                          return '10文字以上入力してください';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // AI分析オプション
                    _buildAiAnalysisSection(),
                    
                    // AI分析結果表示
                    if (_analysisResult != null) ...[
                      const SizedBox(height: 24),
                      _buildAnalysisResultSection(),
                    ],
                  ],
                ),
              ),
            ),
            
            // 保存ボタン
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  /// カテゴリ選択ウィジェット
  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ThoughtCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return FilterChip(
          label: Text(category.displayName),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedCategory = category;
              });
            }
          },
          avatar: isSelected ? null : Icon(
            _getCategoryIcon(category),
            size: 16,
          ),
        );
      }).toList(),
    );
  }

  /// AI分析セクション
  Widget _buildAiAnalysisSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, size: 20),
                const SizedBox(width: 8),
                Text(
                  'AI分析',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            if (!_hasApiKey) ...[
              const Text('AI分析を使用するにはAPIキーの設定が必要です。'),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _showApiKeyDialog,
                icon: const Icon(Icons.key),
                label: const Text('APIキーを設定'),
              ),
            ] else ...[
              SwitchListTile(
                title: const Text('AI分析を有効にする'),
                subtitle: const Text('感情・テーマ・キーワードを自動分析'),
                value: _enableAiAnalysis,
                onChanged: (value) {
                  setState(() {
                    _enableAiAnalysis = value;
                  });
                },
              ),
              
              if (_enableAiAnalysis) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _analyzeThought,
                    icon: _isAnalyzing 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.analytics),
                    label: Text(_isAnalyzing ? '分析中...' : '今すぐ分析'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// AI分析結果表示セクション
  Widget _buildAnalysisResultSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'AI分析結果',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 感情分析
            Row(
              children: [
                _getEmotionIcon(_analysisResult!.emotion),
                const SizedBox(width: 8),
                Text(
                  _getEmotionLabel(_analysisResult!.emotion),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getEmotionColor(_analysisResult!.emotion).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_analysisResult!.emotionScorePercentage}%',
                    style: TextStyle(
                      color: _getEmotionColor(_analysisResult!.emotion),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // テーマ
            if (_analysisResult!.themes.isNotEmpty) ...[
              Text(
                'テーマ',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _analysisResult!.themes.map((theme) =>
                  Chip(
                    label: Text(theme),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                  ),
                ).toList(),
              ),
              const SizedBox(height: 12),
            ],
            
            // 要約
            if (_analysisResult!.summary.isNotEmpty) ...[
              Text(
                '要約',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_analysisResult!.summary),
              ),
              const SizedBox(height: 12),
            ],
            
            // 提案
            if (_analysisResult!.suggestion.isNotEmpty) ...[
              Text(
                '提案',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_analysisResult!.suggestion)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 保存ボタン
  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveThought,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('保存中...'),
                  ],
                )
              : Text(widget.editThought != null ? '更新' : '保存'),
        ),
      ),
    );
  }

  // ヘルパーメソッド
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
        return Icons.favorite;
      case ThoughtCategory.other:
        return Icons.more_horiz;
    }
  }

  Widget _getEmotionIcon(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.positive:
        return const Text('😊', style: TextStyle(fontSize: 20));
      case EmotionType.negative:
        return const Text('😔', style: TextStyle(fontSize: 20));
      case EmotionType.neutral:
        return const Text('😌', style: TextStyle(fontSize: 20));
      case EmotionType.mixed:
        return const Text('😐', style: TextStyle(fontSize: 20));
    }
  }

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