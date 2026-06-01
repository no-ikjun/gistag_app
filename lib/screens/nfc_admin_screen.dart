import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import '../providers/app_providers.dart';
import '../services/gistag_nfc_service.dart';
import '../services/nfc_payload_parser.dart';
import '../widgets/common/gistag_button.dart';
import '../widgets/common/gistag_header.dart';

class NfcAdminScreen extends ConsumerStatefulWidget {
  const NfcAdminScreen({super.key});

  @override
  ConsumerState<NfcAdminScreen> createState() => _NfcAdminScreenState();
}

class _NfcAdminScreenState extends ConsumerState<NfcAdminScreen> {
  final _passwordController = TextEditingController();
  final _tagCodeController = TextEditingController(text: 'GISTAG_TAG_');

  bool _unlocked = false;
  bool _isWriting = false;
  String? _errorMessage;
  GistagNfcTagWrite? _lastWrite;

  @override
  void dispose() {
    _passwordController.dispose();
    _tagCodeController.dispose();
    ref.read(gistagNfcServiceProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminConfig = ref.watch(adminConfigProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
          children: [
            GistagHeader(
              centerTitle: true,
              onBackTap: () => context.go('/home'),
              showBellAction: false,
              center: Text(
                'NFC 태그 등록',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 28),
            if (!adminConfig.canUseNfcAdmin)
              const _AdminNotice(
                icon: Icons.lock_outline_rounded,
                title: '관리자 비밀번호가 설정되지 않았어요',
                message: '.env에 GISTAG_NFC_ADMIN_PASSWORD 값을 추가하면 사용할 수 있어요.',
              )
            else if (!_unlocked)
              _PasswordPanel(
                controller: _passwordController,
                errorMessage: _errorMessage,
                onSubmit: _unlock,
              )
            else
              _TagWritePanel(
                controller: _tagCodeController,
                isWriting: _isWriting,
                errorMessage: _errorMessage,
                lastWrite: _lastWrite,
                onWrite: _writeTag,
              ),
          ],
        ),
      ),
    );
  }

  void _unlock() {
    final config = ref.read(adminConfigProvider);
    setState(() {
      if (config.matchesPassword(_passwordController.text)) {
        _unlocked = true;
        _errorMessage = null;
      } else {
        _errorMessage = '비밀번호가 맞지 않습니다.';
      }
    });
  }

  Future<void> _writeTag() async {
    final tagCode = _tagCodeController.text.trim();
    try {
      parseGistagTagCode(tagCode);
    } on NfcPayloadFormatException {
      setState(() {
        _errorMessage = 'GISTAG_TAG_로 시작하는 태그 코드를 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isWriting = true;
      _errorMessage = null;
      _lastWrite = null;
    });

    try {
      final result = await ref
          .read(gistagNfcServiceProvider)
          .writeTag(tagCode: tagCode);
      if (!mounted) {
        return;
      }
      setState(() {
        _lastWrite = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error is GistagNfcException
            ? error.message
            : '태그 등록 중 오류가 발생했어요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isWriting = false;
        });
      }
    }
  }
}

class _PasswordPanel extends StatelessWidget {
  const _PasswordPanel({
    required this.controller,
    required this.onSubmit,
    this.errorMessage,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      icon: Icons.admin_panel_settings_rounded,
      title: '관리자 확인',
      subtitle: '태그 등록 도구는 관리자만 사용할 수 있습니다.',
      children: [
        TextField(
          controller: controller,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          decoration: _inputDecoration('관리자 비밀번호'),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 10),
          _InlineMessage(message: errorMessage!, isError: true),
        ],
        const SizedBox(height: 16),
        GistagButton(label: '열기', onPressed: onSubmit),
      ],
    );
  }
}

class _TagWritePanel extends StatelessWidget {
  const _TagWritePanel({
    required this.controller,
    required this.isWriting,
    required this.onWrite,
    this.errorMessage,
    this.lastWrite,
  });

  final TextEditingController controller;
  final bool isWriting;
  final VoidCallback onWrite;
  final String? errorMessage;
  final GistagNfcTagWrite? lastWrite;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      icon: Icons.nfc_rounded,
      title: '물리 태그 쓰기',
      subtitle: '태그 코드를 입력한 뒤 NFC 태그를 휴대폰 뒷면에 가까이 대세요.',
      children: [
        TextField(
          controller: controller,
          enabled: !isWriting,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!isWriting) {
              onWrite();
            }
          },
          decoration: _inputDecoration('태그 코드'),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            return _PayloadPreview(tagCode: value.text);
          },
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          _InlineMessage(message: errorMessage!, isError: true),
        ],
        if (lastWrite != null) ...[
          const SizedBox(height: 12),
          _InlineMessage(
            message:
                '등록 완료: ${lastWrite!.ndefPayload}'
                '${lastWrite!.hardwareUid == null ? '' : '\nUID: ${lastWrite!.hardwareUid}'}',
          ),
        ],
        const SizedBox(height: 18),
        GistagButton(
          label: isWriting ? '태그를 기다리는 중' : 'NFC 태그 등록',
          onPressed: isWriting ? null : onWrite,
        ),
      ],
    );
  }
}

class _PayloadPreview extends StatelessWidget {
  const _PayloadPreview({required this.tagCode});

  final String tagCode;

  @override
  Widget build(BuildContext context) {
    String payload;
    try {
      payload = buildGistagTagPayload(tagCode);
    } catch (_) {
      payload = 'gistag://tag/{tagCode}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GistagColors.border),
      ),
      child: Text(
        payload,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: GistagColors.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: GistagColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: GistagColors.primarySoft.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: GistagColors.primaryDark),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GistagColors.mutedText,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _AdminNotice extends StatelessWidget {
  const _AdminNotice({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      icon: icon,
      title: title,
      subtitle: message,
      children: const [],
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? GistagColors.primaryDark : GistagColors.success;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String label) {
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
