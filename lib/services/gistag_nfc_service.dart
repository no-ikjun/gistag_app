import 'dart:async';

import 'package:flutter/foundation.dart';
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

  final String ndefPayload;
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

abstract class GistagNfcService {
  Future<NfcAvailability> checkAvailability();

  Future<GistagNfcTagRead> readTag();

  Future<GistagNfcTagWrite> writeTag({required String tagCode});

  Future<void> stop();
}

class NfcManagerGistagNfcService implements GistagNfcService {
  NfcManagerGistagNfcService({NfcManager? manager}) : _manager = manager;

  final NfcManager? _manager;

  NfcManager get _sessionManager => _manager ?? NfcManager.instance;

  @override
  Future<NfcAvailability> checkAvailability() async {
    if (_isUnsupportedPlatform) {
      return NfcAvailability.unsupported;
    }
    return _sessionManager.checkAvailability();
  }

  @override
  Future<GistagNfcTagRead> readTag() {
    return _runSession<GistagNfcTagRead>(
      alertMessageIos: 'Gistag NFC 태그를 가까이 대주세요.',
      timeout: const Duration(seconds: 30),
      onDiscovered: (tag) async {
        final ndef = Ndef.from(tag);
        if (ndef == null) {
          throw const GistagNfcException('NDEF 형식의 태그가 아닙니다.');
        }

        final message = await ndef.read();
        if (message == null) {
          throw const GistagNfcException('태그에 저장된 데이터가 없습니다.');
        }

        return GistagNfcTagRead(
          ndefPayload: readGistagPayloadFromNdefMessage(message),
          hardwareUid: _readHardwareUid(tag),
        );
      },
      successMessageIos: '태그를 확인했어요.',
    );
  }

  @override
  Future<GistagNfcTagWrite> writeTag({required String tagCode}) async {
    final message = buildGistagNdefMessage(tagCode);
    final ndefPayload = buildGistagTagPayload(tagCode);

    return _runSession<GistagNfcTagWrite>(
      alertMessageIos: '등록할 NFC 태그를 가까이 대주세요.',
      timeout: const Duration(seconds: 30),
      onDiscovered: (tag) async {
        final ndef = Ndef.from(tag);
        if (ndef == null) {
          throw const GistagNfcException('NDEF 쓰기를 지원하지 않는 태그입니다.');
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
        pollingOptions: const {NfcPollingOption.iso14443},
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
