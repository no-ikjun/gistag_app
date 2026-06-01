import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import '../models/user_profile_models.dart';
import '../providers/app_providers.dart';
import '../services/user_profile_api.dart';
import '../widgets/common/app_logo.dart';
import '../widgets/common/gistag_button.dart';
import '../widgets/common/gistag_fixed_bottom_actions.dart';
import '../widgets/common/gistag_header.dart';
import '../widgets/common/selectable_option_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _lastStep = 2;
  static const _genderOptions = [UserGender.male, UserGender.female];

  int _step = 0;
  UserGender? _gender;
  final Set<ExerciseType> _exerciseTypes = {};
  ExerciseFrequency? _exerciseFrequency;
  String? _errorMessage;

  bool get _canContinue {
    return switch (_step) {
      0 => _gender != null,
      1 => _exerciseTypes.isNotEmpty,
      2 => _exerciseFrequency != null,
      _ => false,
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectIfCompleted();
    });
  }

  Future<void> _redirectIfCompleted() async {
    try {
      final profile = await ref
          .read(userProfileControllerProvider.notifier)
          .load();
      if (!mounted) return;
      if (profile.onboardingCompleted) {
        context.go('/home');
      }
    } catch (_) {
      // The submit action below surfaces API failures in the screen.
    }
  }

  Future<void> _continue() async {
    if (!_canContinue) {
      return;
    }

    if (_step < _lastStep) {
      setState(() {
        _step += 1;
        _errorMessage = null;
      });
      return;
    }

    await _submit();
  }

  Future<void> _submit() async {
    final gender = _gender;
    final frequency = _exerciseFrequency;
    if (gender == null || frequency == null || _exerciseTypes.isEmpty) {
      return;
    }

    setState(() => _errorMessage = null);
    try {
      final profile = await ref
          .read(userProfileControllerProvider.notifier)
          .submitOnboarding(
            OnboardingInput(
              gender: gender,
              exerciseTypes: _exerciseTypes.toList(growable: false),
              exerciseFrequency: frequency,
            ),
          );
      if (!mounted) return;
      if (profile.onboardingCompleted) {
        context.go('/home');
      }
    } on UserProfileApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = '온보딩 정보를 저장하지 못했어요. 잠시 후 다시 시도해주세요.');
    }
  }

  void _goBack() {
    if (_step == 0) {
      return;
    }
    setState(() {
      _step -= 1;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileControllerProvider);
    final isSubmitting = profileState.isLoading;
    final title = switch (_step) {
      0 => '성별을 선택해주세요',
      1 => '어떤 운동을 하시나요?',
      2 => '운동 주기를 알려주세요',
      _ => '',
    };
    final subtitle = switch (_step) {
      0 => '운동 장소와 기록 경험을 개인화하는 데 사용됩니다.',
      1 => '관심 있는 운동을 모두 선택할 수 있어요.',
      2 => '현재 루틴에 맞춰 홈 화면을 준비할게요.',
      _ => '',
    };

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
            children: [
              GistagHeader(
                center: const AppLogo(width: 104),
                showBellAction: false,
                automaticallyImplyBack: _step > 0,
                onBackTap: isSubmitting ? null : _goBack,
              ),
              const SizedBox(height: 24),
              _StepIndicator(currentStep: _step, totalSteps: _lastStep + 1),
              const SizedBox(height: 22),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: KeyedSubtree(key: ValueKey(_step), child: _stepBody()),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: GistagColors.primary),
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: GistagFixedBottomActions(
          children: [
            GistagButton(
              label: isSubmitting
                  ? '저장 중...'
                  : _step == _lastStep
                  ? '저장하고 시작하기'
                  : '다음',
              onPressed: !isSubmitting && _canContinue ? _continue : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBody() {
    return switch (_step) {
      0 => _OptionList(
        children: [
          for (final gender in _genderOptions)
            SelectableOptionCard(
              label: gender.label,
              selected: _gender == gender,
              onTap: () => setState(() => _gender = gender),
            ),
        ],
      ),
      1 => _OptionList(
        children: [
          for (final exerciseType in ExerciseType.values)
            SelectableOptionCard(
              label: exerciseType.label,
              selected: _exerciseTypes.contains(exerciseType),
              onTap: () {
                setState(() {
                  if (!_exerciseTypes.add(exerciseType)) {
                    _exerciseTypes.remove(exerciseType);
                  }
                });
              },
            ),
        ],
      ),
      2 => _OptionList(
        children: [
          for (final frequency in ExerciseFrequency.values)
            SelectableOptionCard(
              label: frequency.label,
              selected: _exerciseFrequency == frequency,
              onTap: () => setState(() => _exerciseFrequency = frequency),
            ),
        ],
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < totalSteps; index++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 6,
              decoration: BoxDecoration(
                color: index <= currentStep
                    ? GistagColors.primary
                    : const Color(0xFFFFE4E0),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          if (index != totalSteps - 1) const SizedBox(width: 7),
        ],
      ],
    );
  }
}

class _OptionList extends StatelessWidget {
  const _OptionList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
