import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import '../models/gistag_models.dart';
import '../providers/app_providers.dart';
import '../widgets/common/gistag_button.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _ending = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final session = ref.read(workoutControllerProvider).value?.activeSession;
      if (session == null) {
        return;
      }
      setState(() => _elapsed = DateTime.now().difference(session.startedAt));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _endWorkout() async {
    setState(() => _ending = true);
    final result = await ref
        .read(workoutControllerProvider.notifier)
        .endWorkout();
    await ref.read(homeControllerProvider.notifier).refresh();
    if (!mounted) {
      return;
    }
    setState(() => _ending = false);
    if (result != null) {
      context.go('/workout-result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutControllerProvider);
    final session = workoutState.value?.activeSession;

    if (session == null) {
      return const Scaffold(body: Center(child: Text('진행 중인 운동이 없어요.')));
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '운동 진행 중',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '지금 운동 중인 상태를 유지하고 있어요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 34),
              _SessionCard(session: session),
              const SizedBox(height: 34),
              Center(
                child: Column(
                  children: [
                    Text(
                      _formatDuration(_elapsed),
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontSize: 48, color: GistagColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '진행 시간',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GistagButton(
                label: _ending ? '종료 중...' : '운동 종료',
                onPressed: _ending ? null : _endWorkout,
                backgroundColor: Colors.white,
                foregroundColor: GistagColors.primary,
              ),
              if (workoutState.hasError) ...[
                const SizedBox(height: 12),
                const Text(
                  '운동 종료에 실패했어요. 다시 시도해주세요.',
                  style: TextStyle(color: GistagColors.primary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            session.place.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            session.place.workoutType,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: GistagColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('시작 시간 ${_formatTime(session.startedAt)}'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
