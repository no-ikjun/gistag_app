import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gistag_app/models/auth_models.dart';
import 'package:gistag_app/providers/app_providers.dart';
import 'package:gistag_app/services/analytics_service.dart';
import 'package:gistag_app/widgets/common/gistag_button.dart';

class _AnalyticsEvent {
  const _AnalyticsEvent(this.name, this.properties);

  final String name;
  final Map<String, Object?> properties;
}

class _RecordingAnalyticsService implements AnalyticsService {
  final events = <_AnalyticsEvent>[];

  @override
  bool get enabled => true;

  @override
  Future<void> track(
    String name, {
    Map<String, Object?> properties = const {},
  }) async {
    events.add(_AnalyticsEvent(name, properties));
  }

  @override
  Future<void> trackScreen(String screen, String path) {
    return track('screen_view', properties: {'screen': screen, 'path': path});
  }

  @override
  Future<void> trackButton(
    String buttonId, {
    Map<String, Object?> properties = const {},
  }) {
    return track(
      'button_click',
      properties: {'button_id': buttonId, ...properties},
    );
  }

  @override
  Future<void> identify(AuthUser user) async {}

  @override
  Future<void> reset() async {}
}

void main() {
  testWidgets('GistagButton records button_click when tapped', (tester) async {
    final analytics = _RecordingAnalyticsService();
    var tapped = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsServiceProvider.overrideWithValue(analytics)],
        child: MaterialApp(
          home: Scaffold(
            body: GistagButton(
              label: 'Tap',
              onPressed: () => tapped = true,
              analyticsId: 'test_button',
              analyticsActionType: 'submit',
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tap'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tapped, isTrue);
    expect(analytics.events, hasLength(1));
    expect(analytics.events.single.name, 'button_click');
    expect(
      analytics.events.single.properties,
      containsPair('button_id', 'test_button'),
    );
    expect(
      analytics.events.single.properties,
      containsPair('component', 'gistag_button'),
    );
    expect(
      analytics.events.single.properties,
      containsPair('action_type', 'submit'),
    );
  });
}
