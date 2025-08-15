# 🚀 今すぐデプロイ！ - 具体的手順

## Step 1: Vercelログイン

```bash
cd backend-api
vercel login
```

→ **「Continue with GitHub」**を選択してブラウザでログイン

## Step 2: 初回デプロイ

```bash
vercel
```

プロンプトで以下を入力：

```
? Set up and deploy "backend-api"? [Y/n] Y
? Which scope do you want to deploy to? → あなたのアカウント名を選択
? Link to existing project? [y/N] N
? What's your project's name? clarity-backend-api
? In which directory is your code located? ./
```

## Step 3: 環境変数設定

デプロイ完了後、Vercel Dashboardで設定：

```
https://vercel.com/your-username/clarity-backend-api/settings/environment-variables
```

追加する環境変数：
```
OPENAI_API_KEY = sk-your-openai-api-key-here
NODE_ENV = production
RATE_LIMIT_PER_MINUTE = 10
FREE_PLAN_MONTHLY_LIMIT = 30
MAX_CONTENT_LENGTH = 5000
```

## Step 4: Vercel KVデータベース作成

1. プロジェクトの**「Storage」**タブに移動
2. **「Create Database」→「KV」**をクリック
3. Database name: `clarity-usage-db`
4. **「Create」**をクリック

## Step 5: 再デプロイ（環境変数適用）

```bash
vercel --prod
```

## ✅ 完了確認

デプロイURL（例）: `https://clarity-backend-api-xyz123.vercel.app`

### APIテスト

```bash
curl -X POST https://your-deployed-url.vercel.app/api/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "content": "今日は仕事がうまくいかなくて落ち込んでいます",
    "category": "仕事",
    "deviceId": "test-device-12345"
  }'
```

---

## 🔄 代替方法: GitHub連携デプロイ

### Step 1: GitHubリポジトリ作成

1. [GitHub](https://github.com/new)で新しいリポジトリ作成
2. Repository name: `clarity-backend-api`
3. **「Create repository」**

### Step 2: コードをプッシュ

```bash
cd backend-api
git remote add origin https://github.com/YOUR_USERNAME/clarity-backend-api.git
git branch -M main
git push -u origin main
```

### Step 3: Vercelでインポート

1. [Vercel Dashboard](https://vercel.com/dashboard)
2. **「Add New」→「Project」**
3. **「Import Git Repository」**
4. 作成したリポジトリを選択

---

## ⚡ 最速デプロイ（推奨）

最も簡単な方法：

```bash
# 1. ログイン
vercel login

# 2. デプロイ
vercel

# 3. 本番デプロイ
vercel --prod
```

すべてのプロンプトで**Enter**（デフォルト値）を選択するだけ！