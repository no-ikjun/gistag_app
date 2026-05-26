import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../config/auth_config.dart';
import '../models/auth_models.dart';

class InfoteamIdpAuthService {
  const InfoteamIdpAuthService(this._config);

  final AuthConfig _config;

  Future<InfoteamAuthorizationCode> authorize() async {
    if (!_config.canUseInfoteamLogin) {
      throw const AuthFlowException('인포팀 client_id가 설정되지 않았습니다.');
    }

    final state = _randomBase64Url(16);
    final verifier = _randomBase64Url(32);
    final challenge = _challengeFor(verifier);
    final authorizeUri = _config.idpAuthorizeUri.replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': _config.idpClientId,
        'redirect_uri': _config.redirectUri,
        'scope': _config.idpScopes.join(' '),
        'state': state,
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
      },
    );

    _logAuthorizeUrl(authorizeUri);
    final callbackUrl = await _openBrowser(authorizeUri);
    _logCallbackUrl(callbackUrl);
    final callbackUri = Uri.parse(callbackUrl);
    final callbackState = callbackUri.queryParameters['state'];
    if (callbackState != state) {
      throw const AuthFlowException('인포팀 로그인 state 검증에 실패했습니다.');
    }

    final error = callbackUri.queryParameters['error'];
    if (error != null && error.isNotEmpty) {
      final description = callbackUri.queryParameters['error_description'];
      final message = description == null || description.isEmpty
          ? '인포팀 로그인이 거절되었습니다. ($error)'
          : '인포팀 로그인이 거절되었습니다. ($error: $description)';
      throw AuthFlowException(message);
    }

    final code = callbackUri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw const AuthFlowException('인포팀 인증 코드를 받지 못했습니다.');
    }

    return InfoteamAuthorizationCode(
      code: code,
      redirectUri: _config.redirectUri,
      codeVerifier: verifier,
    );
  }

  String _challengeFor(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  String _randomBase64Url(int byteLength) {
    final random = Random.secure();
    final bytes = List<int>.generate(byteLength, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  Future<String> _openBrowser(Uri authorizeUri) async {
    try {
      return await FlutterWebAuth2.authenticate(
        url: authorizeUri.toString(),
        callbackUrlScheme: _callbackUrlScheme,
        options: _authOptions,
      );
    } on PlatformException catch (error) {
      throw AuthFlowException(error.message ?? '인포팀 로그인이 취소되었습니다.');
    }
  }

  void _logAuthorizeUrl(Uri authorizeUri) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[Gistag Auth] authorize URL: $authorizeUri');
  }

  void _logCallbackUrl(String callbackUrl) {
    if (!kDebugMode) {
      return;
    }

    final callbackUri = Uri.parse(callbackUrl);
    final safeQuery = Map<String, String>.from(callbackUri.queryParameters);
    if (safeQuery.containsKey('code')) {
      safeQuery['code'] = '<redacted>';
    }
    final safeUri = callbackUri.replace(queryParameters: safeQuery);
    debugPrint('[Gistag Auth] callback URL: $safeUri');
  }

  String get _callbackUrlScheme {
    final redirect = _config.redirectUriValue;
    if (_shouldUseDesktopLoopback(redirect)) {
      return _config.redirectUri;
    }
    return redirect.scheme;
  }

  FlutterWebAuth2Options get _authOptions {
    final redirect = _config.redirectUriValue;
    return FlutterWebAuth2Options(
      useWebview: !_shouldUseDesktopLoopback(redirect),
      httpsHost: redirect.scheme == 'https' ? redirect.host : null,
      httpsPath: redirect.scheme == 'https' ? redirect.path : null,
    );
  }

  bool _shouldUseDesktopLoopback(Uri redirect) {
    if (kIsWeb) {
      return false;
    }
    final isDesktop =
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
    return isDesktop &&
        redirect.scheme == 'http' &&
        (redirect.host == 'localhost' || redirect.host == '127.0.0.1') &&
        redirect.hasPort;
  }
}
