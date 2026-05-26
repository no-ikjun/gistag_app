import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'gistag_pressable.dart';

/// 앱 전반에서 쓰는 조밀한 공통 상단 바.
///
/// - 뒤로가기: [automaticallyImplyBack]이 true이고 스택에서 pop 가능할 때만 [icon_arrow] 표시.
/// - 우측: [trailing]이 있으면 그것을 쓰고, 없으면 [showBellAction]일 때 [icon_bell] 표시.
/// - 가로 inset은 부모(SafeArea, ListView padding 등)에 맡깁니다.
class GistagHeader extends StatelessWidget {
  const GistagHeader({
    super.key,
    this.center,
    this.centerTitle = false,
    this.showBellAction = true,
    this.onBellTap,
    this.trailing,
    this.padding = EdgeInsets.zero,
    this.automaticallyImplyBack = true,
    this.onBackTap,
  });

  static const double barHeight = 48;

  static const String _assetBack = 'assets/images/icon_arrow.svg';
  static const String _assetBell = 'assets/images/icon_bell.svg';

  /// 중앙 영역(로고, 타이틀 등). null이면 빈 영역.
  final Widget? center;

  /// true면 [center]를 가로 중앙 정렬(스택 화면 타이틀 등).
  final bool centerTitle;

  final bool showBellAction;
  final VoidCallback? onBellTap;

  /// 있으면 우측 알림 대신 표시.
  final Widget? trailing;

  final EdgeInsetsGeometry padding;

  final bool automaticallyImplyBack;
  final VoidCallback? onBackTap;

  static bool canNavigateBack(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) return true;
    return Navigator.maybeOf(context)?.canPop() ?? false;
  }

  static void navigateBack(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
      return;
    }
    Navigator.maybeOf(context)?.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final showBack =
        automaticallyImplyBack &&
        (onBackTap != null || canNavigateBack(context));
    final trailingAction =
        trailing ??
        (showBellAction
            ? _HeaderIconButton(
                asset: _assetBell,
                iconSize: 24,
                onTap: onBellTap,
                semanticLabel: '알림',
              )
            : null);

    return SizedBox(
      height: barHeight,
      child: Padding(
        padding: padding,
        child: centerTitle
            ? Stack(
                alignment: Alignment.center,
                children: [
                  if (showBack)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _HeaderIconButton(
                        asset: _assetBack,
                        iconSize: 22,
                        onTap: onBackTap ?? () => navigateBack(context),
                        semanticLabel: '뒤로',
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: showBack || trailingAction != null
                          ? _HeaderIconButton.buttonSize + 8
                          : 0,
                    ),
                    child: Center(child: center ?? const SizedBox.shrink()),
                  ),
                  if (trailingAction != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: trailingAction,
                    ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showBack) ...[
                    _HeaderIconButton(
                      asset: _assetBack,
                      iconSize: 22,
                      onTap: onBackTap ?? () => navigateBack(context),
                      semanticLabel: '뒤로',
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: center ?? const SizedBox.shrink(),
                    ),
                  ),
                  if (trailingAction != null) trailingAction,
                ],
              ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.asset,
    required this.iconSize,
    this.onTap,
    this.semanticLabel,
  });

  static const double buttonSize = 40;

  final String asset;
  final double iconSize;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GistagPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Center(
            child: SvgPicture.asset(asset, width: iconSize, height: iconSize),
          ),
        ),
      ),
    );
  }
}
