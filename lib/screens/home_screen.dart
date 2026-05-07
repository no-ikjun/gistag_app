import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import '../models/gistag_models.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_logo.dart';
import '../widgets/common/gistag_pressable.dart';
import '../widgets/gistag/nfc_cta_button.dart';
import '../widgets/gistag/place_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);

    return homeState.when(
      loading: () =>
          const SafeArea(child: Center(child: CircularProgressIndicator())),
      error: (error, _) => _HomeError(
        message: '홈 데이터를 불러오지 못했어요.',
        onRetry: () => ref.read(homeControllerProvider.notifier).refresh(),
      ),
      data: (home) {
        final snapshot = home.snapshot;
        final places = snapshot.recommendedPlaces;
        final recentRecord = home.records.isNotEmpty ? home.records.first : null;
        const footerHeight = 72.0;
        const nfcDockHeight = 190.0;

        return SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: RefreshIndicator(
                  onRefresh: ref.read(homeControllerProvider.notifier).refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 24).copyWith(
                      bottom: 24 + footerHeight + nfcDockHeight,
                    ),
                    children: [
                      _HomeHeader(userName: home.user.name),
                      const SizedBox(height: 14),
                      Text(
                        '오늘은 GIST 주변 루틴을 가볍게 추천해드릴게요',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF5B5F66),
                              fontSize: 15,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _InfoPillsRow(user: home.user),
                      const SizedBox(height: 26),
                      _SectionHeaderRow(
                        title: '최근 나의 기록',
                        actionText: '전체보기',
                        onActionTap: () => ref
                            .read(selectedHomeTabProvider.notifier)
                            .state = 2,
                      ),
                      const SizedBox(height: 10),
                      if (recentRecord != null)
                        _RecentRecordCard(record: recentRecord)
                      else
                        _EmptyCard(
                          title: '아직 기록이 없어요',
                          subtitle: 'NFC 태그로 운동을 시작해보세요.',
                          icon: Icons.fitness_center_rounded,
                        ),
                      const SizedBox(height: 28),
                      _SectionHeaderRow(
                        title: '내 주변 운동 장소',
                        actionText: '지도보기',
                        onActionTap: () {},
                      ),
                      const SizedBox(height: 12),
                      _PlacesCarousel(places: places),
                      const SizedBox(height: 12),
                      const _CarouselDots(activeIndex: 2, total: 4),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: footerHeight,
                child: _HomeBottomDock(
                  onTap: () => _openNfcScan(context),
                  height: nfcDockHeight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openNfcScan(BuildContext context) {
    context.go('/scan');
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppLogo(width: 112),
            const Spacer(),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded, size: 28),
              color: const Color(0xFF8B9098),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '$userName님, 운동을 시작해볼까요?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 23,
                letterSpacing: -0.4,
              ),
        ),
      ],
    );
  }
}

class _HomeBottomDock extends StatelessWidget {
  const _HomeBottomDock({
    required this.onTap,
    required this.height,
  });

  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                GistagColors.background.withValues(alpha: 0.0),
                GistagColors.background.withValues(alpha: 0.92),
                GistagColors.background,
              ],
            ),
          ),
          child: _NfcFloatingCta(onTap: onTap),
        ),
      ),
    );
  }
}

class _InfoPillsRow extends StatelessWidget {
  const _InfoPillsRow({required this.user});

  final GistagUser? user;

  @override
  Widget build(BuildContext context) {
    final level = user?.level ?? 2;
    final streak = user?.streakDays ?? 8;
    final xp = user?.xp ?? 820;

    return Row(
      children: [
        Expanded(
          child: _InfoPill(
            tag: '레벨',
            tagColor: GistagColors.primary,
            label: '레벨',
            value: 'Lv. $level',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _InfoPill(
            tag: '연속',
            tagColor: const Color(0xFFF59E0B),
            label: '연속',
            value: '$streak일',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _InfoPill(
            tag: 'XP',
            tagColor: const Color(0xFF7C3AED),
            label: 'XP',
            value: '$xp XP',
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.tag,
    required this.tagColor,
    required this.label,
    required this.value,
  });

  final String tag;
  final Color tagColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GistagColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFEE),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(
              tag,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tagColor,
                    fontSize: 9,
                    height: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF8B9098),
                        fontSize: 11,
                        height: 1.0,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF111111),
                        fontSize: 14,
                        height: 1.0,
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

class _SectionHeaderRow extends StatelessWidget {
  const _SectionHeaderRow({
    required this.title,
    required this.actionText,
    required this.onActionTap,
  });

  final String title;
  final String actionText;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  letterSpacing: -0.2,
                  color: const Color(0xFF111111),
                ),
          ),
        ),
        GistagPressable(
          onTap: onActionTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              actionText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: GistagColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentRecordCard extends StatelessWidget {
  const _RecentRecordCard({required this.record});

  final WorkoutRecord record;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 132,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: GistagColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: GistagColors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatWhen(record.startedAt, record.placeName),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF8B9098),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      record.workoutType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            color: const Color(0xFF111111),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${record.duration.inMinutes}분 · +${record.earnedXp} XP',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF5B5F66),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 0.72,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFFFE5E2),
                              color: GistagColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '72%',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF8B9098),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 5,
            decoration: const BoxDecoration(
              color: GistagColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatWhen(DateTime date, String placeName) {
    final now = DateTime.now();
    final isYesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1))
        .isAtSameMomentAs(DateTime(date.year, date.month, date.day));

    final prefix = isYesterday ? '어제' : '${date.month}.${date.day}';
    return '$prefix · $placeName';
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GistagColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE5E2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: GistagColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF111111),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF8B9098),
                        fontWeight: FontWeight.w600,
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

class _PlacesCarousel extends StatelessWidget {
  const _PlacesCarousel({required this.places});

  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return const _EmptyCard(
        title: '주변 장소를 불러오는 중이에요',
        subtitle: '잠시만 기다려주세요.',
        icon: Icons.place_rounded,
      );
    }

    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 0, right: 0),
        itemBuilder: (context, index) {
          final place = places[index];
          return PlaceCard(place: place, onTap: () {});
        },
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemCount: places.length.clamp(0, 10),
      ),
    );
  }
}

class _CarouselDots extends StatelessWidget {
  const _CarouselDots({required this.activeIndex, required this.total});

  final int activeIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 18 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? GistagColors.primary : const Color(0xFFE7E1E1),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _NfcFloatingCta extends StatelessWidget {
  const _NfcFloatingCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: NfcCtaButton(
              onTap: onTap,
              size: 102,
              showLabel: false,
              hapticsEnabled: true,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'NFC 태그 시작',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF111111),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
