import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_theme.dart';
import '../../models/auth_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/gistag_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider.notifier)
        .registerWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          nickname: _nicknameController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final loading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 42, 28, 28),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: loading ? null : () => context.go('/login'),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Spacer(),
                const AppLogo(width: 112),
              ],
            ),
            const SizedBox(height: 34),
            Text('계정 만들기', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '로컬 이메일/비밀번호 계정을 생성합니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      enabled: !loading,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration('이메일'),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nicknameController,
                      enabled: !loading,
                      autofillHints: const [AutofillHints.nickname],
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration('닉네임'),
                      validator: _validateNickname,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !loading,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      decoration: _fieldDecoration('비밀번호').copyWith(
                        helperText: '8자 이상',
                        suffixIcon: IconButton(
                          onPressed: loading
                              ? null
                              : () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                        ),
                      ),
                      validator: _validatePassword,
                      onFieldSubmitted: (_) {
                        if (!loading) {
                          _register();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            GistagButton(
              label: loading ? '가입 중...' : '가입하고 시작하기',
              onPressed: loading ? null : _register,
            ),
            if (authState.hasError) ...[
              const SizedBox(height: 12),
              Text(
                _authErrorMessage(authState.error!),
                textAlign: TextAlign.center,
                style: const TextStyle(color: GistagColors.primary),
              ),
            ],
            const SizedBox(height: 18),
            TextButton(
              onPressed: loading ? null : () => context.go('/login'),
              child: const Text('이미 계정이 있어요'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: GistagColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: GistagColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: GistagColors.primary, width: 1.4),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return '이메일을 입력해주세요.';
    }
    if (!email.contains('@')) {
      return '이메일 형식을 확인해주세요.';
    }
    return null;
  }

  String? _validateNickname(String? value) {
    if ((value?.trim() ?? '').isEmpty) {
      return '닉네임을 입력해주세요.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 8) {
      return '비밀번호는 8자 이상이어야 합니다.';
    }
    return null;
  }

  String _authErrorMessage(Object error) {
    return switch (error) {
      AuthApiException(:final message) => message,
      AuthFlowException(:final message) => message,
      _ => '회원가입에 실패했습니다. 다시 시도해주세요.',
    };
  }
}
