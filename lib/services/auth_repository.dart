import '../models/auth_models.dart';
import 'auth_api.dart';
import 'auth_token_manager.dart';
import 'infoteam_idp_auth_service.dart';

class AuthRepository {
  AuthRepository({
    required AuthApi authApi,
    required AuthTokenManager tokenManager,
    required InfoteamIdpAuthService infoteamIdp,
  }) : _authApi = authApi,
       _tokenManager = tokenManager,
       _infoteamIdp = infoteamIdp;

  final AuthApi _authApi;
  final AuthTokenManager _tokenManager;
  final InfoteamIdpAuthService _infoteamIdp;

  Future<AuthUser?> restoreSession() async {
    final tokens = await _tokenManager.load();
    if (tokens == null) {
      return null;
    }
    return _loadUserWithRefreshFallback(tokens);
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final tokens = await _authApi.login(email: email, password: password);
    return _saveAndLoadUser(tokens);
  }

  Future<AuthUser> register({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final tokens = await _authApi.register(
      email: email,
      password: password,
      nickname: nickname,
    );
    return _saveAndLoadUser(tokens);
  }

  Future<AuthUser> loginWithInfoteam() async {
    final authorization = await _infoteamIdp.authorize();
    final tokens = await _authApi.exchangeInfoteamCode(
      code: authorization.code,
      redirectUri: authorization.redirectUri,
      codeVerifier: authorization.codeVerifier,
    );
    return _saveAndLoadUser(tokens);
  }

  Future<void> logout() => _tokenManager.logout();

  Future<AuthUser> _saveAndLoadUser(AuthTokens tokens) async {
    await _tokenManager.save(tokens);
    return _authApi.me(tokens.accessToken);
  }

  Future<AuthUser?> _loadUserWithRefreshFallback(AuthTokens tokens) async {
    try {
      return await _authApi.me(tokens.accessToken);
    } on AuthApiException catch (error) {
      if (error.statusCode != 401) {
        rethrow;
      }
    }

    AuthTokens? refreshed;
    try {
      refreshed = await _tokenManager.refresh();
    } on AuthApiException catch (error) {
      if (error.statusCode == 401) {
        return null;
      }
      rethrow;
    }
    if (refreshed == null) {
      return null;
    }
    return _authApi.me(refreshed.accessToken);
  }
}
