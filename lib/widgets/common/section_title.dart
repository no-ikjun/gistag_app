import 'package:flutter/material.dart';
import 'gistag_pressable.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    required this.title,
    super.key,
    this.actionLabel,
    this.onActionTap,
    this.analyticsId,
    this.analyticsDestination,
    this.analyticsProperties = const {},
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final String? analyticsId;
  final String? analyticsDestination;
  final Map<String, Object?> analyticsProperties;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (actionLabel != null)
          GistagPressable(
            onTap: onActionTap,
            borderRadius: BorderRadius.circular(8),
            analyticsId: analyticsId,
            analyticsComponent: 'text_button',
            analyticsActionType: 'navigate',
            analyticsDestination: analyticsDestination,
            analyticsProperties: analyticsProperties,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(actionLabel!),
            ),
          ),
      ],
    );
  }
}
