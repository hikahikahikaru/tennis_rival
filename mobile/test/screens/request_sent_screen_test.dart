import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/request_sent_screen.dart';

void main() {
  testWidgets('登録完了後は既存の認証済みルートへ戻る', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                const Text('home:user-1'),
                const Text('logout-action'),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const RequestSentScreen(
                        opponentName: '西やん',
                      ),
                    ),
                  ),
                  child: const Text('open result'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open result'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ホームに戻る'));
    await tester.pumpAndSettle();

    expect(find.text('home:user-1'), findsOneWidget);
    expect(find.text('logout-action'), findsOneWidget);
    expect(find.byType(RequestSentScreen), findsNothing);
    expect(
        Navigator.of(tester.element(find.text('home:user-1'))).canPop(), false);
  });
}
