// lib/services/local_database.dart
// SQLite ローカルデータベースサービス
// プライバシーファースト: 全データを端末内で管理

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

// Web対応
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// 削除：不要なプラットフォーム固有インポート

import '../models/thought_entry.dart';
import '../models/analysis_result.dart';
import 'web_storage_service.dart';

/// ローカルデータベース管理クラス
/// SQLiteを使用した完全ローカル保存
class LocalDatabase {
  static LocalDatabase? _instance;
  static Database? _database;
  static bool _isInitialized = false;
  static bool _useLocalStorage = false; // Web環境でのフォールバック用
  static WebStorageService? _webStorage;

  // シングルトンパターン
  LocalDatabase._internal();
  
  static LocalDatabase get instance {
    _instance ??= LocalDatabase._internal();
    return _instance!;
  }

  /// localStorage使用状態の確認
  static bool get isUsingLocalStorage => _useLocalStorage;

  /// WebStorageServiceインスタンスの取得
  static WebStorageService? get webStorageInstance => _webStorage;

  /// プラットフォーム初期化を公開（リトライ用）
  static Future<void> initializePlatform() async {
    await _initializePlatform();
  }

  /// WebStorageService初期化を公開（リトライ用）
  static Future<void> initializeWebStorage() async {
    final instance = LocalDatabase.instance;
    await instance._initWebStorage();
  }

  // データベース定数
  static const String _databaseName = 'clarity_app.db';
  static const int _databaseVersion = 1;
  
  // テーブル名
  static const String _thoughtsTable = 'thoughts';

