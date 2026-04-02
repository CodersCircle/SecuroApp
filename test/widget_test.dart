import 'package:flutter_test/flutter_test.dart';
import 'package:securo_app/app.dart';

void main() {
  testWidgets('App renders without crash', (WidgetTester tester) async {
    await tester.pumpWidget(const SecuroApp());
    expect(find.text('SecuroApp'), findsOneWidget);
    // ✅ Clear pending timers from SplashScreen to prevent test failure
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
