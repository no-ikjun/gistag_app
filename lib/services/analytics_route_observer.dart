import 'dart:async';

import 'package:flutter/widgets.dart';

import 'analytics_service.dart';

class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver({
    required AnalyticsService analytics,
    required Map<String, String> routePaths,
  }) : _analytics = analytics,
       _routePaths = routePaths;

  final AnalyticsService _analytics;
  final Map<String, String> _routePaths;
  String? _lastTrackedRouteName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _track(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _track(previousRoute);
  }

  void _track(Route<dynamic>? route) {
    final routeName = route?.settings.name;
    if (routeName == null || routeName == _lastTrackedRouteName) {
      return;
    }
    _lastTrackedRouteName = routeName;
    unawaited(
      _analytics.trackScreen(routeName, _routePaths[routeName] ?? routeName),
    );
  }
}