  /// プラットフォーム固有の初期化
  static Future<void> _initializePlatform() async {
    if (_isInitialized) return;
    
    if (kIsWeb) {
      // Web環境: SQLiteを試行せずにローカルストレージを直接使用
      debugPrint('Web detected: Using localStorage directly');
      _useLocalStorage = true;
      _isInitialized = true;
      return;
    }
    
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || 
                      defaultTargetPlatform == TargetPlatform.linux || 
                      defaultTargetPlatform == TargetPlatform.macOS)) {
        // Desktop環境: sqflite_common_ffiを使用
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      // モバイル環境では標準のsqfliteを使用（追加設定不要）
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Platform initialization error: $e');
      _isInitialized = true;
    }
  }

  /// データベースインスタンスの取得
  Future<Database> get database async {
    try {
      await _initializePlatform();
      
      // ローカルストレージフォールバックが有効な場合
      if (_useLocalStorage) {
        await _initWebStorage();
        throw Exception('Using localStorage fallback');
      }
      
      _database ??= await _initDatabase();
      return _database!;
    } catch (e) {
      debugPrint('Database getter error: $e');
      // Web環境でのエラーの場合、メモリ内データベースを試行
      if (kIsWeb && _database == null && !_useLocalStorage) {
        try {
          debugPrint('Attempting to create in-memory database for web');
          _database = await openDatabase(
            ':memory:',
            version: _databaseVersion,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
          );
          return _database!;
        } catch (memoryError) {
          debugPrint('In-memory database also failed: $memoryError');
          // 最終的なフォールバックとしてローカルストレージを使用
          _useLocalStorage = true;
          await _initWebStorage();
          throw Exception('All database initialization methods failed');
        }
      }
      rethrow;
    }
  }

  /// データベースの初期化
  Future<Database> _initDatabase() async {
    String path;
    
    if (kIsWeb) {
      // Web環境: 固定パスを使用
      path = _databaseName;
    } else {
      try {
        // モバイル・デスクトップ環境: path_providerを使用
        final documentsPath = await _getDocumentsPath();
        path = join(documentsPath, _databaseName);
      } catch (e) {
        // フォールバック: 現在のディレクトリを使用
        debugPrint('path_provider error: $e, using fallback path');
        path = _databaseName;
      }
    }
    
    try {
      // データベースを開く（なければ作成）
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      debugPrint('Database initialization error: $e');
      // Web環境での初期化に失敗した場合、メモリ内データベースを使用
      if (kIsWeb) {
        debugPrint('Falling back to in-memory database for web');
        return await openDatabase(
          ':memory:',
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        );
      }
      rethrow;
    }
  }

  // ダミー実装：プラットフォーム固有の処理は削除
  Future<String> _getDocumentsPath() async {
    return './'; // シンプルな相対パス
  }

  /// WebStorageServiceの初期化
  Future<void> _initWebStorage() async {
    if (_webStorage == null) {
      _webStorage = WebStorageService.instance;
      await _webStorage!.initialize();
      debugPrint('WebStorageService initialized as fallback');
    }
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
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.insertThought(thought);
    }
    
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
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.getAllThoughts();
    }
    
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _thoughtsTable,
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => ThoughtEntry.fromMap(map)).toList();
  }

  /// IDによる思考記録の取得
  Future<ThoughtEntry?> getThought(String id) async {
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.getThought(id);
    }
    
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
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.updateThought(thought);
    }
    
    final db = await database;
    
    return await db.update(
      _thoughtsTable,
      thought.toMap(),
      where: 'id = ?',
      whereArgs: [thought.id],
    );
  }

  /// 思考記録にAI分析結果を追加
  Future<void> updateThoughtWithAnalysis(String id, AnalysisResult result) async {
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.updateThoughtWithAnalysis(id, result);
    }
    
    final db = await database;
    
    await db.update(
      _thoughtsTable,
      {
        'ai_emotion': result.emotion.value,
        'ai_emotion_score': result.emotionScore,
        'ai_themes': jsonEncode(result.themes),
        'ai_keywords': jsonEncode(result.keywords),
        'ai_summary': result.summary,
        'ai_suggestion': result.suggestion,
        'ai_analyzed_at': result.analyzedAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 思考記録の削除
  Future<int> deleteThought(String id) async {
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.deleteThought(id);
    }
    
    final db = await database;
    
    return await db.delete(
      _thoughtsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 全思考記録の削除（データリセット用）
  Future<int> deleteAllThoughts() async {
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.deleteAllThoughts();
    }
    
    final db = await database;
    return await db.delete(_thoughtsTable);
  }

  // =============================================================================
  // 検索・フィルタリング
  // =============================================================================

  /// カテゴリによる思考記録の取得
  Future<List<ThoughtEntry>> getThoughtsByCategory(ThoughtCategory category) async {
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.getThoughtsByCategory(category);
    }
    
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
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.getThoughtsByEmotion(emotion);
    }
    
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
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.getThoughtsByDateRange(startDate, endDate);
    }
    
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
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.searchThoughts(keyword);
    }
    
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
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.getAnalyzedThoughts();
    }
    
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
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.getTotalThoughtsCount();
    }
    
    final db = await database;
    
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_thoughtsTable');
    return result.first['count'] as int;
  }

  /// AI分析済み記録数の取得
  Future<int> getAnalyzedThoughtsCount() async {
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.getAnalyzedThoughtsCount();
    }
    
    final db = await database;
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_thoughtsTable WHERE ai_emotion IS NOT NULL'
    );
    return result.first['count'] as int;
  }

  /// 今日の記録数の取得
  Future<int> getTodayThoughtsCount() async {
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.getTodayThoughtsCount();
    }
    
    final db = await database;
    
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_thoughtsTable WHERE created_at >= ? AND created_at < ?',
      [todayStart.toIso8601String(), tomorrowStart.toIso8601String()]
    );
    return result.first['count'] as int;
  }

  /// カテゴリ別統計の取得
  Future<Map<String, int>> getCategoryStats() async {
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.getCategoryStats();
    }
    
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
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.getEmotionStats();
    }
    
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
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.getMonthlyStats();
    }
    
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

  /// 日別思考記録数の取得（過去N日間）
  Future<Map<String, int>> getDailyStats({int days = 30}) async {
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.getDailyStats(days: days);
    }
    
    final db = await database;
    
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT entry_date, COUNT(*) as count
      FROM $_thoughtsTable
      WHERE entry_date >= ?
      GROUP BY entry_date
      ORDER BY entry_date DESC
    ''', [cutoffDate.toIso8601String().substring(0, 10)]);
    
    final Map<String, int> stats = {};
    for (final map in maps) {
      stats[map['entry_date'] as String] = map['count'] as int;
    }
    
    return stats;
  }

  /// 平均感情スコアの取得
  Future<double> getAverageEmotionScore() async {
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.getAverageEmotionScore();
    }
    
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
    if (_useLocalStorage && _webStorage != null) {
      return await _webStorage!.getAnalysisStats();
    }
    
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
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_thoughtsTable');
      final count = result.first['count'] as int;
      // 1レコード約1KBと仮定して計算（概算）
      return (count * 1024) / (1024 * 1024);
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