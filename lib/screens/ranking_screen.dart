import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_theme.dart';
import '../models/gistag_models.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_logo.dart';
import '../widgets/common/gistag_pressable.dart';
import '../widgets/gistag/ranking_row.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rankingControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rankingState = ref.watch(rankingControllerProvider);

    return SafeArea(
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final metrics = notification.metrics;
          if (metrics.extentAfter < 260) {
            ref.read(rankingControllerProvider.notifier).loadMore();
          }
          return false;
        },
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          children: [
            const AppLogo(width: 110),
            const SizedBox(height: 28),
            Text('랭킹', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '전체 누적 XP 기준으로 순위를 확인할 수 있어요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 22),
            rankingState.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _ListError(
                message: '랭킹을 불러오지 못했어요.',
                onRetry: () => ref
                    .read(rankingControllerProvider.notifier)
                    .load(force: true),
              ),
              data: (ranking) => _RankingContent(ranking: ranking),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingContent extends StatelessWidget {
  const _RankingContent({required this.ranking});

  final RankingPage ranking;

  @override
  Widget build(BuildContext context) {
    final me = ranking.me;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (me != null) ...[
          _MeRankingCard(user: me),
          const SizedBox(height: 18),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                '전체 랭킹',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
            ),
            Text(
              '총 ${ranking.total}명',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: GistagColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (ranking.items.isEmpty)
          const _EmptyRanking()
        else
          for (final user in ranking.items) RankingRow(user: user),
        if (ranking.hasMore) ...[
          const SizedBox(height: 12),
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ],
    );
  }
}

class _MeRankingCard extends StatelessWidget {
  const _MeRankingCard({required this.user});

  final RankingUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFEE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GistagColors.primary),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GistagColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '#${user.rank}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.name}님의 순위',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lv.${user.level} · ${user.streakDays}일 연속',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${user.xp} XP',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: GistagColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRanking extends StatelessWidget {
  const _EmptyRanking();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GistagColors.border),
      ),
      child: Text(
        '아직 랭킹에 표시할 기록이 없어요.',
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
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
        GistagPressable(
          onTap: onRetry,
          borderRadius: BorderRadius.circular(8),
          analyticsId: 'ranking_retry',
          analyticsComponent: 'text_button',
          analyticsActionType: 'retry',
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text('다시 시도'),
          ),
        ),
      ],
    );
  }
}
