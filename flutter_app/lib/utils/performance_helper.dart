// lib/utils/performance_helper.dart
// パフォーマンス最適化ヘルパー

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// パフォーマンス最適化されたListView
class OptimizedListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedListView({
    super.key,
    required this.children,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    // 子要素が少ない場合は通常のColumn
    if (children.length <= 10) {
      return SingleChildScrollView(
        controller: controller,
        padding: padding,
        physics: physics,
        child: Column(
          children: children,
        ),
      );
    }

    // 多い場合はListView.builder
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// メモ化されたウィジェット基底クラス
abstract class MemoizedWidget extends StatelessWidget {
  const MemoizedWidget({super.key});

  @override
  @nonVirtual
  Widget build(BuildContext context) {
    return _MemoizedWidgetWrapper(
      key: ValueKey(getMemoKey()),
      builder: () => buildMemoized(context),
    );
  }

  /// メモ化キーを生成
  Object getMemoKey();

  /// メモ化されるウィジェットをビルド
  Widget buildMemoized(BuildContext context);
}

class _MemoizedWidgetWrapper extends StatefulWidget {
  final Widget Function() builder;

  const _MemoizedWidgetWrapper({
    super.key,
    required this.builder,
  });

  @override
  State<_MemoizedWidgetWrapper> createState() => _MemoizedWidgetWrapperState();
}

class _MemoizedWidgetWrapperState extends State<_MemoizedWidgetWrapper>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  late final Widget _cachedWidget;

  @override
  void initState() {
    super.initState();
    _cachedWidget = widget.builder();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _cachedWidget;
  }
}

/// パフォーマンス監視用のウィジェット
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String? label;
  final bool enabled;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.label,
    this.enabled = kDebugMode,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  late final Stopwatch _stopwatch;
  int _buildCount = 0;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    _stopwatch.start();
    _buildCount++;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stopwatch.stop();
      if (_stopwatch.elapsedMilliseconds > 16) { // 60fps = 16.67ms
        debugPrint(
          'Performance Warning: ${widget.label ?? 'Widget'} '
          'took ${_stopwatch.elapsedMilliseconds}ms to build '
          '(build count: $_buildCount)',
        );
      }
      _stopwatch.reset();
    });

    return widget.child;
  }
}

/// 条件付きウィジェットビルダー（不要な再構築を防ぐ）
class ConditionalBuilder extends StatelessWidget {
  final bool condition;
  final Widget Function(BuildContext context) trueBuilder;
  final Widget Function(BuildContext context)? falseBuilder;

  const ConditionalBuilder({
    super.key,
    required this.condition,
    required this.trueBuilder,
    this.falseBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (condition) {
      return trueBuilder(context);
    } else if (falseBuilder != null) {
      return falseBuilder!(context);
    } else {
      return const SizedBox.shrink();
    }
  }
}

/// 遅延ローディングウィジェット
class LazyBuilder extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final Widget? placeholder;
  final Duration delay;

  const LazyBuilder({
    super.key,
    required this.builder,
    this.placeholder,
    this.delay = const Duration(milliseconds: 100),
  });

  @override
  State<LazyBuilder> createState() => _LazyBuilderState();
}

class _LazyBuilderState extends State<LazyBuilder> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isReady = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) {
      return widget.builder(context);
    } else {
      return widget.placeholder ?? const SizedBox.shrink();
    }
  }
}

/// メモリ効率的なイメージキャッシュ
class OptimizedImage extends StatelessWidget {
  final String? imageUrl;
  final String? assetPath;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedImage({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  }) : assert(imageUrl != null || assetPath != null);

  @override
  Widget build(BuildContext context) {
    if (assetPath != null) {
      return Image.asset(
        assetPath!,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: width?.toInt(),
        cacheHeight: height?.toInt(),
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? const Icon(Icons.error);
        },
      );
    }

    // ネットワーク画像の場合（実装時に追加）
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: placeholder ?? const Icon(Icons.image),
    );
  }
}

/// パフォーマンス最適化用のヘルパー関数
class PerformanceUtils {
  /// ウィジェットの再構築を最小化するためのキー生成
  static Key generateKey(List<Object?> values) {
    return ValueKey(values.map((v) => v.hashCode).join('_'));
  }

  /// リストの差分計算
  static List<T> calculateDiff<T extends Object>(
    List<T> oldList,
    List<T> newList,
  ) {
    final Set<T> oldSet = Set.from(oldList);
    final Set<T> newSet = Set.from(newList);
    
    return newSet.difference(oldSet).toList();
  }

  /// デバウンス関数
  static VoidCallback debounce(
    VoidCallback callback,
    Duration delay,
  ) {
    Timer? timer;
    
    return () {
      timer?.cancel();
      timer = Timer(delay, callback);
    };
  }

  /// スロットリング関数
  static VoidCallback throttle(
    VoidCallback callback,
    Duration interval,
  ) {
    bool isThrottled = false;
    
    return () {
      if (!isThrottled) {
        callback();
        isThrottled = true;
        Timer(interval, () {
          isThrottled = false;
        });
      }
    };
  }
}

/// スマートな再構築を行うStatefulWidget
abstract class SmartStatefulWidget extends StatefulWidget {
  const SmartStatefulWidget({super.key});

  @override
  State<SmartStatefulWidget> createState() => SmartState();

  /// 状態の比較キーを生成
  Object getStateKey();

  /// ウィジェットをビルド
  Widget buildSmart(BuildContext context);
}

class SmartState extends State<SmartStatefulWidget>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  Object? _lastStateKey;
  Widget? _cachedWidget;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final currentStateKey = widget.getStateKey();
    
    if (_lastStateKey != currentStateKey || _cachedWidget == null) {
      _cachedWidget = widget.buildSmart(context);
      _lastStateKey = currentStateKey;
    }
    
    return _cachedWidget!;
  }
}

