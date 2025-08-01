# Phase 2: Flutter版新規開発指示

## 🎯 **作業目標**
Phase 1で完成したNext.js版を参考に、Flutter + ローカル保存版のClarityアプリを新規開発する

## 📋 **必須事前確認**
**⚠️ 作業開始前に `CLAUDE_INSTRUCTIONS.md` を必ず読み、基本方針を確認してください**

---

## 🏗️ **プロジェクト構成**

### **新規Flutter プロジェクト作成**
```bash
# clarity-appディレクトリ内で実行
flutter create flutter_app
cd flutter_app
```

### **推奨フォルダ構成**
```
flutter_app/
├── lib/
│   ├── main.dart              # エントリーポイント
│   ├── models/                # データモデル
│   │   ├── thought_entry.dart
│   │   └── analysis_result.dart
│   ├── services/              # ビジネスロジック
│   │   ├── local_database.dart
│   │   ├── ai_service.dart
│   │   └── notion_service.dart
│   ├── screens/               # 画面
│   │   ├── home_screen.dart
│   │   ├── add_thought_screen.dart
│   │   ├── analytics_screen.dart
│   │   └── settings_screen.dart
│   ├── widgets/               # 再利用コンポーネント
│   │   ├── thought_card.dart
│   │   ├── emotion_chart.dart
│   │   └── category_selector.dart
│   └── utils/                 # ユーティリティ
│       ├── constants.dart
│       └── helpers.dart
├── assets/                    # 画像・アイコン
└── test/                     # テストコード
```

---

## 📦 **必要な依存関係**

### **pubspec.yaml の設定**
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # ローカルデータベース
  sqflite: ^2.4.0
  path: ^1.9.1
  
  # 設定・状態管理
  shared_preferences: ^2.3.5
  provider: ^6.1.2
  
  # セキュリティ
  flutter_secure_storage: ^9.2.2
  crypto: ^3.0.6
  
  # UI・アニメーション
  material_design_icons_flutter: ^7.0.7296
  fl_chart: ^0.69.2
  lottie: ^4.0.0
  
  # HTTP・API
  http: ^1.3.2
  dio: ^5.7.0
  
  # 日付・時刻
  intl: ^0.19.0
  
  # ファイル操作
  path_provider: ^2.1.5
  file_picker: ^8.1.4
  
  # Notion連携（将来用）
  # notion_api: ^1.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

---

## 📊 **データモデル設計**

### **ThoughtEntry モデル**
```dart
// lib/models/thought_entry.dart
class ThoughtEntry {
  final String id;
  final String content;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // AI分析結果
  final String? aiEmotion;
  final double? aiEmotionScore;
  final List<String>? aiThemes;
  final List<String>? aiKeywords;
  final String? aiSummary;
  final String? aiSuggestion;
  final DateTime? aiAnalyzedAt;

  ThoughtEntry({
    required this.id,
    required this.content,
    required this.category,
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
  
  // JSON変換メソッド
  Map<String, dynamic> toJson() => { /* 実装 */ };
  factory ThoughtEntry.fromJson(Map<String, dynamic> json) => { /* 実装 */ };
  
  // SQLite変換メソッド  
  Map<String, dynamic> toMap() => { /* 実装 */ };
  factory ThoughtEntry.fromMap(Map<String, dynamic> map) => { /* 実装 */ };
}
```

---

## 🗄️ **ローカルデータベース実装**

### **SQLite データベース設計**
```sql
-- thoughts テーブル
CREATE TABLE thoughts (
  id TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  category TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  ai_emotion TEXT,
  ai_emotion_score REAL,
  ai_themes TEXT, -- JSON配列として保存
  ai_keywords TEXT, -- JSON配列として保存
  ai_summary TEXT,
  ai_suggestion TEXT,
  ai_analyzed_at TEXT
);

-- インデックス作成
CREATE INDEX idx_thoughts_created_at ON thoughts(created_at DESC);
CREATE INDEX idx_thoughts_category ON thoughts(category);
CREATE INDEX idx_thoughts_emotion ON thoughts(ai_emotion);
```

### **LocalDatabase クラス実装イメージ**
```dart
// lib/services/local_database.dart
class LocalDatabase {
  static Database? _database;
  
  // データベース初期化
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  // CRUD操作
  Future<String> insertThought(ThoughtEntry thought) async { /* 実装 */ }
  Future<List<ThoughtEntry>> getAllThoughts() async { /* 実装 */ }
  Future<ThoughtEntry?> getThought(String id) async { /* 実装 */ }
  Future<int> updateThought(ThoughtEntry thought) async { /* 実装 */ }
  Future<int> deleteThought(String id) async { /* 実装 */ }
  
  // 分析系クエリ
  Future<Map<String, int>> getCategoryStats() async { /* 実装 */ }
  Future<List<ThoughtEntry>> getThoughtsByDateRange(DateTime start, DateTime end) async { /* 実装 */ }
  Future<Map<String, double>> getEmotionTrends() async { /* 実装 */ }
}
```

---

## 🤖 **AI分析サービス**

### **OpenAI API連携（プライバシー重視）**
```dart
// lib/services/ai_service.dart
class AIService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  
  // 思考分析メソッド
  Future<AnalysisResult?> analyzeThought(String content) async {
    try {
      // データ最小化: 必要最小限の情報のみ送信
      final request = {
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system', 
            'content': 'あなたは思考分析の専門家です。プライバシーを重視し、個人識別情報は一切記録しません。'
          },
          {
            'role': 'user',
            'content': '以下の思考内容を分析してください（感情、テーマ、キーワードを抽出）: $content'
          }
        ],
        'max_tokens': 500,
        'temperature': 0.7
      };
      
      // API呼び出し
      final response = await _callOpenAI(request);
      
      // 結果をパース
      return _parseAnalysisResponse(response);
      
    } catch (e) {
      print('AI分析エラー: $e');
      return null;
    }
  }
  
  // プライバシー配慮: 一時的処理のみ、永続化なし
  Future<Map<String, dynamic>> _callOpenAI(Map<String, dynamic> request) async { /* 実装 */ }
}
```

