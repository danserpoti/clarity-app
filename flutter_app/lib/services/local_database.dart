// lib/services/local_database.dart
// SQLite ローカルデータベースサービス
// プライバシーファースト: 全データを端末内で管理

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../models/thought_entry.dart';
import '../models/analysis_result.dart';

/// ローカルデータベース管理クラス
/// SQLiteを使用した完全ローカル保存
class LocalDatabase {
  static LocalDatabase? _instance;
  static Database? _database;

  // シングルトンパターン
  LocalDatabase._internal();
  
  static LocalDatabase get instance {
    _instance ??= LocalDatabase._internal();
    return _instance!;
  }

  // データベース定数
  static const String _databaseName = 'clarity_app.db';
  static const int _databaseVersion = 1;
  
  // テーブル名
  static const String _thoughtsTable = 'thoughts';

  /// データベースインスタンスの取得
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// データベースの初期化
  Future<Database> _initDatabase() async {
    // アプリケーション専用ディレクトリを取得
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    
    // データベースを開く（なければ作成）
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// データベース作成時の処理
  Future<void> _onCreate(Database db, int version) async {
    // thoughts テーブル作成
    await db.execute('''
      CREATE TABLE $_thoughtsTable (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        category TEXT NOT NULL,
        entry_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        ai_emotion TEXT,
        ai_emotion_score REAL,
        ai_themes TEXT,
        ai_keywords TEXT,
        ai_summary TEXT,
        ai_suggestion TEXT,
        ai_analyzed_at TEXT
      )
    ''');

    // インデックス作成（パフォーマンス向上）
    await db.execute('''
      CREATE INDEX idx_thoughts_created_at ON $_thoughtsTable(created_at DESC)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_thoughts_category ON $_thoughtsTable(category)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_thoughts_emotion ON $_thoughtsTable(ai_emotion)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_thoughts_entry_date ON $_thoughtsTable(entry_date)
    ''');
  }

  /// データベースアップグレード時の処理
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 将来のバージョンアップ時に使用
    // 現在はVersion 1のためスキップ
  }

  // =============================================================================
  // CRUD 操作
  // =============================================================================

