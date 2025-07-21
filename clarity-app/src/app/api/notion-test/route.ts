import { NextResponse } from 'next/server'
import { testNotionConnection } from '@/lib/notion'

export async function GET() {
  try {
    console.log('=== Notion接続テスト開始 ===')
    
    // 環境変数チェック
    const hasApiKey = !!process.env.NOTION_API_KEY
    const hasDatabaseId = !!process.env.NOTION_DATABASE_ID
    
    console.log('環境変数チェック:')
    console.log('- NOTION_API_KEY:', hasApiKey ? '設定済み' : '未設定')
    console.log('- NOTION_DATABASE_ID:', hasDatabaseId ? '設定済み' : '未設定')
    
    if (hasApiKey) {
      console.log('- API Key prefix:', process.env.NOTION_API_KEY?.substring(0, 10) + '...')
    }
    
    if (hasDatabaseId) {
      console.log('- Database ID:', process.env.NOTION_DATABASE_ID)
    }

    if (!hasApiKey || !hasDatabaseId) {
      return NextResponse.json({
        success: false,
        error: '環境変数が設定されていません',
        details: {
          hasApiKey,
          hasDatabaseId
        }
      })
    }

    // Notion接続テスト
    const testResult = await testNotionConnection()
    
    return NextResponse.json({
      success: testResult.success,
      message: testResult.success ? 'Notion接続成功' : 'Notion接続失敗',
      environmentCheck: {
        hasApiKey,
        hasDatabaseId,
        apiKeyPrefix: process.env.NOTION_API_KEY?.substring(0, 10) + '...',
        databaseId: process.env.NOTION_DATABASE_ID
      },
      connectionTest: testResult
    })

  } catch (error) {
    console.error('=== Notion接続テストエラー ===')
    console.error('エラー詳細:', error)
    
    return NextResponse.json({
      success: false,
      error: 'テスト実行中にエラーが発生しました',
      details: error instanceof Error ? error.message : 'Unknown error'
    })
  }
}