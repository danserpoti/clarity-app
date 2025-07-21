import OpenAI from 'openai'

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
})

// 思考分析の型定義
export interface ThoughtAnalysis {
  emotion: 'positive' | 'negative' | 'neutral' | 'mixed'
  emotionScore: number // 0-1の範囲
  themes: string[]
  keywords: string[]
  summary: string
  suggestion: string
}

// 思考を分析する関数
export async function analyzeThought(content: string): Promise<ThoughtAnalysis> {
  try {
    const response = await openai.chat.completions.create({
      model: "gpt-4o-mini", // ← ここを変更！
      messages: [
        {
          role: "system",
          content: `あなたは心理カウンセラーのような役割で、ユーザーの思考や感情を分析します。
以下のJSONフォーマットで回答してください：

{
  "emotion": "positive | negative | neutral | mixed",
  "emotionScore": 0-1の数値,
  "themes": ["テーマ1", "テーマ2"],
  "keywords": ["キーワード1", "キーワード2"],
  "summary": "内容の要約（50文字以内）",
  "suggestion": "建設的なアドバイス（100文字以内）"
}

感情の判定基準：
- positive: 前向き、喜び、達成感など
- negative: 悲しみ、不安、怒りなど  
- neutral: 中性的、事実的
- mixed: 複数の感情が混在

テーマは「仕事」「人間関係」「健康」「学習」「趣味」「家族」などのカテゴリから選択。`
        },
        {
          role: "user",
          content: content
        }
      ],
      temperature: 0.7,
      max_tokens: 500
    })

    const result = response.choices[0]?.message?.content
    if (!result) {
      throw new Error('OpenAI APIからの応答が空です')
    }

    // JSONパースを試行
    try {
      const parsed = JSON.parse(result) as ThoughtAnalysis
      return parsed
    } catch (parseError) {
      console.error('JSON解析エラー:', parseError)
      // フォールバック: デフォルト値を返す
      return {
        emotion: 'neutral',
        emotionScore: 0.5,
        themes: ['その他'],
        keywords: ['分析中'],
        summary: '分析処理中...',
        suggestion: '後ほど詳細な分析結果をお見せします。'
      }
    }
  } catch (error) {
    console.error('OpenAI API エラー:', error)
    throw new Error('AI分析に失敗しました')
  }
}