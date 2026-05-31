import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import '../models/gistag_models.dart';
import '../providers/app_providers.dart';
import '../widgets/common/gistag_button.dart';
import '../widgets/common/gistag_dialog.dart';
import '../widgets/common/gistag_fixed_bottom_actions.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  Timer? _timer;
  Timer? _peersTimer;
  Duration _elapsed = Duration.zero;
  bool _ending = false;
  bool _cancelling = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPeers();
      _peersTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => _refreshPeers(),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _peersTimer?.cancel();
    super.dispose();
  }

  void _refreshPeers() {
    if (!mounted) {
      return;
    }
    ref.read(workoutPeersControllerProvider.notifier).refresh();
  }

  Future<void> _endWorkout() async {
    final router = GoRouter.of(context);
    setState(() => _ending = true);
    final result = await ref
        .read(workoutControllerProvider.notifier)
        .endWorkout();
    if (!mounted) {
      return;
    }
    await ref.read(homeControllerProvider.notifier).refresh();
    if (!mounted) {
      return;
    }
    setState(() => _ending = false);
    if (result != null) {
      router.go('/workout-result');
    }
  }

  Future<void> _cancelWorkout() async {
    final confirmed = await showGistagConfirmDialog(
      context: context,
      title: '운동을 취소할까요?',
      message: '취소하면 이번 세션은 기록으로 저장되지 않습니다.',
      icon: Icons.delete_outline_rounded,
      confirmLabel: '기록 없이 취소',
      destructive: true,
      showCloseButton: false,
    );
    if (confirmed != true || !mounted) {
      return;
    }

    final router = GoRouter.of(context);
    setState(() => _cancelling = true);
    final cancelled = await ref
        .read(workoutControllerProvider.notifier)
        .cancelWorkout();
    if (!mounted) {
      return;
    }
    await ref.read(homeControllerProvider.notifier).refresh();
    if (!mounted) {
      return;
    }
    setState(() => _cancelling = false);
    if (cancelled) {
      router.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutControllerProvider);
    final peersState = ref.watch(workoutPeersControllerProvider);
    final flowState = workoutState.value;
    final session = flowState?.activeSession;
    final errorMessage = flowState?.errorMessage;

    if (session == null) {
      return const Scaffold(body: Center(child: Text('진행 중인 운동이 없어요.')));
    }

    final displayElapsed = DateTime.now().difference(session.startedAt);
    final elapsed = displayElapsed > _elapsed ? displayElapsed : _elapsed;
    final canFinish = elapsed.inSeconds >= 60;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
          children: [
            _WorkoutHeader(session: session),
            const SizedBox(height: 14),
            _TimerPanel(elapsed: elapsed),
            const SizedBox(height: 12),
            _SessionCard(session: session, elapsed: elapsed),
            const SizedBox(height: 12),
            _PeersSection(peersState: peersState),
            const SizedBox(height: 12),
            _MinimumDurationNotice(canFinish: canFinish),
            if (workoutState.hasError || errorMessage != null) ...[
              const SizedBox(height: 12),
              _ErrorNotice(
                message: errorMessage ?? '요청에 실패했어요. 최소 운동 시간은 60초입니다.',
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: GistagFixedBottomActions(
        children: [
          GistagButton(
            label: _ending
                ? '종료 중'
                : canFinish
                ? '운동 종료'
                : '60초 후 종료 가능',
            onPressed: _ending || _cancelling || !canFinish
                ? null
                : _endWorkout,
          ),
          const SizedBox(height: 10),
          GistagButton(
            label: _cancelling ? '취소 중' : '기록 없이 취소',
            onPressed: _ending || _cancelling ? null : _cancelWorkout,
            backgroundColor: Colors.white,
            foregroundColor: GistagColors.text,
          ),
        ],
      ),
    );
  }
}

class _WorkoutHeader extends StatelessWidget {
  const _WorkoutHeader({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusPill(label: '진행 중', icon: Icons.play_arrow_rounded),
              const SizedBox(height: 12),
              Text(
                session.place.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(height: 1.18),
              ),
              const SizedBox(height: 6),
              Text(
                '서버 기준 종료 기록으로 XP가 계산됩니다.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimerPanel extends StatelessWidget {
  const _TimerPanel({required this.elapsed});

  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GistagColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: GistagColors.primaryDark,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '진행 시간',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: GistagColors.primaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatDuration(elapsed),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: GistagColors.text,
                      fontSize: elapsed.inHours > 0 ? 34 : 40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 96,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TimerMetric(label: '분', value: elapsed.inMinutes.toString()),
                const SizedBox(height: 8),
                const _TimerMetric(label: '저장 기준', value: '60초'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerMetric extends StatelessWidget {
  const _TimerMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GistagColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: GistagColors.primaryDark,
              fontSize: 17,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.elapsed});

  final WorkoutSession session;
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GistagColors.border),
      ),
      child: Column(
        children: [
          _SessionRow(
            icon: Icons.location_on_outlined,
            label: '장소',
            value: session.place.name,
          ),
          const SizedBox(height: 14),
          _SessionRow(
            icon: Icons.schedule_rounded,
            label: '시작 시간',
            value: _formatTime(session.startedAt),
          ),
          if (session.startedByTagCode != null) ...[
            const SizedBox(height: 14),
            _SessionRow(
              icon: Icons.nfc_rounded,
              label: '태그',
              value: session.startedByTagCode!,
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: GistagColors.primarySoft.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: GistagColors.primaryDark, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GistagColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _PeersSection extends StatelessWidget {
  const _PeersSection({required this.peersState});

  final AsyncValue<WorkoutPeersSnapshot> peersState;

  @override
  Widget build(BuildContext context) {
    return peersState.when(
      loading: () => const _PeersCard(
        title: '함께 운동 중',
        message: '같은 장소의 운동 중인 사용자를 확인하고 있어요.',
        items: [],
      ),
      error: (error, _) => const _PeersCard(
        title: '함께 운동 중',
        message: '함께 운동 중인 사용자를 불러오지 못했어요.',
        items: [],
      ),
      data: (peers) {
        if (peers.place == null) {
          return const _PeersCard(
            title: '함께 운동 중',
            message: '현재 운동 중인 장소가 없어요.',
            items: [],
          );
        }
        if (peers.items.isEmpty) {
          return _PeersCard(
            title: '${peers.place!.name}에서 운동 중',
            message: '지금은 혼자 운동 중이에요.',
            items: const [],
          );
        }
        return _PeersCard(
          title: '${peers.place!.name}에서 운동 중',
          message: '${peers.items.length}명이 함께 운동 중이에요.',
          items: peers.items,
        );
      },
    );
  }
}

class _PeersCard extends StatelessWidget {
  const _PeersCard({
    required this.title,
    required this.message,
    required this.items,
  });

  final String title;
  final String message;
  final List<WorkoutPeer> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GistagColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: GistagColors.primarySoft.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: GistagColors.primaryDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final item in items) _PeerRow(peer: item),
          ],
        ],
      ),
    );
  }
}

class _PeerRow extends StatelessWidget {
  const _PeerRow({required this.peer});

  final WorkoutPeer peer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFF4E4E2),
            foregroundColor: GistagColors.text,
            child: Text(
              peer.name.characters.first,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Lv.${peer.level} · ${peer.streakDays}일 연속 · ${_formatDuration(peer.duration)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${peer.xp} XP',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GistagColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimumDurationNotice extends StatelessWidget {
  const _MinimumDurationNotice({required this.canFinish});

  final bool canFinish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: canFinish
            ? const Color(0xFFEFFAF5)
            : GistagColors.primarySoft.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canFinish
              ? GistagColors.success.withValues(alpha: 0.18)
              : GistagColors.primarySoft,
        ),
      ),
      child: Row(
        children: [
          Icon(
            canFinish ? Icons.check_circle_rounded : Icons.timer_outlined,
            color: canFinish ? GistagColors.success : GistagColors.primaryDark,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              canFinish ? '운동 종료가 가능합니다.' : '기록 저장은 60초 이상부터 가능합니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: canFinish
                    ? const Color(0xFF187653)
                    : GistagColors.primaryDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: GistagColors.primaryDark,
        fontWeight: FontWeight.w700,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: GistagColors.primarySoft.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: GistagColors.primaryDark, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GistagColors.primaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

String _formatTime(DateTime time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
