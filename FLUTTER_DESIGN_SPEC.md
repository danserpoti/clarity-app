# 🎯 Flutter版 Clarity App 設計仕様書

## 📋 プロジェクト概要
- **目標**: Next.js + localStorage版を参考にFlutter + SQLite版を開発
- **制約**: プライバシーファースト、完全ローカル保存
- **プラットフォーム**: iOS/Android/Web対応

## 🗃️ データモデル設計

### ThoughtEntry (思考記録)
```dart
class ThoughtEntry {
  final String id;
  final String content;
  final ThoughtCategory category;
  final String entryDate;     // YYYY-MM-DD
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // AI分析結果
  final EmotionType? aiEmotion;
  final double? aiEmotionScore;      // 0.0-1.0
  final List<String>? aiThemes;
  final List<String>? aiKeywords;
  final String? aiSummary;
  final String? aiSuggestion;
  final DateTime? aiAnalyzedAt;
}

enum ThoughtCategory {
  work('仕事'),
  relationships('人間関係'),
  goals('目標管理'),
  learning('学習'),
  emotions('感情'),
  other('その他');
}

enum EmotionType {
  positive('positive'),
  negative('negative'),
  neutral('neutral'),
  mixed('mixed');
}
```

## 🗄️ SQLite データベース設計

### テーブル: thought_entries
```sql
CREATE TABLE thought_entries (
  id TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  category TEXT NOT NULL,
  entry_date TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  
  -- AI分析結果
  ai_emotion TEXT,
  ai_emotion_score REAL,
  ai_themes TEXT,        -- JSON array
  ai_keywords TEXT,      -- JSON array
  ai_summary TEXT,
  ai_suggestion TEXT,
  ai_analyzed_at TEXT
);

CREATE INDEX idx_created_at ON thought_entries(created_at);
CREATE INDEX idx_category ON thought_entries(category);
CREATE INDEX idx_emotion ON thought_entries(ai_emotion);
```

## 📦 パッケージ構成

### 必須パッケージ
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # データベース
  sqflite: ^2.3.0
  path: ^1.8.3
  
  # セキュア設定保存
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  
  # HTTP通信 (OpenAI/Notion API)
  http: ^1.1.0
  dio: ^5.3.4
  
  # JSON処理
  json_serializable: ^6.7.1
  json_annotation: ^4.8.1
  
  # 状態管理
  provider: ^6.1.1
  riverpod: ^2.4.9
  
  # UI/UX
  flutter_animate: ^4.3.0
  lottie: ^2.7.0
  
  # ユーティリティ
  uuid: ^4.2.2
  intl: ^0.19.0

dev_dependencies:
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
```

## 🏗️ アーキテクチャ設計

### フォルダ構成
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── errors/
│   ├── themes/
│   └── utils/
├── data/
│   ├── databases/
│   │   ├── database_helper.dart
│   │   └── migrations/
│   ├── models/
│   │   ├── thought_entry.dart
│   │   └── analysis_result.dart
│   ├── repositories/
│   │   ├── thought_repository.dart
│   │   ├── openai_repository.dart
│   │   └── notion_repository.dart
│   └── services/
│       ├── database_service.dart
│       ├── openai_service.dart
│       └── notion_service.dart
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── pages/
│   │   ├── home/
│   │   ├── thoughts/
│   │   ├── analytics/
│   │   └── settings/
│   ├── widgets/
│   │   ├── common/
│   │   ├── thought_cards/
│   │   └── forms/
│   └── providers/
└── shared/
    ├── extensions/
    ├── mixins/
    └── widgets/
```

## 🎨 UI/UX設計

### メイン画面構成
1. **ホーム画面** - ダッシュボード、統計表示
2. **思考記録画面** - 新規記録作成、AI分析
3. **記録一覧画面** - フィルター、検索、カード表示
4. **分析画面** - チャート、統計、傾向分析
5. **設定画面** - Notion連携、エクスポート機能

### デザインシステム
- **テーマ**: Material Design 3
- **カラーパレット**: ブルー系（プライマリ）、グレー系（サブ）
- **アニメーション**: flutter_animate使用
- **レスポンシブ**: タブレット対応

## 🔐 セキュリティ設計

### データ保護
- **ローカル暗号化**: flutter_secure_storage使用
- **API Key管理**: 環境変数 + セキュアストレージ
- **通信暗号化**: HTTPS必須

### プライバシー保護
- **オフライン優先**: ネット接続なしでも基本機能動作
- **データ最小化**: AI分析時の必要最小限データ送信
- **ユーザー制御**: 全外部連携をオプション化

## 🔄 データフロー設計

### 基本フロー
1. **記録作成**: UI → Repository → SQLite
2. **AI分析**: UI → OpenAI Service → Repository → SQLite
3. **Notion同期**: UI → Notion Service → Repository
4. **データ表示**: UI → Repository → SQLite

### 状態管理
- **Provider/Riverpod**: ウィジェット間状態共有
- **Repository Pattern**: データアクセス抽象化
- **Future/Stream**: 非同期処理

## 📊 分析機能設計

### 統計情報
- 総記録数、AI分析済み数、分析率
- カテゴリ別分布、感情分布
- 時系列推移（日次、週次、月次）

### チャート表示
- 感情推移グラフ
- カテゴリ別円グラフ
- テーマ・キーワードクラウド

## 🔗 外部連携設計

### OpenAI API統合
```dart
class OpenAIService {
  Future<AnalysisResult> analyzeThought(String content);
  // プライバシー配慮：必要最小限データのみ送信
}
```

### Notion API統合
```dart
class NotionService {
  Future<void> syncThought(ThoughtEntry thought);
  Future<void> bulkSync(List<ThoughtEntry> thoughts);
  Future<bool> testConnection();
}
```

## 🚀 開発フェーズ

### Phase 2.1: 基盤実装 (Week 1)
- [ ] Flutter プロジェクト作成
- [ ] 依存関係設定
- [ ] データモデル実装
- [ ] SQLite データベース設定
- [ ] 基本CRUD操作

### Phase 2.2: UI実装 (Week 2)
- [ ] 基本画面レイアウト
- [ ] 記録作成フォーム
- [ ] 記録一覧表示
- [ ] ナビゲーション実装

### Phase 2.3: AI連携 (Week 3)
- [ ] OpenAI API統合
- [ ] 分析結果表示
- [ ] エラーハンドリング
- [ ] オフライン対応

### Phase 2.4: 高度機能 (Week 4)
- [ ] 分析画面・チャート
- [ ] Notion連携
- [ ] エクスポート機能
- [ ] 設定画面

## ✅ 品質基準

### プライバシー確認
- [ ] 全データローカル保存
- [ ] 外部サービス依存なし（Notion以外）
- [ ] AI API使用時データ最小化
- [ ] ユーザー制御可能な設定

### パフォーマンス基準
- [ ] アプリ起動時間 < 3秒
- [ ] データベース操作 < 100ms
- [ ] UI応答性 < 16ms (60fps)
- [ ] メモリ使用量 < 100MB

---

**⚠️ 重要**: この設計は CLAUDE_INSTRUCTIONS.md の基本方針に完全準拠しており、プライバシーファーストの原則を最優先としています。