# 🧠 Clarity - AI分析機能付き思考記録PWAアプリ

<div align="center">
  
![Clarity Logo](./clarity-app/public/icon-512.png)

**GitHub公開レベルのプレミアムモダンUI**で作られた、AI分析機能付きの思考記録PWAアプリです。

[![Next.js](https://img.shields.io/badge/Next.js-15.4.1-black?style=flat-square&logo=next.js)](https://nextjs.org/)
[![React](https://img.shields.io/badge/React-19.1.0-blue?style=flat-square&logo=react)](https://reactjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.8.3-blue?style=flat-square&logo=typescript)](https://www.typescriptlang.org/)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind%20CSS-v4-38bdf8?style=flat-square&logo=tailwind-css)](https://tailwindcss.com/)
[![PWA](https://img.shields.io/badge/PWA-Ready-green?style=flat-square)](https://web.dev/progressive-web-apps/)

</div>

## ✨ 特徴

### 🎨 **プレミアムモダンUI**
- **Glassmorphism効果** - 美しい半透明カード・ナビゲーション
- **完全ダークモード対応** - システム設定連動
- **感情分析カラーシステム** - AI分析結果に応じた色変化
- **マイクロアニメーション** - Framer Motion使用のスムーズな動作
- **レスポンシブデザイン** - モバイルファースト設計

### 🧠 **AI分析機能**
- **OpenAI GPT統合** - 思考内容の感情・テーマ分析
- **感情スコア算出** - 詳細な感情分析結果
- **カテゴリ自動分類** - 思考内容の自動カテゴライズ
- **データ可視化** - 美しいチャート・グラフで傾向表示

### 📱 **PWA対応**
- **オフライン対応** - サービスワーカー実装
- **インストール可能** - スマートフォン・デスクトップ対応
- **プッシュ通知** - 記録リマインダー機能
- **高速起動** - Next.js最適化

### 🗄️ **データ管理**
- **Supabaseクラウド** - 安全なデータベース保存
- **リアルタイム同期** - 複数デバイス間での同期
- **エクスポート機能** - CSV・JSON形式での書き出し
- **バックアップ** - 自動データバックアップ

## 🚀 デモ

**🌐 ライブデモ**: [https://danserpoti.github.io/clarity-app/](https://danserpoti.github.io/clarity-app/)

> **Note**: GitHub Pagesでのデモでは、バックエンドAPI（AI分析、データベース）機能は制限されます。完全な機能を体験するには、ローカル環境で実行してください。

## 📸 スクリーンショット

### 🌅 ライトモード
| メインページ | 思考記録作成 | 分析ダッシュボード |
|---|---|---|
| ![Light Home](./docs/screenshots/light-home.png) | ![Light New](./docs/screenshots/light-new.png) | ![Light Analytics](./docs/screenshots/light-analytics.png) |

### 🌙 ダークモード
| メインページ | 思考記録一覧 | 設定画面 |
|---|---|---|
| ![Dark Home](./docs/screenshots/dark-home.png) | ![Dark List](./docs/screenshots/dark-list.png) | ![Dark Settings](./docs/screenshots/dark-settings.png) |

## 🛠️ 技術スタック

### **フロントエンド**
- **Next.js 15.4.1** - React フレームワーク（Turbopack使用）
- **React 19.1.0** - UIライブラリ
- **TypeScript 5.8.3** - 型安全な開発
- **Tailwind CSS v4** - ユーティリティファーストCSS
- **Framer Motion** - アニメーションライブラリ

### **UI/UX**
- **shadcn/ui** - ベースコンポーネント
- **Radix UI** - アクセシブルなUIプリミティブ
- **Lucide React** - アイコンセット
- **Recharts** - データ可視化

### **バックエンド・API**
- **Supabase** - PostgreSQLデータベース + 認証
- **OpenAI API** - AI分析機能
- **Next.js API Routes** - サーバーレス関数

### **開発・ビルド**
- **ESLint** - コード品質管理
- **PostCSS** - CSS処理
- **PWA** - プログレッシブウェブアプリ

## 📦 インストール・セットアップ

### **必要要件**
- Node.js 18.17.0 以上
- npm または yarn
- Git

### **1. リポジトリのクローン**
```bash
git clone https://github.com/yourusername/clarity-app.git
cd clarity-app/clarity-app
```

### **2. 依存関係のインストール**
```bash
npm install
# または
yarn install
```

### **3. 環境変数の設定**
`.env.local`ファイルを作成し、以下の変数を設定：

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# OpenAI
OPENAI_API_KEY=your_openai_api_key

# Notion (オプション)
NOTION_API_KEY=your_notion_api_key
NOTION_DATABASE_ID=your_database_id
```

### **4. Supabaseデータベースセットアップ**

#### **🏗️ Supabaseプロジェクト作成**
1. **Supabaseアカウント作成**: https://supabase.com/dashboard
2. **新しいプロジェクト作成**: "New Project" をクリック
3. **プロジェクト設定**:
   - Organization: 個人用を選択
   - Name: `clarity-app`
   - Database Password: 強力なパスワードを設定
   - Region: 最寄りのリージョンを選択

#### **📊 データベーステーブル作成**
Supabase SQL Editorで以下のSQLを実行：

```sql
-- 思考記録テーブル
CREATE TABLE thoughts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  content TEXT NOT NULL,
  category TEXT NOT NULL,
  ai_analysis TEXT,
  ai_emotion TEXT,
  ai_emotion_score DECIMAL,
  ai_themes TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- インデックス作成（パフォーマンス向上）
CREATE INDEX idx_thoughts_created_at ON thoughts(created_at DESC);
CREATE INDEX idx_thoughts_category ON thoughts(category);
CREATE INDEX idx_thoughts_emotion ON thoughts(ai_emotion);

-- RLS (Row Level Security) 有効化
ALTER TABLE thoughts ENABLE ROW LEVEL SECURITY;

-- 全ユーザーがアクセス可能なポリシー（デモ用）
CREATE POLICY "Enable all access for thoughts" ON thoughts
FOR ALL USING (true);
```

#### **🔑 API キー取得**
1. **Settings** → **API** に移動
2. 以下の値をコピー:
   - `Project URL` → `NEXT_PUBLIC_SUPABASE_URL`
   - `anon public` key → `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `service_role` key → `SUPABASE_SERVICE_ROLE_KEY`

#### **🔒 セキュリティ設定**
- **Authentication** → **Settings** でメール認証を設定（オプション）
- **Database** → **Extensions** で必要な拡張機能を有効化

#### **🤖 OpenAI API設定**

1. **OpenAIアカウント作成**: https://platform.openai.com/signup
2. **API キー生成**:
   - **API Keys** → **Create new secret key**
   - キー名: `clarity-app`
   - キーをコピー: `sk-...` → `OPENAI_API_KEY`
3. **使用量制限設定**（推奨）:
   - **Billing** → **Usage limits** で月額制限を設定
   - 例: $10/月の制限

#### **💰 コスト目安**
- **GPT-4o Mini**: 約$0.0001/リクエスト
- **月間1000回分析**: 約$0.10
- **AI分析はオプション機能**のため、無効化も可能

### **5. 開発サーバーの起動**
```bash
npm run dev
# または
yarn dev
```

アプリケーションは `http://localhost:3000` で起動します。

## 🎯 使用方法

### **1. 思考記録の作成**
1. 「新規記録」ボタンをクリック
2. 思考内容を自由に入力
3. カテゴリを選択
4. 「AI分析を実行」でAI分析（オプション）
5. 「保存」でデータベースに保存

### **2. AI分析機能**
- **感情分析**: positive, negative, neutral, mixed
- **感情スコア**: 0-1の数値で感情の強度を表示
- **テーマ抽出**: 主要なテーマ・キーワードを自動抽出
- **カテゴリ推奨**: 適切なカテゴリを推奨

### **3. データ可視化**
- **カテゴリ別円グラフ**: 記録のカテゴリ分布
- **感情推移グラフ**: 時系列での感情変化
- **分析統計**: 総記録数、分析率、トレンド
- **エクスポート**: CSV/JSON形式でデータ書き出し

### **4. PWAインストール**
1. ブラウザのアドレスバーの「インストール」ボタンをクリック
2. または、アプリ内の「PWAインストール」プロンプトから
3. デスクトップ・スマートフォンでネイティブアプリのように使用可能

## 🎨 デザインシステム

### **カラーパレット**
```css
/* 感情分析カラー */
--emotion-positive: oklch(0.7 0.15 142);  /* 緑系 */
--emotion-negative: oklch(0.65 0.2 29);   /* 赤系 */
--emotion-neutral: oklch(0.6 0.05 225);   /* 青系 */
--emotion-mixed: oklch(0.7 0.12 85);      /* オレンジ系 */

/* グラデーション */
--gradient-primary: linear-gradient(135deg, oklch(0.6 0.2 240), oklch(0.65 0.25 280));
--gradient-secondary: linear-gradient(135deg, oklch(0.85 0.1 160), oklch(0.9 0.08 180));
```

### **Glassmorphism効果**
```css
.glass {
  background: var(--glass-bg);
  backdrop-filter: var(--glass-backdrop);
  border: 1px solid var(--glass-border);
  box-shadow: var(--glass-shadow);
}
```

## 📝 API仕様

### **思考記録 API**
```typescript
// GET /api/thoughts - 思考記録一覧取得
// POST /api/thoughts - 新しい思考記録作成
// PUT /api/thoughts/[id] - 思考記録更新
// DELETE /api/thoughts/[id] - 思考記録削除
```

### **AI分析 API**
```typescript
// POST /api/analyze - AI分析実行
interface AnalysisRequest {
  content: string;
  category?: string;
}

interface AnalysisResponse {
  emotion: 'positive' | 'negative' | 'neutral' | 'mixed';
  emotionScore: number;
  themes: string[];
  summary: string;
}
```

## 🧪 テスト

```bash
# テスト実行
npm run test

# E2Eテスト（Playwright）
npm run test:e2e

# テストカバレッジ
npm run test:coverage
```

## 🏗️ ビルド・デプロイ

### **本番ビルド**
```bash
npm run build
npm run start
```

### **GitHub Pagesデプロイ**
```bash
# 自動デプロイ: mainブランチにpushすると自動的にGitHub Pagesにデプロイ
git push origin main
```

GitHub Actionsが自動的に以下を実行：
1. Node.js環境のセットアップ
2. 依存関係のインストール
3. 静的ファイルのビルド (`npm run build:github`)
4. GitHub Pagesへのデプロイ

### **Vercel完全版デプロイ（推奨）**

#### **🚀 ワンクリックデプロイ**
[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2Fdanserpoti%2Fclarity-app&env=NEXT_PUBLIC_SUPABASE_URL,NEXT_PUBLIC_SUPABASE_ANON_KEY,SUPABASE_SERVICE_ROLE_KEY,OPENAI_API_KEY&envDescription=Required%20environment%20variables%20for%20Clarity%20app&envLink=https%3A%2F%2Fgithub.com%2Fdanserpoti%2Fclarity-app%23setup&project-name=clarity-app&repository-name=clarity-app)

#### **📋 手動デプロイ手順**
1. **Vercelアカウント作成**: https://vercel.com/signup
2. **GitHubリポジトリをインポート**:
   ```bash
   # Vercel CLI使用の場合
   npm i -g vercel
   vercel --prod
   ```
3. **環境変数設定**（Vercelダッシュボード → Settings → Environment Variables）:
   ```env
   NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
   SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
   OPENAI_API_KEY=your_openai_api_key
   ```
4. **デプロイ実行**: 自動デプロイまたは手動トリガー

#### **✅ Vercel設定のメリット**
- ✨ **完全なAI分析機能**
- 💾 **Supabaseデータベース連携**
- 🔄 **リアルタイム同期**
- 📊 **完全なデータ可視化**
- 🌍 **独自ドメイン対応**
- ⚡ **エッジデプロイ（高速）**

### **🥈 Netlify デプロイ（代替案）**

#### **🚀 ワンクリックデプロイ**
[![Deploy to Netlify](https://www.netlify.com/img/deploy/button.svg)](https://app.netlify.com/start/deploy?repository=https://github.com/danserpoti/clarity-app)

#### **📋 設定手順**
1. **Netlifyアカウント作成**: https://app.netlify.com/signup
2. **ビルド設定**:
   ```
   Build command: cd clarity-app && npm run build
   Publish directory: clarity-app/.next
   ```
3. **環境変数設定**: Netlify Dashboard → Site settings → Environment variables

### **🥉 Railway デプロイ（フルスタック）**

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/clarity-app)

### **Docker**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
```

## 🤝 コントリビューション

1. このリポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add some amazing feature'`)
4. ブランチをプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

### **開発ガイドライン**
- TypeScriptの型安全性を保つ
- ESLintルールに従う
- コミットメッセージは[Conventional Commits](https://www.conventionalcommits.org/)形式
- テストを追加/更新する

## 📄 ライセンス

このプロジェクトは [MIT License](LICENSE) の下で公開されています。

## 👥 作成者

**Clarity Team**
- 開発者: [Your Name](https://github.com/yourusername)
- デザイン: [Designer Name](https://github.com/designername)

## 🙏 謝辞

- [Next.js](https://nextjs.org/) - React フレームワーク
- [Tailwind CSS](https://tailwindcss.com/) - CSSフレームワーク
- [Framer Motion](https://www.framer.com/motion/) - アニメーションライブラリ
- [shadcn/ui](https://ui.shadcn.com/) - UIコンポーネント
- [Supabase](https://supabase.com/) - バックエンドサービス
- [OpenAI](https://openai.com/) - AI分析機能

## 📞 サポート

問題や質問がある場合：
- [Issues](https://github.com/yourusername/clarity-app/issues) - バグレポート・機能要望
- [Discussions](https://github.com/yourusername/clarity-app/discussions) - 質問・議論
- Email: support@clarity-app.com

---

<div align="center">

**⭐ このプロジェクトが役に立った場合は、スターをつけていただけると嬉しいです！**

[🌟 Star this repo](https://github.com/yourusername/clarity-app) | [🐛 Report Bug](https://github.com/yourusername/clarity-app/issues) | [💡 Request Feature](https://github.com/yourusername/clarity-app/issues)

</div>