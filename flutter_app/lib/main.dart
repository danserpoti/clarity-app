// lib/main.dart
// Clarity App - メインエントリーポイント
// プライバシーファーストの思考記録アプリ

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/add_thought_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'services/local_database.dart';
import 'services/privacy_service.dart';
import 'services/background_backup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // バックグラウンドバックアップサービスの初期化
  await BackgroundBackupService.initialize();
  
  runApp(const ClarityApp());
}

class ClarityApp extends StatelessWidget {
  const ClarityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // データベースサービスの提供
        Provider<LocalDatabase>.value(
          value: LocalDatabase.instance,
        ),
        
        // プライバシー設定の提供
        FutureProvider<PrivacySettings>(
          create: (_) => PrivacySettings.load(),
          initialData: PrivacySettings.instance,
        ),
        
        // プライバシー設定のChangeNotifier版
        ChangeNotifierProvider<PrivacySettings>.value(
          value: PrivacySettings.instance,
        ),
      ],
      child: MaterialApp(
        title: 'Clarity - 思考記録',
        debugShowCheckedModeBanner: false,
        
        // テーマ設定
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          
          // カードテーマ
          cardTheme: const CardThemeData(
            elevation: 2,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          
          // アプリバーテーマ
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
        ),
        
        // ダークテーマ
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        
        // システムテーマに従う
        themeMode: ThemeMode.system,
        
        // ホーム画面
        home: const HomeScreen(),
        
        // ルート設定（将来の画面遷移用）
        routes: {
          '/home': (context) => const HomeScreen(),
          '/add_thought': (context) => const AddThoughtScreen(),
          '/settings': (context) => const SettingsScreen(),
          // '/analytics': (context) => const AnalyticsScreen(),
        },
      ),
    );
  }
}

/// アプリケーション情報
class AppInfo {
  static const String name = 'Clarity';
  static const String version = '1.0.0';
  static const String description = '思考・感情記録アプリ - プライバシーファースト設計';
  
  // プライバシー方針
  static const List<String> privacyPrinciples = [
    '全データは端末内のみで保存',
    '外部サーバーへのデータ送信なし（AI分析時除く）',
    'ユーザーがデータを完全制御',
    'オフライン動作可能',
    '透明性のあるデータ処理',
  ];
}