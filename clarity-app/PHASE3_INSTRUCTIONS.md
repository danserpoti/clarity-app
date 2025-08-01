# Phase 3: Notion連携・最終完成指示

## 🎯 **Phase 3 目標**
Phase 2で完成したFlutter版Clarityアプリに、**Notion連携によるバックアップ機能**を追加し、本格運用可能な完成版にする。

## 📋 **必須事前確認**
**⚠️ 作業開始前に `CLAUDE_INSTRUCTIONS.md` と `FLUTTER_DESIGN_SPEC.md` を必ず確認してください**

---

## ✅ **Phase 2 完成内容の確認**

### **実装済み基盤機能**
- ✅ Flutter プロジェクト完全セットアップ
- ✅ SQLite ローカルデータベース実装
- ✅ 思考記録のCRUD操作完全動作
- ✅ AI分析機能（OpenAI API統合）
- ✅ データ可視化（fl_chart）
- ✅ プライバシー設定・セキュア保存
- ✅ エクスポート・インポート機能
- ✅ Material Design 3 UI実装

### **現在の技術構成**
```yaml
# 確認済みパッケージ（pubspec.lockより）
sqflite: SQLite ローカルDB
flutter_secure_storage: セキュア設定保存
fl_chart: データ可視化
dio: HTTP通信（AI API用）
file_picker: ファイル操作
lottie: アニメーション
material_design_icons_flutter: アイコン
```

---

## 🔗 **Phase 3A: Notion連携実装**

### **1. Notion API統合**

#### **pubspec.yaml への追加**
```yaml
dependencies:
  # 既存パッケージは維持
  
  # Notion連携用新規追加
  http: ^1.3.2              # HTTP通信（既存の場合はスキップ）
  json_annotation: ^4.9.0   # JSON処理
  
dev_dependencies:
  json_serializable: ^6.8.0  # JSON シリアライズ
```

#### **Notion API サービス実装**
```dart
// lib/services/notion_service.dart
class NotionService {
  final String _apiKey;
  final String _databaseId;
  final Dio _dio;
  
  NotionService({
    required String apiKey,
    required String databaseId,
  }) : _apiKey = apiKey,
       _databaseId = databaseId,
       _dio = Dio() {
    _dio.options.headers = {
      'Authorization': 'Bearer $_apiKey',
      'Notion-Version': '2022-06-28',
      'Content-Type': 'application/json',
    };
  }

  // バックアップ実行
  Future<BackupResult> backupThoughts(List<ThoughtEntry> thoughts) async {
    try {
      // バッチでNotionページを作成
      final results = <String>[];
      
      for (final thought in thoughts) {
        final pageData = _thoughtToNotionPage(thought);
        final response = await _dio.post(
          'https://api.notion.com/v1/pages',
          data: pageData,
        );
        
        if (response.statusCode == 200) {
          results.add(response.data['id']);
        }
      }
      
      return BackupResult.success(
        backedUpCount: results.length,
        pageIds: results,
        timestamp: DateTime.now(),
      );
      
    } catch (e) {
      return BackupResult.error('バックアップエラー: ${e.toString()}');
    }
  }

  // Notionページデータ変換
  Map<String, dynamic> _thoughtToNotionPage(ThoughtEntry thought) {
    return {
      'parent': {'database_id': _databaseId},
      'properties': {
        'タイトル': {
          'title': [
            {
              'text': {
                'content': thought.content.length > 100 
                  ? '${thought.content.substring(0, 100)}...'
                  : thought.content
              }
            }
          ]
        },
        'カテゴリ': {
          'select': {'name': thought.category}
        },
        '作成日': {
          'date': {'start': thought.createdAt.toIso8601String()}
        },
        '感情': thought.aiEmotion != null ? {
          'select': {'name': thought.aiEmotion!}
        } : null,
        '感情スコア': thought.aiEmotionScore != null ? {
          'number': thought.aiEmotionScore!
        } : null,
      }..removeWhere((key, value) => value == null),
      'children': [
        {
          'object': 'block',
          'type': 'paragraph',
          'paragraph': {
            'rich_text': [
              {
                'type': 'text',
                'text': {'content': thought.content}
              }
            ]
          }
        },
        if (thought.aiSummary != null) {
          'object': 'block',
          'type': 'callout',
          'callout': {
            'rich_text': [
              {
                'type': 'text',
                'text': {'content': 'AI分析: ${thought.aiSummary}'}
              }
            ],
            'icon': {'emoji': '🤖'}
          }
        },
      ],
    };
  }
}

// バックアップ結果モデル
class BackupResult {
  final bool isSuccess;
  final String? errorMessage;
  final int backedUpCount;
  final List<String> pageIds;
  final DateTime timestamp;

  BackupResult._({
    required this.isSuccess,
    this.errorMessage,
    required this.backedUpCount,
    required this.pageIds,
    required this.timestamp,
  });

  factory BackupResult.success({
    required int backedUpCount,
    required List<String> pageIds,
    required DateTime timestamp,
  }) => BackupResult._(
    isSuccess: true,
    backedUpCount: backedUpCount,
    pageIds: pageIds,
    timestamp: timestamp,
  );

  factory BackupResult.error(String message) => BackupResult._(
    isSuccess: false,
    errorMessage: message,
    backedUpCount: 0,
    pageIds: [],
    timestamp: DateTime.now(),
  );
}
```

