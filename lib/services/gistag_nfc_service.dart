import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

import 'nfc_payload_parser.dart';

class GistagNfcException implements Exception {
  const GistagNfcException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GistagNfcTagRead {
  const GistagNfcTagRead({required this.ndefPayload, this.hardwareUid});

  final String? ndefPayload;
  final String? hardwareUid;
}

class GistagNfcTagWrite {
  const GistagNfcTagWrite({
    required this.ndefPayload,
    required this.byteLength,
    this.hardwareUid,
  });

  final String ndefPayload;
  final int byteLength;
  final String? hardwareUid;
}

class GistagNfcTagInspection {
  const GistagNfcTagInspection({
    required this.platform,
    required this.technologies,
    required this.supportsNdef,
    required this.canFormatNdef,
    this.hardwareUid,
    this.ndefWritable,
    this.ndefMaxSize,
    this.ndefPayload,
    this.ndefReadError,
  });

  final String platform;
  final List<String> technologies;
  final bool supportsNdef;
  final bool canFormatNdef;
  final String? hardwareUid;
  final bool? ndefWritable;
  final int? ndefMaxSize;
  final String? ndefPayload;
  final String? ndefReadError;
}

abstract class GistagNfcService {
  Future<NfcAvailability> checkAvailability();

  Future<GistagNfcTagRead> readTag();

  Future<GistagNfcTagWrite> writeTag({required String tagCode});

  Future<GistagNfcTagInspection> inspectTag();

  Future<void> stop();
}

class NfcManagerGistagNfcService implements GistagNfcService {
  NfcManagerGistagNfcService({NfcManager? manager}) : _manager = manager;

  static const _demoHardwareUid = 'DEMO-NFC-TAG';

  final NfcManager? _manager;

  NfcManager get _sessionManager => _manager ?? NfcManager.instance;

  @override
  Future<NfcAvailability> checkAvailability() async {
    if (_demoModeEnabled) {
      return NfcAvailability.enabled;
    }
    if (_isUnsupportedPlatform) {
      return NfcAvailability.unsupported;
    }
    return _sessionManager.checkAvailability();
  }

  @override
  Future<GistagNfcTagRead> readTag() async {
    if (_demoModeEnabled) {
      await _demoDelay();
      return const GistagNfcTagRead(
        ndefPayload: 'gistag://tag/GISTAG_TAG_DEMO_001',
        hardwareUid: _demoHardwareUid,
      );
    }

    return _runSession<GistagNfcTagRead>(
      alertMessageIos: 'Gistag NFC 태그를 가까이 대주세요.',
      timeout: const Duration(seconds: 30),
      onDiscovered: (tag) async {
        final hardwareUid = _readHardwareUid(tag);
        final ndef = Ndef.from(tag);
        if (ndef == null) {
          if (hardwareUid != null) {
            return GistagNfcTagRead(
              hardwareUid: hardwareUid,
              ndefPayload: null,
            );
          }
          throw const GistagNfcException('NFC 태그 식별값을 찾지 못했어요.');
        }

        String? ndefPayload;
        try {
          final message = await ndef.read();
          if (message != null) {
            ndefPayload = readGistagPayloadFromNdefMessage(message);
          }
        } on NfcPayloadFormatException {
          ndefPayload = null;
        }

        if (hardwareUid == null && ndefPayload == null) {
          throw const GistagNfcException('NFC 태그 식별값을 찾지 못했어요.');
        }

        return GistagNfcTagRead(
          ndefPayload: ndefPayload,
          hardwareUid: hardwareUid,
        );
      },
      successMessageIos: '태그를 확인했어요.',
    );
  }

