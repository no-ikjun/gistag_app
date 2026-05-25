import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import '../models/gistag_models.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_logo.dart';
import '../widgets/common/gistag_header.dart';
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
        final recentRecord = home.records.isNotEmpty
            ? home.records.first
            : null;
        const nfcDockHeight = 96.0;

        return SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: RefreshIndicator(
                  onRefresh: ref.read(homeControllerProvider.notifier).refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      10,
                      24,
                      24,
                    ).copyWith(bottom: 16 + nfcDockHeight),
                    children: [
                      _HomeHeader(
                        userName: home.user.name,
                        onSettingsTap: () => context.push('/settings'),
                      ),
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
                        onActionTap: () =>
                            ref.read(selectedHomeTabProvider.notifier).state =
                                2,
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
                      _CarouselDots(
                        activeIndex: 0,
                        total: places.isEmpty ? 1 : places.length,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
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
  const _HomeHeader({required this.userName, required this.onSettingsTap});

  final String userName;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GistagHeader(
          center: const AppLogo(width: 104),
          trailing: Semantics(
            button: true,
            label: '설정',
            child: GistagPressable(
              onTap: onSettingsTap,
              borderRadius: BorderRadius.circular(10),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.settings_rounded,
                  color: GistagColors.text,
                  size: 23,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$userName님, 운동을 시작해볼까요?',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontSize: 23, letterSpacing: -0.4),
        ),
      ],
    );
  }
}

class _HomeBottomDock extends StatelessWidget {
  const _HomeBottomDock({required this.onTap, required this.height});

  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.35, 1.0],
                  colors: [
                    GistagColors.background.withValues(alpha: 0.0),
                    GistagColors.background.withValues(alpha: 0.65),
                    GistagColors.background,
                  ],
                ),
              ),
            ),
          ),
          _NfcFloatingCta(onTap: onTap),
        ],
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
    return Container(
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
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: GistagColors.primary),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE5E2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: GistagColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatWhen(record.startedAt, record.placeName),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: const Color(0xFF8B9098),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            record.workoutType,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: 17,
                                  height: 1.25,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111111),
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${record.duration.inMinutes}분 · +${record.earnedXp} XP',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
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
                              const SizedBox(width: 10),
                              Text(
                                '72%',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
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
            ),
          ],
        ),
      ),
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
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.zero,
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

  /// 탭바 바로 위에 붙지 않게 여유 (피그마 홈 인디케이터 구간과 비슷한 간격).
  static const double _bottomInset = 10;

  /// 지름 — 너무 크면 본문을 덮어 보이고, 너무 작으면 탭 대비 비율이 어색함.
  static const double _buttonSize = 68;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: GistagColors.primary.withValues(alpha: 0.28),
              blurRadius: 14,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: NfcCtaButton(
          onTap: onTap,
          size: _buttonSize,
          showLabel: false,
          hapticsEnabled: true,
        ),
      ),
    );
  }
}