  /// 思考記録の挿入
  Future<String> insertThought(ThoughtEntry thought) async {
    final db = await database;
    
    await db.insert(
      _thoughtsTable,
      thought.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    return thought.id;
  }

  /// 全思考記録の取得（作成日時降順）
  Future<List<ThoughtEntry>> getAllThoughts() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _thoughtsTable,
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => ThoughtEntry.fromMap(map)).toList();
  }

  /// IDによる思考記録の取得
  Future<ThoughtEntry?> getThought(String id) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _thoughtsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return ThoughtEntry.fromMap(maps.first);
  }

  /// 思考記録の更新
  Future<int> updateThought(ThoughtEntry thought) async {
    final db = await database;
    
    return await db.update(
      _thoughtsTable,
      thought.toMap(),
      where: 'id = ?',
      whereArgs: [thought.id],
    );
  }

  /// 思考記録の削除
  Future<int> deleteThought(String id) async {
    final db = await database;
    
    return await db.delete(
      _thoughtsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 全思考記録の削除（データリセット用）
  Future<int> deleteAllThoughts() async {
    final db = await database;
    return await db.delete(_thoughtsTable);
  }

  // =============================================================================
  // 検索・フィルタリング
  // =============================================================================

  /// カテゴリによる思考記録の取得
  Future<List<ThoughtEntry>> getThoughtsByCategory(ThoughtCategory category) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _thoughtsTable,
      where: 'category = ?',
      whereArgs: [category.displayName],
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => ThoughtEntry.fromMap(map)).toList();
  }

  /// 感情による思考記録の取得
  Future<List<ThoughtEntry>> getThoughtsByEmotion(EmotionType emotion) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _thoughtsTable,
      where: 'ai_emotion = ?',
      whereArgs: [emotion.value],
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => ThoughtEntry.fromMap(map)).toList();
  }

  /// 日付範囲による思考記録の取得
  Future<List<ThoughtEntry>> getThoughtsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _thoughtsTable,
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => ThoughtEntry.fromMap(map)).toList();
  }

  /// キーワード検索（内容・要約・提案を対象）
  Future<List<ThoughtEntry>> searchThoughts(String keyword) async {
    final db = await database;
    
    final String searchPattern = '%$keyword%';
    
    final List<Map<String, dynamic>> maps = await db.query(
      _thoughtsTable,
      where: '''
        content LIKE ? OR 
        ai_summary LIKE ? OR 
        ai_suggestion LIKE ?
      ''',
      whereArgs: [searchPattern, searchPattern, searchPattern],
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => ThoughtEntry.fromMap(map)).toList();
  }

  /// AI分析済みの思考記録の取得
  Future<List<ThoughtEntry>> getAnalyzedThoughts() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _thoughtsTable,
      where: 'ai_emotion IS NOT NULL',
      orderBy: 'ai_analyzed_at DESC',
    );
    
    return maps.map((map) => ThoughtEntry.fromMap(map)).toList();
  }

  // =============================================================================
  // 統計・分析用クエリ
  // =============================================================================

  /// 総記録数の取得
  Future<int> getTotalThoughtsCount() async {
    final db = await database;
    
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_thoughtsTable');
    return result.first['count'] as int;
  }

  /// AI分析済み記録数の取得
  Future<int> getAnalyzedThoughtsCount() async {
    final db = await database;
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_thoughtsTable WHERE ai_emotion IS NOT NULL'
    );
    return result.first['count'] as int;
  }

  /// カテゴリ別統計の取得
  Future<Map<String, int>> getCategoryStats() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT category, COUNT(*) as count 
      FROM $_thoughtsTable 
      GROUP BY category
    ''');
    
    final Map<String, int> stats = {};
    for (final map in maps) {
      stats[map['category'] as String] = map['count'] as int;
    }
    
    return stats;
  }

  /// 感情別統計の取得
  Future<Map<String, int>> getEmotionStats() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT ai_emotion, COUNT(*) as count 
      FROM $_thoughtsTable 
      WHERE ai_emotion IS NOT NULL
      GROUP BY ai_emotion
    ''');
    
    final Map<String, int> stats = {};
    for (final map in maps) {
      stats[map['ai_emotion'] as String] = map['count'] as int;
    }
    
    return stats;
  }

  /// 月別思考記録数の取得
  Future<Map<String, int>> getMonthlyStats() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT strftime('%Y-%m', created_at) as month, COUNT(*) as count
      FROM $_thoughtsTable
      GROUP BY strftime('%Y-%m', created_at)
      ORDER BY month DESC
    ''');
    
    final Map<String, int> stats = {};
    for (final map in maps) {
      stats[map['month'] as String] = map['count'] as int;
    }
    
    return stats;
  }

  /// 平均感情スコアの取得
  Future<double> getAverageEmotionScore() async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT AVG(ai_emotion_score) as avg_score 
      FROM $_thoughtsTable 
      WHERE ai_emotion_score IS NOT NULL
    ''');
    
    final avgScore = result.first['avg_score'];
    return avgScore != null ? (avgScore as num).toDouble() : 0.0;
  }

  /// 分析統計情報の取得
  Future<AnalysisStats> getAnalysisStats() async {
    final totalAnalyzed = await getAnalyzedThoughtsCount();
    final emotionStatsMap = await getEmotionStats();
    
    // String -> EmotionType 変換
    final Map<EmotionType, int> emotionDistribution = {};
    for (final entry in emotionStatsMap.entries) {
      final emotion = EmotionType.fromString(entry.key);
      if (emotion != null) {
        emotionDistribution[emotion] = entry.value;
      }
    }
    
    // テーマ頻度は複雑な処理のため、簡略化
    final Map<String, int> themeFrequency = {};
    
    final averageScore = await getAverageEmotionScore();
    
    // 最後の分析日時を取得
    final db = await database;
    final lastAnalyzedResult = await db.rawQuery('''
      SELECT MAX(ai_analyzed_at) as last_analyzed
      FROM $_thoughtsTable
      WHERE ai_analyzed_at IS NOT NULL
    ''');
    
    DateTime? lastAnalyzedAt;
    final lastAnalyzedStr = lastAnalyzedResult.first['last_analyzed'] as String?;
    if (lastAnalyzedStr != null) {
      lastAnalyzedAt = DateTime.parse(lastAnalyzedStr);
    }
    
    return AnalysisStats(
      totalAnalyzed: totalAnalyzed,
      emotionDistribution: emotionDistribution,
      themeFrequency: themeFrequency,
      averageEmotionScore: averageScore,
      lastAnalyzedAt: lastAnalyzedAt,
    );
  }

  // =============================================================================
  // データベース管理
  // =============================================================================

  /// データベースを閉じる
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// データベースサイズの取得（MB単位）
  Future<double> getDatabaseSize() async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, _databaseName);
      File dbFile = File(path);
      
      if (await dbFile.exists()) {
        int sizeInBytes = await dbFile.length();
        return sizeInBytes / (1024 * 1024); // MB単位に変換
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// データベースの最適化
  Future<void> optimize() async {
    final db = await database;
    await db.execute('VACUUM');
  }
}