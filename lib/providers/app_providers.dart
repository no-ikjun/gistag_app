import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';

import '../config/admin_config.dart';
import '../config/analytics_config.dart';
import '../config/auth_config.dart';
import '../config/map_config.dart';
import '../models/auth_models.dart';
import '../models/gistag_models.dart';
import '../models/user_profile_models.dart';
import '../services/api_client.dart';
import '../services/api_gistag_service_stub.dart'
    if (dart.library.io) '../services/api_gistag_service.dart';
import '../services/analytics_service.dart';
import '../services/auth_api.dart';
import '../services/auth_repository.dart';
import '../services/auth_token_manager.dart';
import '../services/auth_token_storage.dart';
import '../services/gistag_service.dart';
import '../services/gistag_nfc_service.dart';
import '../services/infoteam_idp_auth_service.dart';
import '../services/user_profile_api.dart';

final authConfigProvider = Provider<AuthConfig>((ref) {
  return AuthConfig.fromEnvironment();
});

final mapConfigProvider = Provider<MapConfig>((ref) {
  return MapConfig.fromEnvironment();
});

final adminConfigProvider = Provider<AdminConfig>((ref) {
  return AdminConfig.fromEnvironment();
});

final analyticsConfigProvider = Provider<AnalyticsConfig>((ref) {
  return AnalyticsConfig.fromEnvironment();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final config = ref.watch(analyticsConfigProvider);
  if (!config.enabled) {
    return const NoopAnalyticsService();
  }
  return AmplitudeAnalyticsService(config);
});

final authDioProvider = Provider<Dio>((ref) {
  return createAuthDio(ref.watch(authConfigProvider));
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(authDioProvider));
});

final authTokenStorageProvider = Provider<AuthTokenStorage>((ref) {
  return SecureAuthTokenStorage();
});

final authTokenManagerProvider = Provider<AuthTokenManager>((ref) {
  return AuthTokenManager(
    storage: ref.watch(authTokenStorageProvider),
    authApi: ref.watch(authApiProvider),
  );
});

final infoteamIdpAuthServiceProvider = Provider<InfoteamIdpAuthService>((ref) {
  return InfoteamIdpAuthService(ref.watch(authConfigProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    authApi: ref.watch(authApiProvider),
    tokenManager: ref.watch(authTokenManagerProvider),
    infoteamIdp: ref.watch(infoteamIdpAuthServiceProvider),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    config: ref.watch(authConfigProvider),
    tokenManager: ref.watch(authTokenManagerProvider),
  );
});

final apiDioProvider = Provider<Dio>((ref) {
  return ref.watch(apiClientProvider).dio;
});

final gistagServiceProvider = Provider<GistagService>((ref) {
  return ApiGistagService(ref.watch(apiDioProvider));
});

final gistagNfcServiceProvider = Provider<GistagNfcService>((ref) {
  return NfcManagerGistagNfcService();
});

final userProfileApiProvider = Provider<UserProfileApi>((ref) {
  return UserProfileApi(ref.watch(apiDioProvider));
});

enum AuthStatus { unauthenticated, authenticated }

@immutable
class AuthSession {
  const AuthSession._({required this.status, this.user});

  const AuthSession.unauthenticated()
    : this._(status: AuthStatus.unauthenticated);

  const AuthSession.authenticated(AuthUser user)
    : this._(status: AuthStatus.authenticated, user: user);

  final AuthStatus status;
  final AuthUser? user;
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession>>((ref) {
      return AuthController(
        ref.watch(authRepositoryProvider),
        ref.watch(authTokenManagerProvider),
        ref.watch(analyticsServiceProvider),
      );
    });

final analyticsBindingProvider = Provider<void>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  String? identifiedUserId;

  ref.listen(authControllerProvider, (_, next) {
    final session = next.maybeWhen(data: (value) => value, orElse: () => null);

    if (session?.status == AuthStatus.authenticated && session?.user != null) {
      final user = session!.user!;
      if (identifiedUserId == user.userId) {
        return;
      }
      identifiedUserId = user.userId;
      unawaited(analytics.identify(user));
      return;
    }

    if (session?.status == AuthStatus.unauthenticated &&
        identifiedUserId != null) {
      identifiedUserId = null;
      unawaited(analytics.reset());
    }
  });
});

class AuthController extends StateNotifier<AsyncValue<AuthSession>> {
  AuthController(this._repository, this._tokenManager, this._analytics)
    : super(const AsyncValue.loading()) {
    _tokenManager.onSessionExpired = _handleSessionExpired;
    initialize();
  }

  final AuthRepository _repository;
  final AuthTokenManager _tokenManager;
  final AnalyticsService _analytics;

