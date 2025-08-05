// lib/utils/accessibility_helper.dart
// アクセシビリティ支援機能

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// アクセシビリティ設定
class AccessibilitySettings {
  static const double minTouchTargetSize = 48.0;
  static const double minFontSize = 14.0;
  static const double maxFontSize = 28.0;
  static const double contrastRatio = 4.5; // WCAG AA準拠

  /// 推奨フォントサイズを取得
  static double getRecommendedFontSize(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textScaleFactor = mediaQuery.textScaler.scale(1.0);
    
    double fontSize = 16.0 * textScaleFactor;
    return fontSize.clamp(minFontSize, maxFontSize);
  }

  /// タッチターゲットサイズを確保
  static Size ensureTouchTargetSize(Size originalSize) {
    return Size(
      originalSize.width < minTouchTargetSize 
          ? minTouchTargetSize 
          : originalSize.width,
      originalSize.height < minTouchTargetSize 
          ? minTouchTargetSize 
          : originalSize.height,
    );
  }
}

/// アクセシブルなボタンウィジェット
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? tooltip;
  final bool excludeSemantics;

  const AccessibleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.semanticLabel,
    this.tooltip,
    this.excludeSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = ElevatedButton(
      onPressed: onPressed,
      child: child,
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    if (!excludeSemantics) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        enabled: onPressed != null,
        excludeSemantics: excludeSemantics,
        child: button,
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AccessibilitySettings.minTouchTargetSize,
        minHeight: AccessibilitySettings.minTouchTargetSize,
      ),
      child: button,
    );
  }
}

/// アクセシブルなテキストフィールド
class AccessibleTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final int? maxLines;
  final String? semanticLabel;

  const AccessibleTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? labelText,
      textField: true,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: AccessibilitySettings.getRecommendedFontSize(context),
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          helperText: helperText,
          errorText: errorText,
        ),
      ),
    );
  }
}

/// アクセシブルなカード
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? tooltip;
  final bool isSelected;

  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.tooltip,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      child: InkWell(
        onTap: onTap,
        child: child,
      ),
    );

    if (tooltip != null) {
      card = Tooltip(
        message: tooltip!,
        child: card,
      );
    }

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      selected: isSelected,
      enabled: onTap != null,
      child: card,
    );
  }
}

/// アクセシブルなリストタイル
class AccessibleListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool isThreeLine;

  const AccessibleListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    this.isThreeLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      enabled: onTap != null,
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        isThreeLine: isThreeLine,
        minVerticalPadding: 12.0, // タッチターゲットサイズ確保
      ),
    );
  }
}

/// アクセシブルなアイコンボタン
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? tooltip;
  final Color? color;
  final double? iconSize;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.semanticLabel,
    this.tooltip,
    this.color,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? tooltip,
      button: true,
      enabled: onPressed != null,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: tooltip,
        color: color,
        iconSize: iconSize ?? 24.0,
        constraints: const BoxConstraints(
          minWidth: AccessibilitySettings.minTouchTargetSize,
          minHeight: AccessibilitySettings.minTouchTargetSize,
        ),
      ),
    );
  }
}

/// フォーカス管理ヘルパー
class FocusHelper {
  /// 次のフォーカス可能な要素に移動
  static void focusNext(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  /// 前のフォーカス可能な要素に移動
  static void focusPrevious(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  /// フォーカスを解除
  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// 特定のフォーカスノードにフォーカス
  static void requestFocus(BuildContext context, FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
  }
}

/// アクセシビリティテスト用ヘルパー
class AccessibilityTester {
  /// コントラスト比をテスト
  static bool testContrastRatio(Color foreground, Color background) {
    final fgLuminance = foreground.computeLuminance();
    final bgLuminance = background.computeLuminance();
    
    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;
    
    final contrastRatio = (lighter + 0.05) / (darker + 0.05);
    return contrastRatio >= AccessibilitySettings.contrastRatio;
  }

  /// タッチターゲットサイズをテスト
  static bool testTouchTargetSize(Size size) {
    return size.width >= AccessibilitySettings.minTouchTargetSize &&
           size.height >= AccessibilitySettings.minTouchTargetSize;
  }

  /// フォントサイズをテスト
  static bool testFontSize(double fontSize) {
    return fontSize >= AccessibilitySettings.minFontSize;
  }
}

/// セマンティクス情報を強化するウィジェット
class EnhancedSemantics extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? value;
  final String? hint;
  final bool? enabled;
  final bool? checked;
  final bool? selected;
  final bool? button;
  final bool? link;
  final bool? header;
  final bool? textField;
  final bool? focusable;
  final bool? focused;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const EnhancedSemantics({
    super.key,
    required this.child,
    this.label,
    this.value,
    this.hint,
    this.enabled,
    this.checked,
    this.selected,
    this.button,
    this.link,
    this.header,
    this.textField,
    this.focusable,
    this.focused,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: value,
      hint: hint,
      enabled: enabled,
      checked: checked,
      selected: selected,
      button: button,
      link: link,
      header: header,
      textField: textField,
      focusable: focusable,
      focused: focused,
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
    );
  }
}

/// 読み上げを一時停止/再開するヘルパー
class ScreenReaderHelper {
  /// アナウンスメント（重要な情報を読み上げ）
  static void announce(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// トースト形式のアナウンスメント
  static void announceToast(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// 緊急アナウンスメント
  static void announceUrgent(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }
}