import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    final selectedHomeTab = ref.watch(selectedHomeTabProvider);
    final screens = [
      const HomeScreen(),
      const RankingScreen(),
      const HistoryScreen(),
    ];

    return Scaffold(
      body: screens[selectedHomeTab],
      bottomNavigationBar: GistagFooter(
        selectedIndex: selectedHomeTab,
        onSelected: (index) {
          ref.read(selectedHomeTabProvider.notifier).state = index;
        },
      ),
    );
  }
}
