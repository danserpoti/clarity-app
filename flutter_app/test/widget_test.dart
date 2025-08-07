// Clarity App widget tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Clarity App basic test', (WidgetTester tester) async {
    // アプリを構築
    await tester.pumpWidget(createTestApp());
    
    // 初期フレームを描画
    await tester.pump();
    
    // 基本的なアプリの構造が正しく構築されることを確認
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('App shows Clarity title', (WidgetTester tester) async {
    // アプリを構築
    await tester.pumpWidget(createTestApp());
    
    // 初期フレームを描画
    await tester.pump();
    
    // タイトルが表示されることを確認（ローディング状態でも表示される）
    expect(find.text('Clarity'), findsOneWidget);
  });
}
