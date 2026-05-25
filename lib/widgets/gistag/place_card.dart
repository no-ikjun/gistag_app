import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/gistag_models.dart';
import '../common/gistag_pressable.dart';

/// 홈 캐러셀 등 가로 스크롤용 — 높이 제한 안에서 깨지지 않도록 가로형 카드.
class PlaceCard extends StatelessWidget {
  const PlaceCard({
    required this.place,
    super.key,
    this.onTap,
    this.width,
    this.showNfcChip = true,
  });

  final Place place;
  final VoidCallback? onTap;

  /// null이면 화면 너비 기준으로 잡음 (옆 카드 살짝 보이게).
  final double? width;

  final bool showNfcChip;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final cardW = width ?? (screenW - 52).clamp(240.0, 340.0);

    return GistagPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: cardW,
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: GistagColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Thumb(workoutType: place.workoutType),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${place.workoutType} · ${place.distance}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF8B9098),
                          fontSize: 11,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111111),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF5B5F66),
                          fontSize: 12,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (showNfcChip) ...[
                    const SizedBox(height: 4),
                    _NfcChip(
                      label: 'NFC 있음',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.workoutType});

  final String workoutType;

  @override
  Widget build(BuildContext context) {
    final isRun =
        workoutType.contains('러닝') || workoutType.toLowerCase().contains('run');
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isRun
            ? const Color(0xFFFFE5E2)
            : const Color(0xFFF5F1F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isRun ? Icons.directions_run_rounded : Icons.fitness_center_rounded,
        size: 32,
        color: isRun ? GistagColors.primary : const Color(0xFF8B9098),
      ),
    );
  }
}

class _NfcChip extends StatelessWidget {
  const _NfcChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: GistagColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
