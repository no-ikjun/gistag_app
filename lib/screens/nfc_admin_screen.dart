import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import '../models/gistag_models.dart';
import '../providers/app_providers.dart';
import '../services/gistag_nfc_service.dart';
import '../widgets/common/gistag_button.dart';
import '../widgets/common/gistag_header.dart';

class NfcAdminScreen extends ConsumerStatefulWidget {
  const NfcAdminScreen({super.key});

  @override
  ConsumerState<NfcAdminScreen> createState() => _NfcAdminScreenState();
}

class _NfcAdminScreenState extends ConsumerState<NfcAdminScreen> {
  final _passwordController = TextEditingController();
  final _placeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _workoutTypeController = TextEditingController(text: '헬스');
  final _latitudeController = TextEditingController(text: '35.2131');
  final _longitudeController = TextEditingController(text: '126.8378');

  bool _unlocked = false;
  bool _isRegistering = false;
  bool _isInspecting = false;
  String? _errorMessage;
  NfcTagRegistration? _lastRegistration;
  GistagNfcTagInspection? _lastInspection;

  @override
  void dispose() {
    _passwordController.dispose();
    _placeNameController.dispose();
    _descriptionController.dispose();
    _workoutTypeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
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
              _TagRegisterPanel(
                placeNameController: _placeNameController,
                descriptionController: _descriptionController,
                workoutTypeController: _workoutTypeController,
                latitudeController: _latitudeController,
                longitudeController: _longitudeController,
                isRegistering: _isRegistering,
                isInspecting: _isInspecting,
                errorMessage: _errorMessage,
                lastRegistration: _lastRegistration,
                lastInspection: _lastInspection,
                onRegister: _registerTag,
                onInspect: _inspectTag,
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

  Future<void> _registerTag() async {
    final placeDraft = _readPlaceDraft();
    if (placeDraft == null) {
      return;
    }

    setState(() {
      _isRegistering = true;
      _errorMessage = null;
      _lastRegistration = null;
      _lastInspection = null;
    });

    try {
      final inspection = await ref.read(gistagNfcServiceProvider).inspectTag();
      final hardwareUid = inspection.hardwareUid;
      if (hardwareUid == null || hardwareUid.isEmpty) {
        throw const GistagNfcException('NFC 태그 UID를 찾지 못했어요.');
      }

      final registration = inspection.platform == 'demo'
          ? _demoRegistration(inspection, placeDraft)
          : await ref
                .read(gistagServiceProvider)
                .registerNfcTag(
                  hardwareUid: hardwareUid,
                  place: placeDraft,
                  technologies: inspection.technologies,
                  ndefPayload: inspection.ndefPayload,
                );

      if (!mounted) {
        return;
      }
      if (inspection.platform == 'demo') {
        ref
            .read(demoNfcTagResolutionProvider.notifier)
            .state = NfcTagResolution(
          tag: registration.tag,
          place: registration.place,
          canStartWorkout: true,
        );
      }
      setState(() {
        _lastRegistration = registration;
        _lastInspection = inspection;
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
          _isRegistering = false;
        });
      }
    }
  }

  NfcTagPlaceDraft? _readPlaceDraft() {
    final name = _placeNameController.text.trim();
    final description = _descriptionController.text.trim();
    final workoutType = _workoutTypeController.text.trim();
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    if (name.isEmpty || workoutType.isEmpty) {
      setState(() {
        _errorMessage = '장소명과 운동 타입을 입력해주세요.';
      });
      return null;
    }
    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      setState(() {
        _errorMessage = '위도/경도를 올바른 숫자로 입력해주세요.';
      });
      return null;
    }

    return NfcTagPlaceDraft(
      name: name,
      description: description,
      workoutType: workoutType,
      latitude: latitude,
      longitude: longitude,
    );
  }

  NfcTagRegistration _demoRegistration(
    GistagNfcTagInspection inspection,
    NfcTagPlaceDraft draft,
  ) {
    final place = Place(
      id: 'demo-${inspection.hardwareUid}',
      name: draft.name,
      description: draft.description,
      workoutType: draft.workoutType,
      distance: '0m',
      latitude: draft.latitude,
      longitude: draft.longitude,
      distanceText: '시연 모드',
      distanceKm: 0,
    );
    return NfcTagRegistration(
      tag: NfcTag(id: 0, code: inspection.hardwareUid!, status: 'ACTIVE'),
      place: place,
      hardwareUid: inspection.hardwareUid!,
      technologies: inspection.technologies,
      ndefPayload: inspection.ndefPayload,
    );
  }

