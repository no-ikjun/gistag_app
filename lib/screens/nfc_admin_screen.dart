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
  final _imageUrlController = TextEditingController();
  final _distanceTextController = TextEditingController();
  final _estimatedDurationController = TextEditingController(text: '60');
  final _sortOrderController = TextEditingController(text: '0');
  final _technologiesController = TextEditingController();
  final _ndefPayloadController = TextEditingController();
  final _ndefTypeController = TextEditingController();
  final _maxSizeBytesController = TextEditingController();
  final _hardwareUidHashController = TextEditingController();

  bool _unlocked = false;
  bool _isRegistering = false;
  bool _isInspecting = false;
  bool? _isRecommended = true;
  bool? _isWritable;
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
    _imageUrlController.dispose();
    _distanceTextController.dispose();
    _estimatedDurationController.dispose();
    _sortOrderController.dispose();
    _technologiesController.dispose();
    _ndefPayloadController.dispose();
    _ndefTypeController.dispose();
    _maxSizeBytesController.dispose();
    _hardwareUidHashController.dispose();
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
                imageUrlController: _imageUrlController,
                distanceTextController: _distanceTextController,
                estimatedDurationController: _estimatedDurationController,
                sortOrderController: _sortOrderController,
                technologiesController: _technologiesController,
                ndefPayloadController: _ndefPayloadController,
                ndefTypeController: _ndefTypeController,
                maxSizeBytesController: _maxSizeBytesController,
                hardwareUidHashController: _hardwareUidHashController,
                isRecommended: _isRecommended,
                isWritable: _isWritable,
                onRecommendedChanged: (value) {
                  setState(() {
                    _isRecommended = value;
                  });
                },
                onWritableChanged: (value) {
                  setState(() {
                    _isWritable = value;
                  });
                },
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
    final metadataDraft = _readMetadataDraft();
    if (placeDraft == null || metadataDraft == null) {
      return;
    }

    setState(() {
      _isRegistering = true;
      _errorMessage = null;
      _lastRegistration = null;
      _lastInspection = null;
    });

    try {
      final tag = await ref.read(gistagNfcServiceProvider).readTag();
      final hardwareUid = tag.hardwareUid;
      if (hardwareUid == null || hardwareUid.isEmpty) {
        throw const GistagNfcException('NFC 태그 UID를 찾지 못했어요.');
      }

      final registration = hardwareUid == 'DEMO-NFC-TAG'
          ? _demoRegistration(
              hardwareUid: hardwareUid,
              ndefPayload: tag.ndefPayload,
              draft: placeDraft,
              metadata: metadataDraft,
            )
          : await ref
                .read(gistagServiceProvider)
                .registerNfcTag(
                  hardwareUid: hardwareUid,
                  place: placeDraft,
                  metadata: _metadataWithReadPayload(
                    metadataDraft,
                    tag.ndefPayload,
                  ),
                );

      if (!mounted) {
        return;
      }
      if (hardwareUid == 'DEMO-NFC-TAG') {
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
        _lastInspection = GistagNfcTagInspection(
          platform: 'nfc',
          technologies: const [],
          supportsNdef: tag.ndefPayload != null,
          canFormatNdef: false,
          hardwareUid: hardwareUid,
          ndefPayload: tag.ndefPayload,
        );
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
    final latitude = _parseOptionalDouble(_latitudeController.text);
    final longitude = _parseOptionalDouble(_longitudeController.text);
    final estimatedDuration = _parseOptionalInt(
      _estimatedDurationController.text,
    );
    final sortOrder = _parseOptionalInt(_sortOrderController.text);
    if (name.isEmpty) {
      setState(() {
        _errorMessage = '장소명을 입력해주세요.';
      });
      return null;
    }
    if ((latitude != null && (latitude < -90 || latitude > 90)) ||
        (longitude != null && (longitude < -180 || longitude > 180))) {
      setState(() {
        _errorMessage = '위도/경도를 올바른 숫자로 입력해주세요.';
      });
      return null;
    }
    if (_hasInvalidNumber(_latitudeController.text, latitude) ||
        _hasInvalidNumber(_longitudeController.text, longitude) ||
        _hasInvalidNumber(
          _estimatedDurationController.text,
          estimatedDuration,
        ) ||
        _hasInvalidNumber(_sortOrderController.text, sortOrder)) {
      setState(() {
        _errorMessage = '숫자 입력값을 확인해주세요.';
      });
      return null;
    }
    if (estimatedDuration != null && estimatedDuration < 0) {
      setState(() {
        _errorMessage = '예상 운동 시간은 0 이상이어야 합니다.';
      });
      return null;
    }

    return NfcTagPlaceDraft(
      name: name,
      description: _optionalText(description),
      workoutType: _optionalText(workoutType),
      latitude: latitude,
      longitude: longitude,
      imageUrl: _optionalText(_imageUrlController.text),
      distanceText: _optionalText(_distanceTextController.text),
      estimatedDurationMinutes: estimatedDuration,
      sortOrder: sortOrder,
      isRecommended: _isRecommended,
    );
  }

  NfcTagMetadataDraft? _readMetadataDraft() {
    final maxSizeBytes = _parseOptionalInt(_maxSizeBytesController.text);
    if (_hasInvalidNumber(_maxSizeBytesController.text, maxSizeBytes)) {
      setState(() {
        _errorMessage = '태그 최대 용량을 올바른 숫자로 입력해주세요.';
      });
      return null;
    }
    if (maxSizeBytes != null && (maxSizeBytes < 0 || maxSizeBytes > 65535)) {
      setState(() {
        _errorMessage = '태그 최대 용량은 0~65535 사이여야 합니다.';
      });
      return null;
    }

    return NfcTagMetadataDraft(
      technologies: _parseTechnologies(_technologiesController.text),
      ndefPayload: _optionalText(_ndefPayloadController.text),
      ndefType: _optionalText(_ndefTypeController.text),
      isWritable: _isWritable,
      maxSizeBytes: maxSizeBytes,
      hardwareUidHash: _optionalText(_hardwareUidHashController.text),
    );
  }

  NfcTagMetadataDraft _metadataWithReadPayload(
    NfcTagMetadataDraft metadata,
    String? readPayload,
  ) {
    return NfcTagMetadataDraft(
      technologies: metadata.technologies,
      ndefPayload: metadata.ndefPayload ?? readPayload,
      ndefType: metadata.ndefType,
      isWritable: metadata.isWritable,
      maxSizeBytes: metadata.maxSizeBytes,
      hardwareUidHash: metadata.hardwareUidHash,
    );
  }

  double? _parseOptionalDouble(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return double.tryParse(trimmed);
  }

  int? _parseOptionalInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return int.tryParse(trimmed);
  }

  bool _hasInvalidNumber<T extends num>(String raw, T? parsed) {
    return raw.trim().isNotEmpty && parsed == null;
  }

  List<String> _parseTechnologies(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String? _optionalText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _fillMetadataFromInspection(GistagNfcTagInspection inspection) {
    _technologiesController.text = inspection.technologies
        .where((item) => item != 'Unknown')
        .join(', ');
    if (inspection.ndefPayload != null) {
      _ndefPayloadController.text = inspection.ndefPayload!;
      _ndefTypeController.text = 'URI';
    }
    if (inspection.ndefWritable != null) {
      _isWritable = inspection.ndefWritable;
    }
    if (inspection.ndefMaxSize != null) {
      _maxSizeBytesController.text = inspection.ndefMaxSize.toString();
    }
  }

  NfcTagRegistration _demoRegistration({
    required String hardwareUid,
    required NfcTagPlaceDraft draft,
    required NfcTagMetadataDraft metadata,
    String? ndefPayload,
  }) {
    final registeredPlace = Place(
      id: 'demo-$hardwareUid',
      name: draft.name,
      description: draft.description ?? '',
      workoutType: draft.workoutType ?? '운동',
      distance: '0m',
      latitude: draft.latitude,
      longitude: draft.longitude,
      imageUrl: draft.imageUrl,
      distanceText: draft.distanceText ?? '시연 모드',
      estimatedDurationMinutes: draft.estimatedDurationMinutes,
      distanceKm: 0,
    );
    return NfcTagRegistration(
      tag: NfcTag(id: 0, code: hardwareUid, status: 'ACTIVE'),
      place: registeredPlace,
      hardwareUid: hardwareUid,
      technologies: metadata.technologies,
      ndefPayload: metadata.ndefPayload ?? ndefPayload,
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
        _fillMetadataFromInspection(result);
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
        GistagButton(
          label: '열기',
          onPressed: onSubmit,
          analyticsId: 'admin_unlock_submit',
          analyticsActionType: 'submit',
        ),
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
    required this.imageUrlController,
    required this.distanceTextController,
    required this.estimatedDurationController,
    required this.sortOrderController,
    required this.technologiesController,
    required this.ndefPayloadController,
    required this.ndefTypeController,
    required this.maxSizeBytesController,
    required this.hardwareUidHashController,
    required this.onRecommendedChanged,
    required this.onWritableChanged,
    required this.isRegistering,
    required this.isInspecting,
    required this.onRegister,
    required this.onInspect,
    this.isRecommended,
    this.isWritable,
    this.errorMessage,
    this.lastRegistration,
    this.lastInspection,
  });

  final TextEditingController placeNameController;
  final TextEditingController descriptionController;
  final TextEditingController workoutTypeController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final TextEditingController imageUrlController;
  final TextEditingController distanceTextController;
  final TextEditingController estimatedDurationController;
  final TextEditingController sortOrderController;
  final TextEditingController technologiesController;
  final TextEditingController ndefPayloadController;
  final TextEditingController ndefTypeController;
  final TextEditingController maxSizeBytesController;
  final TextEditingController hardwareUidHashController;
  final ValueChanged<bool?> onRecommendedChanged;
  final ValueChanged<bool?> onWritableChanged;
  final bool isRegistering;
  final bool isInspecting;
  final bool? isRecommended;
  final bool? isWritable;
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
          decoration: _inputDecoration('장소명 *'),
        ),
        const SizedBox(height: 14),
        _SectionLabel(text: '장소 기본 정보'),
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
                decoration: _inputDecoration('경도'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionLabel(text: '장소 표시 옵션'),
        const SizedBox(height: 10),
        TextField(
          controller: imageUrlController,
          enabled: !isRegistering,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration('이미지 URL'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: distanceTextController,
          enabled: !isRegistering,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration('거리 안내 문구'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: estimatedDurationController,
                enabled: !isRegistering,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration('예상 시간(분)'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: sortOrderController,
                enabled: !isRegistering,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration('정렬 순서'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _NullableBoolField(
          label: '추천 장소',
          value: isRecommended,
          enabled: !isRegistering,
          onChanged: onRecommendedChanged,
        ),
        const SizedBox(height: 14),
        _SectionLabel(text: '태그 메타데이터'),
        const SizedBox(height: 10),
        TextField(
          controller: technologiesController,
          enabled: !isRegistering,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration('기술 목록 (쉼표 구분)'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: ndefPayloadController,
          enabled: !isRegistering,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration('NDEF payload'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ndefTypeController,
                enabled: !isRegistering,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration('NDEF 타입'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: maxSizeBytesController,
                enabled: !isRegistering,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration('최대 용량(bytes)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: hardwareUidHashController,
          enabled: !isRegistering,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!isRegistering && !isInspecting) {
              onRegister();
            }
          },
          decoration: _inputDecoration('UID hash'),
        ),
        const SizedBox(height: 10),
        _NullableBoolField(
          label: 'NDEF 쓰기 가능',
          value: isWritable,
          enabled: !isRegistering,
          onChanged: onWritableChanged,
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
          analyticsId: 'admin_nfc_tag_register',
          analyticsActionType: 'submit',
        ),
        const SizedBox(height: 10),
        GistagButton(
          label: isInspecting ? '태그 확인 중' : '태그 종류 진단',
          onPressed: isRegistering || isInspecting ? null : onInspect,
          backgroundColor: Colors.white,
          foregroundColor: GistagColors.text,
          analyticsId: 'admin_nfc_tag_inspect',
          analyticsActionType: 'submit',
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: GistagColors.primaryDark,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _NullableBoolField extends StatelessWidget {
  const _NullableBoolField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final bool? value;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<bool?>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      items: const [
        DropdownMenuItem<bool?>(value: null, child: Text('미지정')),
        DropdownMenuItem<bool?>(value: true, child: Text('예')),
        DropdownMenuItem<bool?>(value: false, child: Text('아니오')),
      ],
      onChanged: enabled ? onChanged : null,
      decoration: _inputDecoration(label),
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
      (
        'Gistag payload',
        inspection.ndefPayload ??
            (inspection.ndefReadError == null ? '-' : '없음'),
      ),
      if (inspection.ndefReadError != null)
        ('payload 상태', inspection.ndefReadError!),
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
