import { NextRequest, NextResponse } from 'next/server'

export async function POST(request: NextRequest) {
  try {
    const { content } = await request.json()

    if (!content || content.trim().length === 0) {
      return NextResponse.json(
        { error: '分析する内容が入力されていません' },
        { status: 400 }
      )
    }

    // 一時的なモックデータ（OpenAI API呼び出しなし）
    await new Promise(resolve => setTimeout(resolve, 1500)) // リアルな待機時間

    // 入力内容に応じた簡単な分析
    const words = content.toLowerCase()
    let emotion = 'neutral'
    let emotionScore = 0.5
    let themes = ['日常']
    let keywords = ['思考', '記録']

    // 簡単な感情判定
    if (words.includes('嬉しい') || words.includes('楽しい') || words.includes('良い') || words.includes('成功')) {
      emotion = 'positive'
      emotionScore = 0.8
    } else if (words.includes('悲しい') || words.includes('辛い') || words.includes('困る') || words.includes('不安')) {
      emotion = 'negative'
      emotionScore = 0.3
    } else if (words.includes('仕事') && (words.includes('嬉しい') || words.includes('悲しい'))) {
      emotion = 'mixed'
      emotionScore = 0.6
    }

    // テーマ判定
    if (words.includes('仕事') || words.includes('プロジェクト')) {
      themes = ['仕事', 'キャリア']
    } else if (words.includes('友達') || words.includes('家族')) {
      themes = ['人間関係']
    } else if (words.includes('勉強') || words.includes('学習')) {
      themes = ['学習', '成長']
    }

    const mockAnalysis = {
      emotion,
      emotionScore,
      themes,
      keywords: content.split(' ').slice(0, 3), // 最初の3単語をキーワードに
      summary: `${content.length > 30 ? content.substring(0, 30) + '...' : content}`,
      suggestion: emotion === 'positive' ? 
        'その調子で前向きに続けていきましょう！' : 
        emotion === 'negative' ? 
        '一歩ずつ進んでいけば大丈夫です。' : 
        'バランスの取れた視点を持ち続けましょう。'
    }

    return NextResponse.json({
      success: true,
      analysis: mockAnalysis,
      note: '※ これは開発用のモックデータです'
    })

  } catch (error) {
    console.error('API Route エラー:', error)
    return NextResponse.json(
      { error: 'AI分析に失敗しました' },
      { status: 500 }
    )
  }
}