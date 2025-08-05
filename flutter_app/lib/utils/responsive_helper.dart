// lib/utils/responsive_helper.dart
// レスポンシブデザインヘルパー

import 'package:flutter/material.dart';

/// レスポンシブブレークポイント
class ResponsiveBreakpoints {
  static const double mobile = 0;
  static const double tablet = 600;
  static const double desktop = 1200;
  static const double largeDesktop = 1600;
}

/// レスポンシブヘルパークラス
class ResponsiveHelper {
  /// 現在の画面サイズタイプを取得
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= ResponsiveBreakpoints.largeDesktop) {
      return ScreenType.largeDesktop;
    } else if (width >= ResponsiveBreakpoints.desktop) {
      return ScreenType.desktop;
    } else if (width >= ResponsiveBreakpoints.tablet) {
      return ScreenType.tablet;
    } else {
      return ScreenType.mobile;
    }
  }

  /// モバイルかどうか
  static bool isMobile(BuildContext context) {
    return getScreenType(context) == ScreenType.mobile;
  }

  /// タブレットかどうか
  static bool isTablet(BuildContext context) {
    return getScreenType(context) == ScreenType.tablet;
  }

  /// デスクトップかどうか
  static bool isDesktop(BuildContext context) {
    final screenType = getScreenType(context);
    return screenType == ScreenType.desktop || screenType == ScreenType.largeDesktop;
  }

  /// タブレット以上かどうか
  static bool isTabletOrLarger(BuildContext context) {
    final screenType = getScreenType(context);
    return screenType != ScreenType.mobile;
  }

  /// 画面サイズに応じたパディングを取得
  static double getPadding(BuildContext context) {
    switch (getScreenType(context)) {
      case ScreenType.mobile:
        return 16.0;
      case ScreenType.tablet:
        return 24.0;
      case ScreenType.desktop:
        return 32.0;
      case ScreenType.largeDesktop:
        return 40.0;
    }
  }

  /// 画面サイズに応じたマージンを取得
  static double getMargin(BuildContext context) {
    switch (getScreenType(context)) {
      case ScreenType.mobile:
        return 8.0;
      case ScreenType.tablet:
        return 12.0;
      case ScreenType.desktop:
        return 16.0;
      case ScreenType.largeDesktop:
        return 20.0;
    }
  }

  /// 画面サイズに応じたカラム数を取得
  static int getColumns(BuildContext context) {
    switch (getScreenType(context)) {
      case ScreenType.mobile:
        return 1;
      case ScreenType.tablet:
        return 2;
      case ScreenType.desktop:
        return 3;
      case ScreenType.largeDesktop:
        return 4;
    }
  }

  /// グリッドのクロス軸カウントを取得
  static int getCrossAxisCount(BuildContext context, {int? maxColumns}) {
    final columns = getColumns(context);
    return maxColumns != null ? columns.clamp(1, maxColumns) : columns;
  }

  /// 最大コンテンツ幅を取得
  static double getMaxContentWidth(BuildContext context) {
    switch (getScreenType(context)) {
      case ScreenType.mobile:
        return double.infinity;
      case ScreenType.tablet:
        return 800.0;
      case ScreenType.desktop:
        return 1000.0;
      case ScreenType.largeDesktop:
        return 1200.0;
    }
  }

  /// 画面の向きを考慮した値を取得
  static T getValueForOrientation<T>(
    BuildContext context, {
    required T portrait,
    required T landscape,
  }) {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.portrait ? portrait : landscape;
  }

  /// 画面サイズに応じた値を取得
  static T getValueForScreenType<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    switch (getScreenType(context)) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }
}

/// 画面サイズタイプ
enum ScreenType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// レスポンシブウィジェット
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.getValueForScreenType<Widget>(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }
}

/// レスポンシブコンテナ
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;
  final bool centerContent;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? EdgeInsets.all(ResponsiveHelper.getPadding(context));
    final responsiveMaxWidth = maxWidth ?? ResponsiveHelper.getMaxContentWidth(context);

    return Container(
      width: double.infinity,
      padding: responsivePadding,
      child: centerContent
          ? Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: responsiveMaxWidth),
                child: child,
              ),
            )
          : ConstrainedBox(
              constraints: BoxConstraints(maxWidth: responsiveMaxWidth),
              child: child,
            ),
    );
  }
}

/// レスポンシブグリッド
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double? spacing;
  final double? runSpacing;
  final int? maxColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing,
    this.runSpacing,
    this.maxColumns,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.getCrossAxisCount(context, maxColumns: maxColumns);
    final defaultSpacing = ResponsiveHelper.getMargin(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing ?? defaultSpacing,
        mainAxisSpacing: runSpacing ?? defaultSpacing,
        childAspectRatio: 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}