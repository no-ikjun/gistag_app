import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdminConfig {
  const AdminConfig({required this.nfcAdminPassword});

  factory AdminConfig.fromEnvironment() {
    return AdminConfig(
      nfcAdminPassword: _read(
        'GISTAG_NFC_ADMIN_PASSWORD',
        fallback: const String.fromEnvironment('GISTAG_NFC_ADMIN_PASSWORD'),
      ),
    );
  }

  final String nfcAdminPassword;

  bool get canUseNfcAdmin => nfcAdminPassword.trim().isNotEmpty;

  bool matchesPassword(String value) {
    return canUseNfcAdmin && value.trim() == nfcAdminPassword;
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
