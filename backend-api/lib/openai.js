// lib/openai.js
// OpenAI GPT-5-mini-2025-08-07 統合 - Clarityアプリの思考分析

import OpenAI from 'openai';

// OpenAI クライアントの初期化
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

/**
 * GPT-5-mini-2025-08-07 の設定
 * 注意: 正確なモデル名を使用すること
 */
const MODEL_CONFIG = {
  model: 'gpt-5-mini-2025-08-07', // 正確なモデル名
  temperature: 0.3,
  max_tokens: 800,
  reasoning_effort: 'minimal', // 高速化のため
  response_format: { type: 'json_object' }
};

/**
 * 思考内容のカテゴリマッピング
 */
const CATEGORY_MAPPING = {
  '仕事': 'work',
  '人間関係': 'relationships',
  '目標管理': 'goals',
  '学習': 'learning',
  '感情': 'emotions',
  'その他': 'other'
};

/**
 * 思考分析用プロンプトの構築
 * 既存Flutterアプリと完全に同じプロンプトを使用
 * @param {string} content - 思考内容
 * @param {string} category - カテゴリ
 * @returns {string} プロンプト
 */
function buildThoughtAnalysisPrompt(content, category) {
  return `あなたは経験豊富な心理カウンセラー兼ライフコーチです。以下の思考内容を分析し、必ず建設的なアドバイスを提供してください。

思考内容: "${content}"

以下のJSON形式で回答してください：

{
  "emotion": "positive/negative/neutral/mixed",
  "emotionScore": 0.0-1.0の数値,
  "themes": ["主要テーマ1", "主要テーマ2"],
  "keywords": ["キーワード1", "キーワード2", "キーワード3"],
  "summary": "思考内容の要約（1文）",
  "suggestion": "具体的で実践的なアドバイス（必須）"
}

アドバイス作成の重要なルール：
1. 必ず「共感 + 具体的アドバイス」の構成にする
2. 実践可能な行動提案を含める
3. ポジティブで前向きな視点を提供する
4. 2-3文で簡潔にまとめる

例：
- 悪い例：「大変ですね。」「お疲れ様です。」
- 良い例：「契約キャンセルは残念ですが、これは営業でよくあることです。次回は契約前に顧客の懸念事項をより詳しく確認し、フォローアップのタイミングを調整してみましょう。この経験は必ずあなたの営業スキル向上に繋がります。」

JSON形式のみで回答し、他の文字は含めないでください。`;
}

/**
 * システムプロンプト（既存Flutterアプリと同様）
 */
const SYSTEM_PROMPT = `あなたは経験豊富な心理カウンセラーです。深い共感力と実践的なアドバイスで、ユーザーの心の成長をサポートします。

【プライバシー原則】
- 個人識別情報は一切記録・保存しない
- 分析内容を他の目的で使用しない
- セッション終了後は全て忘却する

【共感の基本姿勢】
- ユーザーの感情を100%受け入れ、否定しない
- 「それは大変でしたね」「よく頑張りましたね」など、共感の言葉を必ず含める
- ユーザーの視点に立って、その状況を理解する
- 感情の強さや複雑さを認め、軽視しない

【分析方針】
- 表面的な感情の奥にある本質的なニーズを見抜く
- ユーザーの強みや過去の成功体験を思い出させる
- 現在の困難を成長の機会として再定義する
- ユーザーの価値観や目標に沿ったアドバイスを提供

【アドバイスの基本姿勢】
- まず深い共感を示し、その後で具体的な解決策を提案
- ユーザーの感情を認め、その感情が自然であることを伝える
- 現在の状況を成長の機会として捉える視点を提供
- 具体的で実践可能な次のステップを3つ程度提案
- ユーザーの強みや可能性を引き出す質問を含める
- 「一歩前に進む」ための勇気と希望を与える
- 完璧を求めず、小さな進歩を大切にする姿勢を伝える

JSON形式で正確に回答し、JSON以外は出力しないでください。`;

/**
 * 思考内容をAI分析
 * @param {string} content - 思考内容
 * @param {string} category - カテゴリ（日本語）
 * @returns {Promise<Object>} 分析結果
 */
