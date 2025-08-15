# Clarity Backend API

Clarityアプリ用のバックエンドAPI - GPT-5-mini-2025-08-07を使用したAI思考分析サービス

## 📋 概要

このAPIは、ユーザーの思考内容を分析し、建設的なアドバイスを提供するサービスです。最新のGPT-5-mini-2025-08-07モデルを使用し、プライバシーファーストの設計で使用量制限機能を提供します。

### 主な機能

- 🤖 **GPT-5-mini-2025-08-07による高精度AI分析**
- 🛡️ **プライバシー重視設計** - 思考内容は一切保存しない
- 📊 **使用量制限管理** - デバイス別月間30回制限
- 🚦 **レート制限** - 1分間に10回まで
- 🌐 **CORS対応** - Flutter Webアプリと連携
- ⚡ **高速処理** - reasoning_effort: 'minimal'で最適化

## 🏗️ プロジェクト構成

```
backend-api/
├── api/
│   └── analyze.js          # メインAPIエンドポイント
├── lib/
│   ├── openai.js          # GPT-5-mini-2025-08-07統合
│   ├── usage.js           # 使用量管理システム
│   └── storage.js         # Vercel KVデータ保存
├── package.json           # 依存関係とスクリプト
├── vercel.json           # Vercel設定（CORS、環境変数）
├── .env.example          # 環境変数サンプル
└── README.md             # このファイル
```

## 🚀 セットアップ手順

### 1. 依存関係のインストール

```bash
cd backend-api
npm install
```

### 2. 環境変数の設定

`.env.example`をコピーして`.env`を作成し、必要な値を設定：

```bash
cp .env.example .env
```

`.env`ファイルを編集：

```env
# OpenAI API キー（必須）
OPENAI_API_KEY=sk-your-openai-api-key-here

# Vercel KV データベース（必須）
KV_URL=https://your-kv-database-url.vercel.com
KV_REST_API_TOKEN=your-kv-rest-api-token-here

# オプション設定
NODE_ENV=development
RATE_LIMIT_PER_MINUTE=10
FREE_PLAN_MONTHLY_LIMIT=30
MAX_CONTENT_LENGTH=5000
```

### 3. Vercel KVデータベースの作成

