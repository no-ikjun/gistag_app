import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/common/gistag_header.dart';
import '../widgets/common/gistag_pressable.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final userId = auth.maybeWhen(
      data: (session) => session.user?.userId,
      orElse: () => null,
    );
    final canLogout = !_isLoggingOut && !auth.isLoading;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
          children: [
            GistagHeader(
              centerTitle: true,
              showBellAction: false,
              center: Text('설정', style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 12),
            Text(
              '계정',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  icon: Icons.badge_outlined,
                  title: '사용자 ID',
                  subtitle: userId ?? '인증된 사용자 정보를 확인하고 있어요.',
                ),
                const _SettingsDivider(),
                _SettingsRow(
                  icon: Icons.verified_user_outlined,
                  title: '인증 상태',
                  subtitle: auth.isLoading ? '확인 중' : '로그인됨',
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              '세션',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  icon: Icons.logout_rounded,
                  title: _isLoggingOut ? '로그아웃 중' : '로그아웃',
                  subtitle: '현재 기기에 저장된 인증 정보를 삭제합니다.',
                  destructive: true,
                  enabled: canLogout,
                  onTap: _confirmLogout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    if (_isLoggingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('로그아웃할까요?'),
          content: const Text('현재 기기에서 로그아웃하고 저장된 인증 정보를 삭제합니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: GistagColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isLoggingOut = true);
    try {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) context.go('/login');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃하지 못했어요. 잠시 후 다시 시도해주세요.')),
      );
    }
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GistagColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GistagColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.destructive = false,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool destructive;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = destructive
        ? GistagColors.primaryDark
        : GistagColors.text;
    final iconColor = destructive ? GistagColors.primary : GistagColors.text;
    final opacity = enabled ? 1.0 : 0.45;

    return GistagPressable(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Opacity(
        opacity: opacity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: destructive
                      ? GistagColors.primarySoft.withValues(alpha: 0.42)
                      : const Color(0xFFF5F1F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: titleColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: GistagColors.mutedText,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 10),
                Icon(
                  Icons.chevron_right_rounded,
                  color: destructive
                      ? GistagColors.primary
                      : GistagColors.mutedText,
                  size: 26,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 74),
      child: Divider(height: 1, thickness: 1, color: GistagColors.border),
    );
  }
}
