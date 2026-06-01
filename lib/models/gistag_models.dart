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

class UserStats {
  const UserStats({
    required this.userId,
    required this.level,
    required this.totalXp,
    required this.xpInCurrentLevel,
    required this.xpToNextLevel,
    required this.xpPerLevel,
    required this.currentStreak,
    required this.totalWorkouts,
    required this.totalDuration,
    this.lastWorkoutDate,
  });

  final String userId;
  final int level;
  final int totalXp;
  final int xpInCurrentLevel;
  final int xpToNextLevel;
  final int xpPerLevel;
  final int currentStreak;
  final String? lastWorkoutDate;
  final int totalWorkouts;
  final Duration totalDuration;

  double get levelProgress {
    if (xpPerLevel <= 0) {
      return 0;
    }
    return (xpInCurrentLevel / xpPerLevel).clamp(0, 1);
  }

  bool get completedWorkoutToday {
    final lastDate = lastWorkoutDate;
    if (lastDate == null || lastDate.isEmpty) {
      return false;
    }
    return lastDate == _kstDateString(DateTime.now().toUtc());
  }

  static String _kstDateString(DateTime utc) {
    final kst = utc.add(const Duration(hours: 9));
    return '${kst.year.toString().padLeft(4, '0')}-'
        '${kst.month.toString().padLeft(2, '0')}-'
        '${kst.day.toString().padLeft(2, '0')}';
  }
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.description,
    required this.workoutType,
    required this.distance,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.distanceText,
    this.estimatedDurationMinutes,
    this.distanceKm,
  });

  final String id;
  final String name;
  final String description;
  final String workoutType;
  final String distance;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String? distanceText;
  final int? estimatedDurationMinutes;
  final double? distanceKm;
}

class NfcTagPlaceDraft {
  const NfcTagPlaceDraft({
    required this.name,
    required this.description,
    required this.workoutType,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String description;
  final String workoutType;
  final double latitude;
  final double longitude;
}

class NfcTag {
  const NfcTag({required this.id, required this.code, required this.status});

  final int id;
  final String code;
  final String status;
}

class NfcTagRegistration {
  const NfcTagRegistration({
    required this.tag,
    required this.place,
    required this.hardwareUid,
    required this.technologies,
    this.ndefPayload,
  });

  final NfcTag tag;
  final Place place;
  final String hardwareUid;
  final List<String> technologies;
  final String? ndefPayload;
}

class NfcTagResolution {
  const NfcTagResolution({
    required this.tag,
    required this.place,
    required this.canStartWorkout,
    this.blockedReason,
  });

  final NfcTag tag;
  final Place place;
  final bool canStartWorkout;
  final String? blockedReason;
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
    this.status = 'ACTIVE',
    this.startedByTagCode,
  });

  final String id;
  final Place place;
  final DateTime startedAt;
  final String status;
  final String? startedByTagCode;
}

class WorkoutResult {
  const WorkoutResult({
    required this.place,
    required this.duration,
    required this.earnedXp,
    required this.level,
    required this.leveledUp,
    required this.streakDays,
    this.totalXp,
    this.streakUpdated = false,
    this.alreadyFinished = false,
  });

  final Place place;
  final Duration duration;
  final int earnedXp;
  final int level;
  final bool leveledUp;
  final int streakDays;
  final int? totalXp;
  final bool streakUpdated;
  final bool alreadyFinished;
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
    required this.userId,
    required this.name,
    required this.level,
    required this.xp,
    required this.streakDays,
    this.isMe = false,
  });

  final int rank;
  final String userId;
  final String name;
  final int level;
  final int xp;
  final int streakDays;
  final bool isMe;
}

class RankingPage {
  const RankingPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
    this.me,
  });

  final List<RankingUser> items;
  final RankingUser? me;
  final int total;
  final int limit;
  final int offset;

  bool get hasMore => offset + items.length < total;
}

class WorkoutPeer {
  const WorkoutPeer({
    required this.userId,
    required this.name,
    required this.level,
    required this.xp,
    required this.streakDays,
    required this.sessionStartedAt,
    required this.duration,
  });

  final String userId;
  final String name;
  final int level;
  final int xp;
  final int streakDays;
  final DateTime sessionStartedAt;
  final Duration duration;
}

class WorkoutPeersSnapshot {
  const WorkoutPeersSnapshot({required this.place, required this.items});

  final Place? place;
  final List<WorkoutPeer> items;
}
