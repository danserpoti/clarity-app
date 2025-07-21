import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// 思考記録の型定義（拡張版）
export interface ThoughtEntry {
  id: string
  content: string
  category: '仕事' | '人間関係' | '目標管理' | '応募' | '感情' | 'その他'
  entry_date: string
  created_at: string
  updated_at: string
  // AI分析結果（新規追加）
  ai_emotion?: 'positive' | 'negative' | 'neutral' | 'mixed'
  ai_emotion_score?: number
  ai_themes?: string[]
  ai_keywords?: string[]
  ai_summary?: string
  ai_suggestion?: string
  ai_analyzed_at?: string
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
) {
  try {
    const insertData: any = {
      content,
      category
    }

    // AI分析結果があれば追加
    if (analysis) {
      insertData.ai_emotion = analysis.emotion
      insertData.ai_emotion_score = analysis.emotionScore
      insertData.ai_themes = analysis.themes
      insertData.ai_keywords = analysis.keywords
      insertData.ai_summary = analysis.summary
      insertData.ai_suggestion = analysis.suggestion
      insertData.ai_analyzed_at = new Date().toISOString()
    }

    const { data, error } = await supabase
      .from('thought_entries')
      .insert([insertData])
      .select()

    if (error) {
      console.error('Supabase保存エラー:', error)
      throw error
    }

    return { success: true, data }
  } catch (error) {
    console.error('思考保存エラー:', error)
    return { success: false, error }
  }
}

// 既存の関数も残す（後方互換性）
export async function saveThought(content: string, category: string) {
  return saveThoughtWithAnalysis(content, category)
}

// 思考記録を取得する関数
export async function getThoughts() {
  try {
    const { data, error } = await supabase
      .from('thought_entries')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) {
      console.error('Supabase取得エラー:', error)
      throw error
    }

    return { success: true, data }
  } catch (error) {
    console.error('思考取得エラー:', error)
    return { success: false, error }
  }
}