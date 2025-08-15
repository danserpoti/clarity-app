// lib/usage.js
// 使用量管理システム - デバイス別の月間使用量制限管理

import { getUsageData, updateUsageData, isValidDeviceId } from './storage.js';

/**
 * 使用量制限の設定
 */
const USAGE_LIMITS = {
  FREE_PLAN: {
    monthly: parseInt(process.env.FREE_PLAN_MONTHLY_LIMIT) || 30,
    name: 'Free Plan'
  },
  PREMIUM_PLAN: {
    monthly: 1000,
    name: 'Premium Plan' // 将来的な拡張用
  }
};

/**
 * デバイスの使用量チェック
 * @param {string} deviceId - 匿名デバイスID
 * @param {string} planType - プランタイプ（現在は 'free' のみ）
 * @returns {Promise<Object>} 使用量情報とチェック結果
 */
export async function checkUsageLimit(deviceId, planType = 'free') {
  try {
    // デバイスIDの検証
    if (!isValidDeviceId(deviceId)) {
      throw new Error('Invalid device ID format');
    }

    // プランタイプの検証
    const planConfig = planType === 'premium' ? USAGE_LIMITS.PREMIUM_PLAN : USAGE_LIMITS.FREE_PLAN;
    
    // 現在の使用量データを取得
    const usageData = await getUsageData(deviceId);
    
    const result = {
      deviceId,
      planType,
      planName: planConfig.name,
      usage: {
        used: usageData.used,
        limit: usageData.limit || planConfig.monthly,
        remaining: Math.max(0, (usageData.limit || planConfig.monthly) - usageData.used),
        resetDate: usageData.resetDate
      },
      canUse: usageData.used < (usageData.limit || planConfig.monthly),
      isNewDevice: usageData.used === 0,
      lastUsedAt: usageData.lastUsedAt || null
    };

    return result;
  } catch (error) {
    console.error('Error checking usage limit:', error);
    throw new Error(`Usage limit check failed: ${error.message}`);
  }
}

/**
 * 使用量の増加（API呼び出し後に実行）
 * @param {string} deviceId - 匿名デバイスID
 * @param {number} increment - 増加値（通常は1）
 * @returns {Promise<Object>} 更新後の使用量情報
 */
export async function incrementUsage(deviceId, increment = 1) {
  try {
    // デバイスIDの検証
    if (!isValidDeviceId(deviceId)) {
      throw new Error('Invalid device ID format');
    }

    // 使用量を更新
    const updatedData = await updateUsageData(deviceId, increment);
    
    const result = {
      deviceId,
      usage: {
        used: updatedData.used,
        limit: updatedData.limit,
        remaining: Math.max(0, updatedData.limit - updatedData.used),
        resetDate: updatedData.resetDate
      },
      updatedAt: updatedData.updatedAt,
      lastUsedAt: updatedData.lastUsedAt
    };

    return result;
  } catch (error) {
    console.error('Error incrementing usage:', error);
    throw new Error(`Usage increment failed: ${error.message}`);
  }
}

/**
 * 使用量制限の事前チェック（APIリクエスト前に実行）
 * @param {string} deviceId - 匿名デバイスID
 * @param {string} planType - プランタイプ
 * @returns {Promise<Object>} チェック結果
 */
export async function preCheckUsage(deviceId, planType = 'free') {
  try {
    const usageInfo = await checkUsageLimit(deviceId, planType);
    
    if (!usageInfo.canUse) {
      return {
        allowed: false,
        reason: 'USAGE_LIMIT_EXCEEDED',
        message: '月間使用量上限に達しました',
        usage: usageInfo.usage,
        upgradeUrl: 'https://clarity-app.com/pricing' // 将来的な課金ページ
      };
    }

    // 使用量が上限の90%を超えた場合は警告
    const usagePercentage = (usageInfo.usage.used / usageInfo.usage.limit) * 100;
    const warning = usagePercentage >= 90 ? {
      nearLimit: true,
      message: '月間使用量の上限に近づいています',
      usagePercentage: Math.round(usagePercentage)
    } : null;

    return {
      allowed: true,
      usage: usageInfo.usage,
      warning,
      isNewDevice: usageInfo.isNewDevice
    };
  } catch (error) {
    console.error('Error in pre-check usage:', error);
    // エラーが発生した場合はリクエストを許可（フェイルオープン）
    return {
      allowed: true,
      error: error.message,
      fallback: true
    };
  }
}

