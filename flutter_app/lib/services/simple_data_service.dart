import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/thought_entry.dart';

class SimpleDataService {
  static const String _thoughtsKey = 'clarity_thoughts';

  /// 思考を保存
  static Future<void> saveThought(ThoughtEntry thought) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 既存の思考リストを取得
      final existingThoughts = await getAllThoughts();
      
      // 新しい思考を追加
      existingThoughts.add(thought);
      
      // JSON文字列のリストに変換
      final thoughtJsonList = existingThoughts
          .map((t) => jsonEncode(t.toJson()))
          .toList();
      
      // SharedPreferencesに保存
      await prefs.setStringList(_thoughtsKey, thoughtJsonList);
    } catch (e) {
      throw Exception('思考の保存に失敗しました: $e');
    }
  }

  /// 全ての思考を取得
  static Future<List<ThoughtEntry>> getAllThoughts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final thoughtJsonList = prefs.getStringList(_thoughtsKey) ?? [];
      
      return thoughtJsonList
          .map((jsonString) => ThoughtEntry.fromJson(jsonDecode(jsonString)))
          .toList();
    } catch (e) {
      throw Exception('思考の取得に失敗しました: $e');
    }
  }

  /// 思考を削除
  static Future<void> deleteThought(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingThoughts = await getAllThoughts();
      
      // 指定されたIDの思考を除外
      final filteredThoughts = existingThoughts
          .where((thought) => thought.id != id)
          .toList();
      
      // JSON文字列のリストに変換
      final thoughtJsonList = filteredThoughts
          .map((t) => jsonEncode(t.toJson()))
          .toList();
      
      // SharedPreferencesに保存
      await prefs.setStringList(_thoughtsKey, thoughtJsonList);
    } catch (e) {
      throw Exception('思考の削除に失敗しました: $e');
    }
  }

  /// 全ての思考を削除
  static Future<void> clearAllThoughts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_thoughtsKey);
    } catch (e) {
      throw Exception('思考の全削除に失敗しました: $e');
    }
  }

  /// 思考の数を取得
  static Future<int> getThoughtsCount() async {
    try {
      final thoughts = await getAllThoughts();
      return thoughts.length;
    } catch (e) {
      return 0;
    }
  }
}