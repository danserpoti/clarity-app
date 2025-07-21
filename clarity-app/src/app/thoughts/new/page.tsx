'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { saveThought } from '@/lib/supabase'

export default function NewThought() {
  const [content, setContent] = useState('')
  const [category, setCategory] = useState('')
  const [isSubmitted, setIsSubmitted] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async () => {
    if (content.trim() === '') {
      alert('思考内容を入力してください')
      return
    }
    if (category === '') {
      alert('カテゴリを選択してください')
      return
    }
    
    setIsLoading(true)
    setError('')

    const result = await saveThought(content, category)
    
    if (result.success) {
      setIsSubmitted(true)
      alert('思考がデータベースに保存されました！')
    } else {
      setError('保存に失敗しました。もう一度お試しください。')
      alert('保存エラー: データベースへの保存に失敗しました')
    }
    
    setIsLoading(false)
  }

  const handleNewEntry = () => {
    setIsSubmitted(false)
    setContent('')
    setCategory('')
    setError('')
  }

  if (isSubmitted) {
    return (
      <div className="max-w-2xl mx-auto py-8 px-4">
        <Card>
          <CardHeader>
            <CardTitle className="text-green-600">✅ データベース保存完了</CardTitle>
            <CardDescription>思考がSupabaseデータベースに正常に保存されました</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div>
                <h3 className="font-semibold">カテゴリ:</h3>
                <p className="text-gray-600">{category}</p>
              </div>
              <div>
                <h3 className="font-semibold">内容:</h3>
                <p className="text-gray-600 whitespace-pre-wrap">{content}</p>
              </div>
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <p className="text-sm text-blue-800">
                  💾 この記録はデータベースに永続保存されました。
                </p>
              </div>
              <Button onClick={handleNewEntry} className="w-full">
                新しい思考を記録する
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="max-w-2xl mx-auto py-8 px-4">
      <Card>
        <CardHeader>
          <CardTitle>💾 思考記録（データベース保存）</CardTitle>
          <CardDescription>今の思考や感情を記録してSupabaseデータベースに保存します</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4">
              <p className="text-sm text-red-800">{error}</p>
            </div>
          )}

          <div>
            <label className="text-sm font-medium mb-2 block">
              カテゴリ
            </label>
            <Select value={category} onValueChange={setCategory}>
              <SelectTrigger>
                <SelectValue placeholder="カテゴリを選択してください" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="仕事">仕事</SelectItem>
                <SelectItem value="人間関係">人間関係</SelectItem>
                <SelectItem value="目標管理">目標管理</SelectItem>
                <SelectItem value="応募">応募</SelectItem>
                <SelectItem value="感情">感情</SelectItem>
                <SelectItem value="その他">その他</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div>
            <label className="text-sm font-medium mb-2 block">
              思考内容
            </label>
            <Textarea
              placeholder="今考えていることや感じていることを自由に書いてください..."
              value={content}
              onChange={(e) => setContent(e.target.value)}
              rows={8}
              disabled={isLoading}
            />
          </div>

          <Button 
            onClick={handleSubmit} 
            className="w-full"
            disabled={isLoading}
          >
            {isLoading ? '保存中...' : '💾 データベースに保存'}
          </Button>

          <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
            <p className="text-sm text-gray-600">
              🔒 保存されたデータはSupabaseクラウドデータベースに安全に保存されます
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}