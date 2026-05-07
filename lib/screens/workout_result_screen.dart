import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/common/gistag_button.dart';

class WorkoutResultScreen extends ConsumerWidget {
  const WorkoutResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  const Text('운동 결과가 없어요.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('홈으로 돌아가기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEFEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: GistagColors.xp,
                  size: 82,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '운동 완료!',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                '${result.streakDays}일 연속 운동 중이에요',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: GistagColors.primary),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: GistagColors.border),
                ),
                child: Column(
                  children: [
                    _ResultMetric(
                      label: '획득 XP',
                      value: '+${result.earnedXp} XP',
                    ),
                    const Divider(height: 28),
                    _ResultMetric(
                      label: '현재 레벨',
                      value: result.leveledUp
                          ? 'Lv.${result.level} 레벨업!'
                          : 'Lv.${result.level}',
                    ),
                    const Divider(height: 28),
                    _ResultMetric(
                      label: '운동 시간',
                      value: '${result.duration.inMinutes.clamp(1, 999)}분',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GistagButton(
                label: '홈으로 돌아가기',
                onPressed: () {
                  ref.read(selectedHomeTabProvider.notifier).state = 0;
                  context.go('/home');
                },
              ),
              const SizedBox(height: 12),
              GistagButton(
                label: '내 기록 보기',
                onPressed: () {
                  ref.read(selectedHomeTabProvider.notifier).state = 2;
                  context.go('/home');
                },
                backgroundColor: Colors.white,
                foregroundColor: GistagColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}
