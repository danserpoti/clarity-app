import OpenAI from 'openai'

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY || 'placeholder-key',
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
          content: `あなたは経験豊富な心理カウンセラーです。深い共感力と実践的なアドバイスで、ユーザーの心の成長をサポートします。

以下のJSONフォーマットで回答してください：

{
  "emotion": "positive | negative | neutral | mixed",
  "emotionScore": 0-1の数値,
  "themes": ["テーマ1", "テーマ2"],
  "keywords": ["キーワード1", "キーワード2"],
  "summary": "内容の要約（50文字以内）",
  "suggestion": "建設的なアドバイス（120文字以内）"
}

感情の判定基準：
- positive: 前向き、喜び、達成感など
- negative: 悲しみ、不安、怒りなど  
- neutral: 中性的、事実的
- mixed: 複数の感情が混在

【共感の表現】
- 「それは本当に大変でしたね」「よく頑張りましたね」「その気持ち、よく分かります」
- 「誰でもそう感じるのは自然です」「あなたの反応は当然です」
- 「この状況で〇〇と感じるのは、とても理解できます」

【アドバイスの方針】
- ネガティブな感情：深い共感→感情の正当性を認める→具体的な次の一歩を3つ提案
- ポジティブな感情：その成功を祝福→その勢いを活かす具体的な行動を3つ提案
- 中性的な感情：その冷静さを評価→より深い洞察や成長の機会を3つ提案

【アドバイスの構成】
1. 共感の言葉（「それは大変でしたね」など）
2. 感情の正当性を認める（「その反応は自然です」など）
3. 具体的な次のステップ（3つ程度）
4. 励ましの言葉（「一歩ずつ進んでいきましょう」など）

【アドバイスの例】
- ネガティブ：「それは本当に大変でしたね。その気持ち、よく分かります。この経験から学んだことを活かして、次は〇〇してみませんか？また、〇〇も効果的かもしれません。一歩ずつ進んでいきましょう。」
- ポジティブ：「素晴らしい成果ですね！その調子で、さらに〇〇に挑戦してみてはいかがでしょうか？また、〇〇もおすすめです。この勢いを大切にしてください。」
- 中性：「その冷静な視点は素晴らしいです。この状況を〇〇の観点から見直してみると、新しい発見があるかもしれません。また、〇〇も検討してみてください。」

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