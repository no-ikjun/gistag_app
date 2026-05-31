import 'auth_models.dart';

enum UserGender {
  male('male', '남성'),
  female('female', '여성'),
  other('other', '기타'),
  undisclosed('undisclosed', '응답 안 함');

  const UserGender(this.apiValue, this.label);

  factory UserGender.fromJson(String value) {
    return UserGender.values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => throw FormatException('Unknown gender: $value'),
    );
  }

  final String apiValue;
  final String label;
}

enum ExerciseType {
  gym('gym', '헬스'),
  running('running', '러닝'),
  yogaPilates('yoga_pilates', '요가/필라테스'),
  swimming('swimming', '수영'),
  other('other', '기타');

  const ExerciseType(this.apiValue, this.label);

  factory ExerciseType.fromJson(String value) {
    return ExerciseType.values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => throw FormatException('Unknown exercise type: $value'),
    );
  }

  final String apiValue;
  final String label;
}

enum ExerciseFrequency {
  daily('daily', '매일'),
  threeFourPerWeek('3_4_per_week', '주 3~4회'),
  oneTwoPerWeek('1_2_per_week', '주 1~2회'),
  rarely('rarely', '거의 안함');

  const ExerciseFrequency(this.apiValue, this.label);

  factory ExerciseFrequency.fromJson(String value) {
    return ExerciseFrequency.values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => throw FormatException('Unknown exercise frequency: $value'),
    );
  }

  final String apiValue;
  final String label;
}

class UserExerciseProfile {
  const UserExerciseProfile({
    required this.gender,
    required this.exerciseTypes,
    required this.exerciseFrequency,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserExerciseProfile.fromJson(Map<String, dynamic> json) {
    final exerciseTypes = json['exerciseTypes'];
    if (exerciseTypes is! List) {
      throw const FormatException('exerciseTypes must be a list.');
    }

    return UserExerciseProfile(
      gender: UserGender.fromJson(json['gender'] as String),
      exerciseTypes: [
        for (final item in exerciseTypes) ExerciseType.fromJson(item as String),
      ],
      exerciseFrequency: ExerciseFrequency.fromJson(
        json['exerciseFrequency'] as String,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
    );
  }

  final UserGender gender;
  final List<ExerciseType> exerciseTypes;
  final ExerciseFrequency exerciseFrequency;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get exerciseTypesLabel {
    return exerciseTypes.map((item) => item.label).join(', ');
  }
}

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.nickname,
    required this.providerType,
    required this.onboardingCompleted,
    required this.profile,
    this.email,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final userId = json['userId'] as String;
    final nickname = json['nickname'] as String?;

    return UserProfile(
      userId: userId,
      nickname: nickname == null || nickname.trim().isEmpty
          ? userId
          : nickname.trim(),
      email: json['email'] as String?,
      providerType: AuthProviderType.fromJson(json['providerType'] as String?),
      onboardingCompleted: json['onboardingCompleted'] == true,
      profile: profile == null
          ? null
          : UserExerciseProfile.fromJson(Map<String, dynamic>.from(profile)),
    );
  }

  final String userId;
  final String nickname;
  final String? email;
  final AuthProviderType providerType;
  final bool onboardingCompleted;
  final UserExerciseProfile? profile;
}

class OnboardingInput {
  const OnboardingInput({
    required this.gender,
    required this.exerciseTypes,
    required this.exerciseFrequency,
  });

  final UserGender gender;
  final List<ExerciseType> exerciseTypes;
  final ExerciseFrequency exerciseFrequency;

  Map<String, dynamic> toJson() {
    return {
      'gender': gender.apiValue,
      'exerciseTypes': [for (final item in exerciseTypes) item.apiValue],
      'exerciseFrequency': exerciseFrequency.apiValue,
    };
  }
}
