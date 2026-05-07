import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/gistag_models.dart';
import '../services/gistag_service.dart';
import '../services/mock_gistag_service.dart';

final gistagServiceProvider = Provider<GistagService>((ref) {
  return MockGistagService();
});

enum AuthStatus { unauthenticated, onboardingRequired, authenticated }

@immutable
class AuthSession {
  const AuthSession._({required this.status, this.user});

  const AuthSession.unauthenticated()
    : this._(status: AuthStatus.unauthenticated);

  const AuthSession.onboardingRequired(GistagUser user)
    : this._(status: AuthStatus.onboardingRequired, user: user);

  const AuthSession.authenticated(GistagUser user)
    : this._(status: AuthStatus.authenticated, user: user);

  final AuthStatus status;
  final GistagUser? user;
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession>>((ref) {
      return AuthController(ref.watch(gistagServiceProvider));
    });

class AuthController extends StateNotifier<AsyncValue<AuthSession>> {
  AuthController(this._service) : super(const AsyncValue.loading()) {
    initialize();
  }

  final GistagService _service;

  Future<void> initialize() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.initialize();
      return const AuthSession.unauthenticated();
    });
  }

  Future<void> loginWithKakao() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _service.loginWithKakao();
      if (user.onboardingCompleted) {
        return AuthSession.authenticated(user);
      }
      return AuthSession.onboardingRequired(user);
    });
  }

  Future<void> completeOnboarding(OnboardingProfile profile) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _service.saveOnboarding(profile);
      return AuthSession.authenticated(user);
    });
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