### **2. Notion設定画面実装**

#### **設定管理サービス更新**
```dart
// lib/services/privacy_service.dart に追加
class PrivacySettings {
  // 既存設定
  bool enableAIAnalysis = true;
  bool enableDataEncryption = true;
  
  // Notion連携設定（新規追加）
  bool enableNotionBackup = false;
  String? notionApiKey;
  String? notionDatabaseId;
  DateTime? lastBackupTime;
  bool autoBackupEnabled = false;
  int autoBackupIntervalDays = 7;

  // Notion API キーの安全な保存
  Future<void> setNotionCredentials({
    required String apiKey,
    required String databaseId,
  }) async {
    final secureStorage = FlutterSecureStorage();
    
    await secureStorage.write(key: 'notion_api_key', value: apiKey);
    await secureStorage.write(key: 'notion_database_id', value: databaseId);
    
    notionApiKey = apiKey;  // メモリ内保持
    notionDatabaseId = databaseId;
    enableNotionBackup = true;
    
    await save();
  }

  // 認証情報の削除
  Future<void> clearNotionCredentials() async {
    final secureStorage = FlutterSecureStorage();
    
    await secureStorage.delete(key: 'notion_api_key');
    await secureStorage.delete(key: 'notion_database_id');
    
    notionApiKey = null;
    notionDatabaseId = null;
    enableNotionBackup = false;
    
    await save();
  }
}
```

