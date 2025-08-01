# 📱 Clarity Flutter App

思考・感情記録アプリ - プライバシーファースト設計のFlutter版

## 🎯 プロジェクト概要

Clarityは、ユーザーの思考と感情を記録し、AI分析により自己理解を深めるためのモバイルアプリです。**完全プライバシーファースト**の設計により、すべてのデータは端末内でのみ管理されます。

### 主な特徴
- ✅ **完全ローカル保存**: SQLiteによる端末内データ管理
- ✅ **AI分析機能**: OpenAI APIによる思考分析（オプション）
- ✅ **プライバシー保護**: 外部サーバーへのデータ送信なし
- ✅ **クロスプラットフォーム**: iOS/Android/Web対応
- ✅ **オフライン動作**: ネット接続なしでも基本機能利用可能

## 🚀 セットアップ手順

### 1. Flutter開発環境の準備

#### Flutter SDKのインストール

**Windows:**
```bash
# 公式サイトからZIPファイルをダウンロード
# https://docs.flutter.dev/get-started/install/windows

# PATHに追加後、確認
flutter --version
flutter doctor
```

**macOS:**
```bash
# Homebrewを使用
brew install --cask flutter

# 確認
flutter --version
flutter doctor
```

**Linux:**
```bash
# snapを使用
sudo snap install flutter --classic

# 確認
flutter --version
flutter doctor
```

#### Android Studio / Xcode の準備
```bash
# Android開発用（必須）
# Android Studioをインストール
# Android SDK、Android SDK Command-line Toolsを設定

# iOS開発用（macOSのみ）
# Xcodeをインストール
# CocoaPodsをインストール: sudo gem install cocoapods

# 設定確認
flutter doctor
```

### 2. プロジェクトのセットアップ

```bash
# プロジェクトディレクトリに移動
cd clarity-app/flutter_app

# 依存関係のインストール
flutter pub get

# プラットフォーム固有の設定
flutter precache
```

### 3. 実行・デバッグ

```bash
# 利用可能なデバイスの確認
flutter devices

# 開発サーバーの起動（デバッグモード）
flutter run

# 特定のデバイスで実行
flutter run -d <device-id>

# リリースモードでの実行
flutter run --release
```

### 4. ビルド

```bash
# Android APKの生成
flutter build apk

# iOS アプリの生成（macOSのみ）
flutter build ios

# Web版の生成
flutter build web
```

## 📁 プロジェクト構造

```
flutter_app/
├── lib/
│   ├── main.dart                    # アプリエントリーポイント
│   ├── models/                      # データモデル
│   │   ├── thought_entry.dart       # 思考記録モデル
│   │   └── analysis_result.dart     # AI分析結果モデル
│   ├── services/                    # ビジネスロジック
│   │   ├── local_database.dart      # SQLiteデータベース
│   │   ├── ai_service.dart          # AI分析サービス
│   │   └── privacy_service.dart     # プライバシー設定
│   ├── screens/                     # 画面
│   │   ├── home_screen.dart         # ホーム画面
│   │   ├── add_thought_screen.dart  # 思考追加画面
│   │   ├── analytics_screen.dart    # 分析画面
│   │   └── settings_screen.dart     # 設定画面
│   ├── widgets/                     # 再利用可能コンポーネント
│   │   ├── thought_card.dart        # 思考記録カード
│   │   └── emotion_chart.dart       # 感情チャート
│   └── utils/                       # ユーティリティ
│       ├── constants.dart           # 定数定義
│       └── encryption.dart          # 暗号化ヘルパー
├── assets/                          # アセット
│   ├── images/                      # 画像ファイル
│   └── icons/                       # アイコンファイル
├── test/                           # テストコード
└── pubspec.yaml                    # パッケージ設定
```

## 🔧 開発

### 推奨開発環境
- **IDE**: Android Studio / VS Code (Flutter拡張機能)
- **Flutter**: 3.4.3 以上
- **Dart**: 3.0.0 以上

