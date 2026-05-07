import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/gistag_models.dart';

class RankingRow extends StatelessWidget {
  const RankingRow({required this.user, super.key});

  final RankingUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: user.isMe ? const Color(0xFFFFEFEE) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: user.isMe ? GistagColors.primary : GistagColors.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: user.isMe
                ? GistagColors.primary
                : const Color(0xFFF4E4E2),
            foregroundColor: user.isMe ? Colors.white : GistagColors.text,
            child: Text('${user.rank}'),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.isMe ? '${user.name} (나)' : user.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Lv.${user.level} · ${user.streakDays}일 연속',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            '${user.xp} XP',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: GistagColors.primary),
          ),
        ],
      ),
    );
  }
}
