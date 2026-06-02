import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_theme.dart';
import '../models/gistag_models.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_logo.dart';
import '../widgets/common/gistag_pressable.dart';
import '../widgets/gistag/workout_record_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: ref.read(homeControllerProvider.notifier).refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
          children: [
            const AppLogo(width: 104),
            const SizedBox(height: 24),
            Text('내 기록', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '최근 운동의 시간, 장소, 획득 XP를 확인할 수 있어요.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            homeState.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _ListError(
                message: '기록을 불러오지 못했어요.',
                onRetry: () =>
                    ref.read(homeControllerProvider.notifier).refresh(),
              ),
              data: (home) => _HistoryContent(records: home.records),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({required this.records});

  final List<WorkoutRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _EmptyHistory();
    }

    final totalMinutes = records.fold<int>(
      0,
      (sum, record) => sum + record.duration.inMinutes.clamp(1, 999),
    );
    final totalXp = records.fold<int>(
      0,
      (sum, record) => sum + record.earnedXp,
    );
    final averageMinutes = (totalMinutes / records.length).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HistorySummary(
          totalCount: records.length,
          totalMinutes: totalMinutes,
          totalXp: totalXp,
          averageMinutes: averageMinutes,
        ),
        const SizedBox(height: 24),
        Text(
          '최근 기록',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 12),
        for (final record in records) WorkoutRecordCard(record: record),
      ],
    );
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({
    required this.totalCount,
    required this.totalMinutes,
    required this.totalXp,
    required this.averageMinutes,
  });

  final int totalCount;
  final int totalMinutes;
  final int totalXp;
  final int averageMinutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: GistagColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: '최근 운동',
                  value: '$totalCount회',
                  icon: Icons.history_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  label: '총 시간',
                  value: '$totalMinutes분',
                  icon: Icons.timer_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: '평균 시간',
                  value: '$averageMinutes분',
                  icon: Icons.insights_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  label: '획득 XP',
                  value: '+$totalXp',
                  icon: Icons.bolt_rounded,
                  accent: GistagColors.xp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = GistagColors.primary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GistagColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 34, 22, 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: GistagColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: GistagColors.primarySoft.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: GistagColors.primaryDark,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '아직 저장된 기록이 없어요',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'NFC 태그로 운동을 시작하고 60초 이상 운동하면 이곳에 기록됩니다.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GistagColors.border),
      ),
      child: Column(
        children: [
          Text(message, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GistagPressable(
            onTap: onRetry,
            borderRadius: BorderRadius.circular(8),
            analyticsId: 'history_retry',
            analyticsComponent: 'text_button',
            analyticsActionType: 'retry',
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text('다시 시도'),
            ),
          ),
        ],
      ),
    );
  }
}