  @override
  Future<GistagNfcTagWrite> writeTag({required String tagCode}) async {
    final message = buildGistagNdefMessage(tagCode);
    final ndefPayload = buildGistagTagPayload(tagCode);
    if (_demoModeEnabled) {
      await _demoDelay();
      return GistagNfcTagWrite(
        ndefPayload: ndefPayload,
        byteLength: message.byteLength,
        hardwareUid: _demoHardwareUid,
      );
    }

    return _runSession<GistagNfcTagWrite>(
      alertMessageIos: '등록할 NFC 태그를 가까이 대주세요.',
      timeout: const Duration(seconds: 30),
      onDiscovered: (tag) async {
        final ndef = Ndef.from(tag);
        if (ndef == null) {
          final formatted = await _formatAndroidTagIfPossible(
            tag: tag,
            message: message,
          );
          if (formatted) {
            return GistagNfcTagWrite(
              ndefPayload: ndefPayload,
              byteLength: message.byteLength,
              hardwareUid: _readHardwareUid(tag),
            );
          }

          throw GistagNfcException(
            '태그는 발견했지만 Gistag 태그로 초기화할 수 없습니다. $_supportedTagHint',
          );
        }
        if (!ndef.isWritable) {
          throw const GistagNfcException('쓰기 잠금 상태인 태그입니다.');
        }
        if (message.byteLength > ndef.maxSize) {
          throw GistagNfcException(
            '태그 용량이 부족합니다. ${message.byteLength}/${ndef.maxSize} bytes',
          );
        }

        await ndef.write(message: message);
        return GistagNfcTagWrite(
          ndefPayload: ndefPayload,
          byteLength: message.byteLength,
          hardwareUid: _readHardwareUid(tag),
        );
      },
      successMessageIos: '태그 등록이 완료됐어요.',
    );
  }

  @override
  Future<GistagNfcTagInspection> inspectTag() async {
    if (_demoModeEnabled) {
      await _demoDelay();
      return const GistagNfcTagInspection(
        platform: 'demo',
        technologies: ['NDEF', 'ISO14443A', 'NTAG213-compatible'],
        supportsNdef: true,
        canFormatNdef: true,
        hardwareUid: _demoHardwareUid,
        ndefWritable: true,
        ndefMaxSize: 144,
        ndefPayload: 'gistag://tag/GISTAG_TAG_DEMO_001',
      );
    }

    return _runSession<GistagNfcTagInspection>(
      alertMessageIos: '확인할 NFC 태그를 가까이 대주세요.',
      timeout: const Duration(seconds: 30),
      onDiscovered: _inspectDiscoveredTag,
      successMessageIos: '태그 정보를 확인했어요.',
    );
  }

  @override
  Future<void> stop() async {
    if (_isUnsupportedPlatform) {
      return;
    }
    await _sessionManager.stopSession();
  }

  Future<T> _runSession<T>({
    required String alertMessageIos,
    required Duration timeout,
    required Future<T> Function(NfcTag tag) onDiscovered,
    required String successMessageIos,
  }) async {
    final availability = await checkAvailability();
    if (availability != NfcAvailability.enabled) {
      throw GistagNfcException(_availabilityMessage(availability));
    }

    final completer = Completer<T>();
    final timer = Timer(timeout, () async {
      if (completer.isCompleted) {
        return;
      }
      await _sessionManager.stopSession(errorMessageIos: 'NFC 태그를 찾지 못했어요.');
      completer.completeError(
        const GistagNfcException('NFC 태그를 찾지 못했어요.'),
        StackTrace.current,
      );
    });

    try {
      await _sessionManager.startSession(
        pollingOptions: _pollingOptions,
        alertMessageIos: alertMessageIos,
        invalidateAfterFirstReadIos: false,
        onSessionErrorIos: (error) {
          if (!completer.isCompleted) {
            completer.completeError(
              GistagNfcException(error.message),
              StackTrace.current,
            );
          }
        },
        onDiscovered: (tag) async {
          if (completer.isCompleted) {
            return;
          }
          try {
            final result = await onDiscovered(tag);
            await _sessionManager.stopSession(
              alertMessageIos: successMessageIos,
            );
            completer.complete(result);
          } catch (error, stackTrace) {
            await _sessionManager.stopSession(
              errorMessageIos: _errorMessage(error),
            );
            completer.completeError(error, stackTrace);
          }
        },
      );
      return await completer.future;
    } catch (error) {
      if (!completer.isCompleted) {
        completer.completeError(error, StackTrace.current);
      }
      return await completer.future;
    } finally {
      timer.cancel();
    }
  }

  bool get _isUnsupportedPlatform {
    return kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS);
  }

