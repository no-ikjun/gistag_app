import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/user_profile_models.dart';
import '../providers/app_providers.dart';
import '../widgets/common/gistag_footer.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'ranking_screen.dart';

class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAndRestore();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAndRestore();
    }
  }

  Future<void> _refreshAndRestore() async {
    if (!mounted) {
      return;
    }
    final router = GoRouter.of(context);
    final profile = await _loadProfile();
    if (!mounted) {
      return;
    }
    if (profile == null) {
      return;
    }
    if (!profile.onboardingCompleted) {
      router.go('/onboarding');
      return;
    }
    await ref.read(homeControllerProvider.notifier).refresh();
    if (!mounted) {
      return;
    }
    await ref.read(workoutControllerProvider.notifier).restoreActiveWorkout();
    if (!mounted) {
      return;
    }
    final activeSession = ref
        .read(workoutControllerProvider)
        .value
        ?.activeSession;
    if (activeSession != null) {
      router.go('/workout');
    }
  }

  Future<UserProfile?> _loadProfile() async {
    try {
      return await ref.read(userProfileControllerProvider.notifier).load();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedHomeTab = ref.watch(selectedHomeTabProvider);
    final profileState = ref.watch(userProfileControllerProvider);
    final screens = [
      const HomeScreen(),
      const RankingScreen(),
      const HistoryScreen(),
    ];

    if (profileState.isLoading && !profileState.hasValue) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    if (profileState.hasError) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '프로필 정보를 불러오지 못했어요.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      unawaited(
                        ref
                            .read(analyticsServiceProvider)
                            .trackButton(
                              'home_shell_profile_retry',
                              properties: {
                                'screen': 'home',
                                'component': 'filled_button',
                                'action_type': 'retry',
                              },
                            ),
                      );
                      _refreshAndRestore();
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: screens[selectedHomeTab],
      bottomNavigationBar: GistagFooter(
        selectedIndex: selectedHomeTab,
        onSelected: (index) {
          if (index != selectedHomeTab) {
            unawaited(
              ref
                  .read(analyticsServiceProvider)
                  .track(
                    'tab_viewed',
                    properties: {
                      'tab': _tabName(index),
                      'previous_tab': _tabName(selectedHomeTab),
                    },
                  ),
            );
          }
          ref.read(selectedHomeTabProvider.notifier).state = index;
        },
      ),
    );
  }

  String _tabName(int index) {
    return switch (index) {
      0 => 'home',
      1 => 'ranking',
      2 => 'history',
      _ => 'unknown',
    };
  }
}
