// lib/screens/settings/notion_settings_screen.dart
// Notion連携設定画面 - プライバシーファーストのクラウドバックアップ

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/privacy_service.dart';
import '../../services/notion_service.dart';
import '../../services/local_database.dart';

class NotionSettingsScreen extends StatefulWidget {
  const NotionSettingsScreen({super.key});

  @override
  State<NotionSettingsScreen> createState() => _NotionSettingsScreenState();
}

class _NotionSettingsScreenState extends State<NotionSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _databaseIdController = TextEditingController();
  
  bool _isConnecting = false;
  bool _isBackingUp = false;
  bool _obscureApiKey = true;
  
  @override
  void dispose() {
    _apiKeyController.dispose();
    _databaseIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notion連携設定'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<PrivacySettings>(
        builder: (context, settings, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 説明カード
                  _buildInfoCard(),
                  
                  const SizedBox(height: 24),
                  
                  // メイン設定エリア
                  if (!settings.enableNotionBackup) ...[
                    _buildConnectionForm(settings),
                  ] else ...[
                    _buildConnectedStatus(settings),
                    const SizedBox(height: 24),
                    _buildBackupActions(settings),
                    const SizedBox(height: 24),
                    _buildAutoBackupSettings(settings),
                    const SizedBox(height: 24),
                    _buildBackupStats(settings),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 説明カード
  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'Notion連携について',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Notionと連携することで、思考記録を自動バックアップできます。'
              'データはあなたのNotionワークスペースに保存され、完全にプライベートです。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.security, size: 16, color: Colors.green.shade600),
                const SizedBox(width: 4),
                Text(
                  'プライバシー重視',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade600),
                const SizedBox(width: 4),
                Text(
                  'ユーザー制御',
                  style: TextStyle(
                    color: Colors.orange.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 接続設定フォーム
  Widget _buildConnectionForm(PrivacySettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notion API設定',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        
        // API Key入力
        TextFormField(
          controller: _apiKeyController,
          decoration: InputDecoration(
            labelText: 'Notion API Key',
            helperText: 'Notionで作成したAPIキーを入力してください',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.key),
            suffixIcon: IconButton(
              icon: Icon(_obscureApiKey ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _obscureApiKey = !_obscureApiKey;
                });
              },
            ),
          ),
          obscureText: _obscureApiKey,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'APIキーを入力してください';
            }
            if (!value.trim().startsWith('secret_')) {
              return '正しいAPIキーの形式ではありません';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Database ID入力
        TextFormField(
          controller: _databaseIdController,
          decoration: const InputDecoration(
            labelText: 'Database ID',
            helperText: 'バックアップ先データベースのIDを入力してください',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.storage),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Database IDを入力してください';
            }
            if (value.trim().length != 32) {
              return 'Database IDは32文字である必要があります';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 24),
        
        // 接続ボタン
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isConnecting ? null : _connectToNotion,
            icon: _isConnecting 
                ? const SizedBox(
                    width: 20, 
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.link),
            label: Text(_isConnecting ? '接続中...' : 'Notionに接続'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // セットアップガイドリンク
        TextButton.icon(
          onPressed: _showSetupGuide,
          icon: const Icon(Icons.help_outline),
          label: const Text('セットアップガイドを見る'),
        ),
      ],
    );
  }

  /// 接続済み状態表示
  Widget _buildConnectedStatus(PrivacySettings settings) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'Notion連携中',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _showDisconnectDialog,
                  icon: Icon(Icons.link_off, color: Colors.red.shade600),
                  tooltip: '連携解除',
                ),
              ],
            ),
            if (settings.lastBackupTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '最終バックアップ: ${DateFormat('yyyy/MM/dd HH:mm').format(settings.lastBackupTime!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// バックアップ操作エリア
  Widget _buildBackupActions(PrivacySettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'バックアップ操作',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isBackingUp ? null : _performBackup,
                icon: _isBackingUp
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.backup),
                label: Text(_isBackingUp ? 'バックアップ中...' : '今すぐバックアップ'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _showBackupHistory,
              icon: const Icon(Icons.history),
              label: const Text('履歴'),
            ),
          ],
        ),
      ],
    );
  }

  /// 自動バックアップ設定
  Widget _buildAutoBackupSettings(PrivacySettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '自動バックアップ設定',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('自動バックアップを有効にする'),
              subtitle: const Text('定期的にNotionへバックアップを実行します'),
              value: settings.autoBackupEnabled,
              onChanged: (value) async {
                settings.autoBackupEnabled = value;
                await settings.save();
              },
            ),
            
            if (settings.autoBackupEnabled) ...[
              const SizedBox(height: 8),
              
              Row(
                children: [
                  const Text('バックアップ間隔: '),
                  DropdownButton<int>(
                    value: settings.autoBackupIntervalDays,
                    items: [1, 3, 7, 14, 30].map((days) {
                      String label = days == 1 ? '毎日' : '$days日ごと';
                      return DropdownMenuItem(
                        value: days,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        settings.autoBackupIntervalDays = value;
                        await settings.save();
                      }
                    },
                  ),
                ],
              ),
              
              if (settings.nextAutoBackupDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '次回予定: ${DateFormat('MM/dd HH:mm').format(settings.nextAutoBackupDate!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// バックアップ統計
  Widget _buildBackupStats(PrivacySettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'バックアップ統計',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '総実行回数',
                    '${settings.totalBackupsCount}回',
                    Icons.backup,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '成功回数',
                    '${settings.successfulBackupsCount}回',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '成功率',
                    '${(settings.backupSuccessRate * 100).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    settings.backupSuccessRate > 0.8 ? Colors.green : Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '初回バックアップ',
                    settings.firstBackupTime != null
                        ? DateFormat('yyyy/MM/dd').format(settings.firstBackupTime!)
                        : '未実行',
                    Icons.history,
                    Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 統計アイテム
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Notionへの接続処理
  Future<void> _connectToNotion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isConnecting = true);

    final settings = context.read<PrivacySettings>();
    
    try {
      final apiKey = _apiKeyController.text.trim();
      final databaseId = _databaseIdController.text.trim();
      
      // 接続テスト
      final notionService = NotionService(
        apiKey: apiKey,
        databaseId: databaseId,
      );

      final isConnected = await notionService.testConnection();
      
      if (!isConnected) {
        throw Exception('接続に失敗しました。APIキーとDatabase IDを確認してください。');
      }

      // 設定保存
      await settings.setNotionCredentials(
        apiKey: apiKey,
        databaseId: databaseId,
      );

      if (mounted) {
        _showSnackBar('Notionに正常に接続されました！', isSuccess: true);
        _apiKeyController.clear();
        _databaseIdController.clear();
      }

    } catch (e) {
      if (mounted) {
        _showSnackBar('接続に失敗しました: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  /// バックアップ実行
  Future<void> _performBackup() async {
    setState(() => _isBackingUp = true);

    try {
      final settings = context.read<PrivacySettings>();
      final database = context.read<LocalDatabase>();
      
      // 思考記録を取得
      final thoughts = await database.getAllThoughts();
      
      if (thoughts.isEmpty) {
        _showSnackBar('バックアップする思考記録がありません', isError: true);
        return;
      }
      
      // Notionサービスでバックアップ実行
      final notionService = NotionService(
        apiKey: settings.notionApiKey!,
        databaseId: settings.notionDatabaseId!,
      );

      final result = await notionService.backupThoughts(thoughts);

      // 統計更新
      await settings.updateBackupStats(
        success: result.isSuccess,
        backupTime: result.timestamp,
      );

      if (result.isSuccess) {
        _showSnackBar(
          '${result.backedUpCount}件の記録をバックアップしました',
          isSuccess: true,
        );
        
        if (result.hasPartialErrors) {
          _showSnackBar(
            '${result.partialErrors!.length}件のエラーがありました',
            isError: true,
          );
        }
      } else {
        _showSnackBar(result.errorMessage!, isError: true);
      }

    } catch (e) {
      _showSnackBar('バックアップエラー: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  /// 連携解除ダイアログ
  void _showDisconnectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notion連携を解除'),
        content: const Text(
          'Notion連携を解除しますか？\n'
          'バックアップ機能が使用できなくなります。\n'
          '（既存のNotionデータは削除されません）'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              final settings = context.read<PrivacySettings>();
              final navigator = Navigator.of(context);
              await settings.clearNotionCredentials();
              if (mounted) {
                navigator.pop();
                _showSnackBar('Notion連携を解除しました', isSuccess: true);
              }
            },
            child: Text('解除', style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
  }

  /// セットアップガイドを表示
  void _showSetupGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notionセットアップガイド'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Notion APIキーの取得'),
              Text('• my.notion.so/my-integrations でインテグレーションを作成'),
              Text('• APIキー（secret_xxx）をコピー'),
              SizedBox(height: 12),
              Text('2. データベースの作成'),
              Text('• Notionで新しいデータベースを作成'),
              Text('• インテグレーションをデータベースに招待'),
              SizedBox(height: 12),
              Text('3. Database IDの取得'),
              Text('• データベースのURLから32文字のIDを抽出'),
              Text('• 例: notion.so/xxx/DATABASE_ID?v=xxx'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// バックアップ履歴を表示（簡易版）
  void _showBackupHistory() {
    final settings = context.read<PrivacySettings>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('バックアップ履歴'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('総実行回数: ${settings.totalBackupsCount}回'),
            Text('成功回数: ${settings.successfulBackupsCount}回'),
            Text('成功率: ${(settings.backupSuccessRate * 100).toStringAsFixed(1)}%'),
            if (settings.lastBackupTime != null)
              Text('最終実行: ${DateFormat('yyyy/MM/dd HH:mm').format(settings.lastBackupTime!)}'),
            if (settings.firstBackupTime != null)
              Text('初回実行: ${DateFormat('yyyy/MM/dd HH:mm').format(settings.firstBackupTime!)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// スナックバー表示
  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    
    Color? backgroundColor;
    if (isError) backgroundColor = Colors.red;
    if (isSuccess) backgroundColor = Colors.green;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        action: isError ? SnackBarAction(
          label: '閉じる',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ) : null,
      ),
    );
  }
}