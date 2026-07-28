import 'package:flutter_test/flutter_test.dart';
import 'package:votrite_app/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const VotRiteApp());
    expect(find.text('VotRite'), findsOneWidget);
  });
}
