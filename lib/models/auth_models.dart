class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.tokenType = 'Bearer',
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: (json['expiresIn'] as num).toInt(),
      tokenType: json['tokenType'] as String? ?? 'Bearer',
    );
  }

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
      'tokenType': tokenType,
    };
  }

  String get authorizationHeader => '$tokenType $accessToken';
}

enum AuthProviderType {
  infoteam,
  local,
  unknown;

  factory AuthProviderType.fromJson(String? value) {
    return switch (value) {
      'INFOTEAM' => AuthProviderType.infoteam,
      'LOCAL' => AuthProviderType.local,
      _ => AuthProviderType.unknown,
    };
  }

  String get label {
    return switch (this) {
      AuthProviderType.infoteam => '인포팀 계정',
      AuthProviderType.local => '이메일 계정',
      AuthProviderType.unknown => '알 수 없음',
    };
  }
}

class AuthUser {
  const AuthUser({
    required this.userId,
    required this.nickname,
    required this.providerType,
    this.email,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final userId = json['userId'] as String;
    final nickname = json['nickname'] as String?;

    return AuthUser(
      userId: userId,
      nickname: nickname == null || nickname.trim().isEmpty
          ? userId
          : nickname.trim(),
      email: json['email'] as String?,
      providerType: AuthProviderType.fromJson(json['providerType'] as String?),
    );
  }

  final String userId;
  final String nickname;
  final String? email;
  final AuthProviderType providerType;

  String get emailLabel {
    final value = email?.trim();
    if (value == null || value.isEmpty) {
      return '미연결';
    }
    return value;
  }
}

class InfoteamAuthorizationCode {
  const InfoteamAuthorizationCode({
    required this.code,
    required this.redirectUri,
    required this.codeVerifier,
  });

  final String code;
  final String redirectUri;
  final String codeVerifier;
}

class AuthApiException implements Exception {
  const AuthApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthFlowException implements Exception {
  const AuthFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}
