import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/gistag_button.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final loading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 72, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLogo(width: 132),
              const SizedBox(height: 26),
              Text(
                '운동의 시작을 더 쉽게.\n태그 한 번으로 시작하세요.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 14),
              Text(
                '꾸준한 운동 습관을 만드는\n가장 짧고 직관적인 루틴',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              GistagButton(
                label: loading ? '로그인 중...' : '카카오로 시작',
                onPressed: loading
                    ? null
                    : () => ref
                          .read(authControllerProvider.notifier)
                          .loginWithKakao(),
                backgroundColor: const Color(0xFFFFE812),
                foregroundColor: Colors.black,
                icon: const Icon(Icons.chat_bubble_rounded, size: 18),
              ),
              const SizedBox(height: 12),
              GistagButton(
                label: 'Apple로 로그인',
                onPressed: () {},
                backgroundColor: Colors.black,
                icon: const Icon(Icons.apple_rounded, size: 20),
              ),
              if (authState.hasError) ...[
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    '로그인에 실패했어요. 다시 시도해주세요.',
                    style: TextStyle(color: GistagColors.primary),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  '로그인은 MVP mock 흐름으로 진행됩니다',
                  style: TextStyle(color: GistagColors.mutedText, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
