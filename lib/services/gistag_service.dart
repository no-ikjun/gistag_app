import '../models/gistag_models.dart';

abstract class GistagService {
  Future<HomeSnapshot> loadHome();

  Future<List<Place>> loadNearbyPlaces({
    required double latitude,
    required double longitude,
    required double radiusKm,
  });

  Future<NfcTagResolution> verifyNfcTag({
    String ndefPayload = 'gistag://tag/GISTAG_TAG_DEMO_001',
    String? hardwareUid,
  });

  Future<WorkoutSession?> loadActiveWorkout();

  Future<WorkoutSession> startWorkout(NfcTagResolution resolution);

  Future<WorkoutResult> endWorkout(WorkoutSession session);

  Future<void> cancelWorkout(WorkoutSession session);

  Future<List<WorkoutRecord>> loadRecords();

  Future<List<RankingUser>> loadRanking();
}
