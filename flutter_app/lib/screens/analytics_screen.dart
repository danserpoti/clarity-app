// lib/screens/analytics_screen.dart
// データ分析・可視化画面

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/local_database.dart';

/// 分析画面
/// 思考記録の統計・可視化を提供
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // 統計データ
  int _totalThoughts = 0;
  int _analyzedThoughts = 0;
  Map<String, int> _categoryStats = {};
  Map<String, int> _emotionStats = {};
  Map<String, int> _dailyStats = {};
  
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 分析データの読み込み
  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final database = Provider.of<LocalDatabase>(context, listen: false);
      
      final results = await Future.wait([
        database.getTotalThoughtsCount(),
        database.getAnalyzedThoughtsCount(),
        database.getCategoryStats(),
        database.getEmotionStats(),
        database.getDailyStats(days: 30),
      ]);

      setState(() {
        _totalThoughts = results[0] as int;
        _analyzedThoughts = results[1] as int;
        _categoryStats = results[2] as Map<String, int>;
        _emotionStats = results[3] as Map<String, int>;
        _dailyStats = results[4] as Map<String, int>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'データの読み込みに失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('分析'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pie_chart), text: 'カテゴリ'),
            Tab(icon: Icon(Icons.bar_chart), text: '感情'),
            Tab(icon: Icon(Icons.show_chart), text: '推移'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'データを分析中...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: _buildStatsCards(),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _buildCategoryTab(),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _buildEmotionTab(),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _buildTrendTab(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  /// エラー状態の表示
  Widget _buildErrorState() {
    return Center(
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
            _errorMessage!,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAnalyticsData,
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  /// 統計サマリーカード
  Widget _buildStatsCards() {
    final analysisRate = _totalThoughts > 0 
        ? (_analyzedThoughts / _totalThoughts * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              '総記録数',
              _totalThoughts.toString(),
              Icons.description,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              '分析済み',
              _analyzedThoughts.toString(),
              Icons.analytics,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              '分析率',
              '$analysisRate%',
              Icons.percent,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  /// 統計カード
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// カテゴリ分析タブ
  Widget _buildCategoryTab() {
    if (_categoryStats.isEmpty) {
      return _buildEmptyState('カテゴリデータがありません');
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'カテゴリ別分布',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: _buildPieChartSections(),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCategoryLegend(),
        ],
      ),
    );
  }

  /// 感情分析タブ
  Widget _buildEmotionTab() {
    if (_emotionStats.isEmpty) {
      return _buildEmptyState('感情データがありません');
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '感情分析',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                barGroups: _buildBarGroups(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final emotions = _emotionStats.keys.toList();
                        if (value.toInt() >= 0 && value.toInt() < emotions.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _getEmotionDisplayName(emotions[value.toInt()]),
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 推移分析タブ
  Widget _buildTrendTab() {
    if (_dailyStats.isEmpty) {
      return _buildEmptyState('推移データがありません');
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '30日間の推移',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        final dates = _dailyStats.keys.toList()..sort();
                        if (value.toInt() >= 0 && value.toInt() < dates.length) {
                          final date = DateTime.parse(dates[value.toInt()]);
                          return Text(
                            '${date.month}/${date.day}',
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: _buildLineChartSpots(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 空データ状態の表示
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.insert_chart_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  /// 円グラフセクションの構築
  List<PieChartSectionData> _buildPieChartSections() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];

    return _categoryStats.entries.map((entry) {
      final index = _categoryStats.keys.toList().indexOf(entry.key);
      final color = colors[index % colors.length];
      final percentage = (_categoryStats[entry.key]! / _totalThoughts * 100);
      
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${percentage.round()}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  /// カテゴリ凡例の構築
  Widget _buildCategoryLegend() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: _categoryStats.entries.map((entry) {
        final index = _categoryStats.keys.toList().indexOf(entry.key);
        final color = colors[index % colors.length];
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${entry.key} (${entry.value})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }

  /// バーチャートグループの構築
  List<BarChartGroupData> _buildBarGroups() {
    final colors = [
      Colors.green,   // positive
      Colors.red,     // negative
      Colors.grey,    // neutral
      Colors.orange,  // mixed
    ];

    return _emotionStats.entries.map((entry) {
      final index = _emotionStats.keys.toList().indexOf(entry.key);
      final color = colors[index % colors.length];
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: color,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
  }

  /// ラインチャートスポットの構築
  List<FlSpot> _buildLineChartSpots() {
    final sortedDates = _dailyStats.keys.toList()..sort();
    
    return sortedDates.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      final count = _dailyStats[date] ?? 0;
      
      return FlSpot(index.toDouble(), count.toDouble());
    }).toList();
  }

  /// 感情の表示名を取得
  String _getEmotionDisplayName(String emotion) {
    switch (emotion) {
      case 'positive':
        return 'ポジティブ';
      case 'negative':
        return 'ネガティブ';
      case 'neutral':
        return 'ニュートラル';
      case 'mixed':
        return 'ミックス';
      default:
        return emotion;
    }
  }
}