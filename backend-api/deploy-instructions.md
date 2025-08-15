# 🚀 Clarity Backend API - Vercelデプロイ手順

## 即座にデプロイ可能！

### 方法1: Vercel Dashboard（推奨）

1. **[Vercel Dashboard](https://vercel.com/dashboard)** にアクセス
2. **「Add New」→「Project」** をクリック
3. **「Import Git Repository」** でこのリポジトリを選択

### プロジェクト設定

```
Project Name: clarity-backend-api
Framework: Other
Root Directory: ./
Build Command: (empty)
Output Directory: (empty)
Install Command: npm install
```

### 環境変数設定（重要！）

デプロイ時に以下を設定：

```env
OPENAI_API_KEY=sk-your-openai-api-key-here
NODE_ENV=production
RATE_LIMIT_PER_MINUTE=10
FREE_PLAN_MONTHLY_LIMIT=30
MAX_CONTENT_LENGTH=5000
```

### Vercel KV データベース作成

1. プロジェクトデプロイ後、**「Storage」**タブを選択
2. **「Create Database」→「KV」**をクリック
3. データベース名: `clarity-usage-db`
4. 作成完了後、KV環境変数が自動設定されます

### 方法2: Vercel CLI

```bash
cd backend-api
npx vercel
# プロンプトに従って設定:
# - Project name: clarity-backend-api  
# - Directory: ./
# - Settings: デフォルトのまま
```

### 方法3: GitHub連携（最も推奨）

1. GitHubで新しいリポジトリ作成
2. このディレクトリをpush:
   ```bash
   git remote add origin https://github.com/yourusername/clarity-backend-api.git
   git push -u origin master
   ```
3. VercelでGitHubリポジトリをimport

## ✅ デプロイ後の確認

### 1. URL確認
デプロイ完了後、以下のようなURLが発行されます：
```
https://clarity-backend-api-xyz123.vercel.app
```

### 2. API動作テスト

```bash
curl -X POST https://your-deployed-url.vercel.app/api/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "content": "今日は仕事がうまくいかなくて落ち込んでいます",
    "category": "仕事", 
    "deviceId": "test-device-12345"
  }'
```

### 3. 期待されるレスポンス

```json
{
  "success": true,
  "analysis": {
    "emotion": "negative",
    "emotionScore": 0.7,
    "themes": ["仕事の挫折", "感情管理"],
    "keywords": ["仕事", "落ち込み"],
    "summary": "仕事での失敗により気分が落ち込んでいる状況",
    "suggestion": "仕事がうまくいかない日は誰にでもあります。今日の経験を振り返り、明日に活かせる学びを見つけてみましょう。小さな成功を積み重ねることで、きっと状況は改善されます。"
  },
  "usage": {
    "used": 1,
    "limit": 30,
    "remaining": 29,
    "resetDate": "2025-02-01T00:00:00Z"
  }
}
```

## 🔧 トラブルシューティング

### OpenAI APIエラー
- APIキーが正しく設定されているか確認
- GPT-5-mini-2025-08-07モデルが利用可能か確認

### KVデータベースエラー  
- Vercel KVが正しく作成されているか確認
- 環境変数が自動設定されているか確認

### CORS エラー
- vercel.jsonのCORS設定を確認
- Flutter WebアプリのAPIエンドポイントURL更新

---

**重要**: デプロイ完了後、発行されたURLをFlutterアプリの設定に更新してください！