  Future<void> initialize() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _repository.restoreSession();
      if (user == null) {
        return const AuthSession.unauthenticated();
      }
      await _analytics.track('auth_session_restored');
      return AuthSession.authenticated(user);
    });
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        final user = await _repository.login(email: email, password: password);
        await _analytics.track(
          'auth_login_succeeded',
          properties: {'method': 'email'},
        );
        return AuthSession.authenticated(user);
      } catch (error) {
        await _analytics.track(
          'auth_login_failed',
          properties: {
            'method': 'email',
            'error_type': analyticsErrorType(error),
          },
        );
        rethrow;
      }
    });
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String nickname,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        final user = await _repository.register(
          email: email,
          password: password,
          nickname: nickname,
        );
        await _analytics.track(
          'auth_register_succeeded',
          properties: {'method': 'email'},
        );
        return AuthSession.authenticated(user);
      } catch (error) {
        await _analytics.track(
          'auth_register_failed',
          properties: {
            'method': 'email',
            'error_type': analyticsErrorType(error),
          },
        );
        rethrow;
      }
    });
  }

  Future<void> loginWithInfoteam() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        final user = await _repository.loginWithInfoteam();
        await _analytics.track(
          'auth_login_succeeded',
          properties: {'method': 'infoteam'},
        );
        return AuthSession.authenticated(user);
      } catch (error) {
        await _analytics.track(
          'auth_login_failed',
          properties: {
            'method': 'infoteam',
            'error_type': analyticsErrorType(error),
          },
        );
        rethrow;
      }
    });
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _analytics.track('auth_logout');
    await _repository.logout();
    state = const AsyncValue.data(AuthSession.unauthenticated());
  }

  void _handleSessionExpired() {
    unawaited(_analytics.reset());
    state = const AsyncValue.data(AuthSession.unauthenticated());
  }

  @override
  void dispose() {
    _tokenManager.onSessionExpired = null;
    super.dispose();
  }
}

final userProfileControllerProvider =
    StateNotifierProvider<UserProfileController, AsyncValue<UserProfile?>>((
      ref,
    ) {
      final controller = UserProfileController(
        ref.watch(userProfileApiProvider),
      );
      ref.listen(authControllerProvider, (_, next) {
        final session = next.maybeWhen(
          data: (value) => value,
          orElse: () => null,
        );
        if (next.isLoading ||
            session == null ||
            session.status == AuthStatus.unauthenticated) {
          controller.clear();
        }
      });
      return controller;
    });

class UserProfileController extends StateNotifier<AsyncValue<UserProfile?>> {
  UserProfileController(this._api) : super(const AsyncValue.data(null));

  final UserProfileApi _api;

  Future<UserProfile> load({bool force = false}) async {
    final cached = state.maybeWhen(data: (value) => value, orElse: () => null);
    if (!force && cached != null) {
      return cached;
    }

    state = const AsyncValue.loading();
    try {
      final profile = await _api.fetchProfile();
      state = AsyncValue.data(profile);
      return profile;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<UserProfile> submitOnboarding(OnboardingInput input) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _api.submitOnboarding(input);
      state = AsyncValue.data(profile);
      return profile;
    } on UserProfileApiException catch (error, stackTrace) {
      if (error.statusCode == 409) {
        return load(force: true);
      }
      state = AsyncValue.error(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<UserProfile> updateProfile({
    UserGender? gender,
    List<ExerciseType>? exerciseTypes,
    ExerciseFrequency? exerciseFrequency,
  }) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _api.updateProfile(
        gender: gender,
        exerciseTypes: exerciseTypes,
        exerciseFrequency: exerciseFrequency,
      );
      state = AsyncValue.data(profile);
      return profile;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

@immutable
class HomeData {
  const HomeData({
    required this.user,
    required this.stats,
    required this.snapshot,
    required this.records,
  });

  final GistagUser user;
  final UserStats stats;
  final HomeSnapshot snapshot;
  final List<WorkoutRecord> records;
}

final homeControllerProvider =
    StateNotifierProvider<HomeController, AsyncValue<HomeData>>((ref) {
      return HomeController(ref.watch(gistagServiceProvider));
    });

class HomeController extends StateNotifier<AsyncValue<HomeData>> {
  HomeController(this._service) : super(const AsyncValue.loading());

  final GistagService _service;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final stats = await _service.loadUserStats();
      final snapshot = await _service.loadHome();
      final records = await _service.loadRecords();
      return HomeData(
        user: snapshot.user.copyWith(
          level: stats.level,
          xp: stats.totalXp,
          streakDays: stats.currentStreak,
        ),
        stats: stats,
        snapshot: snapshot,
        records: records,
      );
    });
  }
}

final rankingControllerProvider =
    StateNotifierProvider<RankingController, AsyncValue<RankingPage>>((ref) {
      return RankingController(ref.watch(gistagServiceProvider));
    });

class RankingController extends StateNotifier<AsyncValue<RankingPage>> {
  RankingController(this._service) : super(const AsyncValue.loading());

