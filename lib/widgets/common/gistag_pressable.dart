import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';

class GistagPressable extends StatefulWidget {
  const GistagPressable({
    required this.child,
    super.key,
    this.onTap,
    this.hapticsEnabled = false,
    this.hapticFeedback = HapticFeedback.lightImpact,
    this.scaleDownTo = 0.97,
    this.duration = const Duration(milliseconds: 90),
    this.curve = Curves.easeOut,
    this.borderRadius,
    this.customBorder,
    this.analyticsId,
    this.analyticsComponent = 'pressable',
    this.analyticsActionType,
    this.analyticsDestination,
    this.analyticsProperties = const {},
  }) : assert(
         borderRadius == null || customBorder == null,
         'borderRadius and customBorder cannot be used together.',
       );

  final Widget child;
  final VoidCallback? onTap;

  /// 앱 설정으로 켜고 끌 수 있게 하는 플래그 (기본값 off).
  final bool hapticsEnabled;
  final VoidCallback hapticFeedback;

  final double scaleDownTo;
  final Duration duration;
  final Curve curve;

  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;

  final String? analyticsId;
  final String analyticsComponent;
  final String? analyticsActionType;
  final String? analyticsDestination;
  final Map<String, Object?> analyticsProperties;

  @override
  State<GistagPressable> createState() => _GistagPressableState();
}

class _GistagPressableState extends State<GistagPressable> {
  bool _pressed = false;
  bool _didHapticInThisPress = false;
  int _pressToken = 0;

  bool get _enabled => widget.onTap != null;

  void _setPressed(bool value) {
    if (!_enabled) return;
    if (_pressed == value) return;
    if (!mounted) return;
    setState(() => _pressed = value);
  }

  void _maybeHaptic() {
    if (!_enabled) return;
    if (!widget.hapticsEnabled) return;
    if (_didHapticInThisPress) return;
    _didHapticInThisPress = true;
    widget.hapticFeedback();
  }

  void _handleTap() {
    final onTap = widget.onTap;
    if (onTap == null) {
      return;
    }
    _trackButtonTap();
    onTap();
  }

  void _trackButtonTap() {
    final analyticsId = widget.analyticsId;
    if (analyticsId == null || analyticsId.trim().isEmpty) {
      return;
    }

    String? screen;
    String? path;
    try {
      final state = GoRouterState.of(context);
      screen = state.name;
      path = state.matchedLocation;
    } catch (_) {
      screen = null;
      path = null;
    }

    final analytics = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(analyticsServiceProvider);

    unawaited(
      analytics.trackButton(
        analyticsId,
        properties: {
          'screen': screen ?? 'unknown',
          if (path != null) 'path': path,
          'component': widget.analyticsComponent,
          if (widget.analyticsActionType != null)
            'action_type': widget.analyticsActionType,
          if (widget.analyticsDestination != null)
            'destination': widget.analyticsDestination,
          ...widget.analyticsProperties,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetScale = _enabled && _pressed ? widget.scaleDownTo : 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) {
        _didHapticInThisPress = false;
        _pressToken++;
        _setPressed(true);
        _maybeHaptic();
      },
      onTapUp: (_) {
        // 탭 액션이 상태 변경/네비게이션을 트리거하더라도
        // 눌림(scale down) 애니메이션이 체감상 끊기지 않도록
        // 아주 잠깐 눌림을 유지한 뒤 풀어준다.
        final tokenAtUp = _pressToken;
        Future<void>.delayed(widget.duration, () {
          if (!mounted) return;
          if (tokenAtUp != _pressToken) return;
          _setPressed(false);
        });
      },
      onTapCancel: () {
        _pressToken++;
        _setPressed(false);
      },
      onTap: _handleTap,
      child: AnimatedScale(
        scale: targetScale,
        duration: widget.duration,
        curve: widget.curve,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            // 탭은 GestureDetector가 처리해서,
            // 스케일 애니메이션과 액션이 충돌하지 않게 한다.
            onTap: null,
            borderRadius: widget.borderRadius,
            customBorder: widget.customBorder,
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
