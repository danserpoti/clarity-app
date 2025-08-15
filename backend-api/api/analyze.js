// api/analyze.js
// Clarity思考分析API - メインエンドポイント
// GPT-5-mini-2025-08-07を使用したAI分析サービス

import { analyzeThought } from '../lib/openai.js';
import { preCheckUsage, incrementUsage, createUsageLimitResponse } from '../lib/usage.js';
import { checkRateLimit, anonymizeIP } from '../lib/storage.js';

/**
 * CORS ヘッダー設定
 */
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
  'Access-Control-Max-Age': '86400',
  'Content-Type': 'application/json'
};

/**
 * 入力検証設定
 */
const VALIDATION_CONFIG = {
  MAX_CONTENT_LENGTH: parseInt(process.env.MAX_CONTENT_LENGTH) || 5000,
  MIN_CONTENT_LENGTH: 10,
  VALID_CATEGORIES: ['仕事', '人間関係', '目標管理', '学習', '感情', 'その他'],
  RATE_LIMIT_PER_MINUTE: parseInt(process.env.RATE_LIMIT_PER_MINUTE) || 10
};

/**
 * メインAPIハンドラー
 */
export default async function handler(req, res) {
  // CORS プリフライト対応
  if (req.method === 'OPTIONS') {
    return res.status(200).json({ success: true });
  }

  // HTTP メソッド検証
  if (req.method !== 'POST') {
    return res.status(405).json({
      success: false,
      error: 'METHOD_NOT_ALLOWED',
      message: 'Only POST method is allowed',
      allowedMethods: ['POST', 'OPTIONS']
    });
  }

  // レスポンスヘッダー設定
  Object.entries(CORS_HEADERS).forEach(([key, value]) => {
    res.setHeader(key, value);
  });

  const startTime = Date.now();
  let deviceId = null;

  try {
    console.log('API request started:', {
      method: req.method,
      userAgent: req.headers['user-agent']?.substring(0, 100),
      timestamp: new Date().toISOString(),
      ip: anonymizeIP(getClientIP(req))
    });

    // 1. リクエストボディの検証
    const validationResult = validateRequestBody(req.body);
    if (!validationResult.valid) {
      return res.status(400).json({
        success: false,
        error: 'VALIDATION_ERROR',
        message: validationResult.message,
        details: validationResult.details
      });
    }

    const { content, category, deviceId: requestDeviceId } = req.body;
    deviceId = requestDeviceId;

    console.log('Request validated:', {
      contentLength: content.length,
      category,
      deviceId: deviceId.substring(0, 8) + '...' // ログに部分的なIDのみ記録
    });

    // 2. レート制限チェック
    const clientIP = getClientIP(req);
    const rateLimitResult = await checkRateLimit(
      anonymizeIP(clientIP), 
      VALIDATION_CONFIG.RATE_LIMIT_PER_MINUTE
    );

    if (!rateLimitResult.allowed) {
      console.log('Rate limit exceeded:', {
        ip: anonymizeIP(clientIP),
        count: rateLimitResult.count,
        limit: rateLimitResult.limit
      });

      return res.status(429).json({
        success: false,
        error: 'RATE_LIMIT_EXCEEDED',
        message: `1分間に${VALIDATION_CONFIG.RATE_LIMIT_PER_MINUTE}回までのリクエストが可能です`,
        rateLimit: {
          limit: rateLimitResult.limit,
          remaining: Math.max(0, rateLimitResult.limit - rateLimitResult.count),
          resetTime: rateLimitResult.resetTime
        },
        retryAfter: Math.ceil((rateLimitResult.resetTime - Date.now()) / 1000)
      });
    }

    // 3. 使用量制限チェック
    const usageCheckResult = await preCheckUsage(deviceId, 'free');
    
    if (!usageCheckResult.allowed) {
      console.log('Usage limit exceeded:', {
        deviceId: deviceId.substring(0, 8) + '...',
        reason: usageCheckResult.reason,
        used: usageCheckResult.usage?.used,
        limit: usageCheckResult.usage?.limit
      });

      return res.status(429).json(createUsageLimitResponse({
        usage: usageCheckResult.usage
      }));
    }

    // 4. AI 分析実行
    console.log('Starting AI analysis...');
    const analysisResult = await analyzeThought(content, category);

    if (!analysisResult.success) {
      throw new Error('AI analysis returned unsuccessful result');
    }

    // 5. 使用量の更新
    const updatedUsage = await incrementUsage(deviceId, 1);

    console.log('Analysis completed successfully:', {
      deviceId: deviceId.substring(0, 8) + '...',
      processingTime: Date.now() - startTime,
      newUsageCount: updatedUsage.usage.used,
      remaining: updatedUsage.usage.remaining
    });

    // 6. 成功レスポンス
    const response = {
      success: true,
      analysis: analysisResult.analysis,
      usage: {
        used: updatedUsage.usage.used,
        limit: updatedUsage.usage.limit,
        remaining: updatedUsage.usage.remaining,
        resetDate: updatedUsage.usage.resetDate
      },
      metadata: {
        processingTime: Date.now() - startTime,
        model: analysisResult.metadata?.model || 'gpt-5-mini-2025-08-07',
        version: '1.0.0'
      }
    };

    // 使用量警告の追加
    if (usageCheckResult.warning) {
      response.usage.warning = usageCheckResult.warning;
    }

    return res.status(200).json(response);

  } catch (error) {
    console.error('API error:', {
      error: error.message,
      stack: error.stack?.split('\n')[0], // スタックトレースの1行目のみ
      deviceId: deviceId?.substring(0, 8) + '...' || 'unknown',
      processingTime: Date.now() - startTime
    });

    // エラーレスポンス
    const errorResponse = createErrorResponse(error);
    return res.status(errorResponse.status).json(errorResponse.body);
  }
}

