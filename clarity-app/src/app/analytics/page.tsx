'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { getThoughts, ThoughtEntry } from '@/lib/supabase'
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend, BarChart, Bar, XAxis, YAxis, CartesianGrid } from 'recharts'
import Link from 'next/link'
import { Button } from '@/components/ui/button'

export default function AnalyticsPage() {
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

  // カテゴリ別データの集計
  const getCategoryData = () => {
    const categoryCount: { [key: string]: number } = {}
    
    thoughts.forEach(thought => {
      categoryCount[thought.category] = (categoryCount[thought.category] || 0) + 1
    })

    return Object.entries(categoryCount).map(([category, count]) => ({
      category,
      count,
      percentage: Math.round((count / thoughts.length) * 100)
    }))
  }

  // 日別データの集計（最近7日間）
  const getDailyData = () => {
    const last7Days = Array.from({length: 7}, (_, i) => {
      const date = new Date()
      date.setDate(date.getDate() - i)
      return date.toISOString().split('T')[0] // YYYY-MM-DD形式
    }).reverse()

    return last7Days.map(date => {
      const count = thoughts.filter(thought => 
        thought.entry_date === date
      ).length
      
      return {
        date: new Date(date).toLocaleDateString('ja-JP', { month: 'short', day: 'numeric' }),
        count
      }
    })
  }

  // 円グラフの色設定
  const COLORS = {
    '仕事': '#3B82F6',      // 青
    '人間関係': '#10B981',   // 緑
    '目標管理': '#8B5CF6',   // 紫
    '応募': '#F59E0B',      // オレンジ
    '感情': '#EF4444',      // 赤
    'その他': '#6B7280'      // グレー
  }

  if (isLoading) {
    return (
      <div className="max-w-6xl mx-auto py-8 px-4">
        <div className="text-center">
          <p className="text-lg">分析データを読み込み中...</p>
        </div>
      </div>
    )
  }

  const categoryData = getCategoryData()
  const dailyData = getDailyData()

  return (
    <div className="max-w-6xl mx-auto py-8 px-4">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">📊 思考分析</h1>
        <p className="text-gray-600 mb-4">
          記録された思考データの可視化とトレンド分析
        </p>
        <div className="flex gap-4">
          <Link href="/thoughts">
            <Button variant="outline">記録一覧を見る</Button>
          </Link>
          <Link href="/thoughts/new">
            <Button>新しい記録を作成</Button>
          </Link>
        </div>
      </div>

      {error && (
        <div className="mb-6 bg-red-50 border border-red-200 rounded-lg p-4">
          <p className="text-red-800">{error}</p>
        </div>
      )}

      {thoughts.length === 0 ? (
        <Card>
          <CardContent className="text-center py-12">
            <h3 className="text-lg font-semibold mb-2">まだ分析データがありません</h3>
            <p className="text-gray-500 mb-4">思考を記録してから分析を確認してください</p>
            <Link href="/thoughts/new">
              <Button>最初の記録を作成する</Button>
            </Link>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-8">
          {/* サマリーカード */}
          <div className="grid md:grid-cols-4 gap-4">
            <Card>
              <CardContent className="p-6">
                <div className="text-2xl font-bold text-blue-600">{thoughts.length}</div>
                <p className="text-sm text-gray-600">総記録数</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-6">
                <div className="text-2xl font-bold text-green-600">{categoryData.length}</div>
                <p className="text-sm text-gray-600">使用カテゴリ数</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-6">
                <div className="text-2xl font-bold text-purple-600">
                  {categoryData.length > 0 ? categoryData[0].category : '-'}
                </div>
                <p className="text-sm text-gray-600">最多カテゴリ</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-6">
                <div className="text-2xl font-bold text-orange-600">
                  {dailyData.reduce((sum, day) => sum + day.count, 0)}
                </div>
                <p className="text-sm text-gray-600">過去7日間</p>
              </CardContent>
            </Card>
          </div>

          {/* チャート */}
          <div className="grid md:grid-cols-2 gap-8">
            {/* カテゴリ別円グラフ */}
            <Card>
              <CardHeader>
                <CardTitle>カテゴリ別分布</CardTitle>
                <CardDescription>思考記録のカテゴリごとの割合</CardDescription>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie
                      data={categoryData}
                      dataKey="count"
                      nameKey="category"
                      cx="50%"
                      cy="50%"
                      outerRadius={80}
                      label={({category, percentage}) => `${category} ${percentage}%`}
                    >
                      {categoryData.map((entry, index) => (
                        <Cell key={index} fill={COLORS[entry.category as keyof typeof COLORS]} />
                      ))}
                    </Pie>
                    <Tooltip />
                  </PieChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>

            {/* 日別記録数バーチャート */}
            <Card>
              <CardHeader>
                <CardTitle>記録頻度（過去7日間）</CardTitle>
                <CardDescription>日別の思考記録数の推移</CardDescription>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={dailyData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="count" fill="#3B82F6" />
                  </BarChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </div>

          {/* カテゴリ詳細テーブル */}
          <Card>
            <CardHeader>
              <CardTitle>カテゴリ詳細</CardTitle>
              <CardDescription>各カテゴリの記録数と割合</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {categoryData.map((item, index) => (
                  <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                    <div className="flex items-center gap-3">
                      <div 
                        className="w-4 h-4 rounded-full"
                        style={{ backgroundColor: COLORS[item.category as keyof typeof COLORS] }}
                      ></div>
                      <span className="font-medium">{item.category}</span>
                    </div>
                    <div className="text-right">
                      <div className="font-semibold">{item.count}件</div>
                      <div className="text-sm text-gray-500">{item.percentage}%</div>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  )
}