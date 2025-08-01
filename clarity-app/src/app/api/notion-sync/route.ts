import { NextRequest, NextResponse } from 'next/server'
import { getThoughts } from '@/lib/localStorage'
import { syncMultipleThoughtsToNotion, syncThoughtToNotion, testNotionConnection } from '@/lib/notion'

export async function POST(request: NextRequest) {
  try {
    console.log('=== Notion同期API開始 ===')
    
    const { action, thoughtIds } = await request.json()

    // 環境変数チェック
    if (!process.env.NOTION_API_KEY || !process.env.NOTION_DATABASE_ID) {
      return NextResponse.json(
        { 
          error: 'Notion設定が不完全です。環境変数を確認してください。',
          details: {
            hasApiKey: !!process.env.NOTION_API_KEY,
            hasDatabaseId: !!process.env.NOTION_DATABASE_ID
          }
        },
        { status: 500 }
      )
    }

    if (action === 'test') {
      // 接続テスト
      console.log('Notion接続テスト実行')
      const testResult = await testNotionConnection()
      
      return NextResponse.json({
        success: testResult.success,
        message: testResult.success ? 
          `Notion接続成功: ${testResult.databaseTitle}` : 
          `Notion接続失敗: ${testResult.error}`,
        data: testResult
      })
    }

    if (action === 'sync-all') {
      // 全件同期
      console.log('全思考記録をNotion同期')
      
      const thoughtsResult = await getThoughts()
      if (!thoughtsResult.success || !thoughtsResult.data) {
        return NextResponse.json(
          { error: '思考記録の取得に失敗しました' },
          { status: 500 }
        )
      }

      const thoughts = thoughtsResult.data
      console.log(`同期対象: ${thoughts.length}件`)

      if (thoughts.length === 0) {
        return NextResponse.json({
          success: true,
          message: '同期する思考記録がありません',
          data: { successCount: 0, errorCount: 0, totalCount: 0 }
        })
      }

      const syncResult = await syncMultipleThoughtsToNotion(thoughts)
      
      return NextResponse.json({
        success: syncResult.success,
        message: `同期完了: 成功${syncResult.successCount}件, 失敗${syncResult.errorCount}件`,
        data: syncResult
      })
    }

    if (action === 'sync-selected' && thoughtIds && Array.isArray(thoughtIds)) {
      // 選択した記録のみ同期
      console.log(`選択された思考記録を同期: ${thoughtIds.length}件`)
      
      const thoughtsResult = await getThoughts()
      if (!thoughtsResult.success || !thoughtsResult.data) {
        return NextResponse.json(
          { error: '思考記録の取得に失敗しました' },
          { status: 500 }
        )
      }

      // 指定されたIDの記録のみフィルタ
      const selectedThoughts = thoughtsResult.data.filter(
        thought => thoughtIds.includes(thought.id)
      )

      if (selectedThoughts.length === 0) {
        return NextResponse.json(
          { error: '指定された思考記録が見つかりません' },
          { status: 400 }
        )
      }

      const syncResult = await syncMultipleThoughtsToNotion(selectedThoughts)
      
      return NextResponse.json({
        success: syncResult.success,
        message: `選択した記録の同期完了: 成功${syncResult.successCount}件, 失敗${syncResult.errorCount}件`,
        data: syncResult
      })
    }

    return NextResponse.json(
      { error: '無効なアクションです。test, sync-all, sync-selected のいずれかを指定してください。' },
      { status: 400 }
    )

  } catch (error) {
    console.error('=== Notion同期APIエラー ===')
    console.error('エラー詳細:', error)
    
    return NextResponse.json(
      { 
        error: 'Notion同期に失敗しました',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    )
  }
}

// GET: 同期状況の確認
export async function GET() {
  try {
    // Notion設定の確認
    const hasApiKey = !!process.env.NOTION_API_KEY
    const hasDatabaseId = !!process.env.NOTION_DATABASE_ID
    
    return NextResponse.json({
      configured: hasApiKey && hasDatabaseId,
      hasApiKey,
      hasDatabaseId,
      message: hasApiKey && hasDatabaseId ? 
        'Notion連携が設定されています' : 
        'Notion連携の設定が不完全です'
    })
  } catch (error) {
    return NextResponse.json(
      { error: 'Notion設定の確認に失敗しました' },
      { status: 500 }
    )
  }
}