export async function analyzeThought(content, category) {
  try {
    // 入力検証
    if (!content || typeof content !== 'string') {
      throw new Error('Invalid content: must be a non-empty string');
    }

    if (content.trim().length < 10) {
      throw new Error('Content too short: minimum 10 characters required');
    }

    if (content.length > (parseInt(process.env.MAX_CONTENT_LENGTH) || 5000)) {
      throw new Error('Content too long: maximum 5000 characters allowed');
    }

    if (!category || !CATEGORY_MAPPING[category]) {
      throw new Error(`Invalid category: must be one of ${Object.keys(CATEGORY_MAPPING).join(', ')}`);
    }

    // APIリクエストの構築
    const userPrompt = `カテゴリ: ${category}\n\n${buildThoughtAnalysisPrompt(content, category)}`;

    console.log('OpenAI API request started:', {
      model: MODEL_CONFIG.model,
      contentLength: content.length,
      category,
      timestamp: new Date().toISOString()
    });

    // OpenAI API 呼び出し
    const response = await openai.chat.completions.create({
      model: MODEL_CONFIG.model,
      messages: [
        {
          role: 'system',
          content: SYSTEM_PROMPT
        },
        {
          role: 'user',
          content: userPrompt
        }
      ],
      temperature: MODEL_CONFIG.temperature,
      max_tokens: MODEL_CONFIG.max_tokens,
      reasoning_effort: MODEL_CONFIG.reasoning_effort,
      response_format: MODEL_CONFIG.response_format
    });

    console.log('OpenAI API response received:', {
      id: response.id,
      model: response.model,
      usage: response.usage,
      timestamp: new Date().toISOString()
    });

    // レスポンスの検証
    if (!response.choices || response.choices.length === 0) {
      throw new Error('No response choices received from OpenAI');
    }

    const messageContent = response.choices[0]?.message?.content;
    if (!messageContent) {
      throw new Error('Empty response content from OpenAI');
    }

    // JSON パース
    let analysisData;
    try {
      analysisData = JSON.parse(messageContent);
    } catch (parseError) {
      console.error('JSON parse error:', parseError);
      console.error('Raw content:', messageContent);
      throw new Error('Invalid JSON response from OpenAI');
    }

    // 分析結果の検証と正規化
    const validatedResult = validateAndNormalizeAnalysis(analysisData);

    console.log('Analysis completed successfully:', {
      emotion: validatedResult.emotion,
      themesCount: validatedResult.themes?.length || 0,
      keywordsCount: validatedResult.keywords?.length || 0,
      hasValidSuggestion: !!(validatedResult.suggestion && validatedResult.suggestion.length > 20)
    });

    return {
      success: true,
      analysis: validatedResult,
      metadata: {
        model: response.model,
        usage: response.usage,
        processingTime: Date.now(),
        category: CATEGORY_MAPPING[category]
      }
    };

  } catch (error) {
    console.error('Error in analyzeThought:', error);

    // OpenAI API 固有のエラー処理
    if (error.status === 401) {
      throw new Error('OpenAI API key is invalid or unauthorized');
    } else if (error.status === 429) {
      throw new Error('OpenAI API rate limit exceeded. Please try again later.');
    } else if (error.status === 500) {
      throw new Error('OpenAI API server error. Please try again later.');
    } else if (error.code === 'insufficient_quota') {
      throw new Error('OpenAI API quota exceeded. Please check your billing.');
    }

    // 一般的なエラー
    throw new Error(`AI analysis failed: ${error.message}`);
  }
}

/**
 * 分析結果の検証と正規化
 * @param {Object} data - 分析データ
 * @returns {Object} 検証済みの分析結果
 */
function validateAndNormalizeAnalysis(data) {
  if (!data || typeof data !== 'object') {
    throw new Error('Analysis data must be an object');
  }

  // 必須フィールドの検証
  const requiredFields = ['emotion', 'emotionScore', 'themes', 'keywords', 'summary', 'suggestion'];
  const missingFields = requiredFields.filter(field => !(field in data));
  if (missingFields.length > 0) {
    throw new Error(`Missing required fields: ${missingFields.join(', ')}`);
  }

  // emotion の検証
  const validEmotions = ['positive', 'negative', 'neutral', 'mixed'];
  if (!validEmotions.includes(data.emotion)) {
    throw new Error(`Invalid emotion: must be one of ${validEmotions.join(', ')}`);
  }

  // emotionScore の検証
  const emotionScore = parseFloat(data.emotionScore);
  if (isNaN(emotionScore) || emotionScore < 0 || emotionScore > 1) {
    throw new Error('emotionScore must be a number between 0.0 and 1.0');
  }

  // 配列フィールドの検証
  if (!Array.isArray(data.themes) || !Array.isArray(data.keywords)) {
    throw new Error('themes and keywords must be arrays');
  }

  // 文字列フィールドの検証
  if (typeof data.summary !== 'string' || typeof data.suggestion !== 'string') {
    throw new Error('summary and suggestion must be strings');
  }

  if (data.suggestion.length < 20) {
    throw new Error('suggestion must be at least 20 characters long');
  }

  return {
    emotion: data.emotion,
    emotionScore: Math.round(emotionScore * 100) / 100, // 小数点以下2桁
    themes: data.themes.slice(0, 5).map(theme => String(theme).substring(0, 50)), // 最大5個、各50文字以内
    keywords: data.keywords.slice(0, 10).map(keyword => String(keyword).substring(0, 30)), // 最大10個、各30文字以内
    summary: String(data.summary).substring(0, 200), // 最大200文字
    suggestion: String(data.suggestion).substring(0, 1000) // 最大1000文字
  };
}

/**
 * OpenAI API の接続テスト
 * @returns {Promise<boolean>} 接続成功可否
 */
export async function testOpenAIConnection() {
  try {
    const response = await openai.chat.completions.create({
      model: MODEL_CONFIG.model,
      messages: [
        {
          role: 'user',
          content: 'Hello, this is a connection test. Please respond with "OK" in JSON format: {"status": "OK"}'
        }
      ],
      max_tokens: 50,
      reasoning_effort: 'minimal',
      response_format: { type: 'json_object' }
    });

    const content = response.choices[0]?.message?.content;
    const parsed = JSON.parse(content);
    return parsed.status === 'OK';
  } catch (error) {
    console.error('OpenAI connection test failed:', error);
    return false;
  }
}

/**
 * モデル情報の取得
 * @returns {Object} モデル設定情報
 */
export function getModelInfo() {
  return {
    model: MODEL_CONFIG.model,
    temperature: MODEL_CONFIG.temperature,
    maxTokens: MODEL_CONFIG.max_tokens,
    reasoningEffort: MODEL_CONFIG.reasoning_effort,
    supportedCategories: Object.keys(CATEGORY_MAPPING),
    version: '1.0.0',
    description: 'GPT-5-mini-2025-08-07 integration for Clarity thought analysis'
  };
}