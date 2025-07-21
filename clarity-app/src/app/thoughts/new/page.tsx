'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { saveThoughtWithAnalysis } from '@/lib/supabase' // ← 更新された関数をインポート
import { ThoughtAnalysis } from '@/lib/openai'

export default function NewThought() {
  const [content, setContent] = useState('')
  const [category, setCategory] = useState('')
  const [isSubmitted, setIsSubmitted] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')
  
  // AI分析関連のstate
  const [analysis, setAnalysis] = useState<ThoughtAnalysis | null>(null)
  const [isAnalyzing, setIsAnalyzing] = useState(false)
  const [analysisError, setAnalysisError] = useState('')

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

    // 分析結果も一緒に保存
    const result = await saveThoughtWithAnalysis(content, category, analysis || undefined)
    
    if (result.success) {
      setIsSubmitted(true)
      alert('思考とAI分析結果がデータベースに保存されました！')
    } else {
      setError('保存に失敗しました。もう一度お試しください。')
      alert('保存エラー: データベースへの保存に失敗しました')
    }
    
    setIsLoading(false)
  }

  // AI分析機能
  const handleAnalyze = async () => {
    if (content.trim() === '') {
      alert('分析する内容を入力してください')
      return
    }

    setIsAnalyzing(true)
    setAnalysisError('')

    try {
      const response = await fetch('/api/analyze', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ content })
      })

      const data = await response.json()

      if (data.success) {
        setAnalysis(data.analysis)
      } else {
        setAnalysisError(data.error || 'AI分析に失敗しました')
      }
    } catch (error) {
      console.error('AI分析エラー:', error)
      setAnalysisError('AI分析の通信に失敗しました')
    }

    setIsAnalyzing(false)
  }

  const handleNewEntry = () => {
    setIsSubmitted(false)
    setContent('')
    setCategory('')
    setError('')
    setAnalysis(null)
    setAnalysisError('')
  }

  // 感情に応じた絵文字
  const getEmotionEmoji = (emotion: string) => {
    switch (emotion) {
      case 'positive': return '😊'
      case 'negative': return '😔'
      case 'mixed': return '😐'
      default: return '😌'
    }
  }

  // 感情スコアの色
  const getEmotionColor = (emotion: string) => {
    switch (emotion) {
      case 'positive': return 'text-green-600'
      case 'negative': return 'text-red-600'
      case 'mixed': return 'text-yellow-600'
      default: return 'text-gray-600'
    }
  }

  if (isSubmitted) {
    return (
      <div className="max-w-2xl mx-auto py-8 px-4">
        <Card>
          <CardHeader>
            <CardTitle className="text-green-600">✅ データベース保存完了</CardTitle>
            <CardDescription>
              思考{analysis ? 'とAI分析結果' : ''}がSupabaseデータベースに正常に保存されました
            </CardDescription>
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
              
              {/* AI分析結果の表示 */}
              {analysis && (
                <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                  <h3 className="font-semibold text-blue-800 mb-3">🤖 AI分析結果（データベース保存済み）</h3>
                  <div className="space-y-2 text-sm">
                    <div>
                      <span className="font-medium">感情:</span> 
                      <span className={`ml-2 ${getEmotionColor(analysis.emotion)}`}>
                        {getEmotionEmoji(analysis.emotion)} {analysis.emotion}
                      </span>
                    </div>
                    <div>
                      <span className="font-medium">要約:</span> 
                      <span className="ml-2 text-gray-700">{analysis.summary}</span>
                    </div>
                    <div>
                      <span className="font-medium">アドバイス:</span> 
                      <span className="ml-2 text-gray-700">{analysis.suggestion}</span>
                    </div>
                  </div>
                </div>
              )}
              
              <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                <p className="text-sm text-green-800">
                  💾 この記録{analysis ? 'とAI分析結果' : ''}はデータベースに永続保存されました。
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
          <CardTitle>💾 思考記録（AI分析 + データベース保存）</CardTitle>
          <CardDescription>思考と感情を記録し、AI分析結果も一緒にデータベースに保存します</CardDescription>
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
              disabled={isLoading || isAnalyzing}
            />
          </div>

          {/* AI分析ボタン */}
          <div className="flex space-x-3">
            <Button 
              onClick={handleAnalyze} 
              variant="outline"
              className="flex-1"
              disabled={isAnalyzing || isLoading || content.trim() === ''}
            >
              {isAnalyzing ? '🤖 分析中...' : '🤖 AI分析'}
            </Button>
            <Button 
              onClick={handleSubmit} 
              className="flex-1"
              disabled={isLoading || isAnalyzing}
            >
              {isLoading ? '保存中...' : analysis ? '💾 分析結果も一緒に保存' : '💾 データベースに保存'}
            </Button>
          </div>

          {/* 保存ワークフローの説明 */}
          <div className="bg-amber-50 border border-amber-200 rounded-lg p-4">
            <h4 className="font-medium text-amber-800 mb-2">💡 推奨ワークフロー</h4>
            <ol className="text-sm text-amber-700 space-y-1">
              <li>1. 思考内容を入力</li>
              <li>2. 「🤖 AI分析」をクリックして感情やテーマを分析</li>
              <li>3. 分析結果を確認</li>
              <li>4. 「💾 分析結果も一緒に保存」で完了</li>
            </ol>
          </div>

          {/* AI分析エラー表示 */}
          {analysisError && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4">
              <p className="text-sm text-red-800">{analysisError}</p>
            </div>
          )}

          {/* AI分析結果表示 */}
          {analysis && (
            <Card className="bg-blue-50 border-blue-200">
              <CardHeader>
                <CardTitle className="text-lg text-blue-800">🤖 AI分析結果</CardTitle>
                <CardDescription className="text-blue-600">
                  保存ボタンを押すと、この分析結果もデータベースに保存されます
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <span className="text-sm font-medium text-gray-600">感情:</span>
                    <div className={`text-lg ${getEmotionColor(analysis.emotion)}`}>
                      {getEmotionEmoji(analysis.emotion)} {analysis.emotion}
                    </div>
                  </div>
                  <div>
                    <span className="text-sm font-medium text-gray-600">感情スコア:</span>
                    <div className="text-lg">
                      {Math.round(analysis.emotionScore * 100)}%
                    </div>
                  </div>
                </div>
                
                <div>
                  <span className="text-sm font-medium text-gray-600">テーマ:</span>
                  <div className="flex flex-wrap gap-2 mt-1">
                    {analysis.themes.map((theme, index) => (
                      <span key={index} className="bg-blue-100 text-blue-800 px-2 py-1 rounded-md text-sm">
                        {theme}
                      </span>
                    ))}
                  </div>
                </div>

                <div>
                  <span className="text-sm font-medium text-gray-600">キーワード:</span>
                  <div className="flex flex-wrap gap-2 mt-1">
                    {analysis.keywords.map((keyword, index) => (
                      <span key={index} className="bg-gray-100 text-gray-700 px-2 py-1 rounded-md text-sm">
                        {keyword}
                      </span>
                    ))}
                  </div>
                </div>

                <div>
                  <span className="text-sm font-medium text-gray-600">要約:</span>
                  <p className="text-gray-700 mt-1">{analysis.summary}</p>
                </div>

                <div>
                  <span className="text-sm font-medium text-gray-600">アドバイス:</span>
                  <p className="text-gray-700 mt-1">{analysis.suggestion}</p>
                </div>
              </CardContent>
            </Card>
          )}

          <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
            <p className="text-sm text-gray-600">
              🔒 思考内容とAI分析結果はSupabaseクラウドデータベースに安全に保存されます
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}