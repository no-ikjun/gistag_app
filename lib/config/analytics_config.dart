import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AnalyticsConfig {
  const AnalyticsConfig({required this.apiKey, required this.enabled});

  factory AnalyticsConfig.fromEnvironment({bool isRelease = kReleaseMode}) {
    final apiKey = _read(
      'AMPLITUDE_API_KEY',
      fallback: const String.fromEnvironment('AMPLITUDE_API_KEY'),
    );

    return AnalyticsConfig(
      apiKey: apiKey,
      enabled: isRelease && _isMobileTarget && apiKey.trim().isNotEmpty,
    );
  }

  final String apiKey;
  final bool enabled;

  static bool get _isMobileTarget {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static String _read(String key, {required String fallback}) {
    if (dotenv.isInitialized) {
      final value = dotenv.maybeGet(key);
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }
}
