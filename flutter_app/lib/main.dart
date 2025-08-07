import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/add_thought_screen.dart';
import 'screens/home_screen.dart';
import 'services/simple_data_service.dart';
import 'services/local_database.dart';
import 'services/privacy_service.dart';
import 'models/thought_entry.dart';
import 'widgets/thought_card.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // プライバシー設定の初期化
  await PrivacySettings.load();
  
  runApp(const ClarityApp());
}

class ClarityApp extends StatelessWidget {
  const ClarityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PrivacySettings>(
          create: (_) => PrivacySettings.instance,
        ),
        Provider<LocalDatabase>(
          create: (_) => LocalDatabase.instance,
        ),
      ],
      child: MaterialApp(
        title: 'Clarity - 思考記録',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

