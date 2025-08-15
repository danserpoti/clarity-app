// lib/services/device_id_service.dart
// デバイスID生成・管理サービス - プライバシー重視の匿名識別

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// デバイスID管理サービス
/// プライバシーファースト設計：
/// - UUID v4による完全匿名識別
/// - 個人識別情報は一切含まない
/// - 使用量管理のためのみ使用
class DeviceIdService {
  static const String _deviceIdKey = 'clarity_device_id';
  static const String _firstLaunchKey = 'clarity_first_launch';
  
  /// シングルトンインスタンス
  static final DeviceIdService _instance = DeviceIdService._internal();
  factory DeviceIdService() => _instance;
  DeviceIdService._internal();
  
  /// UUIDジェネレーター
  static const Uuid _uuid = Uuid();
  
  /// デバイスIDの取得（初回は自動生成）
  Future<String> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 既存のデバイスIDを確認
      String? deviceId = prefs.getString(_deviceIdKey);
      
      if (deviceId == null || deviceId.isEmpty) {
        // 新しいデバイスIDを生成
        deviceId = _uuid.v4();
        
        // 生成したIDを保存
        await prefs.setString(_deviceIdKey, deviceId);
        
        // 初回起動フラグを設定
        await prefs.setBool(_firstLaunchKey, true);
        
        debugPrint('新しいデバイスID生成: ${deviceId.substring(0, 8)}...');
      } else {
        debugPrint('既存デバイスID取得: ${deviceId.substring(0, 8)}...');
      }
      
      return deviceId;
    } catch (e) {
      debugPrint('デバイスID取得エラー: $e');
      // エラー時はセッション用の一時IDを生成
      return _uuid.v4();
    }
  }
  
  /// 初回起動かどうかの確認
  Future<bool> isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirst = prefs.getBool(_firstLaunchKey) ?? false;
      
      if (isFirst) {
        // 初回フラグをクリア
        await prefs.setBool(_firstLaunchKey, false);
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('初回起動確認エラー: $e');
      return false;
    }
  }
  
  /// デバイスIDの再生成（リセット機能）
  Future<String> regenerateDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 新しいIDを生成
      final newDeviceId = _uuid.v4();
      
      // 保存
      await prefs.setString(_deviceIdKey, newDeviceId);
      
      debugPrint('デバイスID再生成: ${newDeviceId.substring(0, 8)}...');
      
      return newDeviceId;
    } catch (e) {
      debugPrint('デバイスID再生成エラー: $e');
      throw Exception('デバイスIDの再生成に失敗しました');
    }
  }
  
  /// デバイスIDの削除（完全リセット）
  Future<void> clearDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_deviceIdKey);
      await prefs.remove(_firstLaunchKey);
      
      debugPrint('デバイスIDクリア完了');
    } catch (e) {
      debugPrint('デバイスIDクリアエラー: $e');
      throw Exception('デバイスIDの削除に失敗しました');
    }
  }
  
  /// デバイスIDの形式検証
  static bool isValidDeviceId(String deviceId) {
    if (deviceId.isEmpty) return false;
    
    // UUID v4 形式の検証
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    
    return uuidRegex.hasMatch(deviceId);
  }
  
  /// デバイス情報の取得（デバッグ用）
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final deviceId = await getDeviceId();
      final isFirst = await isFirstLaunch();
      
      return {
        'deviceId': deviceId,
        'deviceIdPrefix': deviceId.substring(0, 8),
        'isFirstLaunch': isFirst,
        'isValidFormat': isValidDeviceId(deviceId),
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'deviceId': null,
        'isFirstLaunch': false,
        'isValidFormat': false,
      };
    }
  }
}