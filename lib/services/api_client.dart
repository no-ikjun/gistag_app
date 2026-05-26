import 'package:dio/dio.dart';

import '../config/auth_config.dart';
import 'auth_token_manager.dart';

class ApiClient {
  ApiClient({
    required AuthConfig config,
    required AuthTokenManager tokenManager,
  }) {
    final client = Dio(_baseOptions(config));
    client.interceptors.add(
      AuthRefreshInterceptor(dio: client, tokens: tokenManager),
    );
    dio = client;
  }

  late final Dio dio;

  static BaseOptions _baseOptions(AuthConfig config) {
    return BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
  }
}

class AuthRefreshInterceptor extends QueuedInterceptor {
  AuthRefreshInterceptor({required Dio dio, required AuthTokenManager tokens})
    : _dio = dio,
      _tokens = tokens;

  static const skipAuthKey = 'skipAuth';
  static const retryKey = 'authRetried';

  final Dio _dio;
  final AuthTokenManager _tokens;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] == true) {
      handler.next(options);
      return;
    }

    final accessToken = await _tokens.accessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final shouldRefresh =
        err.response?.statusCode == 401 &&
        request.extra[skipAuthKey] != true &&
        request.extra[retryKey] != true;

    if (!shouldRefresh) {
      handler.next(err);
      return;
    }

    try {
      final refreshed = await _tokens.refresh();
      if (refreshed == null) {
        handler.next(err);
        return;
      }

      final retryOptions = request.copyWith(
        headers: {
          ...request.headers,
          'Authorization': refreshed.authorizationHeader,
        },
        extra: {...request.extra, retryKey: true},
      );
      final response = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }
}

Dio createAuthDio(AuthConfig config) {
  return Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
}
