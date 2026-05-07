import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeControllerProvider.notifier).refresh();
    });
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
