import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/ndef_record.dart';

class NfcPayloadFormatException implements Exception {
  const NfcPayloadFormatException(this.payload);

  final String payload;

  @override
  String toString() => 'Invalid Gistag NFC payload: $payload';
}

String parseGistagTagCode(String payload) {
  final trimmed = payload.trim();
  final uri = Uri.tryParse(trimmed);

  if (uri != null &&
      uri.scheme == 'gistag' &&
      uri.host == 'tag' &&
      uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.first;
  }

  if (trimmed.startsWith('GISTAG_TAG_')) {
    return trimmed;
  }

  throw NfcPayloadFormatException(payload);
}

String buildGistagTagPayload(String tagCode) {
  final parsed = parseGistagTagCode(tagCode);
  return 'gistag://tag/$parsed';
}

NdefMessage buildGistagNdefMessage(String tagCode) {
  final payload = buildGistagTagPayload(tagCode);
  return NdefMessage(
    records: [
      NdefRecord(
        typeNameFormat: TypeNameFormat.wellKnown,
        type: Uint8List.fromList(utf8.encode('U')),
        identifier: Uint8List(0),
        payload: Uint8List.fromList([0x00, ...utf8.encode(payload)]),
      ),
    ],
  );
}

String readGistagPayloadFromNdefMessage(NdefMessage message) {
  for (final record in message.records) {
    final value = _readTextRecord(record) ?? _readUriRecord(record);
    if (value == null) {
      continue;
    }
    try {
      parseGistagTagCode(value);
      return value;
    } on NfcPayloadFormatException {
      continue;
    }
  }
  throw const NfcPayloadFormatException('NDEF message has no Gistag payload.');
}

String? _readTextRecord(NdefRecord record) {
  if (record.typeNameFormat != TypeNameFormat.wellKnown ||
      !_bytesEqual(record.type, utf8.encode('T')) ||
      record.payload.isEmpty) {
    return null;
  }

  final status = record.payload.first;
  final isUtf16 = (status & 0x80) != 0;
  if (isUtf16) {
    return null;
  }

  final languageCodeLength = status & 0x3F;
  final textStart = 1 + languageCodeLength;
  if (textStart > record.payload.length) {
    return null;
  }
  return utf8.decode(record.payload.skip(textStart).toList());
}

String? _readUriRecord(NdefRecord record) {
  if (record.typeNameFormat == TypeNameFormat.absoluteUri) {
    return utf8.decode(record.type);
  }

  if (record.typeNameFormat != TypeNameFormat.wellKnown ||
      !_bytesEqual(record.type, utf8.encode('U')) ||
      record.payload.isEmpty) {
    return null;
  }

  final prefix = _uriPrefixes[record.payload.first] ?? '';
  final suffix = utf8.decode(record.payload.skip(1).toList());
  return '$prefix$suffix';
}

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i += 1) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

const _uriPrefixes = <int, String>{
  0x00: '',
  0x01: 'http://www.',
  0x02: 'https://www.',
  0x03: 'http://',
  0x04: 'https://',
  0x05: 'tel:',
  0x06: 'mailto:',
  0x07: 'ftp://anonymous:anonymous@',
  0x08: 'ftp://ftp.',
  0x09: 'ftps://',
  0x0A: 'sftp://',
  0x0B: 'smb://',
  0x0C: 'nfs://',
  0x0D: 'ftp://',
  0x0E: 'dav://',
  0x0F: 'news:',
  0x10: 'telnet://',
  0x11: 'imap:',
  0x12: 'rtsp://',
  0x13: 'urn:',
  0x14: 'pop:',
  0x15: 'sip:',
  0x16: 'sips:',
  0x17: 'tftp:',
  0x18: 'btspp://',
  0x19: 'btl2cap://',
  0x1A: 'btgoep://',
  0x1B: 'tcpobex://',
  0x1C: 'irdaobex://',
  0x1D: 'file://',
  0x1E: 'urn:epc:id:',
  0x1F: 'urn:epc:tag:',
  0x20: 'urn:epc:pat:',
  0x21: 'urn:epc:raw:',
  0x22: 'urn:epc:',
  0x23: 'urn:nfc:',
};
