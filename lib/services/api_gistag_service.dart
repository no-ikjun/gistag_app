import 'package:dio/dio.dart';

import '../models/gistag_models.dart';
import 'api_client.dart';
import 'gistag_service.dart';
import 'nfc_payload_parser.dart';

class GistagApiException implements Exception {
  const GistagApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' ($statusCode)';
    return '$message$code';
  }
}

class ApiGistagService implements GistagService {
  ApiGistagService(this._dio);

  final Dio _dio;

  GistagUser _user = const GistagUser(
    name: 'Gistag',
    level: 1,
    xp: 0,
    streakDays: 0,
  );
  UserStats? _stats;

  @override
  Future<HomeSnapshot> loadHome() async {
    final activeSession = await loadActiveWorkout();
    final stats = _stats;
    return HomeSnapshot(
      user: stats == null
          ? _user
          : _user.copyWith(
              level: stats.level,
              xp: stats.totalXp,
              streakDays: stats.currentStreak,
            ),
      recommendedPlaces: [if (activeSession != null) activeSession.place],
      weeklyGoalText: '오늘 운동 태그를 찍고 루틴을 이어가세요',
      hasWorkedOutToday: stats?.completedWorkoutToday ?? false,
    );
  }

  @override
  Future<UserStats> loadUserStats() async {
    final data = await _requestJson(() {
      return _dio.get<dynamic>('/users/me/stats');
    });
    final stats = _parseUserStats(data);
    _stats = stats;
    _user = _user.copyWith(
      level: stats.level,
      xp: stats.totalXp,
      streakDays: stats.currentStreak,
    );
    return stats;
  }