  Future<void> _inspectTag() async {
    setState(() {
      _isInspecting = true;
      _errorMessage = null;
      _lastInspection = null;
      _lastRegistration = null;
    });

    try {
      final result = await ref.read(gistagNfcServiceProvider).inspectTag();
      if (!mounted) {
        return;
      }
      setState(() {
        _lastInspection = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error is GistagNfcException
            ? error.message
            : '태그 진단 중 오류가 발생했어요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInspecting = false;
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

class _TagRegisterPanel extends StatelessWidget {
  const _TagRegisterPanel({
    required this.placeNameController,
    required this.descriptionController,
    required this.workoutTypeController,
    required this.latitudeController,
    required this.longitudeController,
    required this.isRegistering,
    required this.isInspecting,
    required this.onRegister,
    required this.onInspect,
    this.errorMessage,
    this.lastRegistration,
    this.lastInspection,
  });

  final TextEditingController placeNameController;
  final TextEditingController descriptionController;
  final TextEditingController workoutTypeController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final bool isRegistering;
  final bool isInspecting;
  final VoidCallback onRegister;
  final VoidCallback onInspect;
  final String? errorMessage;
  final NfcTagRegistration? lastRegistration;
  final GistagNfcTagInspection? lastInspection;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      icon: Icons.nfc_rounded,
      title: 'NFC 태그 등록',
      subtitle: '장소 정보를 입력한 뒤 NFC 태그를 읽어 서버에 매핑합니다.',
      children: [
        TextField(
          controller: placeNameController,
          enabled: !isRegistering,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration('장소명'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: workoutTypeController,
          enabled: !isRegistering,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration('운동 타입'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: descriptionController,
          enabled: !isRegistering,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration('설명'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: latitudeController,
                enabled: !isRegistering,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration('위도'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: longitudeController,
                enabled: !isRegistering,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!isRegistering && !isInspecting) {
                    onRegister();
                  }
                },
                decoration: _inputDecoration('경도'),
              ),
            ),
          ],
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          _InlineMessage(message: errorMessage!, isError: true),
        ],
        if (lastRegistration != null) ...[
          const SizedBox(height: 12),
          _InlineMessage(
            message:
                '등록 완료: ${lastRegistration!.place.name}'
                '\nUID: ${lastRegistration!.hardwareUid}',
          ),
        ],
        if (lastInspection != null) ...[
          const SizedBox(height: 12),
          _InspectionResult(inspection: lastInspection!),
        ],
        const SizedBox(height: 18),
        GistagButton(
          label: isRegistering ? '태그를 기다리는 중' : 'NFC 태그 읽어서 등록',
          onPressed: isRegistering || isInspecting ? null : onRegister,
        ),
        const SizedBox(height: 10),
        GistagButton(
          label: isInspecting ? '태그 확인 중' : '태그 종류 진단',
          onPressed: isRegistering || isInspecting ? null : onInspect,
          backgroundColor: Colors.white,
          foregroundColor: GistagColors.text,
        ),
      ],
    );
  }
}

class _InspectionResult extends StatelessWidget {
  const _InspectionResult({required this.inspection});

  final GistagNfcTagInspection inspection;

  @override
  Widget build(BuildContext context) {
    final values = [
      ('플랫폼', inspection.platform),
      ('UID', inspection.hardwareUid ?? '-'),
      ('기술', inspection.technologies.join(', ')),
      ('NDEF 지원', inspection.supportsNdef ? '예' : '아니오'),
      ('NDEF 쓰기', _formatNullableBool(inspection.ndefWritable)),
      (
        'NDEF 용량',
        inspection.ndefMaxSize == null
            ? '-'
            : '${inspection.ndefMaxSize} bytes',
      ),
      ('Android 포맷 가능', inspection.canFormatNdef ? '예' : '아니오'),
      ('Gistag payload', inspection.ndefPayload ?? '-'),
      if (inspection.ndefReadError != null)
        ('읽기 오류', inspection.ndefReadError!),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GistagColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '진단 결과',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final entry in values)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '${entry.$1}: ${entry.$2}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: GistagColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatNullableBool(bool? value) {
    return value == null ? '-' : (value ? '예' : '아니오');
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
