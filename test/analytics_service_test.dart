import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gistag_app/config/analytics_config.dart';
import 'package:gistag_app/services/analytics_service.dart';

void main() {
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    dotenv.clean();
  });

  test('debug config stays disabled even when API key exists', () {
    dotenv.loadFromString(envString: 'AMPLITUDE_API_KEY=test-key');

    final config = AnalyticsConfig.fromEnvironment(isRelease: false);

    expect(config.apiKey, 'test-key');
    expect(config.enabled, isFalse);
  });

  test('release config enables analytics when API key exists', () {
    dotenv.loadFromString(envString: 'AMPLITUDE_API_KEY=test-key');

    final config = AnalyticsConfig.fromEnvironment(isRelease: true);

    expect(config.apiKey, 'test-key');
    expect(config.enabled, isTrue);
  });

  test('sanitizes PII and raw device payload properties', () {
    final sanitized = sanitizedAnalyticsProperties({
      'screen': 'login',
      'email': 'user@example.com',
      'nickname': 'runner',
      'accessToken': 'secret',
      'hardwareUid': 'uid',
      'ndef_payload': 'payload',
      'latitude': 35.0,
      'longitude': 126.0,
      'button_id': 'login_email_submit',
    });

    expect(sanitized, {'screen': 'login', 'button_id': 'login_email_submit'});
  });
}