  @override
  Future<List<Place>> loadNearbyPlaces({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final items = await _requestList(() {
      return _dio.get<dynamic>(
        '/places/nearby',
        queryParameters: {
          'lat': latitude,
          'lng': longitude,
          'radius': radiusKm,
        },
        options: Options(
          extra: const {AuthRefreshInterceptor.skipAuthKey: true},
        ),
      );
    });
    return [for (final item in items) _parsePlace(_asMap(item))];
  }

  @override
  Future<NfcTagResolution> verifyNfcTag({
    String ndefPayload = 'gistag://tag/GISTAG_TAG_DEMO_001',
    String? hardwareUid,
  }) async {
    final tagCode = parseGistagTagCode(ndefPayload);
    final data = await _requestJson(() {
      return _dio.post<dynamic>(
        '/tags/resolve',
        data: {
          'tagCode': tagCode,
          if (hardwareUid != null) 'hardwareUid': hardwareUid,
        },
      );
    });
    return _parseResolution(data);
  }

  @override
  Future<WorkoutSession?> loadActiveWorkout() async {
    final data = await _requestJson(() {
      return _dio.get<dynamic>('/workout-sessions/active');
    });
    final session = data['session'];
    if (session == null) {
      return null;
    }
    return _parseSession(_asMap(session));
  }

  @override
  Future<WorkoutSession> startWorkout(NfcTagResolution resolution) async {
    try {
      final data = await _requestJson(() {
        return _dio.post<dynamic>(
          '/workout-sessions/start',
          data: {
            'tagCode': resolution.tag.code,
            'placeId': int.tryParse(resolution.place.id) ?? resolution.place.id,
          },
        );
      });
      return _parseSession(_asMap(data['session']));
    } on GistagApiException catch (error) {
      if (error.statusCode == 409) {
        final active = await loadActiveWorkout();
        if (active != null) {
          return active;
        }
      }
      rethrow;
    }
  }

  @override
  Future<WorkoutResult> endWorkout(WorkoutSession session) async {
    final previousLevel = _stats?.level ?? _user.level;
    final data = await _requestJson(() {
      return _dio.post<dynamic>(
        '/workout-sessions/${session.id}/finish',
        data: {'clientFinishedAt': DateTime.now().toUtc().toIso8601String()},
      );
    });
    final record = _asMap(data['record']);
    final reward = _asMap(data['reward']);
    final level = _asInt(reward['level']);
    final totalXp = _asInt(reward['totalXp']);
    _user = _user.copyWith(
      level: level,
      xp: totalXp,
      streakDays: _asInt(reward['streakDays']),
    );

    return WorkoutResult(
      place: _placeFromRecord(record),
      duration: Duration(seconds: _asInt(record['durationSeconds'])),
      earnedXp: _asInt(record['earnedXp']),
      level: level,
      leveledUp: level > previousLevel,
      streakDays: _asInt(reward['streakDays']),
      totalXp: totalXp,
      streakUpdated: reward['streakUpdated'] == true,
      alreadyFinished: data['alreadyFinished'] == true,
    );
  }

  @override
  Future<void> cancelWorkout(WorkoutSession session) async {
    await _requestJson(() {
      return _dio.post<dynamic>(
        '/workout-sessions/${session.id}/cancel',
        data: {'reason': 'USER_CANCELLED'},
      );
    });
  }

  @override
  Future<List<WorkoutRecord>> loadRecords() async {
    final data = await _requestJson(() {
      return _dio.get<dynamic>(
        '/workout-records/me/recent',
        queryParameters: {'limit': 5},
      );
    });
    final items = data['items'];
    if (items is! List) {
      return const [];
    }
    return [for (final item in items) _parseRecord(_asMap(item))];
  }

  @override
  Future<RankingPage> loadRanking({int limit = 20, int offset = 0}) async {
    final data = await _requestJson(() {
      return _dio.get<dynamic>(
        '/rankings',
        queryParameters: {'limit': limit, 'offset': offset},
      );
    });
    final meData = data['me'];
    final me = meData == null ? null : _parseRankingUser(_asMap(meData), true);
    final items = data['items'];
    return RankingPage(
      items: items is List
          ? [
              for (final item in items)
                _parseRankingUser(
                  _asMap(item),
                  me != null && _asString(_asMap(item)['userId']) == me.userId,
                ),
            ]
          : const [],
      me: me,
      total: _asInt(data['total']),
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<WorkoutPeersSnapshot> loadActiveWorkoutPeers() async {
    final data = await _requestJson(() {
      return _dio.get<dynamic>('/workout-sessions/active/peers');
    });
    final place = data['place'];
    final items = data['items'];
    return WorkoutPeersSnapshot(
      place: place == null ? null : _parsePlace(_asMap(place)),
      items: items is List
          ? [for (final item in items) _parseWorkoutPeer(_asMap(item))]
          : const [],
    );
  }

  Future<Map<String, dynamic>> _requestJson(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      return _asMap(response.data);
    } on DioException catch (error) {
      throw GistagApiException(
        _extractErrorMessage(error.response?.data),
        statusCode: error.response?.statusCode,
      );
    }
  }

  Future<List<dynamic>> _requestList(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data;
      if (data is List) {
        return data;
      }
      throw const GistagApiException('Unexpected API response format.');
    } on DioException catch (error) {
      throw GistagApiException(
        _extractErrorMessage(error.response?.data),
        statusCode: error.response?.statusCode,
      );
    }
  }

  NfcTagResolution _parseResolution(Map<String, dynamic> data) {
    final tag = _asMap(data['tag']);
    final place = _asMap(data['place']);
    return NfcTagResolution(
      tag: NfcTag(
        id: _asInt(tag['id']),
        code: _asString(tag['code']),
        status: _asString(tag['status']),
      ),
      place: _parsePlace(place),
      canStartWorkout: data['canStartWorkout'] == true,
      blockedReason: data['blockedReason'] as String?,
    );
  }

  WorkoutSession _parseSession(Map<String, dynamic> data) {
    final startedByTag = data['startedByTag'];
    return WorkoutSession(
      id: _asString(data['id']),
      status: _asString(data['status'], fallback: 'ACTIVE'),
      startedAt: DateTime.parse(_asString(data['startedAt'])).toLocal(),
      place: _parsePlace(_asMap(data['place'])),
      startedByTagCode: startedByTag is Map
          ? _asString(startedByTag['code'], fallback: '')
          : null,
    );
  }

  Place _parsePlace(Map<String, dynamic> data) {
    final category = _asString(data['category'], fallback: 'gym');
    final distanceKm = _asDouble(data['distanceKm']);
    final distanceText = data['distanceText'] as String?;
    return Place(
      id: _asString(data['id']),
      name: _asString(data['placeName'], fallback: _asString(data['name'])),
      description: _asString(data['description']),
      workoutType: _categoryLabel(category),
      distance: _formatDistance(distanceKm, distanceText),
      imageUrl: data['imageUrl'] as String?,
      latitude: _asDouble(data['latitude']),
      longitude: _asDouble(data['longitude']),
      distanceText: distanceText,
      estimatedDurationMinutes: data['estimatedDurationMinutes'] == null
          ? null
          : _asInt(data['estimatedDurationMinutes']),
      distanceKm: distanceKm,
    );
  }

  WorkoutRecord _parseRecord(Map<String, dynamic> data) {
    return WorkoutRecord(
      id: _asString(data['id']),
      placeName: _asString(data['placeName']),
      workoutType: '운동',
      startedAt: DateTime.parse(_asString(data['startedAt'])).toLocal(),
      duration: Duration(seconds: _asInt(data['durationSeconds'])),
      earnedXp: _asInt(data['earnedXp']),
    );
  }

  UserStats _parseUserStats(Map<String, dynamic> data) {
    return UserStats(
      userId: _asString(data['userId']),
      level: _asInt(data['level']),
      totalXp: _asInt(data['totalXp']),
      xpInCurrentLevel: _asInt(data['xpInCurrentLevel']),
      xpToNextLevel: _asInt(data['xpToNextLevel']),
      xpPerLevel: _asInt(data['xpPerLevel']),
      currentStreak: _asInt(data['currentStreak']),
      lastWorkoutDate: data['lastWorkoutDate'] as String?,
      totalWorkouts: _asInt(data['totalWorkouts']),
      totalDuration: Duration(seconds: _asInt(data['totalDurationSeconds'])),
    );
  }

  RankingUser _parseRankingUser(Map<String, dynamic> data, bool isMe) {
    return RankingUser(
      rank: _asInt(data['rank']),
      userId: _asString(data['userId']),
      name: _asString(data['nickname'], fallback: 'Gistag'),
      level: _asInt(data['level']),
      xp: _asInt(data['totalXp']),
      streakDays: _asInt(data['currentStreak']),
      isMe: isMe,
    );
  }

  WorkoutPeer _parseWorkoutPeer(Map<String, dynamic> data) {
    return WorkoutPeer(
      userId: _asString(data['userId']),
      name: _asString(data['nickname'], fallback: 'Gistag'),
      level: _asInt(data['level']),
      xp: _asInt(data['totalXp']),
      streakDays: _asInt(data['currentStreak']),
      sessionStartedAt: DateTime.parse(
        _asString(data['sessionStartedAt']),
      ).toLocal(),
      duration: Duration(seconds: _asInt(data['durationSeconds'])),
    );
  }

  Place _placeFromRecord(Map<String, dynamic> data) {
    final place = data['place'];
    if (place is Map) {
      return _parsePlace(Map<String, dynamic>.from(place));
    }
    return Place(
      id: '',
      name: _asString(data['placeName'], fallback: '운동 장소'),
      description: '',
      workoutType: '운동',
      distance: '',
    );
  }

  String _extractErrorMessage(Object? decoded) {
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      if (message is String) {
        return message;
      }
      if (message is List) {
        return message.join('\n');
      }
      final error = decoded['error'];
      if (error is String) {
        return error;
      }
    }
    return 'API request failed.';
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw const GistagApiException('Unexpected API response format.');
  }

  int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.parse(_asString(value));
  }

  double? _asDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  String _asString(Object? value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }
    return value.toString();
  }

  String _formatDistance(double? distanceKm, String? distanceText) {
    if (distanceKm != null) {
      if (distanceKm < 1) {
        return '${(distanceKm * 1000).round()}m';
      }
      final precision = distanceKm < 10 ? 1 : 0;
      return '${distanceKm.toStringAsFixed(precision)}km';
    }
    if (distanceText != null && distanceText.trim().isNotEmpty) {
      return distanceText.trim();
    }
    return '';
  }

  String _categoryLabel(String category) {
    return switch (category) {
      'gym' => '헬스',
      'running' => '러닝',
      'run' => '러닝',
      'swimming' => '수영',
      'pool' => '수영',
      _ => '운동',
    };
  }
}
