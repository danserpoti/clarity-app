// lib/utils/app_constants.dart
// アプリケーション定数

class AppConstants {
  // アプリ情報
  static const String appName = 'Clarity';
  static const String appVersion = '1.0.0';
  static const String appDescription = '思考・感情記録アプリ - プライバシーファースト設計';

  // レスポンシブブレークポイント
  static const double tabletBreakpoint = 600.0;
  static const double desktopBreakpoint = 1200.0;

  // アニメーション設定
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  // UI設定
  static const double defaultPadding = 16.0;
  static const double tabletPadding = 24.0;
  static const double desktopPadding = 32.0;
  static const double maxContentWidth = 800.0;

  // カラーパレット
  static const List<int> seedColors = [
    0xFF2196F3, // Blue
    0xFF4CAF50, // Green  
    0xFFFF9800, // Orange
    0xFFF44336, // Red
    0xFF9C27B0, // Purple
    0xFF009688, // Teal
  ];

  // プライバシー方針
  static const List<String> privacyPrinciples = [
    '全データは端末内のみで保存',
    '外部サーバーへのデータ送信なし（AI分析時除く）',
    'ユーザーがデータを完全制御',
    'オフライン動作可能',
    '透明性のあるデータ処理',
  ];

  // 制限値
  static const int maxThoughtLength = 5000;
  static const int maxRecentThoughts = 5;
  static const int defaultDailyStatsRange = 30;
  static const int maxApiRetries = 3;
  static const Duration apiTimeout = Duration(seconds: 30);

  // アクセシビリティ
  static const double minTouchTargetSize = 48.0;
  static const double minFontSize = 14.0;
  static const double maxFontSize = 28.0;
  static const double minContrast = 4.5; // WCAG AA準拠
}

/// レスポンシブヘルパー
class ResponsiveHelper {
  static bool isTablet(double width) => width >= AppConstants.tabletBreakpoint;
  static bool isDesktop(double width) => width >= AppConstants.desktopBreakpoint;
  
  static double getPadding(double width) {
    if (isDesktop(width)) return AppConstants.desktopPadding;
    if (isTablet(width)) return AppConstants.tabletPadding;
    return AppConstants.defaultPadding;
  }
}