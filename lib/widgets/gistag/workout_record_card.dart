import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/gistag_models.dart';

class WorkoutRecordCard extends StatelessWidget {
  const WorkoutRecordCard({required this.record, super.key});

  final WorkoutRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GistagColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFEFEE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: GistagColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.placeName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  '${_formatDate(record.startedAt)} · ${record.workoutType} · ${record.duration.inMinutes}분',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            '+${record.earnedXp} XP',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: GistagColors.xp),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}.${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
