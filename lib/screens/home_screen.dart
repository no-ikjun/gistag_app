import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import '../models/gistag_models.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_logo.dart';
import '../widgets/common/gistag_header.dart';
import '../widgets/common/gistag_pressable.dart';
import '../widgets/gistag/nearby_places_map_panel.dart';

const _fallbackNearbyPlaces = [
  Place(
    id: 'gist-gym',
    name: '제2학생회관 헬스장',
    description: '캠퍼스 내 헬스장',
    workoutType: '헬스',
    distance: '320m',
    latitude: 35.2131,
    longitude: 126.8378,
    distanceText: '중앙도서관에서 도보 약 5분',
    estimatedDurationMinutes: 60,
    distanceKm: 0,
  ),
  Place(
    id: 'gist-track',
    name: 'GIST 대학 기숙사 A동 러닝 코스',
    description: '기숙사 주변 러닝 코스',
    workoutType: '러닝',
    distance: '120m',
    latitude: 35.214,
    longitude: 126.8385,
    distanceText: '기숙사 A동 인근',
    estimatedDurationMinutes: 30,
    distanceKm: 0.12,
  ),
  Place(
    id: 'gist-court',
    name: '체육관 코트',
    description: '실내 운동과 스트레칭을 시작하기 좋은 공간',
    workoutType: '운동',
    distance: '780m',
    latitude: 35.2118,
    longitude: 126.8369,
    distanceText: '학생회관 옆 실내 체육관',
    estimatedDurationMinutes: 45,
    distanceKm: 0.78,
  ),
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nearbyPlacesControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeControllerProvider);
    final nearbyState = ref.watch(nearbyPlacesControllerProvider);
    final nearbyPlaces = nearbyState.asData?.value;
    final mapConfig = ref.watch(mapConfigProvider);

    return homeState.when(
      loading: () =>
          const SafeArea(child: Center(child: CircularProgressIndicator())),
      error: (error, _) => _HomeError(
        message: '홈 데이터를 불러오지 못했어요.',
        onRetry: () => ref.read(homeControllerProvider.notifier).refresh(),
      ),
      data: (home) {
        final snapshot = home.snapshot;
        final places = nearbyPlaces?.places.isNotEmpty ?? false
            ? nearbyPlaces!.places
            : snapshot.recommendedPlaces.isEmpty
            ? _fallbackNearbyPlaces
            : snapshot.recommendedPlaces;
        final center =
            nearbyPlaces?.center ?? NearbyPlacesController.fallbackCenter;
        final recentRecord = home.records.isNotEmpty
            ? home.records.first
            : null;
        const nfcDockHeight = 142.0;

        return SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                      ref.read(homeControllerProvider.notifier).refresh(),
                      ref
                          .read(nearbyPlacesControllerProvider.notifier)
                          .load(force: true),
                    ]);
                  },
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
                        onActionTap: () => context.push('/places-map'),
                      ),
                      const SizedBox(height: 12),
                      NearbyPlacesMapPanel(
                        center: center,
                        places: places,
                        canUseNaverMap: mapConfig.canUseNaverMap,
                        isLoading: nearbyState.isLoading,
                        statusMessage: _mapStatusMessage(
                          hasMapKey: mapConfig.canUseNaverMap,
                          nearby: nearbyPlaces,
                          error: nearbyState.error,
                        ),
                        height: MediaQuery.sizeOf(context).height * 0.52,
                        onExpand: () => context.push('/places-map'),
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
                  onNfcTap: () => _openNfcScan(context),
                  onMapTap: () => context.push('/places-map'),
                  onHistoryTap: () =>
                      ref.read(selectedHomeTabProvider.notifier).state = 2,
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

  String _mapStatusMessage({
    required bool hasMapKey,
    required NearbyPlacesState? nearby,
    required Object? error,
  }) {
    if (!hasMapKey) {
      return '지도 키 설정 전이라 미리보기로 표시 중';
    }
    if (error != null) {
      return '기본 장소 표시 중';
    }
    if (nearby?.permissionMessage != null) {
      return nearby!.permissionMessage!;
    }
    if (nearby?.places.isEmpty ?? false) {
      return '주변 장소 없음';
    }
    return '핀을 눌러 장소 정보 보기';
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
  const _HomeBottomDock({
    required this.onNfcTap,
    required this.onMapTap,
    required this.onHistoryTap,
    required this.height,
  });

  final VoidCallback onNfcTap;
  final VoidCallback onMapTap;
  final VoidCallback onHistoryTap;
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
                  stops: const [0.0, 0.28, 0.68, 1.0],
                  colors: [
                    GistagColors.background.withValues(alpha: 0.0),
                    GistagColors.background.withValues(alpha: 0.74),
                    GistagColors.background.withValues(alpha: 0.96),
                    GistagColors.background,
                  ],
                ),
              ),
            ),
          ),
          _WorkoutActionCluster(
            onNfcTap: onNfcTap,
            onMapTap: onMapTap,
            onHistoryTap: onHistoryTap,
          ),
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: GistagColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _InfoPill(
              icon: Icons.trending_up_rounded,
              iconColor: GistagColors.primary,
              label: '레벨',
              value: 'Lv. $level',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _InfoPill(
              icon: Icons.local_fire_department_rounded,
              iconColor: const Color(0xFFF59E0B),
              label: '연속',
              value: '$streak일',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _InfoPill(
              icon: Icons.bolt_rounded,
              iconColor: const Color(0xFF7C3AED),
              label: 'XP',
              value: '$xp',
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 9),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GistagColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: GistagColors.primarySoft.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: GistagColors.primaryDark,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatWhen(record.startedAt, record.placeName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF8B9098),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    record.placeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MiniChip(
                        icon: Icons.timer_outlined,
                        label: '${record.duration.inMinutes.clamp(1, 999)}분',
                      ),
                      const SizedBox(width: 7),
                      _MiniChip(
                        icon: Icons.bolt_rounded,
                        label: '+${record.earnedXp} XP',
                        accent: GistagColors.xp,
                      ),
                    ],
                  ),
                ],
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
    return '$prefix 운동 완료';
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.icon,
    required this.label,
    this.accent = GistagColors.primary,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3F2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GistagColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GistagColors.text,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
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

class _WorkoutActionCluster extends StatelessWidget {
  const _WorkoutActionCluster({
    required this.onNfcTap,
    required this.onMapTap,
    required this.onHistoryTap,
  });

  final VoidCallback onNfcTap;
  final VoidCallback onMapTap;
  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        height: 118,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundToolButton(
                  icon: Icons.map_rounded,
                  label: '지도',
                  onTap: onMapTap,
                ),
                const SizedBox(width: 34),
                const SizedBox(width: 104),
                const SizedBox(width: 34),
                _RoundToolButton(
                  icon: Icons.history_rounded,
                  label: '기록',
                  onTap: onHistoryTap,
                ),
              ],
            ),
            _PrimaryNfcButton(onTap: onNfcTap),
          ],
        ),
      ),
    );
  }
}

class _PrimaryNfcButton extends StatelessWidget {
  const _PrimaryNfcButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GistagPressable(
      onTap: onTap,
      hapticsEnabled: true,
      customBorder: const CircleBorder(),
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: GistagColors.primary,
          boxShadow: [
            BoxShadow(
              color: GistagColors.primary.withValues(alpha: 0.30),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(Icons.sensors_rounded, color: Colors.white, size: 44),
      ),
    );
  }
}

class _RoundToolButton extends StatelessWidget {
  const _RoundToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GistagPressable(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: GistagColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(icon, color: GistagColors.text, size: 28),
        ),
      ),
    );
  }
}
