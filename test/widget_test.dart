import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gistag_app/app/gistag_app.dart';
import 'package:gistag_app/models/auth_models.dart';
import 'package:gistag_app/providers/app_providers.dart';
import 'package:gistag_app/services/auth_token_storage.dart';

class _MemoryAuthTokenStorage implements AuthTokenStorage {
  AuthTokens? _tokens;

  @override
  Future<void> clear() async {
    _tokens = null;
  }

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async {
    _tokens = tokens;
  }
}

void main() {
  testWidgets('Gistag app shows splash then login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authTokenStorageProvider.overrideWithValue(_MemoryAuthTokenStorage()),
        ],
        child: const GistagApp(),
      ),
    );

    expect(find.text('운동의 시작을 더 쉽게'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Gistag 로그인'), findsOneWidget);
  });
}
