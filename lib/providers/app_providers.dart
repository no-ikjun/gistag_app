import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../config/auth_config.dart';
import '../models/auth_models.dart';
import '../models/gistag_models.dart';
import '../services/api_client.dart';
import '../services/auth_api.dart';
import '../services/auth_repository.dart';
import '../services/auth_token_manager.dart';
import '../services/auth_token_storage.dart';
import '../services/gistag_service.dart';
import '../services/infoteam_idp_auth_service.dart';
import '../services/mock_gistag_service.dart';

final authConfigProvider = Provider<AuthConfig>((ref) {
  return AuthConfig.fromEnvironment();
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
  return MockGistagService();
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
      );
    });

class AuthController extends StateNotifier<AsyncValue<AuthSession>> {
  AuthController(this._repository, this._tokenManager)
    : super(const AsyncValue.loading()) {
    _tokenManager.onSessionExpired = _handleSessionExpired;
    initialize();
  }

  final AuthRepository _repository;
  final AuthTokenManager _tokenManager;

  Future<void> initialize() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _repository.restoreSession();
      if (user == null) {
        return const AuthSession.unauthenticated();
      }
      return AuthSession.authenticated(user);
    });
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _repository.login(email: email, password: password);
      return AuthSession.authenticated(user);
    });
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String nickname,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _repository.register(
        email: email,
        password: password,
        nickname: nickname,
      );
      return AuthSession.authenticated(user);
    });
  }

  Future<void> loginWithInfoteam() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _repository.loginWithInfoteam();
      return AuthSession.authenticated(user);
    });
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _repository.logout();
    state = const AsyncValue.data(AuthSession.unauthenticated());
  }

  void _handleSessionExpired() {
    state = const AsyncValue.data(AuthSession.unauthenticated());
  }

  @override
  void dispose() {
    _tokenManager.onSessionExpired = null;
    super.dispose();
  }
}

@immutable
class HomeData {
  const HomeData({
    required this.user,
    required this.snapshot,
    required this.records,
    required this.ranking,
  });

  final GistagUser user;
  final HomeSnapshot snapshot;
  final List<WorkoutRecord> records;
  final List<RankingUser> ranking;
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
      final snapshot = await _service.loadHome();
      final records = await _service.loadRecords();
      final ranking = await _service.loadRanking();
      return HomeData(
        user: snapshot.user,
        snapshot: snapshot,
        records: records,
        ranking: ranking,
      );
    });
  }
}

@immutable
class WorkoutFlowState {
  const WorkoutFlowState({
    this.scannedPlace,
    this.activeSession,
    this.lastResult,
  });

  final Place? scannedPlace;
  final WorkoutSession? activeSession;
  final WorkoutResult? lastResult;

  WorkoutFlowState copyWith({
    Place? scannedPlace,
    WorkoutSession? activeSession,
    WorkoutResult? lastResult,
    bool clearScannedPlace = false,
    bool clearActiveSession = false,
    bool clearLastResult = false,
  }) {
    return WorkoutFlowState(
      scannedPlace: clearScannedPlace
          ? null
          : scannedPlace ?? this.scannedPlace,
      activeSession: clearActiveSession
          ? null
          : activeSession ?? this.activeSession,
      lastResult: clearLastResult ? null : lastResult ?? this.lastResult,
    );
  }
}

final workoutControllerProvider =
    StateNotifierProvider<WorkoutController, AsyncValue<WorkoutFlowState>>((
      ref,
    ) {
      return WorkoutController(ref.watch(gistagServiceProvider));
    });

class WorkoutController extends StateNotifier<AsyncValue<WorkoutFlowState>> {
  WorkoutController(this._service)
    : super(const AsyncValue.data(WorkoutFlowState()));

  final GistagService _service;

  WorkoutFlowState get _value => state.value ?? const WorkoutFlowState();

  Future<Place?> scanNfcTag() async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final place = await _service.verifyNfcTag();
      return _value.copyWith(scannedPlace: place, clearLastResult: true);
    });
    state = result;
    return result.value?.scannedPlace;
  }

  Future<void> startWorkout(Place place) async {
    state = await AsyncValue.guard(() async {
      final session = await _service.startWorkout(place);
      return _value.copyWith(
        activeSession: session,
        scannedPlace: place,
        clearLastResult: true,
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

    final result = await AsyncValue.guard(() async {
      final workoutResult = await _service.endWorkout(session);
      return _value.copyWith(
        lastResult: workoutResult,
        clearActiveSession: true,
      );
    });
    state = result;
    return result.value?.lastResult;
  }
}

final selectedHomeTabProvider = StateProvider<int>((ref) => 0);