#### **Notion設定UI実装**
```dart
// lib/screens/settings/notion_settings_screen.dart
class NotionSettingsScreen extends StatefulWidget {
  @override
  _NotionSettingsScreenState createState() => _NotionSettingsScreenState();
}

class _NotionSettingsScreenState extends State<NotionSettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _databaseIdController = TextEditingController();
  bool _isConnecting = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notion連携設定'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<PrivacySettings>(
        builder: (context, settings, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 説明カード
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Notion連携について', 
                              style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Notionと連携することで、思考記録を自動バックアップできます。'
                          'データはあなたのNotionワークスペースに保存され、完全にプライベートです。',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // API設定セクション
                if (!settings.enableNotionBackup) ...[
                  Text('Notion API設定', 
                    style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 16),
                  
                  TextField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      labelText: 'Notion API Key',
                      helperText: 'Notionで作成したAPIキーを入力',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                    ),
                    obscureText: true,
                  ),
                  
                  SizedBox(height: 16),
                  
                  TextField(
                    controller: _databaseIdController,
                    decoration: InputDecoration(
                      labelText: 'Database ID',
                      helperText: 'バックアップ先データベースのID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.storage),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isConnecting ? null : _connectToNotion,
                      icon: _isConnecting 
                        ? SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.link),
                      label: Text(_isConnecting ? '接続中...' : 'Notionに接続'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ] else ...[
                  // 連携済み状態
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Notion連携中', 
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                )),
                            ],
                          ),
                          if (settings.lastBackupTime != null) ...[
                            SizedBox(height: 8),
                            Text(
                              '最終バックアップ: ${DateFormat('yyyy/MM/dd HH:mm').format(settings.lastBackupTime!)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // バックアップ操作
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _performBackup,
                          icon: Icon(Icons.backup),
                          label: Text('今すぐバックアップ'),
                        ),
                      ),
                      SizedBox(width: 12),
                      IconButton(
                        onPressed: _showDisconnectDialog,
                        icon: Icon(Icons.link_off, color: Colors.red),
                        tooltip: '連携解除',
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 24),
                  
                  // 自動バックアップ設定
                  SwitchListTile(
                    title: Text('自動バックアップ'),
                    subtitle: Text('定期的にNotionへバックアップを実行'),
                    value: settings.autoBackupEnabled,
                    onChanged: (value) {
                      settings.autoBackupEnabled = value;
                      settings.save();
                    },
                  ),
                  
                  if (settings.autoBackupEnabled) ...[
                    ListTile(
                      title: Text('バックアップ間隔'),
                      subtitle: Text('${settings.autoBackupIntervalDays}日ごと'),
                      trailing: DropdownButton<int>(
                        value: settings.autoBackupIntervalDays,
                        items: [1, 3, 7, 14, 30].map((days) {
                          return DropdownMenuItem(
                            value: days,
                            child: Text('${days}日'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            settings.autoBackupIntervalDays = value;
                            settings.save();
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _connectToNotion() async {
    if (_apiKeyController.text.isEmpty || _databaseIdController.text.isEmpty) {
      _showSnackBar('APIキーとDatabase IDを入力してください', isError: true);
      return;
    }

    setState(() => _isConnecting = true);

    try {
      // 接続テスト
      final notionService = NotionService(
        apiKey: _apiKeyController.text.trim(),
        databaseId: _databaseIdController.text.trim(),
      );

      // テスト用の空ページ作成で接続確認
      // await notionService.testConnection();

      // 設定保存
      final settings = Provider.of<PrivacySettings>(context, listen: false);
      await settings.setNotionCredentials(
        apiKey: _apiKeyController.text.trim(),
        databaseId: _databaseIdController.text.trim(),
      );

      _showSnackBar('Notionに正常に接続されました！');
      _apiKeyController.clear();
      _databaseIdController.clear();

    } catch (e) {
      _showSnackBar('接続に失敗しました: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  Future<void> _performBackup() async {
    try {
      _showSnackBar('バックアップを開始しています...');

      final thoughtRepository = Provider.of<ThoughtRepository>(context, listen: false);
      final settings = Provider.of<PrivacySettings>(context, listen: false);

      final thoughts = await thoughtRepository.getAllThoughts();
      
      final notionService = NotionService(
        apiKey: settings.notionApiKey!,
        databaseId: settings.notionDatabaseId!,
      );

      final result = await notionService.backupThoughts(thoughts);

      if (result.isSuccess) {
        settings.lastBackupTime = DateTime.now();
        await settings.save();
        
        _showSnackBar('${result.backedUpCount}件の記録をバックアップしました');
      } else {
        _showSnackBar(result.errorMessage!, isError: true);
      }

    } catch (e) {
      _showSnackBar('バックアップエラー: ${e.toString()}', isError: true);
    }
  }

  void _showDisconnectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notion連携を解除'),
        content: Text('Notion連携を解除しますか？バックアップ機能が使用できなくなります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              final settings = Provider.of<PrivacySettings>(context, listen: false);
              await settings.clearNotionCredentials();
              Navigator.pop(context);
              _showSnackBar('Notion連携を解除しました');
            },
            child: Text('解除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
```

### **3. 自動バックアップ機能**

#### **バックグラウンドタスク実装**
```dart
// lib/services/background_backup_service.dart
class BackgroundBackupService {
  static const String _lastBackupKey = 'last_backup_timestamp';
  
  static Future<void> checkAndPerformBackup() async {
    final settings = await PrivacySettings.load();
    
    if (!settings.enableNotionBackup || !settings.autoBackupEnabled) {
      return;
    }

    final lastBackup = settings.lastBackupTime;
    final now = DateTime.now();
    
    if (lastBackup == null || 
        now.difference(lastBackup).inDays >= settings.autoBackupIntervalDays) {
      
      try {
        await _performAutomaticBackup(settings);
        
        // 成功通知
        await _showBackupNotification(success: true);
        
      } catch (e) {
        // エラー通知
        await _showBackupNotification(success: false, error: e.toString());
      }
    }
  }

  static Future<void> _performAutomaticBackup(PrivacySettings settings) async {
    final thoughtRepository = ThoughtRepository();
    final thoughts = await thoughtRepository.getAllThoughts();
    
    final notionService = NotionService(
      apiKey: settings.notionApiKey!,
      databaseId: settings.notionDatabaseId!,
    );

    final result = await notionService.backupThoughts(thoughts);
    
    if (!result.isSuccess) {
      throw Exception(result.errorMessage);
    }

    // 設定更新
    settings.lastBackupTime = DateTime.now();
    await settings.save();
  }

  static Future<void> _showBackupNotification({
    required bool success,
    String? error,
  }) async {
    // Flutter Local Notifications実装
    // 成功・失敗に応じた通知表示
  }
}
```

