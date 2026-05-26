import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../screens/active_workout_screen.dart';
import '../screens/home_shell_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/login/register_screen.dart';
import '../screens/nfc_scan_screen.dart';
import '../screens/settings_screen.dart';
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
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeShellScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
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
