import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapConfig {
  const MapConfig({required this.naverMapClientId});

  factory MapConfig.fromEnvironment() {
    return MapConfig(
      naverMapClientId: _read(
        'GISTAG_NAVER_MAP_CLIENT_ID',
        fallback: const String.fromEnvironment('GISTAG_NAVER_MAP_CLIENT_ID'),
      ),
    );
  }

  final String naverMapClientId;

  bool get canUseNaverMap => naverMapClientId.trim().isNotEmpty;

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
