import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/default_tracking.dart';
import 'package:amplitude_flutter/events/base_event.dart';
import 'package:amplitude_flutter/events/identify.dart';
import 'package:flutter/foundation.dart';

import '../config/analytics_config.dart';
import '../models/auth_models.dart';

abstract class AnalyticsService {
  bool get enabled;

  Future<void> track(String name, {Map<String, Object?> properties = const {}});

  Future<void> trackScreen(String screen, String path);

  Future<void> trackButton(
    String buttonId, {
    Map<String, Object?> properties = const {},
  });

  Future<void> identify(AuthUser user);

  Future<void> reset();
}

class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  bool get enabled => false;

  @override
  Future<void> track(
    String name, {
    Map<String, Object?> properties = const {},
  }) async {}

  @override
  Future<void> trackScreen(String screen, String path) async {}

  @override
  Future<void> trackButton(
    String buttonId, {
    Map<String, Object?> properties = const {},
  }) async {}

  @override
  Future<void> identify(AuthUser user) async {}

  @override
  Future<void> reset() async {}
}

class AmplitudeAnalyticsService implements AnalyticsService {
  AmplitudeAnalyticsService._(this._amplitude);

  factory AmplitudeAnalyticsService(AnalyticsConfig config) {
    return AmplitudeAnalyticsService._(
      Amplitude(
        Configuration(
          apiKey: config.apiKey,
          instanceName: 'gistag',
          defaultTracking: const DefaultTrackingOptions(
            sessions: true,
            appLifecycles: false,
            deepLinks: false,
            attribution: false,
            pageViews: false,
            formInteractions: false,
            fileDownloads: false,
          ),
          locationListening: false,
          useAdvertisingIdForDeviceId: false,
          useAppSetIdForDeviceId: false,
        ),
      ),
    );
  }

  final Amplitude _amplitude;

  @override
  bool get enabled => true;

  @override
  Future<void> track(
    String name, {
    Map<String, Object?> properties = const {},
  }) async {
    await _guard(() async {
      final eventProperties = sanitizedAnalyticsProperties(properties);
      await _amplitude.track(
        BaseEvent(
          name,
          eventProperties: eventProperties.isEmpty ? null : eventProperties,
        ),
      );
    });
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
  Future<void> identify(AuthUser user) async {
    await _guard(() async {
      await _amplitude.setUserId(user.userId);
      await _amplitude.identify(
        Identify().set('provider_type', user.providerType.analyticsValue),
      );
    });
  }

  @override
  Future<void> reset() async {
    await _guard(_amplitude.reset);
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      final initialized = await _amplitude.isBuilt;
      if (!initialized) {
        return;
      }
      await action();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Amplitude analytics error: $error');
      }
    }
  }
}

Map<String, Object?> sanitizedAnalyticsProperties(
  Map<String, Object?> properties,
) {
  return {
    for (final entry in properties.entries)
      if (!_isDisallowedAnalyticsKey(entry.key) && entry.value != null)
        entry.key: entry.value,
  };
}

String analyticsErrorType(Object error) {
  final type = error.runtimeType.toString();
  return type.isEmpty ? 'unknown' : type;
}

extension AuthProviderTypeAnalytics on AuthProviderType {
  String get analyticsValue {
    return switch (this) {
      AuthProviderType.infoteam => 'infoteam',
      AuthProviderType.local => 'local',
      AuthProviderType.unknown => 'unknown',
    };
  }
}

const _disallowedAnalyticsKeys = {
  'email',
  'nickname',
  'token',
  'access_token',
  'refresh_token',
  'accessToken',
  'refreshToken',
  'authorization',
  'authorization_header',
  'password',
  'ndef_payload',
  'ndefPayload',
  'hardware_uid',
  'hardwareUid',
  'raw_payload',
  'rawPayload',
  'latitude',
  'longitude',
  'lat',
  'lng',
};

bool _isDisallowedAnalyticsKey(String key) {
  if (_disallowedAnalyticsKeys.contains(key)) {
    return true;
  }
  final lower = key.toLowerCase();
  return lower.contains('token') ||
      lower.contains('password') ||
      lower.contains('payload') ||
      lower.contains('hardwareuid');
}
