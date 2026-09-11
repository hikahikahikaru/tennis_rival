import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/constants/app_strings.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Tennis Rival - ホーム'), findsOneWidget);
    expect(find.text(AppStrings.recordMatch), findsOneWidget);
  });
}
