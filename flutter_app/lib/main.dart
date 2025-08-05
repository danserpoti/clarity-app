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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Icon(
                    Icons.book,
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_thoughtsCount',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    '思考記録',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.blue.shade200,
              ),
              Column(
                children: [
                  const Icon(
                    Icons.today,
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_recentThoughts.where((t) => t.entryDate == DateTime.now().toString().substring(0, 10)).length}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    '今日の記録',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('Clarity'),
        centerTitle: true,
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
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddThoughtScreen(),
            ),
          );
          // 画面から戻った後、データを更新
          _loadData();
        },
        tooltip: '思考を記録',
        icon: const Icon(Icons.edit),
        label: const Text('思考を記録'),
      ),
    );
  }
}