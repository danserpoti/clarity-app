// lib/screens/home_screen.dart
// ホーム画面 - ダッシュボード機能

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/thought_entry.dart';
import '../services/local_database.dart';
import '../widgets/thought_card.dart';
import '../utils/responsive_helper.dart';
import '../utils/page_transitions.dart';
import '../utils/accessibility_helper.dart';
import 'add_thought_screen.dart';
import 'analytics_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<ThoughtEntry> _recentThoughts = [];
  bool _isLoading = true;
  String? _error;

  // 統計情報
  int _totalCount = 0;
  int _analyzedCount = 0;
  int _todayCount = 0;
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
        db.getTodayThoughtsCount(),
        db.getCategoryStats(),
      ]);

      final allThoughts = results[0] as List<ThoughtEntry>;
      final total = results[1] as int;
      final analyzed = results[2] as int;
      final today = results[3] as int;
      final categoryStats = results[4] as Map<String, int>;

      setState(() {
        _recentThoughts = allThoughts.take(5).toList(); // 最新5件
        _totalCount = total;
        _analyzedCount = analyzed;
        _todayCount = today;
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
    super.build(context); // AutomaticKeepAliveClientMixin用
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clarity'),
        actions: [
          AccessibleIconButton(
            icon: Icons.analytics,
            onPressed: () {
              AnimatedNavigation.pushSlide(
                context,
                const AnalyticsScreen(),
              );
            },
            tooltip: '分析',
            semanticLabel: '分析画面に移動',
          ),
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
      
      floatingActionButton: FloatingActionButton.extended(
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
        icon: const Icon(Icons.edit_rounded),
        label: const Text('思考を記録'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 8,
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
    return ResponsiveContainer(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 統計サマリー
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: _buildStatsSection(),
              ),
              
              SizedBox(height: ResponsiveHelper.getMargin(context) * 2),
              
              // 最近の思考記録
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: _buildRecentThoughtsSection(),
              ),
              
              SizedBox(height: ResponsiveHelper.getMargin(context) * 2),
              
              // クイックアクション
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: _buildQuickActionsSection(),
              ),
              
              const SizedBox(height: 80), // FABとの重複を避ける
            ],
          ),
        ),
      ),
    );
  }

  /// 統計情報セクション
  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '統計情報',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AnalyticsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.analytics, size: 16),
              label: const Text('詳細'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: '思考記録',
                value: '$_totalCount',
                color: Colors.blue,
                icon: Icons.psychology_alt,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AnalyticsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: '今日の記録',
                value: '$_todayCount',
                color: Colors.purple,
                icon: Icons.today_rounded,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AnalyticsScreen(),
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

  /// 統計カード（グラデーション版）
  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final gradientColors = _getGradientColors(color);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Semantics(
            label: '$title: $value',
            button: onTap != null,
            hint: onTap != null ? 'タップして詳細を表示' : null,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon, 
                    color: Colors.white,
                    size: 28,
                    semanticLabel: title,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                    semanticsLabel: '$title の値: $value',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// グラデーション色の取得
  List<Color> _getGradientColors(Color baseColor) {
    if (baseColor == Colors.blue) {
      // 思考記録カード用のブルー系グラデーション
      return [
        Colors.blue.shade400,
        Colors.blue.shade600,
      ];
    } else if (baseColor == Colors.purple) {
      // 今日の記録カード用のパープル系グラデーション
      return [
        Colors.purple.shade400,
        Colors.purple.shade600,
      ];
    } else if (baseColor == Colors.green) {
      return [
        const Color(0xFF11998e),
        const Color(0xFF38ef7d),
      ];
    } else if (baseColor == Colors.orange) {
      return [
        const Color(0xFFf093fb),
        const Color(0xFFf5576c),
      ];
    } else {
      return [
        baseColor,
        baseColor.withOpacity(0.7),
      ];
    }
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AnalyticsScreen(),
                    ),
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