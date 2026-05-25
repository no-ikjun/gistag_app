import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import 'gistag_pressable.dart';

enum GistagDialogActionStyle { primary, secondary, destructive }

class GistagDialogAction<T> {
  const GistagDialogAction({
    required this.label,
    this.result,
    this.onPressed,
    this.style = GistagDialogActionStyle.primary,
  });

  final String label;
  final T? result;
  final VoidCallback? onPressed;
  final GistagDialogActionStyle style;
}

Future<T?> showGistagDialog<T>({
  required BuildContext context,
  required String title,
  String? message,
  Widget? content,
  IconData? icon,
  List<GistagDialogAction<T>> actions = const [],
  bool showCloseButton = true,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder: (context) {
      return GistagDialog<T>(
        title: title,
        message: message,
        content: content,
        icon: icon,
        actions: actions,
        showCloseButton: showCloseButton,
      );
    },
  );
}

Future<bool?> showGistagConfirmDialog({
  required BuildContext context,
  required String title,
  String? message,
  Widget? content,
  IconData? icon,
  String cancelLabel = '취소',
  String confirmLabel = '확인',
  bool destructive = false,
  bool showCloseButton = true,
  bool barrierDismissible = true,
}) {
  return showGistagDialog<bool>(
    context: context,
    title: title,
    message: message,
    content: content,
    icon: icon,
    showCloseButton: showCloseButton,
    barrierDismissible: barrierDismissible,
    actions: [
      GistagDialogAction<bool>(
        label: cancelLabel,
        result: false,
        style: GistagDialogActionStyle.secondary,
      ),
      GistagDialogAction<bool>(
        label: confirmLabel,
        result: true,
        style: destructive
            ? GistagDialogActionStyle.destructive
            : GistagDialogActionStyle.primary,
      ),
    ],
  );
}

class GistagDialog<T> extends StatelessWidget {
  const GistagDialog({
    required this.title,
    super.key,
    this.message,
    this.content,
    this.icon,
    this.actions = const [],
    this.showCloseButton = true,
  });

  final String title;
  final String? message;
  final Widget? content;
  final IconData? icon;
  final List<GistagDialogAction<T>> actions;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GistagColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: GistagColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showCloseButton)
                Align(
                  alignment: Alignment.centerRight,
                  child: _DialogCloseButton<T>(),
                ),
              if (icon != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: _DialogIcon(icon: icon!),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5F6368),
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (content != null) ...[const SizedBox(height: 16), content!],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 22),
                _DialogActions<T>(actions: actions),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogIcon extends StatelessWidget {
  const _DialogIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: GistagColors.primarySoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: GistagColors.primaryDark, size: 24),
    );
  }
}

class _DialogCloseButton<T> extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GistagPressable(
      onTap: () => Navigator.of(context).pop<T>(),
      borderRadius: BorderRadius.circular(10),
      child: const SizedBox(
        width: 34,
        height: 34,
        child: Icon(Icons.close_rounded, size: 22, color: GistagColors.text),
      ),
    );
  }
}

class _DialogActions<T> extends StatelessWidget {
  const _DialogActions({required this.actions});

  final List<GistagDialogAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.length == 1) {
      return _DialogActionButton<T>(action: actions.single);
    }

    if (actions.length == 2) {
      return Row(
        children: [
          Expanded(child: _DialogActionButton<T>(action: actions.first)),
          const SizedBox(width: 10),
          Expanded(child: _DialogActionButton<T>(action: actions.last)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          _DialogActionButton<T>(action: actions[index]),
        ],
      ],
    );
  }
}

class _DialogActionButton<T> extends StatelessWidget {
  const _DialogActionButton({required this.action});

  final GistagDialogAction<T> action;

  @override
  Widget build(BuildContext context) {
    final colors = _DialogActionColors.fromStyle(action.style);

    return GistagPressable(
      onTap: () {
        action.onPressed?.call();
        Navigator.of(context).pop<T>(action.result);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 50,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          action.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colors.foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DialogActionColors {
  const _DialogActionColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;

  factory _DialogActionColors.fromStyle(GistagDialogActionStyle style) {
    return switch (style) {
      GistagDialogActionStyle.primary => const _DialogActionColors(
        background: GistagColors.primary,
        foreground: Colors.white,
        border: GistagColors.primary,
      ),
      GistagDialogActionStyle.secondary => const _DialogActionColors(
        background: Color(0xFFF7F3F2),
        foreground: GistagColors.text,
        border: GistagColors.border,
      ),
      GistagDialogActionStyle.destructive => const _DialogActionColors(
        background: GistagColors.primaryDark,
        foreground: Colors.white,
        border: GistagColors.primaryDark,
      ),
    };
  }
}
