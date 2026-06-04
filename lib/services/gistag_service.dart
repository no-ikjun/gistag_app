import '../models/gistag_models.dart';

abstract class GistagService {
  Future<HomeSnapshot> loadHome();

  Future<UserStats> loadUserStats();

  Future<List<Place>> loadNearbyPlaces({
    required double latitude,
    required double longitude,
    required double radiusKm,
  });

  Future<NfcTagResolution> verifyNfcTag({
    String? ndefPayload,
    String? hardwareUid,
  });

  Future<NfcTagRegistration> registerNfcTag({
    required String hardwareUid,
    required NfcTagPlaceDraft place,
    NfcTagMetadataDraft metadata = const NfcTagMetadataDraft(),
  });

  Future<WorkoutSession?> loadActiveWorkout();

  Future<WorkoutSession> startWorkout(NfcTagResolution resolution);

  Future<WorkoutResult> endWorkout(WorkoutSession session);

  Future<void> cancelWorkout(WorkoutSession session);

  Future<List<WorkoutRecord>> loadRecords();

  Future<RankingPage> loadRanking({int limit = 20, int offset = 0});

  Future<WorkoutPeersSnapshot> loadActiveWorkoutPeers();
}
