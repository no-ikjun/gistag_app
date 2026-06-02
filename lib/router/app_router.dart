import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../screens/active_workout_screen.dart';
import '../screens/home_shell_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/login/register_screen.dart';
import '../screens/nfc_admin_screen.dart';
import '../screens/nfc_scan_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/place_map_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/tag_success_screen.dart';
import '../screens/workout_result_screen.dart';
import '../services/analytics_route_observer.dart';

abstract final class AppRouteNames {
  static const splash = 'splash';
  static const login = 'login';
  static const register = 'register';
  static const home = 'home';
  static const onboarding = 'onboarding';
  static const settings = 'settings';
  static const placesMap = 'places_map';
  static const scan = 'scan';
  static const adminNfcTags = 'admin_nfc_tags';
  static const tagSuccess = 'tag_success';
  static const workout = 'workout';
  static const workoutResult = 'workout_result';

  static const paths = {
    splash: '/splash',
    login: '/login',
    register: '/register',
    home: '/home',
    onboarding: '/onboarding',
    settings: '/settings',
    placesMap: '/places-map',
    scan: '/scan',
    adminNfcTags: '/admin/nfc-tags',
    tagSuccess: '/tag-success',
    workout: '/workout',
    workoutResult: '/workout-result',
  };
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  final analytics = ref.watch(analyticsServiceProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    observers: [
      AnalyticsRouteObserver(
        analytics: analytics,
        routePaths: AppRouteNames.paths,
      ),
    ],
    routes: [
      GoRoute(
        name: AppRouteNames.splash,
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        name: AppRouteNames.login,
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: AppRouteNames.register,
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        name: AppRouteNames.home,
        path: '/home',
        builder: (context, state) => const HomeShellScreen(),
      ),
      GoRoute(
        name: AppRouteNames.onboarding,
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        name: AppRouteNames.settings,
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        name: AppRouteNames.placesMap,
        path: '/places-map',
        builder: (context, state) => const PlaceMapScreen(),
      ),
      GoRoute(
        name: AppRouteNames.scan,
        path: '/scan',
        builder: (context, state) => const NfcScanScreen(),
      ),
      GoRoute(
        name: AppRouteNames.adminNfcTags,
        path: '/admin/nfc-tags',
        builder: (context, state) => const NfcAdminScreen(),
      ),
      GoRoute(
        name: AppRouteNames.tagSuccess,
        path: '/tag-success',
        builder: (context, state) => const TagSuccessScreen(),
      ),
      GoRoute(
        name: AppRouteNames.workout,
        path: '/workout',
        builder: (context, state) => const ActiveWorkoutScreen(),
      ),
      GoRoute(
        name: AppRouteNames.workoutResult,
        path: '/workout-result',
        builder: (context, state) => const WorkoutResultScreen(),
      ),
    ],
  );
});

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authControllerProvider);
    final location = state.matchedLocation;
    final isAuthRoute =
        location == '/splash' ||
        location == '/login' ||
        location == '/register';

    if (auth.isLoading) {
      return isAuthRoute ? null : '/splash';
    }

    if (auth.hasError) {
      return isAuthRoute ? null : '/login';
    }

    final session = auth.value;
    return switch (session?.status) {
      AuthStatus.unauthenticated =>
        location == '/login' || location == '/register' ? null : '/login',
      AuthStatus.authenticated => isAuthRoute ? '/home' : null,
      null => '/splash',
    };
  }
}
