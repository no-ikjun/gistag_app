import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthConfig {
  const AuthConfig({
    required this.apiBaseUrl,
    required this.idpAuthorizeUrl,
    required this.idpClientId,
    required this.redirectUri,
    required this.idpScopes,
  });

  factory AuthConfig.fromEnvironment() {
    final redirectUri = _read(
      'GISTAG_IDP_REDIRECT_URI',
      fallback: const String.fromEnvironment(
        'GISTAG_IDP_REDIRECT_URI',
        defaultValue: 'gistag://oauth/callback',
      ),
    );

    return AuthConfig(
      apiBaseUrl: _read(
        'GISTAG_API_BASE_URL',
        fallback: const String.fromEnvironment(
          'GISTAG_API_BASE_URL',
          defaultValue: 'http://localhost:3000',
        ),
      ),
      idpAuthorizeUrl: _read(
        'GISTAG_IDP_AUTHORIZE_URL',
        fallback: const String.fromEnvironment(
          'GISTAG_IDP_AUTHORIZE_URL',
          defaultValue: 'https://api.account.gistory.me/oauth/authorize',
        ),
      ),
      idpClientId: _read(
        'GISTAG_IDP_CLIENT_ID',
        fallback: const String.fromEnvironment('GISTAG_IDP_CLIENT_ID'),
      ),
      redirectUri: redirectUri,
      idpScopes: const ['name', 'email'],
    );
  }

  final String apiBaseUrl;
  final String idpAuthorizeUrl;
  final String idpClientId;
  final String redirectUri;
  final List<String> idpScopes;

  Uri get idpAuthorizeUri {
    final parsed = Uri.parse(idpAuthorizeUrl);
    if (parsed.path.isEmpty || parsed.path == '/') {
      return parsed.replace(path: '/oauth/authorize');
    }
    return parsed;
  }

  Uri get redirectUriValue => Uri.parse(redirectUri);

  String get redirectScheme => redirectUriValue.scheme;

  bool get canUseInfoteamLogin => idpClientId.trim().isNotEmpty;

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
