// This is a basic Flutter widget test for EduBot.

import 'package:flutter_test/flutter_test.dart';

import 'package:edubot/main.dart';

void main() {
  testWidgets('EduBot app starts correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EduBotApp());

    // Verify that the home screen loads with the welcome message.
    expect(find.text('Hello, Parent! 👋'), findsOneWidget);
    expect(find.text('Ready to help with homework?'), findsOneWidget);

    // Verify that quick action cards are present.
    expect(find.text('Scan Problem'), findsOneWidget);
    expect(find.text('Ask Question'), findsOneWidget);
  });
}
