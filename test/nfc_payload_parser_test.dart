import 'package:flutter_test/flutter_test.dart';
import 'package:gistag_app/services/nfc_payload_parser.dart';

void main() {
  group('parseGistagTagCode', () {
    test('extracts tagCode from gistag URI payload', () {
      expect(
        parseGistagTagCode('gistag://tag/GISTAG_TAG_DEMO_001'),
        'GISTAG_TAG_DEMO_001',
      );
    });

    test('accepts raw demo tagCode for local testing', () {
      expect(parseGistagTagCode('GISTAG_TAG_DEMO_001'), 'GISTAG_TAG_DEMO_001');
    });

    test('rejects unsupported payloads', () {
      expect(
        () => parseGistagTagCode('https://example.com/tag'),
        throwsA(isA<NfcPayloadFormatException>()),
      );
    });

    test('builds canonical Gistag URI payload', () {
      expect(
        buildGistagTagPayload('GISTAG_TAG_DEMO_001'),
        'gistag://tag/GISTAG_TAG_DEMO_001',
      );
    });

    test('reads Gistag URI from generated NDEF message', () {
      final message = buildGistagNdefMessage('GISTAG_TAG_DEMO_001');

      expect(
        readGistagPayloadFromNdefMessage(message),
        'gistag://tag/GISTAG_TAG_DEMO_001',
      );
    });
  });
}
