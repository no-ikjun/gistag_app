import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_theme.dart';
import '../models/gistag_models.dart';
import '../providers/app_providers.dart';
import '../widgets/common/gistag_header.dart';
import '../widgets/gistag/nearby_places_map_panel.dart';

const _mapFallbackPlaces = [
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

class PlaceMapScreen extends ConsumerStatefulWidget {
  const PlaceMapScreen({super.key});

  @override
  ConsumerState<PlaceMapScreen> createState() => _PlaceMapScreenState();
}

class _PlaceMapScreenState extends ConsumerState<PlaceMapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nearbyPlacesControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nearbyState = ref.watch(nearbyPlacesControllerProvider);
    final mapConfig = ref.watch(mapConfigProvider);

    final nearby = nearbyState.asData?.value;
    final places = nearby?.places.isEmpty ?? true
        ? _mapFallbackPlaces
        : nearby!.places;
    final center = nearby?.center ?? NearbyPlacesController.fallbackCenter;
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final mapHeight = (MediaQuery.sizeOf(context).height - 132 - safeBottom)
        .clamp(440.0, 720.0)
        .toDouble();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () {
            return ref
                .read(nearbyPlacesControllerProvider.notifier)
                .load(force: true);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24, 10, 24, 28 + safeBottom),
            children: [
              GistagHeader(
                centerTitle: true,
                showBellAction: false,
                center: Text(
                  '주변 지도',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 18),
              NearbyPlacesMapPanel(
                center: center,
                places: places,
                canUseNaverMap: mapConfig.canUseNaverMap,
                isLoading: nearbyState.isLoading,
                statusMessage: _statusMessage(
                  hasMapKey: mapConfig.canUseNaverMap,
                  nearby: nearby,
                  error: nearbyState.error,
                ),
                height: mapHeight,
              ),
              const SizedBox(height: 14),
              _MapHint(
                message: nearby?.places.isEmpty ?? false
                    ? '현재 반경 안에 등록된 운동 장소가 없습니다.'
                    : '핀을 누르면 장소와 예상 운동 시간이 지도 위에 표시됩니다.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusMessage({
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

class _MapHint extends StatelessWidget {
  const _MapHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GistagColors.border),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: GistagColors.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
