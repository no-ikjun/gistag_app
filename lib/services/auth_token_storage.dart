import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_models.dart';

abstract class AuthTokenStorage {
  Future<AuthTokens?> read();

  Future<void> write(AuthTokens tokens);

  Future<void> clear();
}

class SecureAuthTokenStorage implements AuthTokenStorage {
  SecureAuthTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokensKey = 'gistag.auth.tokens';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthTokens?> read() async {
    final raw = await _storage.read(key: _tokensKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      await clear();
      return null;
    }

    return AuthTokens.fromJson(decoded);
  }

  @override
  Future<void> write(AuthTokens tokens) {
    return _storage.write(key: _tokensKey, value: jsonEncode(tokens.toJson()));
  }

  @override
  Future<void> clear() {
    return _storage.delete(key: _tokensKey);
  }
}
