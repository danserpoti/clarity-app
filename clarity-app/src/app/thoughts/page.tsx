'use client'

import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { getThoughts, ThoughtEntry } from '@/lib/supabase'
import Link from 'next/link'

// Notion同期ボタンコンポーネント
function NotionSyncButton({ thoughts }: { thoughts: ThoughtEntry[] }) {
  const [isLoading, setIsLoading] = useState(false)
  const [message, setMessage] = useState('')

  const handleSync = async () => {
    setIsLoading(true)
    setMessage('')

    try {
      const response = await fetch('/api/notion-sync', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ action: 'sync-all' })
      })

      const result = await response.json()
      
      if (result.success) {
        setMessage(`✅ ${result.message}`)
      } else {
        setMessage(`❌ ${result.error || 'Notion同期に失敗しました'}`)
      }
    } catch (error) {
      setMessage('❌ Notion同期でエラーが発生しました')
    }

    setIsLoading(false)
  }

  return (
    <div className="flex flex-col gap-2">
      <Button 
        variant="outline"
        onClick={handleSync}
        disabled={isLoading}
      >
        {isLoading ? '🔄 同期中...' : '📝 Notionに同期'}
      </Button>
      {message && (
        <p className="text-sm text-gray-600">{message}</p>
      )}
    </div>
  )
}

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

  // 感情に応じた絵文字と色
  const getEmotionDisplay = (emotion?: string) => {
    if (!emotion) return null
    
    const emotions = {
      'positive': { emoji: '😊', color: 'bg-green-100 text-green-800', label: 'ポジティブ' },
      'negative': { emoji: '😔', color: 'bg-red-100 text-red-800', label: 'ネガティブ' },
      'neutral': { emoji: '😌', color: 'bg-gray-100 text-gray-800', label: 'ニュートラル' },
      'mixed': { emoji: '😐', color: 'bg-yellow-100 text-yellow-800', label: 'ミックス' }
    }
    
    return emotions[emotion as keyof typeof emotions] || null
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

  // 分析統計の計算
  const analyzedCount = thoughts.filter(thought => thought.ai_emotion).length
  const analysisRate = thoughts.length > 0 ? Math.round((analyzedCount / thoughts.length) * 100) : 0

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
        <h1 className="text-3xl font-bold text-gray-900 mb-2">📝 思考記録一覧</h1>
        <p className="text-gray-600 mb-4">
          これまでに記録された思考 ({thoughts.length}件) / AI分析済み ({analyzedCount}件 - {analysisRate}%)
        </p>
        
        {/* ボタンエリア（Notion同期機能追加） */}
        <div className="flex gap-4 flex-wrap">
          <Link href="/thoughts/new">
            <Button>新しい思考を記録する</Button>
          </Link>
          <Link href="/analytics">
            <Button variant="outline">📊 分析結果を見る</Button>
          </Link>
          
          {/* Notion同期機能 */}
          {thoughts.length > 0 && (
            <NotionSyncButton thoughts={thoughts} />
          )}
          
          {/* エクスポート機能 */}
          {thoughts.length > 0 && (
            <div className="flex gap-2">
              <Button 
                variant="outline" 
                size="sm"
                onClick={() => window.open('/api/export?format=csv', '_blank')}
              >
                📄 CSV
              </Button>
              <Button 
                variant="outline" 
                size="sm"
                onClick={() => window.open('/api/export?format=json', '_blank')}
              >
                📋 JSON
              </Button>
            </div>
          )}
        </div>
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
            <h3 className="text-lg font-semibold mb-2">まだ思考記録がありません</h3>
            <p className="text-gray-500 mb-4">最初の記録を作成してみましょう</p>
            <Link href="/thoughts/new">
              <Button>最初の記録を作成する</Button>
            </Link>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-4">
          {thoughts.map((thought) => {
            const emotionDisplay = getEmotionDisplay(thought.ai_emotion)
            const hasAnalysis = Boolean(thought.ai_emotion)
            
            return (
              <Card key={thought.id} className="hover:shadow-md transition-shadow">
                <CardHeader className="pb-3">
                  <div className="flex justify-between items-start">
                    <div className="flex items-center gap-2 flex-wrap">
                      <Badge className={getCategoryColor(thought.category)}>
                        {thought.category}
                      </Badge>
                      
                      {/* AI分析結果バッジ */}
                      {emotionDisplay && (
                        <Badge className={emotionDisplay.color}>
                          {emotionDisplay.emoji} {emotionDisplay.label}
                        </Badge>
                      )}
                      
                      {/* 感情スコア */}
                      {thought.ai_emotion_score !== null && thought.ai_emotion_score !== undefined && (
                        <Badge variant="outline">
                          スコア: {Math.round(thought.ai_emotion_score * 100)}%
                        </Badge>
                      )}
                      
                      {/* 未分析バッジ */}
                      {!hasAnalysis && (
                        <Badge variant="outline" className="bg-gray-50 text-gray-500">
                          未分析
                        </Badge>
                      )}
                    </div>
                    <span className="text-sm text-gray-500 shrink-0 ml-2">
                      {formatDate(thought.created_at)}
                    </span>
                  </div>
                </CardHeader>
                <CardContent className="space-y-4">
                  {/* 思考内容 */}
                  <div className="bg-gray-50 rounded-lg p-4">
                    <p className="text-gray-800 whitespace-pre-wrap leading-relaxed">
                      {thought.content}
                    </p>
                  </div>
                  
                  {/* AI分析結果詳細 */}
                  {hasAnalysis && (
                    <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 space-y-3">
                      <h4 className="text-sm font-semibold text-blue-800">🤖 AI分析結果</h4>
                      
                      {/* テーマ */}
                      {thought.ai_themes && Array.isArray(thought.ai_themes) && thought.ai_themes.length > 0 && (
                        <div>
                          <span className="text-xs font-medium text-blue-700">テーマ: </span>
                          <div className="flex flex-wrap gap-1 mt-1">
                            {thought.ai_themes.map((theme, index) => (
                              <span key={index} className="bg-blue-100 text-blue-800 px-2 py-1 rounded text-xs">
                                {theme}
                              </span>
                            ))}
                          </div>
                        </div>
                      )}
                      
                      {/* キーワード */}
                      {thought.ai_keywords && Array.isArray(thought.ai_keywords) && thought.ai_keywords.length > 0 && (
                        <div>
                          <span className="text-xs font-medium text-blue-700">キーワード: </span>
                          <div className="flex flex-wrap gap-1 mt-1">
                            {thought.ai_keywords.map((keyword, index) => (
                              <span key={index} className="bg-gray-100 text-gray-700 px-2 py-1 rounded text-xs">
                                {keyword}
                              </span>
                            ))}
                          </div>
                        </div>
                      )}
                      
                      {/* 要約 */}
                      {thought.ai_summary && (
                        <div>
                          <span className="text-xs font-medium text-blue-700">要約: </span>
                          <span className="text-xs text-blue-600">{thought.ai_summary}</span>
                        </div>
                      )}
                      
                      {/* アドバイス */}
                      {thought.ai_suggestion && (
                        <div>
                          <span className="text-xs font-medium text-blue-700">アドバイス: </span>
                          <span className="text-xs text-blue-600">{thought.ai_suggestion}</span>
                        </div>
                      )}
                    </div>
                  )}
                </CardContent>
              </Card>
            )
          })}
        </div>
      )}

      <div className="mt-8 text-center">
        <Button onClick={fetchThoughts} variant="outline">
          🔄 データを更新
        </Button>
      </div>

      {/* 統計情報とナビゲーション */}
      {thoughts.length > 0 && (
        <div className="mt-8 space-y-4">
          {/* 分析統計 */}
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-6">
            <h3 className="text-lg font-semibold text-blue-800 mb-2">
              📊 分析統計
            </h3>
            <div className="grid md:grid-cols-3 gap-4 text-sm">
              <div className="bg-white rounded p-3">
                <div className="text-2xl font-bold text-blue-600">{thoughts.length}</div>
                <div className="text-blue-700">総記録数</div>
              </div>
              <div className="bg-white rounded p-3">
                <div className="text-2xl font-bold text-green-600">{analyzedCount}</div>
                <div className="text-green-700">AI分析済み</div>
              </div>
              <div className="bg-white rounded p-3">
                <div className="text-2xl font-bold text-purple-600">{analysisRate}%</div>
                <div className="text-purple-700">分析率</div>
              </div>
            </div>
          </div>
          
          {/* 推奨アクション */}
          <div className="bg-green-50 border border-green-200 rounded-lg p-6">
            <h3 className="text-lg font-semibold text-green-800 mb-2">
              💡 推奨アクション
            </h3>
            <div className="grid md:grid-cols-2 gap-4">
              <div className="bg-white rounded p-4 border">
                <h4 className="font-medium mb-2">詳細分析を見る</h4>
                <p className="text-sm text-gray-600 mb-3">
                  感情の推移やテーマ分析をグラフで確認
                </p>
                <Link href="/analytics">
                  <Button size="sm">分析ページへ</Button>
                </Link>
              </div>
              <div className="bg-white rounded p-4 border">
                <h4 className="font-medium mb-2">新しい記録を作成</h4>
                <p className="text-sm text-gray-600 mb-3">
                  思考を記録してAI分析で新たな洞察を得る
                </p>
                <Link href="/thoughts/new">
                  <Button size="sm" variant="outline">記録作成</Button>
                </Link>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}