#!/bin/bash
# Clarity Backend API テストスクリプト

# デプロイ後のURLを設定してください
API_URL="https://your-deployed-url.vercel.app"

echo "🧪 Clarity Backend API テスト開始"
echo "URL: $API_URL/api/analyze"
echo ""

# テスト1: 正常なリクエスト
echo "📝 テスト1: 正常なリクエスト"
curl -X POST "$API_URL/api/analyze" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "今日は仕事がうまくいかなくて落ち込んでいます。プロジェクトでミスをしてしまい、チームに迷惑をかけてしまいました。",
    "category": "仕事",
    "deviceId": "test-device-12345"
  }' | jq '.'

echo -e "\n\n"

# テスト2: 感情カテゴリのテスト
echo "😊 テスト2: ポジティブな感情"
curl -X POST "$API_URL/api/analyze" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "今日は新しいプロジェクトが成功して、とても嬉しいです！チーム全体が喜んでくれて、達成感を感じています。",
    "category": "仕事",
    "deviceId": "test-device-12345"
  }' | jq '.analysis.emotion'

echo -e "\n\n"

# テスト3: 人間関係カテゴリ
echo "👥 テスト3: 人間関係カテゴリ"
curl -X POST "$API_URL/api/analyze" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "友人との関係で悩んでいます。最近連絡が取れなくなって、何か悪いことを言ってしまったのかもしれません。",
    "category": "人間関係",
    "deviceId": "test-device-12345"
  }' | jq '.analysis.suggestion'

echo -e "\n\n"

# テスト4: 使用量確認
echo "📊 テスト4: 使用量確認"
curl -X POST "$API_URL/api/analyze" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "使用量テストのための短いメッセージです。",
    "category": "その他",
    "deviceId": "test-device-12345"
  }' | jq '.usage'

echo -e "\n\n"

# テスト5: エラーテスト（短すぎるコンテンツ）
echo "❌ テスト5: エラーテスト（短すぎるコンテンツ）"
curl -X POST "$API_URL/api/analyze" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "短い",
    "category": "その他",
    "deviceId": "test-device-12345"
  }' | jq '.error'

echo -e "\n\n"

# テスト6: 無効なカテゴリ
echo "❌ テスト6: エラーテスト（無効なカテゴリ）"
curl -X POST "$API_URL/api/analyze" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "これは有効なコンテンツですが、カテゴリが無効です。",
    "category": "無効なカテゴリ",
    "deviceId": "test-device-12345"
  }' | jq '.error'

echo -e "\n\n"
echo "✅ テスト完了"