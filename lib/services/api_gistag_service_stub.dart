import '../models/gistag_models.dart';
import 'gistag_service.dart';

class ApiGistagService implements GistagService {
  ApiGistagService(Object dio);

  UnsupportedError get _unsupported => UnsupportedError(
    'ApiGistagService is only available on mobile and desktop builds.',
  );

  @override
  Future<HomeSnapshot> loadHome() async => throw _unsupported;

  @override
  Future<UserStats> loadUserStats() async => throw _unsupported;

  @override
  Future<List<Place>> loadNearbyPlaces({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async => throw _unsupported;

  @override
  Future<NfcTagResolution> verifyNfcTag({
    String? ndefPayload,
    String? hardwareUid,
  }) async => throw _unsupported;

  @override
  Future<NfcTagRegistration> registerNfcTag({
    required String hardwareUid,
    required NfcTagPlaceDraft place,
    List<String> technologies = const [],
    String? ndefPayload,
  }) async => throw _unsupported;

  @override
  Future<WorkoutSession?> loadActiveWorkout() async => throw _unsupported;

  @override
  Future<WorkoutSession> startWorkout(NfcTagResolution resolution) async =>
      throw _unsupported;

  @override
  Future<WorkoutResult> endWorkout(WorkoutSession session) async =>
      throw _unsupported;

  @override
  Future<void> cancelWorkout(WorkoutSession session) async =>
      throw _unsupported;

  @override
  Future<List<WorkoutRecord>> loadRecords() async => throw _unsupported;

  @override
  Future<RankingPage> loadRanking({int limit = 20, int offset = 0}) async =>
      throw _unsupported;

  @override
  Future<WorkoutPeersSnapshot> loadActiveWorkoutPeers() async =>
      throw _unsupported;
}
