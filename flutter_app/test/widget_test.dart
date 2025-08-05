// Clarity App widget tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:clarity_app/main.dart';
import 'package:clarity_app/services/local_database.dart';
import 'package:clarity_app/services/privacy_service.dart';

void main() {
  testWidgets('Clarity App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LocalDatabase>.value(value: LocalDatabase.instance),
          ChangeNotifierProvider<PrivacySettings>.value(
            value: PrivacySettings.instance,
          ),
        ],
        child: const ClarityApp(),
      ),
    );

    // Verify that the home screen loads
    expect(find.text('Clarity'), findsOneWidget);
    
    // Verify that the FAB is present
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
