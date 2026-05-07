import 'package:flutter/material.dart';

import 'gistag_pressable.dart';

class GistagButton extends StatelessWidget {
  const GistagButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.hapticsEnabled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? backgroundColor;
  final Color foregroundColor;
  final bool hapticsEnabled;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [icon!, const SizedBox(width: 8), Text(label)],
          );

    final theme = Theme.of(context);
    final buttonStyle = theme.elevatedButtonTheme.style;

    final enabledBg =
        backgroundColor ?? buttonStyle?.backgroundColor?.resolve(const {}) ?? theme.colorScheme.primary;
    final disabledBg = buttonStyle?.backgroundColor?.resolve(
          const {WidgetState.disabled},
        ) ??
        enabledBg.withValues(alpha: 0.45);

    final enabledFg = foregroundColor;
    final disabledFg = buttonStyle?.foregroundColor?.resolve(
          const {WidgetState.disabled},
        ) ??
        enabledFg.withValues(alpha: 0.9);

    return SizedBox(
      width: double.infinity,
      child: GistagPressable(
        onTap: onPressed,
        hapticsEnabled: hapticsEnabled,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 56,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: onPressed == null ? disabledBg : enabledBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: DefaultTextStyle.merge(
            style: theme.textTheme.labelLarge?.copyWith(
              color: onPressed == null ? disabledFg : enabledFg,
            ),
            child: IconTheme.merge(
              data: IconThemeData(
                color: onPressed == null ? disabledFg : enabledFg,
                size: 18,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
