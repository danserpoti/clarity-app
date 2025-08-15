// lib/storage.js
// Vercel KV データベース統合 - プライバシー重視の最小限データ保存

import { kv } from '@vercel/kv';

/**
 * KV データベースのキー命名規則
 * - usage:{deviceId}:{month} - 使用量データ
 * - rate:{ip}:{minute} - レート制限データ
 */

/**
 * 使用量データの取得
 * @param {string} deviceId - 匿名デバイスID
 * @returns {Promise<Object|null>} 使用量データ
 */
export async function getUsageData(deviceId) {
  try {
    // 現在の月をキーとして使用 (YYYY-MM形式)
    const currentMonth = new Date().toISOString().slice(0, 7);
    const key = `usage:${deviceId}:${currentMonth}`;
    
    const data = await kv.get(key);
    
    if (!data) {
      // データが存在しない場合は初期値を返す
      return {
        used: 0,
        limit: 30,
        resetDate: getNextMonthFirstDay(),
        deviceId,
        month: currentMonth
      };
    }
    
    return data;
  } catch (error) {
    console.error('Error getting usage data:', error);
    throw new Error('Failed to get usage data');
  }
}

/**
 * 使用量データの更新
 * @param {string} deviceId - 匿名デバイスID
 * @param {number} increment - 増加値（通常は1）
 * @returns {Promise<Object>} 更新後の使用量データ
 */
export async function updateUsageData(deviceId, increment = 1) {
  try {
    const currentMonth = new Date().toISOString().slice(0, 7);
    const key = `usage:${deviceId}:${currentMonth}`;
    
    // 現在の使用量データを取得
    const currentData = await getUsageData(deviceId);
    
    // 使用量を増加
    const newUsed = currentData.used + increment;
    
    const updatedData = {
      ...currentData,
      used: newUsed,
      lastUsedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    // データを保存（月末に自動削除されるよう TTL を設定）
    const ttlSeconds = getTTLUntilNextMonth();
    await kv.setex(key, ttlSeconds, updatedData);
    
    return updatedData;
  } catch (error) {
    console.error('Error updating usage data:', error);
    throw new Error('Failed to update usage data');
  }
}

/**
 * レート制限データの確認・更新
 * @param {string} ip - クライアントIPアドレス
 * @param {number} limit - 分間制限数
 * @returns {Promise<Object>} レート制限情報
 */
export async function checkRateLimit(ip, limit = 10) {
  try {
    const currentMinute = Math.floor(Date.now() / 60000); // 分単位のタイムスタンプ
    const key = `rate:${ip}:${currentMinute}`;
    
    // 現在の分でのリクエスト数を取得
    const currentCount = await kv.get(key) || 0;
    
    if (currentCount >= limit) {
      return {
        allowed: false,
        count: currentCount,
        limit,
        resetTime: (currentMinute + 1) * 60000 // 次の分のタイムスタンプ
      };
    }
    
    // カウントを増加（1分間でexpire）
    await kv.setex(key, 60, currentCount + 1);
    
    return {
      allowed: true,
      count: currentCount + 1,
      limit,
      resetTime: (currentMinute + 1) * 60000
    };
  } catch (error) {
    console.error('Error checking rate limit:', error);
    // レート制限チェックに失敗した場合はリクエストを許可
    return { allowed: true, count: 0, limit, resetTime: Date.now() + 60000 };
  }
}

/**
 * デバイスIDの有効性チェック
 * @param {string} deviceId - デバイスID
 * @returns {boolean} 有効性
 */
export function isValidDeviceId(deviceId) {
  if (!deviceId || typeof deviceId !== 'string') {
    return false;
  }
  
  // UUID v4 形式または英数字36文字以内
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  const customIdRegex = /^[a-zA-Z0-9_-]{8,36}$/;
  
  return uuidRegex.test(deviceId) || customIdRegex.test(deviceId);
}

/**
 * 使用量統計の取得（管理用）
 * @returns {Promise<Object>} システム全体の統計
 */
export async function getSystemStats() {
  try {
    // 実際の実装では、Vercel KVの制限により、全キーのスキャンは効率的ではない
    // 代わりに、別途統計用のキーを管理するか、外部分析サービスを使用することを推奨
    
    return {
      totalUsers: 'N/A', // KVの制限により計算困難
      totalRequests: 'N/A',
      currentMonth: new Date().toISOString().slice(0, 7),
      message: 'For detailed analytics, consider integrating with external services'
    };
  } catch (error) {
    console.error('Error getting system stats:', error);
    return {
      totalUsers: 0,
      totalRequests: 0,
      error: 'Failed to get system stats'
    };
  }
}

/**
 * データのクリーンアップ（過去月のデータ削除）
 * 注意: Vercel KV では TTL による自動削除が推奨
 */
export async function cleanupOldData() {
  try {
    // TTLによる自動削除を使用しているため、手動クリーンアップは不要
    console.log('Using TTL-based auto cleanup, manual cleanup not required');
    return { success: true, message: 'Auto cleanup via TTL' };
  } catch (error) {
    console.error('Error in cleanup:', error);
    return { success: false, error: error.message };
  }
}

// ユーティリティ関数

/**
 * 来月1日の Date オブジェクトを取得
 * @returns {Date} 来月1日 00:00:00 UTC
 */
function getNextMonthFirstDay() {
  const now = new Date();
  const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);
  return nextMonth.toISOString();
}

/**
 * 来月までの秒数を取得（TTL用）
 * @returns {number} 秒数
 */
function getTTLUntilNextMonth() {
  const now = new Date();
  const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);
  const diffMs = nextMonth.getTime() - now.getTime();
  return Math.ceil(diffMs / 1000);
}

/**
 * IP アドレスの匿名化
 * @param {string} ip - IPアドレス
 * @returns {string} 匿名化されたIP
 */
export function anonymizeIP(ip) {
  if (!ip) return 'unknown';
  
  // IPv4 の場合、最後のオクテットを0にする
  if (ip.includes('.')) {
    const parts = ip.split('.');
    if (parts.length === 4) {
      return `${parts[0]}.${parts[1]}.${parts[2]}.0`;
    }
  }
  
  // IPv6 の場合、下位64ビットを削除
  if (ip.includes(':')) {
    const parts = ip.split(':');
    return parts.slice(0, 4).join(':') + '::';
  }
  
  return 'unknown';
}