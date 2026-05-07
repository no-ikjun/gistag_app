import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gistag_app/app/gistag_app.dart';

void main() {
  testWidgets('Gistag app shows splash then login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GistagApp()));

    expect(find.text('운동의 시작을 더 쉽게'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('카카오로 시작'), findsOneWidget);
  });
}