---

## 🎨 **UI実装方針**

### **参考: Next.js版のUI/UX**
Phase 1で完成した画面構成を Flutter で再現：

1. **ホーム画面**: 思考一覧・統計サマリー
2. **思考追加画面**: テキスト入力・カテゴリ選択・AI分析
3. **分析画面**: チャート・グラフ表示
4. **設定画面**: プライバシー設定・エクスポート機能

### **UI実装の重要ポイント**
```dart
// マテリアルデザイン準拠
class ClarityTheme {
  static ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    useMaterial3: true,
    // プライバシーを意識したダークモード対応
  );
}

// レスポンシブ対応
class ResponsiveLayout extends StatelessWidget {
  // モバイル・タブレット・デスクトップ対応
}
```

---

## 🔒 **プライバシー・セキュリティ実装**

### **データ暗号化**
```dart
// lib/utils/encryption.dart
class EncryptionHelper {
  // センシティブデータの暗号化
  static String encryptSensitiveData(String data) { /* 実装 */ }
  static String decryptSensitiveData(String encryptedData) { /* 実装 */ }
  
  // APIキーの安全な保存
  static Future<void> storeApiKey(String key) async { /* flutter_secure_storage使用 */ }
}
```

### **プライバシー設定**
```dart
// ユーザー制御可能な設定
class PrivacySettings {
  bool enableAIAnalysis = true;      // AI分析のON/OFF
  bool enableDataEncryption = true;  // データ暗号化
  bool enableNotionBackup = false;   // Notion連携
  
  // 設定の永続化
  Future<void> save() async { /* shared_preferences使用 */ }
  static Future<PrivacySettings> load() async { /* 実装 */ }
}
```

---

## 📱 **段階的実装計画**

### **Week 1: 基盤実装**
- [ ] Flutter プロジェクト初期化
- [ ] データモデル定義
- [ ] SQLite データベース実装
- [ ] 基本CRUD操作
- [ ] 簡単なUI（一覧・追加画面）

### **Week 2: コア機能**
- [ ] AI分析サービス統合
- [ ] UI/UX改善（Next.js版を参考）
- [ ] データ可視化（fl_chart使用）
- [ ] エラーハンドリング

### **Week 3: 高度な機能**
- [ ] データエクスポート・インポート
- [ ] プライバシー設定画面
- [ ] パフォーマンス最適化
- [ ] テスト実装

### **Week 4: Notion連携準備**
- [ ] Notion API連携基盤
- [ ] バックアップ・同期機能
- [ ] 最終テスト・調整

---

## 🧪 **テスト戦略**

### **必須テスト項目**
```dart
// test/widget_test.dart
void main() {
  group('思考記録機能テスト', () {
    testWidgets('思考追加画面の表示', (WidgetTester tester) async { /* 実装 */ });
    testWidgets('AI分析結果の表示', (WidgetTester tester) async { /* 実装 */ });
  });
  
  group('データベーステスト', () {
    test('思考データのCRUD操作', () async { /* 実装 */ });
    test('データ暗号化・復号化', () async { /* 実装 */ });
  });
  
  group('プライバシーテスト', () {
    test('外部通信の制限確認', () async { /* 実装 */ });
    test('ローカルデータの暗号化確認', () async { /* 実装 */ });
  });
}
```

---

## ⚠️ **制約・注意事項**

### **Tier 1 基本方針の厳守**
- ✅ 全データはSQLiteローカル保存のみ
- ✅ AI API以外の外部通信禁止
- ✅ ユーザーデータの完全制御
- ✅ オフライン動作保証

### **実装時の注意点**
- ❌ 外部データベース（Firebase等）の使用禁止
- ❌ 不要な権限要求の禁止
- ⚠️ AI分析時のデータ最小化
- ⚠️ エラー時の適切なフォールバック
- ⚠️ パフォーマンス最適化（大量データ対応）

---

## 🎯 **Phase 2完了基準**

### **機能完了チェックリスト**
- [ ] 思考記録のCRUD操作完全動作
- [ ] AI分析機能（オプション）動作
- [ ] データ可視化（チャート・統計）表示
- [ ] プライバシー設定機能
- [ ] データエクスポート・インポート機能
- [ ] オフライン動作確認
- [ ] クロスプラットフォーム動作確認

### **品質基準**
- [ ] プライバシー基本方針100%準拠
- [ ] レスポンシブUI対応
- [ ] エラーハンドリング適切実装
- [ ] パフォーマンス要求満足
- [ ] テスト実装完了

---

## 📞 **開発中のサポート**

### **参考リソース**
- **Next.js版**: UI/UX、データ構造、機能フローの参考
- **データ構造**: `ThoughtEntry` インターフェースを維持
- **AI分析ロジック**: 既存の分析パターンを参考

### **困った時の対処**
1. `CLAUDE_INSTRUCTIONS.md` で基本方針確認
2. Next.js版の実装を参考
3. プライバシー最優先で判断
4. 不明な場合は質問してから実装

---

**🚀 この指示に従って、Flutter版Clarityアプリの新規開発を開始してください。Phase 1のNext.js版を参考にしながら、プライバシーファーストの理想的なモバイルアプリを作成しましょう！**