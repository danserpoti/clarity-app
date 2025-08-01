# Phase 1: Next.js版ローカル化指示

## 🎯 **作業目標**
現在のNext.js + Supabase版を Next.js + ローカル保存版に改造する

## 📋 **必須事前確認**
**⚠️ 作業開始前に `CLAUDE_INSTRUCTIONS.md` を必ず読み、基本方針を確認してください**

## 🔄 **具体的な変更内容**

### **1. データ保存の変更**
```javascript
// 変更前: Supabase
import { createClient } from '@supabase/supabase-js'

// 変更後: ブラウザローカル
// IndexedDB + localStorage の組み合わせ
```

### **2. 実装する機能**
- ✅ **IndexedDB**: 思考データの永続化
- ✅ **localStorage**: アプリ設定・UI状態
- ✅ **データ暗号化**: センシティブデータの保護
- ✅ **エクスポート**: JSON/CSV形式でのバックアップ
- ✅ **インポート**: バックアップからの復元

### **3. 削除する依存関係**
```json
// package.json から削除
"@supabase/supabase-js": "^2.52.0",
"SUPABASE_SERVICE_ROLE_KEY": "削除"
```

### **4. 追加する依存関係**
```json
// package.json に追加
"idb": "^8.0.0",           // IndexedDB ラッパー
"crypto-js": "^4.2.0"      // データ暗号化
```

## 🏗️ **実装手順**

### **Step 1: データアクセス層の置き換え**
1. `lib/supabase.js` → `lib/localdb.js` に変更
2. IndexedDBベースのCRUD操作を実装
3. 既存のSupabase APIコールを全て置き換え

### **Step 2: データモデルの調整**
```javascript
// 既存のthoughtsテーブル構造を維持
const thoughtSchema = {
  id: 'string',
  content: 'string', 
  category: 'string',
  ai_analysis: 'string',
  ai_emotion: 'string',
  ai_emotion_score: 'number',
  ai_themes: 'array',
  created_at: 'date',
  updated_at: 'date'
}
```

### **Step 3: UI層の最小限修正**
- データ取得・保存ロジックの変更のみ
- UIコンポーネントは既存のまま維持
- ローディング状態の調整（ローカルは高速）

### **Step 4: セキュリティ実装**
```javascript
// センシティブデータの暗号化
import CryptoJS from 'crypto-js';

const encryptData = (data, key) => {
  return CryptoJS.AES.encrypt(JSON.stringify(data), key).toString();
};
```

### **Step 5: エクスポート/インポート機能**
```javascript
// データバックアップ機能
const exportData = async () => {
  const allThoughts = await localDB.getAllThoughts();
  const exportData = {
    version: '1.0',
    export_date: new Date().toISOString(),
    thoughts: allThoughts
  };
  // JSONファイルとしてダウンロード
};
```

## ⚠️ **制約・注意事項**

### **Tier 1 基本方針の確認**
- ✅ データはブラウザローカルのみ
- ✅ 外部サービスへの送信なし（AI分析除く）
- ✅ ユーザーがデータを完全制御
- ✅ オフライン動作可能

### **技術的制約**
- ❌ Supabase関連コードは完全削除
- ❌ 外部データベースの使用禁止
- ⚠️ AI分析時のデータ最小化
- ⚠️ エラー処理の適切な実装

## 🧪 **テスト項目**

### **機能テスト**
- [ ] 思考データの作成・読み取り・更新・削除
- [ ] AI分析の実行・結果保存
- [ ] データ可視化の表示
- [ ] エクスポート・インポート機能
- [ ] ブラウザリロード後のデータ永続化

### **プライバシーテスト**
- [ ] 外部への通信がAI API以外発生しないこと
- [ ] ローカルデータの暗号化
- [ ] 機密データの適切な処理

## 🎯 **完了基準**

### **Phase 1完了の定義**
1. ✅ Supabase依存を完全除去
2. ✅ ローカルストレージで全機能動作
3. ✅ 既存UIが問題なく動作
4. ✅ データエクスポート・インポート機能
5. ✅ AI分析機能の維持
6. ✅ プライバシー基準のクリア

### **次のPhase 2への準備**
- Flutter版開発の参考実装として活用
- UI/UXの改善点を文書化
- データ構造の最適化案を検討

## 📞 **困った時の対応**

### **よくある問題と対処**
- **IndexedDB接続エラー**: ブラウザ互換性を確認
- **データ移行問題**: 段階的移行スクリプトを作成
- **パフォーマンス問題**: データ量制限・インデックス最適化

### **判断に迷った場合**
1. `CLAUDE_INSTRUCTIONS.md` の基本方針を確認
2. プライバシー保護を最優先
3. 不明な場合は質問してから実装

---

**🚀 この指示に従って、Phase 1のローカル化を実装してください。完了後、Phase 2のFlutter開発に進みます。**