---

## 🧪 **Phase 3B: テスト・品質向上**

### **1. 統合テスト実装**
```dart
// test/integration_test/notion_integration_test.dart
void main() {
  group('Notion連携統合テスト', () {
    testWidgets('Notion接続・バックアップフロー', (tester) async {
      // 1. アプリ起動
      await tester.pumpWidget(MyApp());
      
      // 2. 設定画面に移動
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      
      // 3. Notion設定画面に移動
      await tester.tap(find.text('Notion連携'));
      await tester.pumpAndSettle();
      
      // 4. API認証情報入力
      await tester.enterText(
        find.byKey(Key('notion_api_key')), 
        'test_api_key'
      );
      await tester.enterText(
        find.byKey(Key('notion_database_id')), 
        'test_database_id'
      );
      
      // 5. 接続実行
      await tester.tap(find.text('Notionに接続'));
      await tester.pumpAndSettle();
      
      // 6. 接続成功確認
      expect(find.text('Notion連携中'), findsOneWidget);
      
      // 7. バックアップ実行
      await tester.tap(find.text('今すぐバックアップ'));
      await tester.pumpAndSettle();
      
      // 8. 成功メッセージ確認
      expect(find.textContaining('バックアップしました'), findsOneWidget);
    });
  });
}
```

### **2. エラーハンドリング強化**
```dart
// lib/utils/error_handler.dart
class ErrorHandler {
  static void handleNotionError(dynamic error, BuildContext context) {
    String userMessage;
    
    if (error is DioException) {
      switch (error.response?.statusCode) {
        case 401:
          userMessage = 'Notion APIキーが無効です。設定を確認してください。';
          break;
        case 404:
          userMessage = 'データベースが見つかりません。Database IDを確認してください。';
          break;
        case 429:
          userMessage = 'API制限に達しました。しばらく待ってから再試行してください。';
          break;
        default:
          userMessage = 'Notionとの通信でエラーが発生しました。';
      }
    } else {
      userMessage = '予期しないエラーが発生しました: ${error.toString()}';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userMessage),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: '再試行',
          textColor: Colors.white,
          onPressed: () {
            // 再試行ロジック
          },
        ),
      ),
    );
  }
}
```

---

## 🎯 **Phase 3 完了基準**

### **機能完了チェックリスト**
- [ ] **Notion API統合**: 認証・接続・データ送信
- [ ] **バックアップ機能**: 手動・自動バックアップ実行
- [ ] **設定画面**: API設定・連携管理UI
- [ ] **エラーハンドリング**: 適切なエラー表示・回復
- [ ] **データ変換**: ThoughtEntry → Notion Page
- [ ] **セキュリティ**: API キーの安全な保存
- [ ] **自動化**: バックグラウンド自動バックアップ
- [ ] **通知**: バックアップ完了・エラー通知
- [ ] **テスト**: 統合テスト・エラーケーステスト

### **品質基準**
- [ ] **プライバシー**: ユーザーデータの安全な処理
- [ ] **パフォーマンス**: 大量データの効率的バックアップ
- [ ] **信頼性**: ネットワークエラー時の適切な処理
- [ ] **ユーザビリティ**: 直感的な設定・操作UI
- [ ] **保守性**: コードの可読性・拡張性

---

## 📞 **Phase 3 開発サポート**

### **参考リソース**
- **Notion API ドキュメント**: https://developers.notion.com/
- **Phase 2完成版**: 既存のFlutter実装を基盤として活用
- **プライバシー基本方針**: CLAUDE_INSTRUCTIONS.mdの Tier 1 を厳守

### **困った時の対処**
1. **CLAUDE_INSTRUCTIONS.md** でプライバシー基本方針を再確認
2. **FLUTTER_DESIGN_SPEC.md** で既存アーキテクチャを参照
3. **Notion API制限**: レート制限・データサイズ制限を考慮
4. **不明な場合は質問**: 基本方針に反しない範囲で実装

---

**🚀 Phase 2の素晴らしい成果を基盤に、Notion連携を実装してClarityアプリを完全体にしましょう！**