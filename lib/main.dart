import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/gistag_app.dart';
import 'config/map_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);

  final mapConfig = MapConfig.fromEnvironment();
  if (mapConfig.canUseNaverMap) {
    await FlutterNaverMap().init(
      clientId: mapConfig.naverMapClientId,
      onAuthFailed: (exception) {
        debugPrint('Naver map auth failed: $exception');
      },
    );
  }

  runApp(const ProviderScope(child: GistagApp()));
}
