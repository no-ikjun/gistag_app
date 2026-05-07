import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../widgets/common/app_logo.dart';
import '../widgets/gistag/workout_record_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        children: [
          const AppLogo(width: 110),
          const SizedBox(height: 28),
          Text('내 기록', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '최근 운동 기록을 최신순으로 모았어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          homeState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ListError(
              message: '기록을 불러오지 못했어요.',
              onRetry: () =>
                  ref.read(homeControllerProvider.notifier).refresh(),
            ),
            data: (home) => Column(
              children: [
                for (final record in home.records)
                  WorkoutRecordCard(record: record),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListError extends StatelessWidget {
  const _ListError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(message),
        TextButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    );
  }
}
