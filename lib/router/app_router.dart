import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../screens/active_workout_screen.dart';
import '../screens/home_shell_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/nfc_scan_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/tag_success_screen.dart';
import '../screens/workout_result_screen.dart';

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeShellScreen(),
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => const NfcScanScreen(),
      ),
      GoRoute(
        path: '/tag-success',
        builder: (context, state) => const TagSuccessScreen(),
      ),
      GoRoute(
        path: '/workout',
        builder: (context, state) => const ActiveWorkoutScreen(),
      ),
      GoRoute(
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

    if (auth.isLoading) {
      final canStayPut =
          location == '/splash' ||
          location == '/login' ||
          location == '/onboarding';
      return canStayPut ? null : '/splash';
    }

    if (auth.hasError) {
      return location == '/login' ? null : '/login';
    }

    final session = auth.value;
    return switch (session?.status) {
      AuthStatus.unauthenticated => location == '/login' ? null : '/login',
      AuthStatus.onboardingRequired =>
        location == '/onboarding' ? null : '/onboarding',
      AuthStatus.authenticated =>
        location == '/splash' ||
                location == '/login' ||
                location == '/onboarding'
            ? '/home'
            : null,
      null => '/splash',
    };
  }
}