1. [Vercel Dashboard](https://vercel.com/dashboard)にログイン
2. プロジェクトの「Storage」タブを選択
3. 「Create Database」→「KV」を選択
4. データベース名を設定（例：`clarity-usage-db`）
5. 作成後、`KV_URL`と`KV_REST_API_TOKEN`をコピー

### 4. OpenAI APIキーの取得

1. [OpenAI Platform](https://platform.openai.com/)にログイン
2. API Keysページで新しいキーを作成
3. キーをコピーして環境変数に設定

### 5. ローカル開発サーバーの起動

```bash
npm run dev
```

サーバーは `http://localhost:3000` で起動します。

## 🌐 Vercelへのデプロイ

### 1. Vercelプロジェクトの作成

```bash
npm install -g vercel
vercel login
vercel
```

### 2. 環境変数の設定

Vercel Dashboardで以下の環境変数を設定：

```
OPENAI_API_KEY=sk-your-openai-api-key-here
KV_URL=@kv-rest-api-url
KV_REST_API_TOKEN=@kv-rest-api-token
NODE_ENV=production
```

### 3. プロダクションデプロイ

```bash
npm run deploy
```

## 📡 API仕様

### エンドポイント

```
POST /api/analyze
```

### リクエスト形式

```json
{
  "content": "今日のプロジェクトミーティングで意見が通らなかった。自分の提案力に不安を感じている。",
  "category": "仕事",
  "deviceId": "550e8400-e29b-41d4-a716-446655440000"
}
```

### レスポンス形式（成功時）

```json
{
  "success": true,
  "analysis": {
    "emotion": "negative",
    "emotionScore": 0.65,
    "themes": ["職場コミュニケーション", "自己効力感"],
    "keywords": ["プロジェクト", "ミーティング", "提案"],
    "summary": "職場での提案が受け入れられず、自分の能力に対する不安を感じている状況。",
    "suggestion": "提案が通らなかった経験は誰にでもあります。次回は事前に関係者と個別に話し合い、懸念点を把握してから提案してみましょう。今回の経験を活かして、より効果的な提案方法を身につけることができます。"
  },
  "usage": {
    "used": 15,
    "limit": 30,
    "remaining": 15,
    "resetDate": "2025-09-01T00:00:00Z"
  },
  "metadata": {
    "processingTime": 1250,
    "model": "gpt-5-mini-2025-08-07",
    "version": "1.0.0"
  }
}
```

### レスポンス形式（使用量超過時）

```json
{
  "success": false,
  "error": "USAGE_LIMIT_EXCEEDED",
  "message": "月間使用量上限に達しました",
  "usage": {
    "used": 30,
    "limit": 30,
    "remaining": 0,
    "resetDate": "2025-09-01T00:00:00Z"
  },
  "upgrade": {
    "recommended": true,
    "url": "https://clarity-app.com/pricing",
    "message": "より多くのAI分析をご利用いただくためにプレミアムプランをご検討ください。",
    "benefits": ["月間1000回のAI分析", "優先サポート"]
  }
}
```

## 📱 Flutterアプリとの連携

### FlutterアプリでのAPI呼び出し例

```dart
// lib/services/backend_ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendAIService {
  static const String baseUrl = 'https://your-api-domain.vercel.app';
  
  Future<Map<String, dynamic>> analyzeThought({
    required String content,
    required String category,
    required String deviceId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/analyze'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'content': content,
        'category': category,
        'deviceId': deviceId,
      }),
    );
    
    return jsonDecode(response.body);
  }
}
```

### デバイスIDの生成

```dart
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdManager {
  static const String _deviceIdKey = 'device_id';
  
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }
    
    return deviceId;
  }
}
```

## 🛡️ セキュリティ機能

### レート制限

- **制限**: 1分間に10回まで
- **識別**: IPアドレス（匿名化）
- **リセット**: 毎分自動

### 使用量制限

- **無料プラン**: 月間30回まで
- **リセット**: 毎月1日UTC
- **識別**: デバイスID

### 入力検証

- **コンテンツ長**: 10-5000文字
- **XSS対策**: HTMLタグ検出・拒否
- **デバイスID**: UUID v4形式検証

## 📊 モニタリングとログ

### ログ出力

```javascript
// 成功時のログ例
console.log('Analysis completed successfully:', {
  deviceId: 'device_id_prefix...',
  processingTime: 1250,
  newUsageCount: 15,
  remaining: 15
});

// エラー時のログ例
console.error('API error:', {
  error: 'AI analysis failed',
  deviceId: 'device_id_prefix...',
  processingTime: 2000
});
```

### 統計情報の取得

```javascript
import { getUsageStats } from './lib/usage.js';

const stats = await getUsageStats(deviceId);
console.log('Usage statistics:', stats);
```

## 🔧 トラブルシューティング

### よくある問題

#### 1. OpenAI API エラー

**症状**: `OpenAI API key is invalid`
**解決策**: 
- APIキーが正しく設定されているか確認
- APIキーに十分なクレジットがあるか確認

#### 2. Vercel KV接続エラー

**症状**: `Failed to get usage data`
**解決策**:
- KV_URLとKV_REST_API_TOKENが正しく設定されているか確認
- Vercel KVデータベースが作成されているか確認

#### 3. CORS エラー

**症状**: Flutterアプリからのリクエストが失敗
**解決策**:
- `vercel.json`のCORS設定を確認
- リクエストヘッダーが正しく設定されているか確認

### デバッグ方法

1. **ローカル開発時**
   ```bash
   npm run dev
   # ログを確認してエラーの詳細を把握
   ```

2. **Vercel上でのデバッグ**
   ```bash
   vercel logs
   # 本番環境のログを確認
   ```

## 📈 パフォーマンス最適化

### 推奨設定

- **reasoning_effort**: `minimal` （高速化）
- **max_tokens**: `800` （コスト最適化）
- **temperature**: `0.3` （一貫性向上）

### キャッシュ戦略

- 使用量データ: TTL付きで月末まで保存
- レート制限データ: 1分間のTTL

## 🚀 今後の拡張予定

- [ ] プレミアムプラン対応
- [ ] より詳細な分析機能
- [ ] ダッシュボード機能
- [ ] Webhook通知
- [ ] 多言語対応

## 📄 ライセンス

MIT License

## 🤝 サポート

問題や質問がある場合は、GitHubのIssuesページでお知らせください。

---

**注意**: このAPIはGPT-5-mini-2025-08-07モデルを使用します。モデル名を変更する場合は、`lib/openai.js`の`MODEL_CONFIG.model`を更新してください。