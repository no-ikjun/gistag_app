import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import '../models/gistag_models.dart';
import '../providers/app_providers.dart';
import '../widgets/common/gistag_button.dart';
import '../widgets/common/gistag_fixed_bottom_actions.dart';

class WorkoutResultScreen extends ConsumerStatefulWidget {
  const WorkoutResultScreen({super.key});

  @override
  ConsumerState<WorkoutResultScreen> createState() =>
      _WorkoutResultScreenState();
}

class _WorkoutResultScreenState extends ConsumerState<WorkoutResultScreen> {
  void _goHome({int tabIndex = 0}) {
    final router = GoRouter.of(context);
    ref.read(selectedHomeTabProvider.notifier).state = tabIndex;
    if (!mounted) {
      return;
    }
    router.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(workoutControllerProvider).value?.lastResult;

    if (result == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    color: GistagColors.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '운동 결과가 없어요',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: GistagFixedBottomActions(
          children: [GistagButton(label: '홈으로 돌아가기', onPressed: _goHome)],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          children: [
            _ResultHero(result: result),
            const SizedBox(height: 18),
            _RewardCard(result: result),
            const SizedBox(height: 18),
            _PlaceResultCard(result: result),
          ],
        ),
      ),
      bottomNavigationBar: GistagFixedBottomActions(
        children: [
          GistagButton(label: '홈으로 돌아가기', onPressed: _goHome),
          const SizedBox(height: 10),
          GistagButton(
            label: '내 기록 보기',
            onPressed: () => _goHome(tabIndex: 2),
            backgroundColor: Colors.white,
            foregroundColor: GistagColors.text,
          ),
        ],
      ),
    );
  }
}

class _ResultHero extends StatelessWidget {
  const _ResultHero({required this.result});

  final WorkoutResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GistagColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: GistagColors.primarySoft.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: GistagColors.xp,
              size: 48,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            result.alreadyFinished ? '기록을 다시 불러왔어요' : '운동 완료',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            result.streakUpdated
                ? '${result.streakDays}일 연속 루틴을 이어갔어요'
                : '오늘의 운동 기록이 저장됐습니다.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GistagColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.result});

  final WorkoutResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3F2),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: GistagColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _RewardMetric(
                  label: '획득 XP',
                  value: '+${result.earnedXp}',
                  icon: Icons.bolt_rounded,
                  accent: GistagColors.xp,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RewardMetric(
                  label: '운동 시간',
                  value: '${result.duration.inMinutes.clamp(1, 999)}분',
                  icon: Icons.timer_outlined,
                  accent: GistagColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _RewardMetric(
                  label: '현재 레벨',
                  value: result.leveledUp
                      ? 'Lv.${result.level} ↑'
                      : 'Lv.${result.level}',
                  icon: Icons.trending_up_rounded,
                  accent: GistagColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RewardMetric(
                  label: '누적 XP',
                  value: '${result.totalXp ?? result.earnedXp}',
                  icon: Icons.stars_rounded,
                  accent: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardMetric extends StatelessWidget {
  const _RewardMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GistagColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 21),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceResultCard extends StatelessWidget {
  const _PlaceResultCard({required this.result});

  final WorkoutResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GistagColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: GistagColors.primarySoft.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: GistagColors.primaryDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.place.workoutType,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
