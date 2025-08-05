import 'package:flutter/material.dart';
import 'screens/add_thought_screen.dart';
import 'services/simple_data_service.dart';
import 'models/thought_entry.dart';
import 'widgets/thought_card.dart';

void main() {
  runApp(const ClarityApp());
}

class ClarityApp extends StatelessWidget {
  const ClarityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const ClarityHomePage(),
    );
  }
}

class ClarityHomePage extends StatefulWidget {
  const ClarityHomePage({super.key});

  @override
  State<ClarityHomePage> createState() => _ClarityHomePageState();
}

class _ClarityHomePageState extends State<ClarityHomePage> {
  int _thoughtsCount = 0;
  List<ThoughtEntry> _recentThoughts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final thoughts = await SimpleDataService.getAllThoughts();
      
      // 作成日時順でソート（最新順）
      thoughts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      setState(() {
        _thoughtsCount = thoughts.length;
        _recentThoughts = thoughts.take(5).toList(); // 最新5件
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _thoughtsCount = 0;
        _recentThoughts = [];
        _isLoading = false;
      });
    }
  }

  Widget _buildHeader() {
    final _todayCount = _recentThoughts.where((t) => t.entryDate == DateTime.now().toString().substring(0, 10)).length;
    
    return Column(
      children: [
        const Icon(
          Icons.psychology,
          size: 80,
          color: Colors.blue,
        ),
        const SizedBox(height: 16),
        const Text(
          'Clarity アプリ',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '思考・感情を記録して自己理解を深めよう',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF42A5F5).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
                    const SizedBox(height: 8),
                    Text('$_thoughtsCount', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('思考記録', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFAB47BC), Color(0xFF6A1B9A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFAB47BC).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.today_rounded, color: Colors.white, size: 28),
                    const SizedBox(height: 8),
                    Text('$_todayCount', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('今日の記録', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThoughtsList() {
    if (_thoughtsCount == 0) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '最近の思考記録',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (_thoughtsCount > 5)
              TextButton(
                onPressed: () {
                  // TODO: 全件表示画面への遷移
                },
                child: const Text('すべて見る'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...(_recentThoughts.map((thought) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ThoughtCard(thought: thought),
        ))),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.sentiment_satisfied_alt,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '最初の思考を記録しましょう',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'あなたの日々の思考や感情を記録して、\n自己理解を深めていきましょう。',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Clarity',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: 設定画面への遷移
            },
            icon: Icon(
              Icons.settings_rounded,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ヘッダー部分
                  _buildHeader(),
                  const SizedBox(height: 24),
                  
                  // 思考一覧部分
                  _buildThoughtsList(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddThoughtScreen()),
        ).then((_) => _loadData()),
        icon: const Icon(Icons.edit_rounded),
        label: const Text(
          '思考を記録',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 8,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    );
  }
}