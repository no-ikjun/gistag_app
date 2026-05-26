import '../models/auth_models.dart';
import 'auth_api.dart';
import 'auth_token_storage.dart';

class AuthTokenManager {
  AuthTokenManager({
    required AuthTokenStorage storage,
    required AuthApi authApi,
  }) : _storage = storage,
       _authApi = authApi;

  final AuthTokenStorage _storage;
  final AuthApi _authApi;

  void Function()? onSessionExpired;

  AuthTokens? _tokens;
  bool _loaded = false;
  Future<AuthTokens?>? _refreshInFlight;

  Future<AuthTokens?> load() async {
    if (_loaded) {
      return _tokens;
    }
    _tokens = await _storage.read();
    _loaded = true;
    return _tokens;
  }

  Future<String?> accessToken() async {
    final tokens = await load();
    return tokens?.accessToken;
  }

  Future<AuthTokens?> currentTokens() => load();

  Future<void> save(AuthTokens tokens) async {
    _tokens = tokens;
    _loaded = true;
    await _storage.write(tokens);
  }

  Future<void> clear() async {
    _tokens = null;
    _loaded = true;
    await _storage.clear();
  }

  Future<AuthTokens?> refresh() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final refreshFuture = _refresh();
    _refreshInFlight = refreshFuture;
    return refreshFuture.whenComplete(() => _refreshInFlight = null);
  }

  Future<void> logout() async {
    final tokens = await load();
    if (tokens != null) {
      try {
        await _authApi.logout(tokens.refreshToken);
      } on AuthApiException {
        // Local logout must still clear credentials if the server is unavailable.
      }
    }
    await clear();
  }

  Future<AuthTokens?> _refresh() async {
    final tokens = await load();
    final refreshToken = tokens?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await clear();
      return null;
    }

    try {
      final refreshed = await _authApi.refresh(refreshToken);
      await save(refreshed);
      return refreshed;
    } on AuthApiException catch (error) {
      if (error.statusCode == 401) {
        await clear();
        onSessionExpired?.call();
      }
      rethrow;
    }
  }
}
