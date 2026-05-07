import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/common/gistag_button.dart';

class TagSuccessScreen extends ConsumerStatefulWidget {
  const TagSuccessScreen({super.key});

  @override
  ConsumerState<TagSuccessScreen> createState() => _TagSuccessScreenState();
}

class _TagSuccessScreenState extends ConsumerState<TagSuccessScreen> {
  Future<void> _startWorkout() async {
    final place = ref.read(workoutControllerProvider).value?.scannedPlace;
    if (place == null) {
      context.go('/scan');
      return;
    }

    await ref.read(workoutControllerProvider.notifier).startWorkout(place);
    if (!mounted) {
      return;
    }
    context.go('/workout');
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutControllerProvider);
    final place = workoutState.value?.scannedPlace;
    final starting = workoutState.isLoading;

    if (place == null && !starting) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('확인된 NFC 태그가 없어요.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.go('/scan'),
                    child: const Text('다시 태그하기'),
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
              const Icon(
                Icons.check_circle_rounded,
                color: GistagColors.success,
                size: 84,
              ),
              const SizedBox(height: 18),
              Text('태그 성공!', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              Text(
                '장소를 확인하고 운동을 시작하세요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: GistagColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place?.name ?? '',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      place?.description ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Chip(
                      label: Text(place?.workoutType ?? ''),
                      backgroundColor: const Color(0xFFFFEFEE),
                      labelStyle: const TextStyle(
                        color: GistagColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide.none,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GistagButton(
                label: starting ? '시작 중...' : '운동 시작',
                onPressed: starting ? null : _startWorkout,
              ),
              const SizedBox(height: 12),
              GistagButton(
                label: '다시 태그하기',
                onPressed: starting ? null : () => context.go('/scan'),
                backgroundColor: Colors.white,
                foregroundColor: GistagColors.primary,
              ),
              if (workoutState.hasError) ...[
                const SizedBox(height: 12),
                const Text(
                  '운동을 시작하지 못했어요. 다시 시도해주세요.',
                  style: TextStyle(color: GistagColors.primary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
