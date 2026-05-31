import 'package:dio/dio.dart';

import '../models/user_profile_models.dart';

class UserProfileApi {
  const UserProfileApi(this._dio);

  final Dio _dio;

  Future<UserProfile> fetchProfile() async {
    final response = await _request(() => _dio.get<dynamic>('/users/profile'));
    return UserProfile.fromJson(_asJsonObject(response.data));
  }

  Future<UserProfile> submitOnboarding(OnboardingInput input) async {
    final response = await _request(
      () => _dio.post<dynamic>('/users/onboarding', data: input.toJson()),
    );
    return UserProfile.fromJson(_asJsonObject(response.data));
  }

  Future<UserProfile> updateProfile({
    UserGender? gender,
    List<ExerciseType>? exerciseTypes,
    ExerciseFrequency? exerciseFrequency,
  }) async {
    final data = <String, dynamic>{
      if (gender != null) 'gender': gender.apiValue,
      if (exerciseTypes != null)
        'exerciseTypes': [for (final item in exerciseTypes) item.apiValue],
      if (exerciseFrequency != null)
        'exerciseFrequency': exerciseFrequency.apiValue,
    };

    final response = await _request(
      () => _dio.patch<dynamic>('/users/profile', data: data),
    );
    return UserProfile.fromJson(_asJsonObject(response.data));
  }

  Future<Response<T>> _request<T>(
    Future<Response<T>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw _toUserProfileApiException(error);
    } on FormatException catch (error) {
      throw UserProfileApiException(error.message);
    }
  }

  Map<String, dynamic> _asJsonObject(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw const UserProfileApiException('서버 응답 형식이 올바르지 않습니다.');
  }

  UserProfileApiException _toUserProfileApiException(DioException error) {
    final statusCode = error.response?.statusCode;
    final message =
        _extractMessage(error.response?.data) ?? _fallbackMessage(statusCode);
    return UserProfileApiException(message, statusCode: statusCode);
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
    final error = data['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error;
    }
    return null;
  }

  String _fallbackMessage(int? statusCode) {
    return switch (statusCode) {
      400 => '입력값을 다시 확인해주세요.',
      401 => '인증 정보가 올바르지 않거나 만료되었습니다.',
      404 => '온보딩 정보가 아직 없습니다.',
      409 => '이미 온보딩이 완료되었습니다.',
      _ => '프로필 정보를 처리하지 못했습니다.',
    };
  }
}

class UserProfileApiException implements Exception {
  const UserProfileApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
