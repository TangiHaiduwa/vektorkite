import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vektorkite/features/auth/presentation/screens/welcome_screen.dart';

void main() {
  testWidgets('renders customer welcome actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WelcomeScreen()),
    );

    expect(find.text('VektorKite'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });
}
