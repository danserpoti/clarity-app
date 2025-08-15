@echo off
REM Clarity Backend API テストスクリプト (Windows)

REM デプロイ後のURLを設定してください
set API_URL=https://your-deployed-url.vercel.app

echo 🧪 Clarity Backend API テスト開始
echo URL: %API_URL%/api/analyze
echo.

REM テスト1: 正常なリクエスト
echo 📝 テスト1: 正常なリクエスト
curl -X POST "%API_URL%/api/analyze" ^
  -H "Content-Type: application/json" ^
  -d "{\"content\": \"今日は仕事がうまくいかなくて落ち込んでいます\", \"category\": \"仕事\", \"deviceId\": \"test-device-12345\"}"

echo.
echo.

REM テスト2: 感情カテゴリのテスト  
echo 😊 テスト2: ポジティブな感情
curl -X POST "%API_URL%/api/analyze" ^
  -H "Content-Type: application/json" ^
  -d "{\"content\": \"今日は新しいプロジェクトが成功して、とても嬉しいです！\", \"category\": \"仕事\", \"deviceId\": \"test-device-12345\"}"

echo.
echo.

REM テスト3: 使用量確認
echo 📊 テスト3: 使用量確認
curl -X POST "%API_URL%/api/analyze" ^
  -H "Content-Type: application/json" ^
  -d "{\"content\": \"使用量テストのためのメッセージです。今日の気分について記録したいと思います。\", \"category\": \"その他\", \"deviceId\": \"test-device-12345\"}"

echo.
echo.

REM テスト4: エラーテスト
echo ❌ テスト4: エラーテスト（短すぎるコンテンツ）
curl -X POST "%API_URL%/api/analyze" ^
  -H "Content-Type: application/json" ^
  -d "{\"content\": \"短い\", \"category\": \"その他\", \"deviceId\": \"test-device-12345\"}"

echo.
echo.
echo ✅ テスト完了