import { NextRequest, NextResponse } from 'next/server'
import { getThoughts } from '@/lib/supabase'

export async function GET(request: NextRequest) {
  try {
    console.log('=== Export API開始 ===')
    
    const { searchParams } = new URL(request.url)
    const format = searchParams.get('format') || 'csv'
    console.log('エクスポート形式:', format)

    // データを取得
    const result = await getThoughts()
    console.log('データ取得結果:', result.success, result.data?.length || 0)
    
    if (!result.success || !result.data) {
      console.error('データ取得失敗:', result.error)
      return NextResponse.json(
        { error: 'データの取得に失敗しました' },
        { status: 500 }
      )
    }

    const thoughts = result.data
    console.log('取得したデータ数:', thoughts.length)

    if (thoughts.length === 0) {
      return NextResponse.json(
        { error: 'エクスポートするデータがありません' },
        { status: 400 }
      )
    }

    if (format === 'csv') {
      // CSV形式でエクスポート
      const csvHeaders = [
        'ID',
        'カテゴリ',
        '内容',
        '記録日',
        '作成日時',
        'AI感情',
        'AI感情スコア',
        'AIテーマ',
        'AIキーワード',
        'AI要約',
        'AIアドバイス',
        'AI分析日時'
      ]

      const csvRows = thoughts.map(thought => [
        thought.id,
        thought.category,
        `"${(thought.content || '').replace(/"/g, '""')}"`, // CSVエスケープ
        thought.entry_date || '',
        thought.created_at || '',
        thought.ai_emotion || '',
        thought.ai_emotion_score !== null && thought.ai_emotion_score !== undefined ? thought.ai_emotion_score : '',
        thought.ai_themes && Array.isArray(thought.ai_themes) ? `"${thought.ai_themes.join(', ')}"` : '',
        thought.ai_keywords && Array.isArray(thought.ai_keywords) ? `"${thought.ai_keywords.join(', ')}"` : '',
        thought.ai_summary ? `"${thought.ai_summary.replace(/"/g, '""')}"` : '',
        thought.ai_suggestion ? `"${thought.ai_suggestion.replace(/"/g, '""')}"` : '',
        thought.ai_analyzed_at || ''
      ])

      const csvContent = [csvHeaders.join(','), ...csvRows.map(row => row.join(','))].join('\n')
      console.log('CSV生成完了、文字数:', csvContent.length)

      // BOM付きUTF-8でエンコード（日本語対応）
      const bomUtf8 = '\uFEFF' + csvContent

      return new NextResponse(bomUtf8, {
        status: 200,
        headers: {
          'Content-Type': 'text/csv; charset=utf-8',
          'Content-Disposition': `attachment; filename="clarity-thoughts-${new Date().toISOString().split('T')[0]}.csv"`,
          'Cache-Control': 'no-cache',
        },
      })

    } else if (format === 'json') {
      // JSON形式でエクスポート
      const exportData = {
        exportDate: new Date().toISOString(),
        totalRecords: thoughts.length,
        analyzedRecords: thoughts.filter(t => t.ai_emotion).length,
        data: thoughts.map(thought => ({
          id: thought.id,
          category: thought.category,
          content: thought.content,
          entryDate: thought.entry_date,
          createdAt: thought.created_at,
          aiAnalysis: {
            emotion: thought.ai_emotion,
            emotionScore: thought.ai_emotion_score,
            themes: thought.ai_themes,
            keywords: thought.ai_keywords,
            summary: thought.ai_summary,
            suggestion: thought.ai_suggestion,
            analyzedAt: thought.ai_analyzed_at
          }
        }))
      }

      console.log('JSON生成完了')

      return new NextResponse(JSON.stringify(exportData, null, 2), {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Content-Disposition': `attachment; filename="clarity-thoughts-${new Date().toISOString().split('T')[0]}.json"`,
          'Cache-Control': 'no-cache',
        },
      })

    } else {
      return NextResponse.json(
        { error: 'サポートされていないフォーマットです。csv または json を指定してください。' },
        { status: 400 }
      )
    }

  } catch (error) {
    console.error('=== Export APIエラー ===')
    console.error('エラー詳細:', error)
    
    const errorMessage = error instanceof Error ? error.message : 'Unknown error'
    
    return NextResponse.json(
      { 
        error: 'エクスポートに失敗しました', 
        details: errorMessage 
      },
      { status: 500 }
    )
  }
}