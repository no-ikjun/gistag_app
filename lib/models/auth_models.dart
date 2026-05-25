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

class AuthUser {
  const AuthUser({required this.userId});

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(userId: json['userId'] as String);
  }

  final String userId;
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