  bool get _demoModeEnabled {
    if (dotenv.isInitialized) {
      final value = dotenv.maybeGet('GISTAG_NFC_DEMO_MODE');
      if (value != null) {
        return _isTruthy(value);
      }
    }
    return const bool.fromEnvironment('GISTAG_NFC_DEMO_MODE');
  }

  bool _isTruthy(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  Future<void> _demoDelay() {
    return Future<void>.delayed(const Duration(milliseconds: 650));
  }

  Set<NfcPollingOption> get _pollingOptions {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => const {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      _ => const {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
    };
  }

  String _availabilityMessage(NfcAvailability availability) {
    return switch (availability) {
      NfcAvailability.enabled => 'NFC를 사용할 수 있습니다.',
      NfcAvailability.disabled => '기기 설정에서 NFC를 켜주세요.',
      NfcAvailability.unsupported => '이 기기는 NFC를 지원하지 않습니다.',
    };
  }

  String _errorMessage(Object error) {
    if (error is GistagNfcException) {
      return error.message;
    }
    return 'NFC 처리 중 오류가 발생했어요.';
  }

  Future<bool> _formatAndroidTagIfPossible({
    required NfcTag tag,
    required NdefMessage message,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    final formatable = NdefFormatableAndroid.from(tag);
    if (formatable == null) {
      return false;
    }

    await formatable.format(message);
    return true;
  }

  String get _supportedTagHint {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        'NTAG213/215/216처럼 NDEF 또는 NDEF 포맷 가능 스티커를 사용해주세요.',
      TargetPlatform.iOS => 'iPhone에서는 NDEF 쓰기를 지원하는 NFC 스티커를 사용해주세요.',
      _ => 'NDEF를 지원하는 NFC 스티커를 사용해주세요.',
    };
  }

  Future<GistagNfcTagInspection> _inspectDiscoveredTag(NfcTag tag) async {
    final ndef = Ndef.from(tag);
    String? payload;
    String? readError;

    if (ndef != null) {
      try {
        final message = await ndef.read();
        if (message != null) {
          payload = readGistagPayloadFromNdefMessage(message);
        }
      } catch (error) {
        readError = error is GistagNfcException
            ? error.message
            : error.toString();
      }
    }

    return GistagNfcTagInspection(
      platform: defaultTargetPlatform.name,
      technologies: _readTechnologies(tag),
      hardwareUid: _readHardwareUid(tag),
      supportsNdef: ndef != null,
      canFormatNdef:
          defaultTargetPlatform == TargetPlatform.android &&
          NdefFormatableAndroid.from(tag) != null,
      ndefWritable: ndef?.isWritable,
      ndefMaxSize: ndef?.maxSize,
      ndefPayload: payload,
      ndefReadError: readError,
    );
  }

  List<String> _readTechnologies(NfcTag tag) {
    final androidTag = NfcTagAndroid.from(tag);
    if (androidTag != null) {
      return androidTag.techList;
    }

    final technologies = <String>[
      if (Ndef.from(tag) != null) 'NDEF',
      if (MiFareIos.from(tag) != null) 'MiFare',
      if (Iso7816Ios.from(tag) != null) 'ISO7816',
      if (Iso15693Ios.from(tag) != null) 'ISO15693',
      if (FeliCaIos.from(tag) != null) 'FeliCa',
    ];
    return technologies.isEmpty ? const ['Unknown'] : technologies;
  }

  String? _readHardwareUid(NfcTag tag) {
    final androidTag = NfcTagAndroid.from(tag);
    if (androidTag != null) {
      return _hex(androidTag.id);
    }

    final miFare = MiFareIos.from(tag);
    if (miFare != null) {
      return _hex(miFare.identifier);
    }

    final iso7816 = Iso7816Ios.from(tag);
    if (iso7816 != null) {
      return _hex(iso7816.identifier);
    }

    final iso15693 = Iso15693Ios.from(tag);
    if (iso15693 != null) {
      return _hex(iso15693.identifier);
    }

    final feliCa = FeliCaIos.from(tag);
    if (feliCa != null) {
      return _hex(feliCa.currentIDm);
    }

    return null;
  }

  String _hex(Uint8List bytes) {
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }
}