  static const int pageSize = 20;

  final GistagService _service;
  bool _loadingMore = false;

  Future<void> load({bool force = false}) async {
    if (!force && state.hasValue) {
      return;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return _service.loadRanking(limit: pageSize, offset: 0);
    });
  }

  Future<void> loadMore() async {
    final current = state.maybeWhen(data: (value) => value, orElse: () => null);
    if (current == null || !current.hasMore || _loadingMore) {
      return;
    }

    _loadingMore = true;
    final previous = current;
    final next = await AsyncValue.guard(() {
      return _service.loadRanking(
        limit: previous.limit,
        offset: previous.offset + previous.items.length,
      );
    });
    state = next.when(
      data: (page) => AsyncValue.data(
        RankingPage(
          items: [...previous.items, ...page.items],
          me: page.me ?? previous.me,
          total: page.total,
          limit: page.limit,
          offset: previous.offset,
        ),
      ),
      error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
      loading: () => AsyncValue.data(previous),
    );
    _loadingMore = false;
  }
}

final workoutPeersControllerProvider =
    StateNotifierProvider<
      WorkoutPeersController,
      AsyncValue<WorkoutPeersSnapshot>
    >((ref) {
      return WorkoutPeersController(ref.watch(gistagServiceProvider));
    });

class WorkoutPeersController
    extends StateNotifier<AsyncValue<WorkoutPeersSnapshot>> {
  WorkoutPeersController(this._service) : super(const AsyncValue.loading());

  final GistagService _service;

  Future<void> refresh() async {
    state = await AsyncValue.guard(_service.loadActiveWorkoutPeers);
  }

  void clear() {
    state = const AsyncValue.data(WorkoutPeersSnapshot(place: null, items: []));
  }
}

@immutable
class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

@immutable
class NearbyPlacesState {
  const NearbyPlacesState({
    required this.center,
    required this.places,
    required this.usingFallbackLocation,
    this.permissionMessage,
  });

  final GeoPoint center;
  final List<Place> places;
  final bool usingFallbackLocation;
  final String? permissionMessage;
}

final nearbyPlacesControllerProvider =
    StateNotifierProvider<
      NearbyPlacesController,
      AsyncValue<NearbyPlacesState>
    >((ref) {
      return NearbyPlacesController(ref.watch(gistagServiceProvider));
    });

class NearbyPlacesController
    extends StateNotifier<AsyncValue<NearbyPlacesState>> {
  NearbyPlacesController(this._service) : super(const AsyncValue.loading());

  static const GeoPoint fallbackCenter = GeoPoint(
    latitude: 35.2131,
    longitude: 126.8378,
  );

  final GistagService _service;

  Future<void> load({double radiusKm = 1.5, bool force = false}) async {
    if (!force && state.hasValue) {
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final location = await _resolveLocation();
      final places = await _service.loadNearbyPlaces(
        latitude: location.center.latitude,
        longitude: location.center.longitude,
        radiusKm: radiusKm,
      );
      return NearbyPlacesState(
        center: location.center,
        places: places,
        usingFallbackLocation: location.usingFallbackLocation,
        permissionMessage: location.permissionMessage,
      );
    });
  }

  Future<_ResolvedLocation> _resolveLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const _ResolvedLocation(
          center: fallbackCenter,
          usingFallbackLocation: true,
          permissionMessage: '위치 서비스가 꺼져 있어 GIST 기준으로 보여드려요.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        return const _ResolvedLocation(
          center: fallbackCenter,
          usingFallbackLocation: true,
          permissionMessage: '위치 권한이 없어 GIST 기준으로 보여드려요.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return _ResolvedLocation(
        center: GeoPoint(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        usingFallbackLocation: false,
      );
    } catch (_) {
      return const _ResolvedLocation(
        center: fallbackCenter,
        usingFallbackLocation: true,
        permissionMessage: '현재 위치를 확인하지 못해 GIST 기준으로 보여드려요.',
      );
    }
  }
}

@immutable
class _ResolvedLocation {
  const _ResolvedLocation({
    required this.center,
    required this.usingFallbackLocation,
    this.permissionMessage,
  });

  final GeoPoint center;
  final bool usingFallbackLocation;
  final String? permissionMessage;
}

