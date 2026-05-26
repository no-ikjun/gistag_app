import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';

class AuthApi {
  const AuthApi(this._dio);

  final Dio _dio;

  Future<AuthTokens> register({
    required String email,
    required String password,
    required String nickname,
  }) {
    return _postTokens(
      '/auth/register',
      data: {'email': email, 'password': password, 'nickname': nickname},
    );
  }

  Future<AuthTokens> login({required String email, required String password}) {
    return _postTokens(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
  }

  Future<AuthTokens> exchangeInfoteamCode({
    required String code,
    required String redirectUri,
    required String codeVerifier,
  }) {
    _debugLog(
      'POST /auth/infoteam/token redirectUri=$redirectUri '
      'code=<redacted> codeVerifierLength=${codeVerifier.length}',
    );
    return _postTokens(
      '/auth/infoteam/token',
      data: {
        'code': code,
        'redirectUri': redirectUri,
        'codeVerifier': codeVerifier,
      },
    );
  }

  Future<AuthTokens> refresh(String refreshToken) {
    return _postTokens('/auth/refresh', data: {'refreshToken': refreshToken});
  }

  Future<void> logout(String refreshToken) async {
    await _request(
      () => _dio.post<dynamic>(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
        options: Options(extra: const {'skipAuth': true}),
      ),
    );
  }

  Future<AuthUser> me(String accessToken) async {
    final response = await _request(
      () => _dio.get<dynamic>(
        '/auth/me',
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
          extra: const {'skipAuth': true},
        ),
      ),
    );
    return AuthUser.fromJson(_asJsonObject(response.data));
  }

  Future<AuthTokens> _postTokens(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    final response = await _request(
      () => _dio.post<dynamic>(
        path,
        data: data,
        options: Options(extra: const {'skipAuth': true}),
      ),
    );
    return AuthTokens.fromJson(_asJsonObject(response.data));
  }

  Future<Response<T>> _request<T>(
    Future<Response<T>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw _toAuthApiException(error);
    }
  }

  Map<String, dynamic> _asJsonObject(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    throw const AuthApiException('서버 응답 형식이 올바르지 않습니다.');
  }

  AuthApiException _toAuthApiException(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final message = _extractMessage(data) ?? _fallbackMessage(statusCode);
    _debugLog(
      'Auth API error status=$statusCode path=${error.requestOptions.path} '
      'message=$message',
    );
    return AuthApiException(message, statusCode: statusCode);
  }

  String? _extractMessage(Object? data) {
    if (data is! Map) {
      return null;
    }

    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }
    if (message is List && message.isNotEmpty) {
      return message.map((value) => value.toString()).join('\n');
    }
    return null;
  }

  String _fallbackMessage(int? statusCode) {
    return switch (statusCode) {
      400 => '입력값을 다시 확인해주세요.',
      401 => '인증 정보가 올바르지 않거나 만료되었습니다.',
      409 => '이미 등록된 이메일입니다.',
      _ => '인증 서버와 통신하지 못했습니다.',
    };
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[Gistag Auth] $message');
    }
  }
}
