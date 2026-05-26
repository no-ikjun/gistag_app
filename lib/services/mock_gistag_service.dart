import '../models/gistag_models.dart';
import 'gistag_service.dart';
import 'nfc_payload_parser.dart';

class MockGistagService implements GistagService {
  GistagUser? _user;
  WorkoutSession? _activeSession;

  final List<Place> _places = const [
    Place(
      id: 'gym-gangnam',
      name: '강남 피트니스존',
      description: '퇴근 후 가볍게 들르기 좋은 실내 운동 공간',
      workoutType: '헬스',
      distance: '350m',
      latitude: 35.2131,
      longitude: 126.8378,
      distanceText: '중앙도서관에서 도보 약 5분',
      estimatedDurationMinutes: 60,
      distanceKm: 0,
    ),
    Place(
      id: 'park-run',
      name: '탄천 러닝 코스',
      description: '오늘 컨디션을 깨우기 좋은 야외 러닝 코스',
      workoutType: '러닝',
      distance: '1.2km',
      latitude: 35.214,
      longitude: 126.8385,
      distanceText: '기숙사 A동 인근',
      estimatedDurationMinutes: 30,
      distanceKm: 0.12,
    ),
    Place(
      id: 'pool-center',
      name: '서초 수영장',
      description: '꾸준한 루틴을 만들기 좋은 수영 시설',
      workoutType: '수영',
      distance: '900m',
      latitude: 35.2124,
      longitude: 126.8369,
      distanceText: '체육관 인근',
      estimatedDurationMinutes: 45,
      distanceKm: 0.32,
    ),
  ];

  @override
  Future<HomeSnapshot> loadHome() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final user =
        _user ??
        const GistagUser(name: '최익준', level: 4, xp: 1280, streakDays: 7);
    _user = user;
    return HomeSnapshot(
      user: user,
      recommendedPlaces: _places,
      weeklyGoalText: '이번 주 목표까지 2번 남았어요',
      hasWorkedOutToday: false,
    );
  }

  @override
  Future<List<Place>> loadNearbyPlaces({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _places;
  }

  @override
  Future<NfcTagResolution> verifyNfcTag({
    String ndefPayload = 'gistag://tag/GISTAG_TAG_DEMO_001',
    String? hardwareUid,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final tagCode = parseGistagTagCode(ndefPayload);
    return NfcTagResolution(
      tag: NfcTag(id: 1, code: tagCode, status: 'ACTIVE'),
      place: _places.first,
      canStartWorkout: true,
    );
  }

  @override
  Future<WorkoutSession?> loadActiveWorkout() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return _activeSession;
  }

  @override
  Future<WorkoutSession> startWorkout(NfcTagResolution resolution) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (_activeSession != null) {
      return _activeSession!;
    }
    _activeSession = WorkoutSession(
      id: 'session-${DateTime.now().millisecondsSinceEpoch}',
      place: resolution.place,
      startedAt: DateTime.now(),
      startedByTagCode: resolution.tag.code,
    );
    return _activeSession!;
  }

  @override
  Future<WorkoutResult> endWorkout(WorkoutSession session) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final duration = DateTime.now().difference(session.startedAt);
    final current =
        _user ??
        const GistagUser(name: '최익준', level: 4, xp: 1280, streakDays: 7);
    const earnedXp = 80;
    final totalXp = current.xp + earnedXp;
    final leveledUp = totalXp >= 1320;
    _user = current.copyWith(
      xp: totalXp,
      level: leveledUp ? current.level + 1 : current.level,
      streakDays: current.streakDays + 1,
    );
    _activeSession = null;

    return WorkoutResult(
      place: session.place,
      duration: duration,
      earnedXp: earnedXp,
      level: _user!.level,
      leveledUp: leveledUp,
      streakDays: _user!.streakDays,
      totalXp: _user!.xp,
      streakUpdated: true,
    );
  }

  @override
  Future<void> cancelWorkout(WorkoutSession session) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (_activeSession?.id == session.id) {
      _activeSession = null;
    }
  }

  @override
  Future<List<WorkoutRecord>> loadRecords() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final now = DateTime.now();
    return [
      WorkoutRecord(
        id: 'record-1',
        placeName: '강남 피트니스존',
        workoutType: '헬스',
        startedAt: now.subtract(const Duration(days: 1, hours: 2)),
        duration: const Duration(minutes: 42),
        earnedXp: 80,
      ),
      WorkoutRecord(
        id: 'record-2',
        placeName: '탄천 러닝 코스',
        workoutType: '러닝',
        startedAt: now.subtract(const Duration(days: 2, hours: 1)),
        duration: const Duration(minutes: 28),
        earnedXp: 60,
      ),
      WorkoutRecord(
        id: 'record-3',
        placeName: '서초 수영장',
        workoutType: '수영',
        startedAt: now.subtract(const Duration(days: 4, hours: 3)),
        duration: const Duration(minutes: 50),
        earnedXp: 95,
      ),
    ];
  }

  @override
  Future<List<RankingUser>> loadRanking() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final me =
        _user ??
        const GistagUser(name: '최익준', level: 4, xp: 1280, streakDays: 7);
    return [
      const RankingUser(
        rank: 1,
        name: '러닝메이트',
        level: 7,
        xp: 2430,
        streakDays: 18,
      ),
      const RankingUser(
        rank: 2,
        name: '꾸준왕',
        level: 6,
        xp: 2110,
        streakDays: 14,
      ),
      RankingUser(
        rank: 3,
        name: me.name,
        level: me.level,
        xp: me.xp,
        streakDays: me.streakDays,
        isMe: true,
      ),
      const RankingUser(
        rank: 4,
        name: '헬스루틴',
        level: 4,
        xp: 1160,
        streakDays: 5,
      ),
    ];
  }
}
