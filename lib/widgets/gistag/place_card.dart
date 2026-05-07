import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/gistag_models.dart';
import '../common/gistag_pressable.dart';

class PlaceCard extends StatelessWidget {
  const PlaceCard({required this.place, super.key, this.onTap});

  final Place place;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GistagPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: GistagColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEFEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.place_rounded,
                    color: GistagColors.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  place.distance,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(place.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              place.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Text(
              place.workoutType,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: GistagColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
