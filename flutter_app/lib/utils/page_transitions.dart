// lib/utils/page_transitions.dart
// カスタムページトランジション

import 'package:flutter/material.dart';

/// スライドトランジション（右から左へ）
class SlideRightRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SlideRightRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}

/// フェードトランジション
class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  FadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}

/// スケールトランジション（拡大縮小）
class ScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  ScaleRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeInOutCubic;
            var scaleTween = Tween(begin: 0.8, end: 1.0).chain(
              CurveTween(curve: curve),
            );
            var opacityTween = Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: curve),
            );

            return ScaleTransition(
              scale: animation.drive(scaleTween),
              child: FadeTransition(
                opacity: animation.drive(opacityTween),
                child: child,
              ),
            );
          },
        );
}

/// 回転フェードトランジション
class RotationFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  RotationFadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeInOutCubic;
            var rotationTween = Tween(begin: 0.1, end: 0.0).chain(
              CurveTween(curve: curve),
            );
            var opacityTween = Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: curve),
            );
            var scaleTween = Tween(begin: 0.9, end: 1.0).chain(
              CurveTween(curve: curve),
            );

            return Transform.rotate(
              angle: animation.drive(rotationTween).value,
              child: ScaleTransition(
                scale: animation.drive(scaleTween),
                child: FadeTransition(
                  opacity: animation.drive(opacityTween),
                  child: child,
                ),
              ),
            );
          },
        );
}

/// アニメーション付きナビゲーションヘルパー
class AnimatedNavigation {
  /// スライドトランジションで遷移
  static Future<T?> pushSlide<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.of(context).push<T>(SlideRightRoute(page: page));
  }

  /// フェードトランジションで遷移  
  static Future<T?> pushFade<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.of(context).push<T>(FadeRoute(page: page));
  }

  /// スケールトランジションで遷移
  static Future<T?> pushScale<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.of(context).push<T>(ScaleRoute(page: page));
  }

  /// 回転フェードトランジションで遷移
  static Future<T?> pushRotationFade<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.of(context).push<T>(RotationFadeRoute(page: page));
  }

  /// 置き換え遷移（スライド）
  static Future<T?> replaceSlide<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.of(context).pushReplacement<T, TO>(
      SlideRightRoute(page: page),
    );
  }

  /// 置き換え遷移（フェード）
  static Future<T?> replaceFade<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.of(context).pushReplacement<T, TO>(
      FadeRoute(page: page),
    );
  }
}

/// 遅延アニメーション用ヘルパー
class DelayedAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Offset? slideFrom;
  final bool fade;
  final bool scale;

  const DelayedAnimation({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 0),
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutCubic,
    this.slideFrom,
    this.fade = true,
    this.scale = false,
  });

  @override
  State<DelayedAnimation> createState() => _DelayedAnimationState();
}

class _DelayedAnimationState extends State<DelayedAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _slideAnimation = Tween<Offset>(
      begin: widget.slideFrom ?? Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _scaleAnimation = Tween<double>(
      begin: widget.scale ? 0.8 : 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        Widget result = widget.child;

        if (widget.scale) {
          result = ScaleTransition(
            scale: _scaleAnimation,
            child: result,
          );
        }

        if (widget.slideFrom != null) {
          result = SlideTransition(
            position: _slideAnimation,
            child: result,
          );
        }

        if (widget.fade) {
          result = FadeTransition(
            opacity: _animation,
            child: result,
          );
        }

        return result;
      },
    );
  }
}