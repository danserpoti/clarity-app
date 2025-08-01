// lib/screens/settings/settings_screen.dart
// 設定画面 - プライバシー設定とNotion連携

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/privacy_service.dart';
import '../../services/ai_service.dart';
import 'notion_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AIService _aiService = AIService();
  bool _hasAiApiKey = false;

  @override
  void initState() {
    super.initState();
    _checkAiApiKey();
  }

  /// AI APIキーの設定状況をチェック
  Future<void> _checkAiApiKey() async {
    final hasKey = await _aiService.hasApiKey();
    setState(() {
      _hasAiApiKey = hasKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<PrivacySettings>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // プライバシー設定セクション
              _buildSectionHeader('プライバシー設定'),
              _buildPrivacySettings(settings),
              
              const SizedBox(height: 24),
              
              // AI機能設定セクション
              _buildSectionHeader('AI機能設定'),
              _buildAiSettings(settings),
              
              const SizedBox(height: 24),
              
              // バックアップ・連携設定セクション
              _buildSectionHeader('バックアップ・連携'),
              _buildBackupSettings(settings),
              
              const SizedBox(height: 24),
              
              // アプリ情報セクション
              _buildSectionHeader('アプリ情報'),
              _buildAppInfo(),
              
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  /// セクションヘッダー
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// プライバシー設定
  Widget _buildPrivacySettings(PrivacySettings settings) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('データ暗号化'),
            subtitle: const Text('ローカルデータを暗号化して保存'),
            secondary: const Icon(Icons.security),
            value: settings.enableDataEncryption,
            onChanged: (value) async {
              settings.enableDataEncryption = value;
              await settings.save();
            },
          ),
          
          const Divider(height: 1),
          
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('プライバシーポリシー'),
            subtitle: const Text('データの取り扱いについて'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showPrivacyPolicy,
          ),
          
          const Divider(height: 1),
          
          ListTile(
            leading: Icon(Icons.info_outline, color: Colors.blue.shade600),
            title: const Text('データの保存場所'),
            subtitle: const Text('すべてのデータは端末内に安全に保存されます'),
            trailing: Icon(Icons.verified_user, color: Colors.green.shade600),
          ),
        ],
      ),
    );
  }

  /// AI機能設定
  Widget _buildAiSettings(PrivacySettings settings) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('AI分析機能'),
            subtitle: const Text('思考内容の感情・テーマ分析'),
            secondary: const Icon(Icons.psychology),
            value: settings.enableAIAnalysis,
            onChanged: (value) async {
              settings.enableAIAnalysis = value;
              await settings.save();
            },
          ),
          
          const Divider(height: 1),
          
          ListTile(
            leading: Icon(
              Icons.key,
              color: _hasAiApiKey ? Colors.green.shade600 : Colors.grey.shade600,
            ),
            title: const Text('OpenAI APIキー'),
            subtitle: Text(_hasAiApiKey ? '設定済み' : '未設定'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showApiKeyDialog,
          ),
          
          if (settings.enableAIAnalysis) ...[
            const Divider(height: 1),
            
            ListTile(
              leading: Icon(Icons.info_outline, color: Colors.orange.shade600),
              title: const Text('AI分析について'),
              subtitle: const Text('分析時のみ最小限のデータを送信します'),
              onTap: _showAiAnalysisInfo,
            ),
          ],
        ],
      ),
    );
  }

  /// バックアップ・連携設定
  Widget _buildBackupSettings(PrivacySettings settings) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.backup,
              color: settings.enableNotionBackup 
                  ? Colors.green.shade600 
                  : Colors.grey.shade600,
            ),
            title: const Text('Notion連携'),
            subtitle: Text(
              settings.enableNotionBackup 
                  ? '接続中 - バックアップ機能が利用できます' 
                  : '未設定 - クラウドバックアップが利用できます',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotionSettingsScreen(),
                ),
              );
            },
          ),
          
          if (settings.enableNotionBackup) ...[
            const Divider(height: 1),
            
            ListTile(
              leading: Icon(Icons.schedule, color: Colors.blue.shade600),
              title: const Text('自動バックアップ'),
              subtitle: Text(
                settings.autoBackupEnabled 
                    ? '${settings.autoBackupIntervalDays}日ごとに実行' 
                    : '無効',
              ),
              trailing: Switch(
                value: settings.autoBackupEnabled,
                onChanged: (value) async {
                  settings.autoBackupEnabled = value;
                  await settings.save();
                },
              ),
            ),
          ],
          
          const Divider(height: 1),
          
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('データエクスポート'),
            subtitle: const Text('思考記録をJSONファイルで書き出し'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportData,
          ),
        ],
      ),
    );
  }

  /// アプリ情報
  Widget _buildAppInfo() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('アプリについて'),
            subtitle: const Text('Clarity - 思考記録アプリ v1.0.0'),
          ),
          
          const Divider(height: 1),
          
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('オープンソース'),
            subtitle: const Text('GitHubでソースコードを公開'),
            trailing: const Icon(Icons.open_in_new),
            onTap: _openGitHub,
          ),
          
          const Divider(height: 1),
          
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('フィードバック'),
            subtitle: const Text('改善提案やバグ報告'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showFeedbackDialog,
          ),
        ],
      ),
    );
  }

  /// プライバシーポリシー表示
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プライバシーポリシー'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🔒 データプライバシー'),
              SizedBox(height: 8),
              Text('• すべての思考記録は端末内のみに保存されます'),
              Text('• 外部サーバーへのデータ送信は行いません'),
              Text('• AI分析時のみ、必要最小限のデータを一時的に送信'),
              SizedBox(height: 16),
              Text('🔐 セキュリティ'),
              SizedBox(height: 8),
              Text('• APIキーは安全に暗号化して保存'),
              Text('• データベースは端末内で暗号化'),
              Text('• 個人識別情報の収集は一切行いません'),
              SizedBox(height: 16),
              Text('☁️ Notion連携'),
              SizedBox(height: 8),
              Text('• 連携は完全にオプション機能'),
              Text('• あなたのNotionワークスペースに保存'),
              Text('• いつでも連携解除可能'),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              final apiKey = controller.text.trim();
              if (apiKey.isNotEmpty) {
                try {
                  await _aiService.setApiKey(apiKey);
                  await _checkAiApiKey();
                  
                  if (mounted) {
                    Navigator.pop(context);
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

  /// AI分析情報表示
  void _showAiAnalysisInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI分析について'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🤖 分析内容'),
              SizedBox(height: 8),
              Text('• 感情の種類と強度を分析'),
              Text('• 主要なテーマとキーワードを抽出'),
              Text('• 建設的な提案やアドバイスを生成'),
              SizedBox(height: 16),
              Text('🔒 プライバシー保護'),
              SizedBox(height: 8),
              Text('• 思考内容のみを送信（個人情報は除外）'),
              Text('• 分析後すぐにデータは削除される'),
              Text('• OpenAIのデータ利用ポリシーに準拠'),
              SizedBox(height: 16),
              Text('⚙️ 設定可能'),
              SizedBox(height: 8),
              Text('• いつでもON/OFF切り替え可能'),
              Text('• 個別の思考記録ごとに選択可能'),
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

  /// データエクスポート
  void _exportData() {
    // 実装予定: データのJSONエクスポート
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('データエクスポート機能は実装中です'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// GitHub開く
  void _openGitHub() {
    // 実装予定: ブラウザでGitHubリポジトリを開く
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GitHub: https://github.com/danserpoti/clarity-app'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// フィードバックダイアログ
  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フィードバック'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ご意見・ご要望をお聞かせください'),
            SizedBox(height: 16),
            Text('📧 連絡方法:'),
            Text('• GitHub Issues'),
            Text('• アプリ内フィードバック（実装予定）'),
            SizedBox(height: 16),
            Text('🐛 バグ報告:'),
            Text('• 発生状況の詳細'),
            Text('• エラーメッセージ'),
            Text('• 再現手順'),
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
}