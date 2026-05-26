import '../models/gistag_models.dart';

abstract class GistagService {
  Future<HomeSnapshot> loadHome();

  Future<Place> verifyNfcTag();

  Future<WorkoutSession> startWorkout(Place place);

  Future<WorkoutResult> endWorkout(WorkoutSession session);

  Future<List<WorkoutRecord>> loadRecords();

  Future<List<RankingUser>> loadRanking();
}
