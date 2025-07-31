'use client'

// 思考記録の型定義
export interface ThoughtEntry {
  id: string
  content: string
  category: '仕事' | '人間関係' | '目標管理' | '学習' | '感情' | 'その他'
  entry_date: string
  created_at: string
  updated_at: string
  // AI分析結果
  ai_emotion?: 'positive' | 'negative' | 'neutral' | 'mixed'
  ai_emotion_score?: number
  ai_themes?: string[]
  ai_keywords?: string[]
  ai_summary?: string
  ai_suggestion?: string
  ai_analyzed_at?: string
}

// ローカルストレージのキー
const STORAGE_KEY = 'clarity-thoughts'

// UUIDを生成する関数
function generateId(): string {
  return 'xxxx-xxxx-4xxx-yxxx-xxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0
    const v = c === 'x' ? r : (r & 0x3 | 0x8)
    return v.toString(16)
  })
}

// 思考記録を保存する関数（AI分析結果込み）
export async function saveThoughtWithAnalysis(
  content: string, 
  category: string,
  analysis?: {
    emotion: string
    emotionScore: number
    themes: string[]
    keywords: string[]
    summary: string
    suggestion: string
  }
): Promise<{ success: boolean; data?: ThoughtEntry; error?: any }> {
  try {
    const now = new Date().toISOString()
    const today = new Date().toISOString().split('T')[0]

    const newThought: ThoughtEntry = {
      id: generateId(),
      content,
      category: category as ThoughtEntry['category'],
      entry_date: today,
      created_at: now,
      updated_at: now
    }

    // AI分析結果があれば追加
    if (analysis) {
      newThought.ai_emotion = analysis.emotion as ThoughtEntry['ai_emotion']
      newThought.ai_emotion_score = analysis.emotionScore
      newThought.ai_themes = analysis.themes
      newThought.ai_keywords = analysis.keywords
      newThought.ai_summary = analysis.summary
      newThought.ai_suggestion = analysis.suggestion
      newThought.ai_analyzed_at = now
    }

    // 既存のデータを取得
    const existingData = localStorage.getItem(STORAGE_KEY)
    const thoughts: ThoughtEntry[] = existingData ? JSON.parse(existingData) : []

    // 新しい記録を追加
    thoughts.unshift(newThought) // 最新が最初に来るように

    // ローカルストレージに保存
    localStorage.setItem(STORAGE_KEY, JSON.stringify(thoughts))

    return { success: true, data: newThought }
  } catch (error) {
    console.error('ローカル保存エラー:', error)
    return { success: false, error }
  }
}

// 既存の関数も残す（後方互換性）
export async function saveThought(content: string, category: string) {
  return saveThoughtWithAnalysis(content, category)
}

// 思考記録を取得する関数
export async function getThoughts(): Promise<{ success: boolean; data?: ThoughtEntry[]; error?: any }> {
  try {
    const existingData = localStorage.getItem(STORAGE_KEY)
    const thoughts: ThoughtEntry[] = existingData ? JSON.parse(existingData) : []

    // 作成日時の降順でソート
    thoughts.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())

    return { success: true, data: thoughts }
  } catch (error) {
    console.error('ローカル取得エラー:', error)
    return { success: false, error }
  }
}

// 思考記録を削除する関数
export async function deleteThought(id: string): Promise<{ success: boolean; error?: any }> {
  try {
    const existingData = localStorage.getItem(STORAGE_KEY)
    const thoughts: ThoughtEntry[] = existingData ? JSON.parse(existingData) : []

    // 指定されたIDの記録を削除
    const filteredThoughts = thoughts.filter(thought => thought.id !== id)

    // ローカルストレージに保存
    localStorage.setItem(STORAGE_KEY, JSON.stringify(filteredThoughts))

    return { success: true }
  } catch (error) {
    console.error('ローカル削除エラー:', error)
    return { success: false, error }
  }
}

// 全データをエクスポートする関数
export function exportThoughts(): string {
  const existingData = localStorage.getItem(STORAGE_KEY)
  return existingData || '[]'
}

// データをインポートする関数
export function importThoughts(jsonData: string): { success: boolean; error?: any } {
  try {
    const thoughts = JSON.parse(jsonData)
    localStorage.setItem(STORAGE_KEY, JSON.stringify(thoughts))
    return { success: true }
  } catch (error) {
    console.error('インポートエラー:', error)
    return { success: false, error }
  }
}

// データを初期化する関数
export function clearAllThoughts(): { success: boolean; error?: any } {
  try {
    localStorage.removeItem(STORAGE_KEY)
    return { success: true }
  } catch (error) {
    console.error('データ初期化エラー:', error)
    return { success: false, error }
  }
}