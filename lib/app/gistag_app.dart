import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';
import 'app_theme.dart';

class GistagApp extends ConsumerWidget {
  const GistagApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Gistag',
      debugShowCheckedModeBanner: false,
      theme: buildGistagTheme(),
      routerConfig: router,
    );
  }
}