/**
 * 使用量統計の生成
 * @param {string} deviceId - 匿名デバイスID
 * @returns {Promise<Object>} 統計情報
 */
export async function getUsageStats(deviceId) {
  try {
    if (!isValidDeviceId(deviceId)) {
      throw new Error('Invalid device ID format');
    }

    const usageData = await getUsageData(deviceId);
    const currentDate = new Date();
    const resetDate = new Date(usageData.resetDate);
    
    // 今月の残り日数を計算
    const daysInMonth = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0).getDate();
    const currentDay = currentDate.getDate();
    const remainingDays = daysInMonth - currentDay;
    
    // 1日あたりの平均使用量を計算
    const dailyAverage = usageData.used > 0 ? Math.round((usageData.used / currentDay) * 10) / 10 : 0;
    
    // 予想使用量を計算
    const projectedUsage = Math.round(dailyAverage * daysInMonth);

    return {
      deviceId,
      current: {
        used: usageData.used,
        limit: usageData.limit,
        remaining: usageData.limit - usageData.used,
        percentage: Math.round((usageData.used / usageData.limit) * 100)
      },
      timeframe: {
        currentMonth: currentDate.toISOString().slice(0, 7),
        resetDate: usageData.resetDate,
        remainingDays,
        currentDay
      },
      analytics: {
        dailyAverage,
        projectedUsage,
        onTrackForLimit: projectedUsage <= usageData.limit,
        recommendedDailyUsage: Math.floor((usageData.limit - usageData.used) / Math.max(1, remainingDays))
      },
      lastActivity: {
        lastUsedAt: usageData.lastUsedAt,
        updatedAt: usageData.updatedAt
      }
    };
  } catch (error) {
    console.error('Error getting usage stats:', error);
    throw new Error(`Usage stats failed: ${error.message}`);
  }
}

/**
 * 使用量リセット日の計算
 * @returns {string} 次回リセット日（ISO文字列）
 */
export function getNextResetDate() {
  const now = new Date();
  const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);
  return nextMonth.toISOString();
}

/**
 * プランアップグレードの提案生成
 * @param {Object} usageInfo - 使用量情報
 * @returns {Object} アップグレード提案
 */
export function generateUpgradeRecommendation(usageInfo) {
  const { used, limit } = usageInfo.usage;
  const usagePercentage = (used / limit) * 100;
  
  if (usagePercentage >= 100) {
    return {
      recommended: true,
      reason: 'LIMIT_EXCEEDED',
      message: '月間使用量上限に達しています。より多くのAI分析をご利用いただくためにプレミアムプランをご検討ください。',
      benefits: [
        '月間1000回のAI分析',
        '優先サポート',
        '高度な分析機能（予定）'
      ]
    };
  }
  
  if (usagePercentage >= 80) {
    return {
      recommended: true,
      reason: 'HIGH_USAGE',
      message: '使用量が上限の80%を超えています。プレミアムプランで制限なくAI分析をお楽しみください。',
      benefits: [
        '月間1000回のAI分析',
        '使用量を気にせず利用可能'
      ]
    };
  }
  
  return {
    recommended: false,
    message: '現在のプランで十分ご利用いただけています。'
  };
}

/**
 * エラーレスポンス生成（使用量超過時）
 * @param {Object} usageInfo - 使用量情報
 * @returns {Object} エラーレスポンス
 */
export function createUsageLimitResponse(usageInfo) {
  const upgradeRecommendation = generateUpgradeRecommendation(usageInfo);
  
  return {
    success: false,
    error: 'USAGE_LIMIT_EXCEEDED',
    message: '月間使用量上限に達しました',
    usage: usageInfo.usage,
    upgrade: {
      recommended: true,
      url: 'https://clarity-app.com/pricing',
      message: upgradeRecommendation.message,
      benefits: upgradeRecommendation.benefits
    },
    resetInfo: {
      resetDate: usageInfo.usage.resetDate,
      message: `使用量は ${new Date(usageInfo.usage.resetDate).toLocaleDateString('ja-JP')} にリセットされます。`
    }
  };
}