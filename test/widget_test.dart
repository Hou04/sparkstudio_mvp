// This is a basic Flutter widget test for SparkStudio MVP.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sparkstudio_mvp/app.dart';

void main() {
  testWidgets('SparkStudio app loads LoginPage', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SparkStudioApp());

    // Verify that the app shows the Login screen
    expect(find.text('Log in'), findsOneWidget);
    expect(
      find.byType(TextField),
      findsNWidgets(2),
    ); // Email and password fields

    // Verify that the app bar is present
    expect(find.byType(AppBar), findsOneWidget);
  });
}
