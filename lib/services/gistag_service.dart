import '../models/gistag_models.dart';

abstract class GistagService {
  Future<void> initialize();

  Future<GistagUser> loginWithKakao();

  Future<GistagUser> saveOnboarding(OnboardingProfile profile);

  Future<HomeSnapshot> loadHome();

  Future<Place> verifyNfcTag();

  Future<WorkoutSession> startWorkout(Place place);

  Future<WorkoutResult> endWorkout(WorkoutSession session);

  Future<List<WorkoutRecord>> loadRecords();

  Future<List<RankingUser>> loadRanking();
}
