import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_theme.dart';
import '../../models/auth_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/gistag_button.dart';
import '../../widgets/common/gistag_pressable.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider.notifier)
        .loginWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  Future<void> _loginWithInfoteam() async {
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).loginWithInfoteam();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final authConfig = ref.watch(authConfigProvider);
    final loading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 54, 28, 28),
          children: [
            const AppLogo(width: 132),
            const SizedBox(height: 28),
            Text(
              'Gistag 로그인',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '이메일 계정이나 인포팀 계정으로 계속하세요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 30),
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
                      controller: _passwordController,
                      enabled: !loading,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      decoration: _fieldDecoration('비밀번호').copyWith(
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
                          _loginWithEmail();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _EmailLoginButton(
              label: loading ? '로그인 중...' : '이메일로 로그인',
              onPressed: loading ? null : _loginWithEmail,
            ),
            if (authState.hasError) ...[
              const SizedBox(height: 12),
              Text(
                _authErrorMessage(authState.error!),
                textAlign: TextAlign.center,
                style: const TextStyle(color: GistagColors.primary),
              ),
            ],
            const SizedBox(height: 14),
            TextButton(
              onPressed: loading ? null : () => context.go('/register'),
              style: TextButton.styleFrom(
                foregroundColor: GistagColors.mutedText,
                textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('계정 만들기'),
            ),
            const SizedBox(height: 48),
            const _LoginDivider(label: '간편 로그인'),
            const SizedBox(height: 18),
            GistagButton(
              label: '인포팀 계정으로 계속하기',
              onPressed: loading || !authConfig.canUseInfoteamLogin
                  ? null
                  : _loginWithInfoteam,
              icon: const Icon(Icons.account_circle_rounded, size: 20),
            ),
            if (!authConfig.canUseInfoteamLogin) ...[
              const SizedBox(height: 8),
              const Text(
                'GISTAG_IDP_CLIENT_ID가 앱에 주입되지 않았어요. .env 저장 후 flutter run --dart-define-from-file=.env로 다시 실행해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: GistagColors.mutedText, fontSize: 12),
              ),
            ],
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

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) {
      return '비밀번호를 입력해주세요.';
    }
    return null;
  }

  String _authErrorMessage(Object error) {
    return switch (error) {
      AuthApiException(:final message) => message,
      AuthFlowException(:final message) => message,
      _ => '로그인에 실패했습니다. 다시 시도해주세요.',
    };
  }
}

class _EmailLoginButton extends StatelessWidget {
  const _EmailLoginButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = enabled ? GistagColors.text : GistagColors.mutedText;
    final borderColor = enabled ? GistagColors.border : GistagColors.border;

    return SizedBox(
      width: double.infinity,
      child: GistagPressable(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 52,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: enabled
                ? GistagColors.surface.withValues(alpha: 0.72)
                : const Color(0xFFF4EEEE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginDivider extends StatelessWidget {
  const _LoginDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: GistagColors.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GistagColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: GistagColors.border, height: 1)),
      ],
    );
  }
}
