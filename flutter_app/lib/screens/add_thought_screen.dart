import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/thought_entry.dart';
import '../models/analysis_result.dart';
import '../models/usage_info.dart';
import '../services/simple_data_service.dart';
import '../services/local_database.dart';
import '../services/ai_service.dart';
import '../services/privacy_service.dart';
import '../widgets/usage_counter_widget.dart';

class AddThoughtScreen extends StatefulWidget {
  const AddThoughtScreen({super.key});

  @override
  State<AddThoughtScreen> createState() => _AddThoughtScreenState();
}

class _AddThoughtScreenState extends State<AddThoughtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _thoughtController = TextEditingController();
  final AIService _aiService = AIService();
  String _selectedCategory = '仕事';
  bool _isLoading = false;
  bool _isAnalyzing = false;
  bool _enableAIAnalysis = false;
  bool _hasAiApiKey = false;
  UsageInfo? _usageInfo;

  final List<String> _categories = [
    '仕事',
    '人間関係',
    '目標管理',
    '学習',
    '感情',
    'その他',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAISettings();
  }

  @override
  void dispose() {
    _thoughtController.dispose();
    super.dispose();
  }

  /// AI設定の初期化
  Future<void> _initializeAISettings() async {
    final privacySettings = Provider.of<PrivacySettings>(context, listen: false);
    final hasApiKey = await _aiService.hasApiKey();
    
    // 使用量情報を非同期で取得（エラーは無視）
    _loadUsageInfo();
    
    setState(() {
      _hasAiApiKey = hasApiKey;
      _enableAIAnalysis = privacySettings.enableAIAnalysis && hasApiKey;
    });
  }
  
  /// 使用量情報の読み込み
  Future<void> _loadUsageInfo() async {
    try {
      final usageInfo = await _aiService.getUsageInfo();
      if (mounted) {
        setState(() {
          _usageInfo = usageInfo;
        });
      }
    } catch (e) {
      // エラーは無視（使用量情報はオプション）
      debugPrint('使用量情報の読み込みに失敗: $e');
    }
  }

  void _saveThought() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 一意のIDを生成
        const uuid = Uuid();
        final now = DateTime.now();
        final entryDate = DateFormat('yyyy-MM-dd').format(now);

        // ThoughtEntryを作成
        final thoughtEntry = ThoughtEntry(
          id: uuid.v4(),
          content: _thoughtController.text.trim(),
          category: ThoughtCategory.fromString(_selectedCategory),
          entryDate: entryDate,
          createdAt: now,
          updatedAt: now,
        );

        // データベースに思考を保存
        final database = LocalDatabase.instance;
        await database.insertThought(thoughtEntry);

        // AI分析を実行（有効な場合）
        if (_enableAIAnalysis && _hasAiApiKey) {
          setState(() {
            _isAnalyzing = true;
          });
          
          try {
            final analysisResult = await _aiService.analyzeThought(
              thoughtEntry.content,
              thoughtEntry.category,
            );

            if (analysisResult != null) {
              // AI分析結果をデータベースに保存
              await database.updateThoughtWithAnalysis(
                thoughtEntry.id,
                analysisResult,
              );
              
              // 使用量情報を更新
              _loadUsageInfo();
            }
          } catch (aiError) {
            // AI分析エラーの詳細処理
            if (mounted) {
              String errorMessage;
              Color backgroundColor = Colors.orange;
              
              if (aiError.toString().contains('UsageLimitException')) {
                errorMessage = '月間使用量上限に達しました。来月まで少しお待ちください。';
                backgroundColor = Colors.red;
              } else if (aiError.toString().contains('RateLimitException')) {
                errorMessage = 'リクエスト制限に達しました。しばらく待ってから再試行してください。';
                backgroundColor = Colors.orange;
              } else if (aiError.toString().contains('NetworkException')) {
                errorMessage = 'ネットワーク接続を確認してください。';
                backgroundColor = Colors.red;
              } else if (aiError.toString().contains('ServiceUnavailableException')) {
                errorMessage = 'AI分析サービスが一時的に利用できません。';
                backgroundColor = Colors.orange;
              } else {
                errorMessage = 'AI分析に失敗しました: $aiError';
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: backgroundColor,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          } finally {
            setState(() {
              _isAnalyzing = false;
            });
          }
        }

        if (mounted) {
          // 成功メッセージを表示
          final message = _enableAIAnalysis && _hasAiApiKey 
              ? '思考を保存し、AI分析を完了しました'
              : '思考を保存しました';
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('思考記録を保存しました'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // 🚀 保存成功をホーム画面に通知
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          // エラーメッセージを表示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('保存に失敗しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isAnalyzing = false;
          });
        }
      }
    }
  }

  void _cancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('思考を記録'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // カテゴリ選択
              const Text(
                'カテゴリ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              
              // AI分析設定
              Consumer<PrivacySettings>(
                builder: (context, privacySettings, child) {
                  if (!privacySettings.enableAIAnalysis || !_hasAiApiKey) {
                    return const SizedBox.shrink();
                  }
                  
                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.psychology,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'AI分析',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: _enableAIAnalysis,
                                onChanged: (value) {
                                  setState(() {
                                    _enableAIAnalysis = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          
                          // 使用量表示（コンパクト）
                          if (_enableAIAnalysis && _usageInfo != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '使用量:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                UsageCounterWidget(
                                  usageInfo: _usageInfo,
                                  size: UsageCounterSize.compact,
                                ),
                              ],
                            ),
                          ],
                          
                          if (_enableAIAnalysis) ...[
                            const SizedBox(height: 8),
                            Text(
                              '感情・テーマ・キーワードを自動分析し、建設的なアドバイスを提供します',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (_isAnalyzing) ...[
                              const SizedBox(height: 8),
                              Row(
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
                                  const Text(
                                    'AI分析中...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // 思考入力
              const Text(
                '思考・感情の内容',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextFormField(
                  controller: _thoughtController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'どんなことを考えていますか？\n感情や思考を自由に記録してください...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '思考の内容を入力してください';
                    }
                    if (value.trim().length < 10) {
                      return '10文字以上入力してください';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              
              // ボタン
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _cancel,
                      child: const Text('キャンセル'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isLoading || _isAnalyzing) ? null : _saveThought,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(_isAnalyzing ? 'AI分析中...' : '保存中...'),
                              ],
                            )
                          : const Text('保存'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}