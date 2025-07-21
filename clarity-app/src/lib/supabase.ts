import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// 思考記録の型定義
export interface ThoughtEntry {
  id: string
  content: string
  category: '仕事' | '人間関係' | '目標管理' | '応募' | '感情' | 'その他'
  entry_date: string
  created_at: string
  updated_at: string
}

// 思考記録を保存する関数
export async function saveThought(content: string, category: string) {
  try {
    const { data, error } = await supabase
      .from('thought_entries')
      .insert([
        {
          content,
          category
        }
      ])
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