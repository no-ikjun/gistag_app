class GistagUser {
  const GistagUser({
    required this.name,
    required this.level,
    required this.xp,
    required this.streakDays,
  });

  final String name;
  final int level;
  final int xp;
  final int streakDays;

  GistagUser copyWith({String? name, int? level, int? xp, int? streakDays}) {
    return GistagUser(
      name: name ?? this.name,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      streakDays: streakDays ?? this.streakDays,
    );
  }
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.description,
    required this.workoutType,
    required this.distance,
  });

  final String id;
  final String name;
  final String description;
  final String workoutType;
  final String distance;
}

class HomeSnapshot {
  const HomeSnapshot({
    required this.user,
    required this.recommendedPlaces,
    required this.weeklyGoalText,
    required this.hasWorkedOutToday,
  });

  final GistagUser user;
  final List<Place> recommendedPlaces;
  final String weeklyGoalText;
  final bool hasWorkedOutToday;
}

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.place,
    required this.startedAt,
  });

  final String id;
  final Place place;
  final DateTime startedAt;
}

class WorkoutResult {
  const WorkoutResult({
    required this.place,
    required this.duration,
    required this.earnedXp,
    required this.level,
    required this.leveledUp,
    required this.streakDays,
  });

  final Place place;
  final Duration duration;
  final int earnedXp;
  final int level;
  final bool leveledUp;
  final int streakDays;
}

class WorkoutRecord {
  const WorkoutRecord({
    required this.id,
    required this.placeName,
    required this.workoutType,
    required this.startedAt,
    required this.duration,
    required this.earnedXp,
  });

  final String id;
  final String placeName;
  final String workoutType;
  final DateTime startedAt;
  final Duration duration;
  final int earnedXp;
}

class RankingUser {
  const RankingUser({
    required this.rank,
    required this.name,
    required this.level,
    required this.xp,
    required this.streakDays,
    this.isMe = false,
  });

  final int rank;
  final String name;
  final int level;
  final int xp;
  final int streakDays;
  final bool isMe;
}