### 主要パッケージ
```yaml
dependencies:
  # データベース
  sqflite: ^2.4.0           # SQLite
  
  # 状態管理
  provider: ^6.1.2          # 状態管理
  
  # セキュリティ
  flutter_secure_storage: ^9.2.2  # セキュア設定保存
  crypto: ^3.0.6                  # 暗号化
  
  # UI/チャート
  fl_chart: ^0.69.2         # チャート表示
  
  # HTTP通信
  dio: ^5.7.0               # HTTP クライアント
```

### コード品質
```bash
# リンター実行
flutter analyze

# フォーマット
flutter format .

# テスト実行
flutter test

# カバレッジ測定
flutter test --coverage
```

## 🔒 プライバシー・セキュリティ

### データ保護原則
1. **ローカル保存のみ**: 全データはSQLiteで端末内に保存
2. **外部通信制限**: AI分析時のみOpenAI APIと通信
3. **データ暗号化**: センシティブデータの暗号化保存
4. **ユーザー制御**: 全外部連携機能をオプション化
5. **透明性**: データ処理の完全な透明性

### セキュリティ機能
- `flutter_secure_storage`によるAPIキー管理
- `crypto`パッケージによるデータ暗号化
- ローカルデータベースの最適化とバックアップ

## 🧪 テスト

### テスト実行
```bash
# 全テストの実行
flutter test

# 特定のテストファイル実行
flutter test test/models/thought_entry_test.dart

# ウィジェットテスト実行
flutter test test/widgets/
```

### テスト構成
- **ユニットテスト**: データモデル、サービスクラス
- **ウィジェットテスト**: UI コンポーネント
- **統合テスト**: 画面間の連携動作

## 📱 プラットフォーム対応

### Android
- **最小SDK**: API 21 (Android 5.0)
- **対象SDK**: API 34 (Android 14)
- **権限**: インターネット接続（AI分析時のみ）

### iOS
- **最小バージョン**: iOS 12.0
- **対象バージョン**: iOS 17.0
- **権限**: インターネット接続（AI分析時のみ）

### Web
- **対応ブラウザ**: Chrome 86+, Firefox 91+, Safari 14+
- **PWA対応**: オフライン機能、インストール可能

## 🔗 関連ドキュメント

- [Flutter公式ドキュメント](https://docs.flutter.dev/)
- [プロジェクト設計仕様書](../FLUTTER_DESIGN_SPEC.md)
- [基本方針](../clarity-app/CLAUDE_INSTRUCTIONS.md)
- [Phase 2 開発指示](../clarity-app/PHASE2_INSTRUCTIONS.md)

## 🚨 トラブルシューティング

### よくある問題

**1. `flutter pub get` が失敗する**
```bash
# キャッシュクリア
flutter clean
flutter pub cache repair
flutter pub get
```

**2. Android ビルドが失敗する**
```bash
# Gradle キャッシュクリア
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**3. iOS ビルドが失敗する**
```bash
# Podfile依存関係更新
cd ios
pod install --repo-update
cd ..
flutter clean
flutter pub get
```

**4. SQLiteエラーが発生する**
```bash
# データベースリセット
flutter clean
# アプリを削除して再インストール
```

### デバッグ方法
```bash
# Flutter Inspector使用
flutter run --debug

# ログ確認
flutter logs

# パフォーマンス確認
flutter run --profile
```

## 📞 サポート

- **Issue報告**: GitHubのIssueで報告してください
- **開発ガイドライン**: [CLAUDE_INSTRUCTIONS.md](../clarity-app/CLAUDE_INSTRUCTIONS.md)を参照
- **プライバシーポリシー**: 全データはローカル保存、詳細は設定画面で確認

---

**🎯 このアプリは完全にプライバシーファーストの設計です。あなたの思考データは完全にあなたの制御下にあります。**