// lib/screens/home_screen.dart
// ホーム画面 - ダッシュボード機能

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/thought_entry.dart';
import '../services/local_database.dart';
import '../widgets/thought_card.dart';
import 'add_thought_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ThoughtEntry> _recentThoughts = [];
  bool _isLoading = true;
  String? _error;

  // 統計情報
  int _totalCount = 0;
  int _analyzedCount = 0;
  Map<String, int> _categoryStats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// データの読み込み
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final db = context.read<LocalDatabase>();

      // 並行してデータを取得
      final results = await Future.wait([
        db.getAllThoughts(),
        db.getTotalThoughtsCount(),
        db.getAnalyzedThoughtsCount(),
        db.getCategoryStats(),
      ]);

      final allThoughts = results[0] as List<ThoughtEntry>;
      final total = results[1] as int;
      final analyzed = results[2] as int;
      final categoryStats = results[3] as Map<String, int>;

      setState(() {
        _recentThoughts = allThoughts.take(5).toList(); // 最新5件
        _totalCount = total;
        _analyzedCount = analyzed;
        _categoryStats = categoryStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'データの読み込みに失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  /// 分析率の計算
  double get _analysisRate {
    if (_totalCount == 0) return 0.0;
    return _analyzedCount / _totalCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clarity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '更新',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: '設定',
          ),
        ],
      ),
      
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildContent(),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => const AddThoughtScreen(),
            ),
          );
          
          // 新しい思考が追加された場合はデータを再読み込み
          if (result == true) {
            _loadData();
          }
        },
        child: const Icon(Icons.add),
        tooltip: '新しい思考を記録',
      ),
    );
  }

  /// エラー表示ウィジェット
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }

  /// メインコンテンツ
  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 統計サマリー
            _buildStatsSection(),
            
            const SizedBox(height: 24),
            
            // 最近の思考記録
            _buildRecentThoughtsSection(),
            
            const SizedBox(height: 24),
            
            // クイックアクション
            _buildQuickActionsSection(),
            
            const SizedBox(height: 80), // FABとの重複を避ける
          ],
        ),
      ),
    );
  }

  /// 統計情報セクション
  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '統計情報',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: '総記録数',
                value: '$_totalCount',
                color: Colors.blue,
                icon: Icons.book,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'AI分析済み',
                value: '$_analyzedCount',
                color: Colors.green,
                icon: Icons.psychology,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: '分析率',
                value: '${(_analysisRate * 100).toInt()}%',
                color: Colors.purple,
                icon: Icons.analytics,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'カテゴリ数',
                value: '${_categoryStats.length}',
                color: Colors.orange,
                icon: Icons.category,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 統計カード
  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 最近の思考記録セクション
  Widget _buildRecentThoughtsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '最近の記録',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (_recentThoughts.isNotEmpty)
              TextButton(
                onPressed: () {
                  // TODO: 一覧画面への遷移
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('一覧画面は実装中です')),
                  );
                },
                child: const Text('すべて見る'),
              ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        if (_recentThoughts.isEmpty)
          _buildEmptyState()
        else
          ...(_recentThoughts.map((thought) => ThoughtCard(thought: thought))),
      ],
    );
  }

  /// 空状態の表示
  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'まだ記録がありません',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '最初の思考を記録してみましょう',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => const AddThoughtScreen(),
                  ),
                );
                
                // 新しい思考が追加された場合はデータを再読み込み
                if (result == true) {
                  _loadData();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('記録を作成'),
            ),
          ],
        ),
      ),
    );
  }

  /// クイックアクションセクション
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'クイックアクション',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.analytics,
                title: '分析結果',
                subtitle: 'チャートと統計',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('分析画面は実装中です')),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.settings,
                title: '設定',
                subtitle: 'プライバシー設定',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// アクションカード
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}