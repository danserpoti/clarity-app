// test/test_helpers.dart
// テスト用ヘルパー関数

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:clarity_app/main.dart';
import 'package:clarity_app/services/local_database.dart';
import 'package:clarity_app/services/privacy_service.dart';

/// テスト用のアプリウィジェットを作成
Widget createTestApp() {
  return MultiProvider(
    providers: [
      Provider<LocalDatabase>.value(value: LocalDatabase.instance),
      ChangeNotifierProvider<PrivacySettings>.value(
        value: PrivacySettings.instance,
      ),
    ],
    child: const ClarityApp(),
  );
} 