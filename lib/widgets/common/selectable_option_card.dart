import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import 'gistag_pressable.dart';

class SelectableOptionCard extends StatelessWidget {
  const SelectableOptionCard({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.subtitle,
    this.hapticsEnabled = false,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool hapticsEnabled;

  @override
  Widget build(BuildContext context) {
    return GistagPressable(
      onTap: onTap,
      hapticsEnabled: hapticsEnabled,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFFBFB) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? GistagColors.primary : const Color(0xFFF4E4E2),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected
                    ? GistagColors.primary
                    : const Color(0xFFFFEFEE),
                shape: BoxShape.circle,
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 15)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