@immutable
class WorkoutFlowState {
  const WorkoutFlowState({
    this.resolvedTag,
    this.activeSession,
    this.lastResult,
    this.errorMessage,
  });

  final NfcTagResolution? resolvedTag;
  final WorkoutSession? activeSession;
  final WorkoutResult? lastResult;
  final String? errorMessage;

  WorkoutFlowState copyWith({
    NfcTagResolution? resolvedTag,
    WorkoutSession? activeSession,
    WorkoutResult? lastResult,
    String? errorMessage,
    bool clearResolvedTag = false,
    bool clearActiveSession = false,
    bool clearLastResult = false,
    bool clearError = false,
  }) {
    return WorkoutFlowState(
      resolvedTag: clearResolvedTag ? null : resolvedTag ?? this.resolvedTag,
      activeSession: clearActiveSession
          ? null
          : activeSession ?? this.activeSession,
      lastResult: clearLastResult ? null : lastResult ?? this.lastResult,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final demoNfcTagResolutionProvider = StateProvider<NfcTagResolution?>(
  (ref) => null,
);

final workoutControllerProvider =
    StateNotifierProvider<WorkoutController, AsyncValue<WorkoutFlowState>>((
      ref,
    ) {
      return WorkoutController(
        ref.watch(gistagServiceProvider),
        ref.watch(gistagNfcServiceProvider),
        ref.watch(demoNfcTagResolutionProvider),
        ref.watch(analyticsServiceProvider),
      );
    });

class WorkoutController extends StateNotifier<AsyncValue<WorkoutFlowState>> {
  WorkoutController(
    this._service,
    this._nfcService,
    this._demoResolution,
    this._analytics,
  ) : super(const AsyncValue.data(WorkoutFlowState()));

  static const _demoHardwareUid = 'DEMO-NFC-TAG';
  static const _demoTagCode = 'GISTAG_TAG_DEMO_001';
  static const _demoSessionPrefix = 'demo-session-';
  static const _demoPlace = Place(
    id: 'gist-demo-place',
    name: 'GIST 운동 시연 공간',
    description: 'NFC 시연용 운동 장소',
    workoutType: '헬스',
    distance: '0m',
    latitude: 35.2131,
    longitude: 126.8378,
    distanceText: '시연 모드',
    estimatedDurationMinutes: 60,
    distanceKm: 0,
  );

  final GistagService _service;
  final GistagNfcService _nfcService;
  final NfcTagResolution? _demoResolution;
  final AnalyticsService _analytics;

  WorkoutFlowState get _value => state.value ?? const WorkoutFlowState();

  Future<NfcTagResolution?> scanNfcTag() async {
    final previous = _value;
    await _analytics.track('nfc_scan_started');
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final tag = await _nfcService.readTag();
      if (_isDemoTag(tag.hardwareUid)) {
        await _analytics.track(
          'nfc_scan_succeeded',
          properties: _nfcResolutionProperties(_activeDemoResolution),
        );
        return previous.copyWith(
          resolvedTag: _activeDemoResolution,
          clearLastResult: true,
          clearError: true,
        );
      }
      final resolution = await _service.verifyNfcTag(
        ndefPayload: tag.ndefPayload,
        hardwareUid: tag.hardwareUid,
      );
      await _analytics.track(
        'nfc_scan_succeeded',
        properties: _nfcResolutionProperties(resolution),
      );
      return previous.copyWith(
        resolvedTag: resolution,
        clearLastResult: true,
        clearError: true,
      );
    });
    if (result.hasError) {
      await _analytics.track(
        'nfc_scan_failed',
        properties: {'error_type': analyticsErrorType(result.error!)},
      );
    }
    state = result;
    return result.value?.resolvedTag;
  }

  Future<void> restoreActiveWorkout() async {
    final previous = _value;
    final result = await AsyncValue.guard(() async {
      final session = await _service.loadActiveWorkout();
      return previous.copyWith(
        activeSession: session,
        clearActiveSession: session == null,
        clearError: true,
      );
    });
    state = result;
  }

  Future<void> startWorkout(NfcTagResolution resolution) async {
    final previous = _value;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (_isDemoResolution(resolution)) {
        await _analytics.track(
          'workout_started',
          properties: _workoutPlaceProperties(resolution.place),
        );
        return previous.copyWith(
          activeSession: _demoSession(resolution),
          resolvedTag: resolution,
          clearLastResult: true,
          clearError: true,
        );
      }
      final session = await _service.startWorkout(resolution);
      await _analytics.track(
        'workout_started',
        properties: _workoutPlaceProperties(session.place),
      );
      return previous.copyWith(
        activeSession: session,
        resolvedTag: resolution,
        clearLastResult: true,
        clearError: true,
      );
    });
  }

  Future<WorkoutResult?> endWorkout() async {
    final session = _value.activeSession;
    if (session == null) {
      state = AsyncValue.error(
        StateError('No active workout session.'),
        StackTrace.current,
      );
      return null;
    }

    final previous = _value;
    try {
      if (_isDemoSession(session)) {
        final workoutResult = _demoWorkoutResult(session);
        await _analytics.track(
          'workout_completed',
          properties: _workoutResultProperties(workoutResult),
        );
        final next = previous.copyWith(
          lastResult: workoutResult,
          clearActiveSession: true,
          clearError: true,
        );
        state = AsyncValue.data(next);
        return workoutResult;
      }
      final workoutResult = await _service.endWorkout(session);
      await _analytics.track(
        'workout_completed',
        properties: _workoutResultProperties(workoutResult),
      );
      final next = previous.copyWith(
        lastResult: workoutResult,
        clearActiveSession: true,
        clearError: true,
      );
      state = AsyncValue.data(next);
      return workoutResult;
    } catch (error) {
      state = AsyncValue.data(
        previous.copyWith(errorMessage: _workoutErrorMessage(error)),
      );
      return null;
    }
  }

  Future<bool> cancelWorkout() async {
    final session = _value.activeSession;
    if (session == null) {
      state = AsyncValue.error(
        StateError('No active workout session.'),
        StackTrace.current,
      );
      return false;
    }

    final previous = _value;
    final result = await AsyncValue.guard(() async {
      if (!_isDemoSession(session)) {
        await _service.cancelWorkout(session);
      }
      await _analytics.track(
        'workout_cancelled',
        properties: _workoutPlaceProperties(session.place),
      );
      return previous.copyWith(
        clearActiveSession: true,
        clearResolvedTag: true,
        clearError: true,
      );
    });
    state = result;
    return !result.hasError;
  }

  bool _isDemoTag(String? hardwareUid) => hardwareUid == _demoHardwareUid;

  bool _isDemoResolution(NfcTagResolution resolution) {
    return resolution.tag.code == _demoTagCode ||
        resolution.tag.code == _demoHardwareUid;
  }

  bool _isDemoSession(WorkoutSession session) {
    return session.id.startsWith(_demoSessionPrefix);
  }

  NfcTagResolution get _activeDemoResolution {
    final registered = _demoResolution;
    if (registered != null) {
      return registered;
    }
    return const NfcTagResolution(
      tag: NfcTag(id: 0, code: _demoTagCode, status: 'ACTIVE'),
      place: _demoPlace,
      canStartWorkout: true,
    );
  }

  WorkoutSession _demoSession(NfcTagResolution resolution) {
    return WorkoutSession(
      id: '$_demoSessionPrefix${DateTime.now().millisecondsSinceEpoch}',
      place: resolution.place,
      startedAt: DateTime.now(),
      startedByTagCode: resolution.tag.code,
    );
  }

  WorkoutResult _demoWorkoutResult(WorkoutSession session) {
    final duration = DateTime.now().difference(session.startedAt);
    return WorkoutResult(
      place: session.place,
      duration: duration < const Duration(seconds: 1)
          ? const Duration(minutes: 1)
          : duration,
      earnedXp: 80,
      level: 4,
      leveledUp: false,
      streakDays: 8,
      totalXp: 1360,
      streakUpdated: true,
    );
  }

  Map<String, Object?> _nfcResolutionProperties(NfcTagResolution resolution) {
    return {
      'tag_status': resolution.tag.status,
      'can_start_workout': resolution.canStartWorkout,
      'workout_type': resolution.place.workoutType,
    };
  }

  Map<String, Object?> _workoutPlaceProperties(Place place) {
    return {'place_id': place.id, 'workout_type': place.workoutType};
  }

  Map<String, Object?> _workoutResultProperties(WorkoutResult result) {
    return {
      'place_id': result.place.id,
      'workout_type': result.place.workoutType,
      'duration_seconds': result.duration.inSeconds,
      'earned_xp': result.earnedXp,
      'level': result.level,
      'leveled_up': result.leveledUp,
      'streak_updated': result.streakUpdated,
    };
  }

  String _workoutErrorMessage(Object error) {
    final message = error.toString();
    if (message.trim().isEmpty) {
      return '요청에 실패했어요. 최소 운동 시간은 60초입니다.';
    }
    return '요청에 실패했어요. 최소 운동 시간은 60초입니다.';
  }
}

final selectedHomeTabProvider = StateProvider<int>((ref) => 0);
