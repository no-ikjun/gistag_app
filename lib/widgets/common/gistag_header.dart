import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'gistag_pressable.dart';

/// Figma `Header` 컴포넌트 기준 공통 상단 바.
///
/// - 뒤로가기: [automaticallyImplyBack]이 true이고 스택에서 pop 가능할 때만 [icon_arrow] 표시.
/// - 우측: [trailing]이 있으면 그것을 쓰고, 없으면 [showBellAction]일 때 [icon_bell] 표시.
/// - 가로 inset은 부모(SafeArea, ListView padding 등)에 맡기고, 기본값은 상·하만 둡니다.
class GistagHeader extends StatelessWidget {
  const GistagHeader({
    super.key,
    this.center,
    this.centerTitle = false,
    this.showBellAction = true,
    this.onBellTap,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(0, 13, 0, 13),
    this.automaticallyImplyBack = true,
    this.onBackTap,
  });

  /// Figma 프레임 높이 72에 맞춤.
  static const double barHeight = 72;

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

  /// 기본은 상·하 13 (Figma top offset). 좌우는 부모 패딩에 맞추려면 0 유지.
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
    final showBack = automaticallyImplyBack && canNavigateBack(context);

    return SizedBox(
      height: barHeight,
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showBack) ...[
              _HeaderIconButton(
                asset: _assetBack,
                onTap: onBackTap ?? () => navigateBack(context),
                semanticLabel: '뒤로',
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Align(
                alignment: centerTitle
                    ? Alignment.center
                    : Alignment.centerLeft,
                child: center ?? const SizedBox.shrink(),
              ),
            ),
            if (trailing != null)
              trailing!
            else if (showBellAction)
              _HeaderIconButton(
                asset: _assetBell,
                onTap: onBellTap,
                semanticLabel: '알림',
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.asset,
    this.onTap,
    this.semanticLabel,
  });

  final String asset;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GistagPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(child: SvgPicture.asset(asset, width: 35, height: 35)),
        ),
      ),
    );
  }
}
