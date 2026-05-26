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