/**
 * リクエストボディの検証
 * @param {Object} body - リクエストボディ
 * @returns {Object} 検証結果
 */
function validateRequestBody(body) {
  if (!body || typeof body !== 'object') {
    return {
      valid: false,
      message: 'Request body must be a JSON object',
      details: { expectedType: 'object', receivedType: typeof body }
    };
  }

  // 必須フィールドの確認
  const requiredFields = ['content', 'category', 'deviceId'];
  const missingFields = requiredFields.filter(field => !(field in body));
  
  if (missingFields.length > 0) {
    return {
      valid: false,
      message: `Missing required fields: ${missingFields.join(', ')}`,
      details: { missingFields, requiredFields }
    };
  }

  const { content, category, deviceId } = body;

  // content の検証
  if (typeof content !== 'string') {
    return {
      valid: false,
      message: 'Content must be a string',
      details: { field: 'content', expectedType: 'string', receivedType: typeof content }
    };
  }

  if (content.trim().length < VALIDATION_CONFIG.MIN_CONTENT_LENGTH) {
    return {
      valid: false,
      message: `Content must be at least ${VALIDATION_CONFIG.MIN_CONTENT_LENGTH} characters`,
      details: { field: 'content', minLength: VALIDATION_CONFIG.MIN_CONTENT_LENGTH, actualLength: content.trim().length }
    };
  }

  if (content.length > VALIDATION_CONFIG.MAX_CONTENT_LENGTH) {
    return {
      valid: false,
      message: `Content must not exceed ${VALIDATION_CONFIG.MAX_CONTENT_LENGTH} characters`,
      details: { field: 'content', maxLength: VALIDATION_CONFIG.MAX_CONTENT_LENGTH, actualLength: content.length }
    };
  }

  // category の検証
  if (typeof category !== 'string') {
    return {
      valid: false,
      message: 'Category must be a string',
      details: { field: 'category', expectedType: 'string', receivedType: typeof category }
    };
  }

  if (!VALIDATION_CONFIG.VALID_CATEGORIES.includes(category)) {
    return {
      valid: false,
      message: `Invalid category. Must be one of: ${VALIDATION_CONFIG.VALID_CATEGORIES.join(', ')}`,
      details: { field: 'category', validOptions: VALIDATION_CONFIG.VALID_CATEGORIES, received: category }
    };
  }

  // deviceId の検証
  if (typeof deviceId !== 'string') {
    return {
      valid: false,
      message: 'DeviceId must be a string',
      details: { field: 'deviceId', expectedType: 'string', receivedType: typeof deviceId }
    };
  }

  // デバイスIDの形式チェック
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  const customIdRegex = /^[a-zA-Z0-9_-]{8,36}$/;
  
  if (!uuidRegex.test(deviceId) && !customIdRegex.test(deviceId)) {
    return {
      valid: false,
      message: 'DeviceId must be a valid UUID v4 format or alphanumeric string (8-36 characters)',
      details: { field: 'deviceId', format: 'UUID v4 or alphanumeric 8-36 chars', received: deviceId.substring(0, 10) + '...' }
    };
  }

  // XSS対策: HTMLタグのチェック
  const htmlRegex = /<[^>]*>/g;
  if (htmlRegex.test(content)) {
    return {
      valid: false,
      message: 'Content must not contain HTML tags',
      details: { field: 'content', issue: 'HTML tags detected' }
    };
  }

  return { valid: true };
}

/**
 * クライアントIPアドレスの取得
 * @param {Object} req - リクエストオブジェクト
 * @returns {string} IPアドレス
 */
function getClientIP(req) {
  return req.headers['x-forwarded-for']?.split(',')[0] ||
         req.headers['x-real-ip'] ||
         req.connection?.remoteAddress ||
         req.socket?.remoteAddress ||
         req.ip ||
         'unknown';
}

/**
 * エラーレスポンスの生成
 * @param {Error} error - エラーオブジェクト
 * @returns {Object} エラーレスポンス
 */
function createErrorResponse(error) {
  const message = error.message || 'An unexpected error occurred';

  // OpenAI API エラー
  if (message.includes('OpenAI')) {
    if (message.includes('rate limit')) {
      return {
        status: 429,
        body: {
          success: false,
          error: 'OPENAI_RATE_LIMIT',
          message: 'AI分析サービスが一時的に制限されています。しばらく経ってから再試行してください。',
          retryAfter: 60,
          canRetry: true
        }
      };
    }

    if (message.includes('quota')) {
      return {
        status: 503,
        body: {
          success: false,
          error: 'SERVICE_UNAVAILABLE',
          message: 'AI分析サービスが一時的に利用できません。後でもう一度お試しください。',
          canRetry: false
        }
      };
    }

    if (message.includes('unauthorized') || message.includes('invalid')) {
      return {
        status: 503,
        body: {
          success: false,
          error: 'SERVICE_CONFIGURATION_ERROR',
          message: 'サービス設定に問題があります。管理者にお問い合わせください。',
          canRetry: false
        }
      };
    }
  }

  // 入力検証エラー
  if (message.includes('Invalid') || message.includes('must be')) {
    return {
      status: 400,
      body: {
        success: false,
        error: 'VALIDATION_ERROR',
        message,
        canRetry: true
      }
    };
  }

  // その他のエラー
  return {
    status: 500,
    body: {
      success: false,
      error: 'INTERNAL_SERVER_ERROR',
      message: 'AI分析処理中にエラーが発生しました。しばらく経ってから再試行してください。',
      canRetry: true,
      supportMessage: '問題が続く場合は、サポートまでお問い合わせください。'
    }
  };
}