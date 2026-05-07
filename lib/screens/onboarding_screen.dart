import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_theme.dart';
import '../models/gistag_models.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_logo.dart';
import '../widgets/common/gistag_button.dart';
import '../widgets/common/selectable_option_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  String? _gender;
  final Set<String> _workoutTypes = {};
  String? _frequency;

  bool get _canContinue {
    return switch (_step) {
      0 => _gender != null,
      1 => _workoutTypes.isNotEmpty,
      _ => _frequency != null,
    };
  }

  Future<void> _continue() async {
    if (!_canContinue) {
      return;
    }

    if (_step < 2) {
      setState(() => _step += 1);
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .completeOnboarding(
          OnboardingProfile(
            gender: _gender!,
            workoutTypes: _workoutTypes.toList(),
            workoutFrequency: _frequency!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final saving = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            children: [
              const AppLogo(width: 116),
              const SizedBox(height: 34),
              Text(
                _title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(child: _buildStep()),
              _StepIndicator(current: _step),
              const SizedBox(height: 18),
              GistagButton(
                label: saving ? '저장 중...' : '다음',
                onPressed: _canContinue && !saving ? _continue : null,
              ),
              if (authState.hasError) ...[
                const SizedBox(height: 12),
                const Text(
                  '온보딩 저장에 실패했어요. 다시 시도해주세요.',
                  style: TextStyle(color: GistagColors.primary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get _title {
    return switch (_step) {
      0 => '성별을 선택해주세요',
      1 => '어떤 운동을 주로 하시나요?',
      _ => '운동 주기를 알려주세요',
    };
  }

  Widget _buildStep() {
    if (_step == 0) {
      return _OptionList(
        children: [
          SelectableOptionCard(
            label: '남성',
            selected: _gender == '남성',
            onTap: () => setState(() => _gender = '남성'),
          ),
          SelectableOptionCard(
            label: '여성',
            selected: _gender == '여성',
            onTap: () => setState(() => _gender = '여성'),
          ),
        ],
      );
    }

    if (_step == 1) {
      final options = ['헬스', '러닝', '요가/필라테스', '수영', '기타'];
      return _OptionList(
        children: [
          for (final option in options)
            SelectableOptionCard(
              label: option,
              selected: _workoutTypes.contains(option),
              onTap: () {
                setState(() {
                  if (_workoutTypes.contains(option)) {
                    _workoutTypes.remove(option);
                  } else {
                    _workoutTypes.add(option);
                  }
                });
              },
            ),
        ],
      );
    }

    final options = ['매일', '주 3~4회', '주 1~2회', '거의 안함'];
    return _OptionList(
      children: [
        for (final option in options)
          SelectableOptionCard(
            label: option,
            selected: _frequency == option,
            onTap: () => setState(() => _frequency = option),
          ),
      ],
    );
  }
}

class _OptionList extends StatelessWidget {
  const _OptionList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => children[index],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < 3; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: current == index ? 22 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: current == index
                  ? GistagColors.primary
                  : const Color(0xFFFFD8D5),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}
