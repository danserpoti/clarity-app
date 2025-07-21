import { Client } from '@notionhq/client'
import { ThoughtEntry } from './supabase'

// Notion クライアントの初期化
const notion = new Client({
  auth: process.env.NOTION_API_KEY,
})

const DATABASE_ID = process.env.NOTION_DATABASE_ID!

// 思考記録をNotionに同期する関数
export async function syncThoughtToNotion(thought: ThoughtEntry) {
  try {
    console.log('Notion同期開始:', thought.id)

    // タイトルを生成（AI要約があればそれを使用、なければ内容の最初の50文字）
    const title = thought.ai_summary || 
                  (thought.content.length > 50 ? 
                   thought.content.substring(0, 50) + '...' : 
                   thought.content)

    // Notionページのプロパティを構築
    const properties: any = {
      'タイトル': {
        title: [
          {
            text: {
              content: title
            }
          }
        ]
      },
      '内容': {
        rich_text: [
          {
            text: {
              content: thought.content
            }
          }
        ]
      },
      'カテゴリ': {
        select: {
          name: thought.category
        }
      },
      '記録日': {
        date: {
          start: thought.entry_date || thought.created_at.split('T')[0]
        }
      },
      '同期日': {
        date: {
          start: new Date().toISOString()
        }
      }
    }

    // AI分析結果がある場合は追加
    if (thought.ai_emotion) {
      properties['感情'] = {
        select: {
          name: thought.ai_emotion
        }
      }
    }

    if (thought.ai_emotion_score !== null && thought.ai_emotion_score !== undefined) {
      properties['感情スコア'] = {
        number: Math.round(thought.ai_emotion_score * 100)
      }
    }

    if (thought.ai_themes && Array.isArray(thought.ai_themes) && thought.ai_themes.length > 0) {
      properties['テーマ'] = {
        multi_select: thought.ai_themes.map(theme => ({ name: theme }))
      }
    }

    if (thought.ai_keywords && Array.isArray(thought.ai_keywords) && thought.ai_keywords.length > 0) {
      properties['キーワード'] = {
        multi_select: thought.ai_keywords.map(keyword => ({ name: keyword }))
      }
    }

    if (thought.ai_summary) {
      properties['AI要約'] = {
        rich_text: [
          {
            text: {
              content: thought.ai_summary
            }
          }
        ]
      }
    }

    if (thought.ai_suggestion) {
      properties['アドバイス'] = {
        rich_text: [
          {
            text: {
              content: thought.ai_suggestion
            }
          }
        ]
      }
    }

    // Notionページを作成
    const response = await notion.pages.create({
      parent: {
        database_id: DATABASE_ID
      },
      properties
    })

    console.log('Notion同期成功:', response.id)
    return {
      success: true,
      notionPageId: response.id,
      url: `https://notion.so/${response.id.replace(/-/g, '')}`
    }

  } catch (error) {
    console.error('Notion同期エラー:', error)
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }
  }
}

// 複数の思考記録を一括同期する関数
export async function syncMultipleThoughtsToNotion(thoughts: ThoughtEntry[]) {
  console.log(`${thoughts.length}件の思考記録をNotion同期開始`)
  
  const results = []
  let successCount = 0
  let errorCount = 0

  for (const thought of thoughts) {
    const result = await syncThoughtToNotion(thought)
    results.push({
      thoughtId: thought.id,
      ...result
    })

    if (result.success) {
      successCount++
    } else {
      errorCount++
    }

    // API制限を避けるため、少し待機
    await new Promise(resolve => setTimeout(resolve, 100))
  }

  console.log(`Notion一括同期完了: 成功${successCount}件, 失敗${errorCount}件`)

  return {
    success: errorCount === 0,
    successCount,
    errorCount,
    totalCount: thoughts.length,
    results
  }
}

// Notion連携設定のテスト
export async function testNotionConnection() {
  try {
    console.log('Notion接続テスト開始')

    // データベースの情報を取得してテスト
    const database = await notion.databases.retrieve({ database_id: DATABASE_ID })
    
    console.log('Notion接続テスト成功:', DATABASE_ID)
    return {
      success: true,
      databaseTitle: 'Clarity Database',
      databaseId: DATABASE_ID
    }
  } catch (error) {
    console.error('Notion接続テストエラー:', error)
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }
  }
}