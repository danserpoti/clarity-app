'use client'

import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { getThoughts, ThoughtEntry } from '@/lib/supabase'
import Link from 'next/link'

export default function ThoughtsPage() {
  const [thoughts, setThoughts] = useState<ThoughtEntry[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState('')

  // データを取得
  useEffect(() => {
    fetchThoughts()
  }, [])

  const fetchThoughts = async () => {
    setIsLoading(true)
    const result = await getThoughts()
    
    if (result.success && result.data) {
      setThoughts(result.data)
    } else {
      setError('データの取得に失敗しました')
    }
    
    setIsLoading(false)
  }

  // カテゴリごとの色分け
  const getCategoryColor = (category: string) => {
    const colors: { [key: string]: string } = {
      '仕事': 'bg-blue-100 text-blue-800',
      '人間関係': 'bg-green-100 text-green-800',
      '目標管理': 'bg-purple-100 text-purple-800',
      '応募': 'bg-orange-100 text-orange-800',
      '感情': 'bg-pink-100 text-pink-800',
      'その他': 'bg-gray-100 text-gray-800'
    }
    return colors[category] || 'bg-gray-100 text-gray-800'
  }

  // 日付フォーマット
  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleDateString('ja-JP', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  if (isLoading) {
    return (
      <div className="max-w-4xl mx-auto py-8 px-4">
        <div className="text-center">
          <p className="text-lg">データを読み込み中...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="max-w-4xl mx-auto py-8 px-4">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">思考記録一覧</h1>
        <p className="text-gray-600 mb-4">
          これまでに記録された思考 ({thoughts.length}件)
        </p>
        <Link href="/thoughts/new">
          <Button>新しい思考を記録する</Button>
        </Link>
      </div>

      {error && (
        <div className="mb-6 bg-red-50 border border-red-200 rounded-lg p-4">
          <p className="text-red-800">{error}</p>
          <Button onClick={fetchThoughts} variant="outline" className="mt-2">
            再読み込み
          </Button>
        </div>
      )}

      {thoughts.length === 0 ? (
        <Card>
          <CardContent className="text-center py-12">
            <p className="text-gray-500 mb-4">まだ思考記録がありません</p>
            <Link href="/thoughts/new">
              <Button>最初の記録を作成する</Button>
            </Link>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-4">
          {thoughts.map((thought) => (
            <Card key={thought.id} className="hover:shadow-md transition-shadow">
              <CardHeader className="pb-3">
                <div className="flex justify-between items-start">
                  <div className="flex items-center gap-2">
                    <Badge className={getCategoryColor(thought.category)}>
                      {thought.category}
                    </Badge>
                    <span className="text-sm text-gray-500">
                      {formatDate(thought.created_at)}
                    </span>
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <p className="text-gray-800 whitespace-pre-wrap leading-relaxed">
                  {thought.content}
                </p>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <div className="mt-8 text-center">
        <Button onClick={fetchThoughts} variant="outline">
          🔄 データを更新
        </Button>
      </div>

      {thoughts.length > 0 && (
        <div className="mt-8 bg-green-50 border border-green-200 rounded-lg p-6">
          <h3 className="text-lg font-semibold text-green-800 mb-2">
            📊 次の段階: 可視化機能
          </h3>
          <p className="text-green-700 mb-4">
            データが蓄積されました！次はグラフやチャートで可視化しましょう。
          </p>
          <div className="grid md:grid-cols-2 gap-4">
            <div className="bg-white rounded p-4 border">
              <h4 className="font-medium mb-2">カテゴリ別分析</h4>
              <p className="text-sm text-gray-600">どのカテゴリが多いかをグラフで表示</p>
            </div>
            <div className="bg-white rounded p-4 border">
              <h4 className="font-medium mb-2">時系列分析</h4>
              <p className="text-sm text-gray-600">記録頻度の推移をチャートで表示</p>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}