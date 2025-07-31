'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { motion } from 'framer-motion'
import {
  BarChart3,
  Brain,
  TrendingUp,
  Calendar,
  Heart,
  Sparkles,
  ArrowLeft,
  RefreshCw,
  Download,
  PieChart as PieChartIcon,
  Activity,
  Target,
  BookOpen,
  Plus,
  Tag
} from 'lucide-react'

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { getThoughts, ThoughtEntry } from '@/lib/supabase'
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, BarChart, Bar, XAxis, YAxis, CartesianGrid, LineChart, Line } from 'recharts'

export default function AnalyticsPage() {
  const [thoughts, setThoughts] = useState<ThoughtEntry[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState('')
  const [refreshing, setRefreshing] = useState(false)

  // データを取得
  useEffect(() => {
    fetchThoughts()
  }, [])

  const fetchThoughts = async (isRefresh = false) => {
    if (isRefresh) {
      setRefreshing(true)
    } else {
      setIsLoading(true)
    }
    
    const result = await getThoughts()
    
    if (result.success && result.data) {
      setThoughts(result.data)
      setError('')
    } else {
      setError('データの取得に失敗しました')
    }
    
    if (isRefresh) {
      setRefreshing(false)
    } else {
      setIsLoading(false)
    }
  }

  // カテゴリ別データの集計
  const getCategoryData = () => {
    const categoryCount: { [key: string]: number } = {}
    
    thoughts.forEach((thought: ThoughtEntry) => {
      categoryCount[thought.category] = (categoryCount[thought.category] || 0) + 1
    })

    return Object.entries(categoryCount).map(([category, count]) => ({
      category,
      count,
      percentage: Math.round((count / thoughts.length) * 100)
    }))
  }

  // 感情分析データの集計（AI分析結果）
  const getEmotionData = () => {
    const emotionCount: { [key: string]: number } = {}
    const analyzedThoughts = thoughts.filter((thought: ThoughtEntry) => thought.ai_emotion)
    
    analyzedThoughts.forEach((thought: ThoughtEntry) => {
      if (thought.ai_emotion) {
        emotionCount[thought.ai_emotion] = (emotionCount[thought.ai_emotion] || 0) + 1
      }
    })

    return Object.entries(emotionCount).map(([emotion, count]) => ({
      emotion,
      count,
      percentage: analyzedThoughts.length > 0 ? Math.round((count / analyzedThoughts.length) * 100) : 0
    }))
  }

  // 感情スコアの推移（最近10件）
  const getEmotionTrendData = () => {
    const analyzedThoughts = thoughts
      .filter((thought: ThoughtEntry) => thought.ai_emotion && thought.ai_emotion_score !== null)
      .slice(0, 10)
      .reverse()

    return analyzedThoughts.map((thought: ThoughtEntry, index: number) => ({
      index: index + 1,
      score: Math.round((thought.ai_emotion_score || 0) * 100),
      emotion: thought.ai_emotion,
      date: new Date(thought.created_at).toLocaleDateString('ja-JP', { month: 'short', day: 'numeric' })
    }))
  }

  // テーマ分析データの集計
  const getThemeData = () => {
    const themeCount: { [key: string]: number } = {}
    
    thoughts.forEach((thought: ThoughtEntry) => {
      if (thought.ai_themes && Array.isArray(thought.ai_themes)) {
        (thought.ai_themes as string[]).forEach((theme: string) => {
          themeCount[theme] = (themeCount[theme] || 0) + 1
        })
      }
    })

    return Object.entries(themeCount)
      .map(([theme, count]) => ({ theme, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 8) // 上位8テーマ
  }

  // 日別データの集計（最近7日間）
  const getDailyData = () => {
    const last7Days = Array.from({length: 7}, (_, i) => {
      const date = new Date()
      date.setDate(date.getDate() - i)
      return date.toISOString().split('T')[0] // YYYY-MM-DD形式
    }).reverse()

    return last7Days.map((date: string) => {
      const count = thoughts.filter((thought: ThoughtEntry) => 
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

  // 感情の色設定（感情分析カラーシステム対応）
  const EMOTION_COLORS = {
    'positive': '#22C55E',   // より鮮やかな緑
    'negative': '#EF4444',   // 赤
    'neutral': '#8B5CF6',    // 紫
    'mixed': '#F59E0B'       // オレンジ
  }

  // 感情の絵文字
  const getEmotionEmoji = (emotion: string) => {
    switch (emotion) {
      case 'positive': return '😊'
      case 'negative': return '😔'
      case 'mixed': return '😐'
      default: return '😌'
    }
  }

  if (isLoading) {
    return (
      <div className="min-h-screen pt-20 pb-32">
        <div className="container mx-auto px-4 max-w-6xl">
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="space-y-8"
          >
            {/* ヘッダースケルトン */}
            <div className="text-center">
              <div className="w-16 h-16 bg-gray-200 dark:bg-gray-700 rounded-full mx-auto mb-6 shimmer" />
              <div className="w-64 h-10 bg-gray-200 dark:bg-gray-700 rounded mx-auto mb-4 shimmer" />
              <div className="w-96 h-6 bg-gray-200 dark:bg-gray-700 rounded mx-auto shimmer" />
            </div>
            
            {/* 統計カードスケルトン */}
            <div className="grid md:grid-cols-4 gap-6">
              {Array.from({ length: 4 }).map((_, index) => (
                <Card key={index} className="modern-card">
                  <CardContent className="p-6 text-center">
                    <div className="w-16 h-8 bg-gray-200 dark:bg-gray-700 rounded mx-auto mb-2 shimmer" />
                    <div className="w-20 h-4 bg-gray-200 dark:bg-gray-700 rounded mx-auto shimmer" />
                  </CardContent>
                </Card>
              ))}
            </div>
            
            {/* チャートスケルトン */}
            <div className="grid md:grid-cols-2 gap-6">
              {Array.from({ length: 4 }).map((_, index) => (
                <Card key={index} className="modern-card">
                  <CardHeader>
                    <div className="w-40 h-6 bg-gray-200 dark:bg-gray-700 rounded shimmer" />
                    <div className="w-60 h-4 bg-gray-200 dark:bg-gray-700 rounded shimmer" />
                  </CardHeader>
                  <CardContent>
                    <div className="w-full h-64 bg-gray-200 dark:bg-gray-700 rounded shimmer" />
                  </CardContent>
                </Card>
              ))}
            </div>
          </motion.div>
        </div>
      </div>
    )
  }

  const categoryData = getCategoryData()
  const emotionData = getEmotionData()
  const emotionTrendData = getEmotionTrendData()
  const themeData = getThemeData()
  const dailyData = getDailyData()
  const analyzedCount = thoughts.filter((thought: ThoughtEntry) => thought.ai_emotion).length

  return (
    <div className="min-h-screen pt-20 pb-32">
      <div className="container mx-auto px-4 max-w-6xl">
        <motion.div
          initial="initial"
          animate="animate"
          variants={{
            animate: {
              transition: {
                staggerChildren: 0.1
              }
            }
          }}
          className="space-y-8"
        >
          {/* ヘッダー */}
          <motion.div 
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, ease: 'easeOut' }}
            className="text-center"
          >
            <Link href="/" className="inline-flex items-center text-blue-600 dark:text-blue-400 hover:text-blue-700 mb-6 group">
              <ArrowLeft className="mr-2 h-4 w-4 group-hover:-translate-x-1 transition-transform" />
              ホームに戻る
            </Link>
            <motion.div
              className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gradient-to-r from-blue-500 to-purple-600 text-white mb-6"
              whileHover={{ scale: 1.1, rotate: 360 }}
              transition={{ duration: 0.6 }}
            >
              <BarChart3 className="h-8 w-8" />
            </motion.div>
            <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-4">思考分析ダッシュボード</h1>
            <p className="text-xl text-gray-600 dark:text-gray-300 max-w-2xl mx-auto">
              記録された思考データの可視化とAI分析結果のトレンド分析
            </p>
          </motion.div>
          
          {/* アクションボタン */}
          <motion.div 
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, ease: 'easeOut' }}
          >
            <Card className="modern-card">
              <CardContent className="p-6">
                <div className="flex flex-wrap gap-4 justify-center">
                  <Link href="/thoughts">
                    <Button variant="outline" className="flex items-center">
                      <BookOpen className="mr-2 h-4 w-4" />
                      記録一覧を見る
                    </Button>
                  </Link>
                  
                  <Link href="/thoughts/new">
                    <Button className="bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700">
                      <Plus className="mr-2 h-4 w-4" />
                      新しい記録を作成
                    </Button>
                  </Link>
                  
                  <Button 
                    variant="outline" 
                    onClick={() => fetchThoughts(true)}
                    disabled={refreshing}
                    className="flex items-center"
                  >
                    <RefreshCw className={`mr-2 h-4 w-4 ${refreshing ? 'animate-spin' : ''}`} />
                    {refreshing ? '更新中...' : 'データ更新'}
                  </Button>
                  
                  {/* エクスポート機能 */}
                  {thoughts.length > 0 && (
                    <>
                      <Button 
                        variant="outline" 
                        onClick={() => window.open('/api/export?format=csv', '_blank')}
                        className="flex items-center"
                      >
                        <Download className="mr-2 h-4 w-4" />
                        CSV エクスポート
                      </Button>
                      <Button 
                        variant="outline" 
                        onClick={() => window.open('/api/export?format=json', '_blank')}
                        className="flex items-center"
                      >
                        <Download className="mr-2 h-4 w-4" />
                        JSON エクスポート
                      </Button>
                    </>
                  )}
                </div>
              </CardContent>
            </Card>
          </motion.div>

          {/* エラー表示 */}
          {error && (
            <motion.div 
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, ease: "easeOut" }}
            >
              <Card className="modern-card border-red-200 dark:border-red-800">
                <CardContent className="p-6">
                  <div className="flex items-center text-red-600 dark:text-red-400">
                    <span className="text-2xl mr-3">❌</span>
                    <div>
                      <h3 className="font-semibold">データ取得エラー</h3>
                      <p className="text-sm">{error}</p>
                    </div>
                  </div>
                  <Button 
                    onClick={() => fetchThoughts()} 
                    variant="outline" 
                    className="mt-4"
                  >
                    <RefreshCw className="mr-2 h-4 w-4" />
                    再読み込み
                  </Button>
                </CardContent>
              </Card>
            </motion.div>
          )}

          {thoughts.length === 0 ? (
            <motion.div 
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, ease: "easeOut" }}
            >
              <Card className="modern-card">
                <CardContent className="text-center py-16">
                  <div className="text-6xl mb-6">📊</div>
                  <h3 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">まだ分析データがありません</h3>
                  <p className="text-gray-600 dark:text-gray-400 mb-8 max-w-md mx-auto">
                    思考を記録してから分析を確認してください。最初の記録を作成して、AIによる洞察を得ましょう。
                  </p>
                  <Link href="/thoughts/new">
                    <Button className="bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700">
                      <Plus className="mr-2 h-4 w-4" />
                      最初の記録を作成する
                    </Button>
                  </Link>
                </CardContent>
              </Card>
            </motion.div>
          ) : (
            <motion.div 
              variants={{
                animate: {
                  transition: {
                    staggerChildren: 0.1
                  }
                }
              }}
              className="space-y-8"
            >
              {/* サマリーカード */}
              <motion.div 
                initial={{ opacity: 0, y: 30 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, ease: "easeOut" }}
              >
                <div className="grid md:grid-cols-4 gap-6">
                  <Card className="modern-card-glass group hover:scale-105 transition-all duration-300">
                    <CardContent className="p-6 text-center">
                      <motion.div
                        className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-gradient-to-r from-blue-500 to-blue-600 text-white mb-4 group-hover:shadow-lg group-hover:shadow-blue-500/25 transition-all duration-300"
                        whileHover={{ scale: 1.1 }}
                      >
                        <BookOpen className="h-6 w-6" />
                      </motion.div>
                      <div className="text-3xl font-bold text-blue-600 mb-2">{thoughts.length}</div>
                      <p className="text-sm text-gray-600 dark:text-gray-400 font-medium">総記録数</p>
                    </CardContent>
                  </Card>
                  
                  <Card className="modern-card-glass group hover:scale-105 transition-all duration-300">
                    <CardContent className="p-6 text-center">
                      <motion.div
                        className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-gradient-to-r from-green-500 to-green-600 text-white mb-4 group-hover:shadow-lg group-hover:shadow-green-500/25 transition-all duration-300"
                        whileHover={{ rotate: 360 }}
                        transition={{ duration: 0.6 }}
                      >
                        <Brain className="h-6 w-6" />
                      </motion.div>
                      <div className="text-3xl font-bold text-green-600 mb-2">{analyzedCount}</div>
                      <p className="text-sm text-gray-600 dark:text-gray-400 font-medium">AI分析済み</p>
                    </CardContent>
                  </Card>
                  
                  <Card className="modern-card-glass group hover:scale-105 transition-all duration-300">
                    <CardContent className="p-6 text-center">
                      <motion.div
                        className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-gradient-to-r from-purple-500 to-purple-600 text-white mb-4 group-hover:shadow-lg group-hover:shadow-purple-500/25 transition-all duration-300"
                        whileHover={{ y: -5 }}
                      >
                        <Target className="h-6 w-6" />
                      </motion.div>
                      <div className="text-3xl font-bold text-purple-600 mb-2">
                        {categoryData.length > 0 ? categoryData[0].category : '-'}
                      </div>
                      <p className="text-sm text-gray-600 dark:text-gray-400 font-medium">最多カテゴリ</p>
                    </CardContent>
                  </Card>
                  
                  <Card className="modern-card-glass group hover:scale-105 transition-all duration-300">
                    <CardContent className="p-6 text-center">
                      <motion.div
                        className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-gradient-to-r from-orange-500 to-orange-600 text-white mb-4 group-hover:shadow-lg group-hover:shadow-orange-500/25 transition-all duration-300"
                        whileHover={{ scale: 1.1 }}
                      >
                        <Heart className="h-6 w-6" />
                      </motion.div>
                      <div className="text-3xl font-bold text-orange-600 mb-2">
                        {emotionData.length > 0 ? getEmotionEmoji(emotionData[0].emotion) + ' ' + emotionData[0].emotion : '-'}
                      </div>
                      <p className="text-sm text-gray-600 dark:text-gray-400 font-medium">最多感情</p>
                    </CardContent>
                  </Card>
                </div>
              </motion.div>

              {/* AI分析チャート */}
              {analyzedCount > 0 && (
                <motion.div 
                  initial={{ opacity: 0, y: 30 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.6 }}
                  className="space-y-8"
                >
                  <div className="flex items-center justify-center">
                    <motion.div
                      className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-gradient-to-r from-purple-500 to-pink-600 text-white mr-4"
                      animate={{ rotate: 360 }}
                      transition={{ duration: 20, repeat: Infinity, ease: "linear" }}
                    >
                      <Brain className="h-6 w-6" />
                    </motion.div>
                    <h2 className="text-3xl font-bold text-gray-900 dark:text-white">AI分析結果</h2>
                    <motion.div
                      className="ml-4"
                      animate={{ scale: [1, 1.2, 1] }}
                      transition={{ duration: 2, repeat: Infinity }}
                    >
                      <Sparkles className="h-6 w-6 text-purple-500" />
                    </motion.div>
                  </div>
                  
                  <div className="grid md:grid-cols-2 gap-8">
                    {/* 感情分析円グラフ */}
                    <Card className="modern-card-glass group hover:scale-105 transition-all duration-300">
                      <CardHeader>
                        <CardTitle className="flex items-center text-xl font-bold">
                          <Heart className="mr-2 h-5 w-5 text-pink-500" />
                          感情分布
                        </CardTitle>
                        <CardDescription className="text-gray-600 dark:text-gray-400">
                          AI分析による感情の分布とバランス
                        </CardDescription>
                      </CardHeader>
                      <CardContent>
                        <motion.div
                          initial={{ opacity: 0, scale: 0.8 }}
                          animate={{ opacity: 1, scale: 1 }}
                          transition={{ duration: 0.8, delay: 0.2 }}
                        >
                          <ResponsiveContainer width="100%" height={300}>
                            <PieChart>
                              <Pie
                                data={emotionData}
                                dataKey="count"
                                nameKey="emotion"
                                cx="50%"
                                cy="50%"
                                outerRadius={90}
                                innerRadius={40}
                                label={(entry: any) => `${getEmotionEmoji(entry.emotion)} ${entry.emotion} ${entry.percentage}%`}
                                labelLine={false}
                              >
                                {emotionData.map((entry, index) => (
                                  <Cell 
                                    key={index} 
                                    fill={EMOTION_COLORS[entry.emotion as keyof typeof EMOTION_COLORS]}
                                    className="hover:opacity-80 transition-opacity cursor-pointer"
                                  />
                                ))}
                              </Pie>
                              <Tooltip 
                                contentStyle={{
                                  backgroundColor: 'rgba(255, 255, 255, 0.95)',
                                  border: 'none',
                                  borderRadius: '12px',
                                  boxShadow: '0 10px 25px rgba(0, 0, 0, 0.1)'
                                }}
                              />
                            </PieChart>
                          </ResponsiveContainer>
                        </motion.div>
                      </CardContent>
                    </Card>

                    {/* 感情スコア推移 */}
                    <Card className="modern-card-glass group hover:scale-105 transition-all duration-300">
                      <CardHeader>
                        <CardTitle className="flex items-center text-xl font-bold">
                          <TrendingUp className="mr-2 h-5 w-5 text-blue-500" />
                          感情スコア推移
                        </CardTitle>
                        <CardDescription className="text-gray-600 dark:text-gray-400">
                          最近の感情スコアの変化トレンド（最新10件）
                        </CardDescription>
                      </CardHeader>
                      <CardContent>
                        <motion.div
                          initial={{ opacity: 0, x: 50 }}
                          animate={{ opacity: 1, x: 0 }}
                          transition={{ duration: 0.8, delay: 0.4 }}
                        >
                          <ResponsiveContainer width="100%" height={300}>
                            <LineChart data={emotionTrendData}>
                              <CartesianGrid strokeDasharray="3 3" stroke="rgba(156, 163, 175, 0.3)" />
                              <XAxis 
                                dataKey="date" 
                                axisLine={false}
                                tickLine={false}
                                tick={{ fontSize: 12, fill: '#6B7280' }}
                              />
                              <YAxis 
                                domain={[0, 100]} 
                                axisLine={false}
                                tickLine={false}
                                tick={{ fontSize: 12, fill: '#6B7280' }}
                              />
                              <Tooltip 
                                formatter={(value: any) => [`${value}%`, '感情スコア']}
                                labelFormatter={(label: any) => `記録: ${label}`}
                                contentStyle={{
                                  backgroundColor: 'rgba(255, 255, 255, 0.95)',
                                  border: 'none',
                                  borderRadius: '12px',
                                  boxShadow: '0 10px 25px rgba(0, 0, 0, 0.1)'
                                }}
                              />
                              <Line 
                                type="monotone" 
                                dataKey="score" 
                                stroke="url(#colorGradient)" 
                                strokeWidth={3}
                                dot={{ fill: '#3B82F6', strokeWidth: 2, r: 5 }}
                                activeDot={{ r: 7, stroke: '#3B82F6', strokeWidth: 2, fill: '#ffffff' }}
                              />
                              <defs>
                                <linearGradient id="colorGradient" x1="0" y1="0" x2="1" y2="0">
                                  <stop offset="0%" stopColor="#3B82F6" />
                                  <stop offset="100%" stopColor="#8B5CF6" />
                                </linearGradient>
                              </defs>
                            </LineChart>
                          </ResponsiveContainer>
                        </motion.div>
                      </CardContent>
                    </Card>
                  </div>

                  {/* テーマ分析 */}
                  <Card className="modern-card">
                    <CardHeader>
                      <CardTitle className="flex items-center text-xl font-bold">
                        <Tag className="mr-2 h-5 w-5 text-purple-500" />
                        テーマ分析
                      </CardTitle>
                      <CardDescription className="text-gray-600 dark:text-gray-400">
                        AIが抽出した主要テーマの出現頻度とパターン
                      </CardDescription>
                    </CardHeader>
                    <CardContent>
                      <motion.div
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.8, delay: 0.6 }}
                      >
                        <ResponsiveContainer width="100%" height={350}>
                          <BarChart data={themeData}>
                            <CartesianGrid strokeDasharray="3 3" stroke="rgba(156, 163, 175, 0.3)" />
                            <XAxis 
                              dataKey="theme" 
                              axisLine={false}
                              tickLine={false}
                              tick={{ fontSize: 12, fill: '#6B7280' }}
                              angle={-45}
                              textAnchor="end"
                              height={80}
                            />
                            <YAxis 
                              axisLine={false}
                              tickLine={false}
                              tick={{ fontSize: 12, fill: '#6B7280' }}
                            />
                            <Tooltip 
                              contentStyle={{
                                backgroundColor: 'rgba(255, 255, 255, 0.95)',
                                border: 'none',
                                borderRadius: '12px',
                                boxShadow: '0 10px 25px rgba(0, 0, 0, 0.1)'
                              }}
                            />
                            <Bar 
                              dataKey="count" 
                              fill="url(#purpleGradient)"
                              radius={[4, 4, 0, 0]}
                              className="hover:opacity-80 transition-opacity cursor-pointer"
                            />
                            <defs>
                              <linearGradient id="purpleGradient" x1="0" y1="0" x2="0" y2="1">
                                <stop offset="0%" stopColor="#8B5CF6" />
                                <stop offset="100%" stopColor="#A855F7" />
                              </linearGradient>
                            </defs>
                          </BarChart>
                        </ResponsiveContainer>
                      </motion.div>
                    </CardContent>
                  </Card>
                </motion.div>
              )}

              {/* 基本チャート */}
              <motion.div 
                initial={{ opacity: 0, y: 30 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, ease: "easeOut" }}
                className="space-y-8"
              >
                <div className="flex items-center justify-center">
                  <motion.div
                    className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-gradient-to-r from-green-500 to-emerald-600 text-white mr-4"
                    whileHover={{ scale: 1.1 }}
                  >
                    <BarChart3 className="h-6 w-6" />
                  </motion.div>
                  <h2 className="text-3xl font-bold text-gray-900 dark:text-white">基本分析</h2>
                </div>
                
                <div className="grid md:grid-cols-2 gap-8">
                  {/* カテゴリ別円グラフ */}
                  <Card className="modern-card-glass group hover:scale-105 transition-all duration-300">
                    <CardHeader>
                      <CardTitle className="flex items-center text-xl font-bold">
                        <PieChartIcon className="mr-2 h-5 w-5 text-blue-500" />
                        カテゴリ別分布
                      </CardTitle>
                      <CardDescription className="text-gray-600 dark:text-gray-400">
                        思考記録のカテゴリごとの割合とバランス
                      </CardDescription>
                    </CardHeader>
                    <CardContent>
                      <motion.div
                        initial={{ opacity: 0, scale: 0.8 }}
                        animate={{ opacity: 1, scale: 1 }}
                        transition={{ duration: 0.8 }}
                      >
                        <ResponsiveContainer width="100%" height={300}>
                          <PieChart>
                            <Pie
                              data={categoryData}
                              dataKey="count"
                              nameKey="category"
                              cx="50%"
                              cy="50%"
                              outerRadius={90}
                              innerRadius={50}
                              label={(entry: any) => `${entry.category} ${entry.percentage}%`}
                              labelLine={false}
                            >
                              {categoryData.map((entry, index) => (
                                <Cell 
                                  key={index} 
                                  fill={COLORS[entry.category as keyof typeof COLORS]}
                                  className="hover:opacity-80 transition-opacity cursor-pointer"
                                />
                              ))}
                            </Pie>
                            <Tooltip 
                              contentStyle={{
                                backgroundColor: 'rgba(255, 255, 255, 0.95)',
                                border: 'none',
                                borderRadius: '12px',
                                boxShadow: '0 10px 25px rgba(0, 0, 0, 0.1)'
                              }}
                            />
                          </PieChart>
                        </ResponsiveContainer>
                      </motion.div>
                    </CardContent>
                  </Card>

                  {/* 日別記録数バーチャート */}
                  <Card className="modern-card-glass group hover:scale-105 transition-all duration-300">
                    <CardHeader>
                      <CardTitle className="flex items-center text-xl font-bold">
                        <Calendar className="mr-2 h-5 w-5 text-green-500" />
                        記録頻度（過去7日間）
                      </CardTitle>
                      <CardDescription className="text-gray-600 dark:text-gray-400">
                        日別の思考記録数のアクティビティ推移
                      </CardDescription>
                    </CardHeader>
                    <CardContent>
                      <motion.div
                        initial={{ opacity: 0, x: -50 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ duration: 0.8, delay: 0.2 }}
                      >
                        <ResponsiveContainer width="100%" height={300}>
                          <BarChart data={dailyData}>
                            <CartesianGrid strokeDasharray="3 3" stroke="rgba(156, 163, 175, 0.3)" />
                            <XAxis 
                              dataKey="date" 
                              axisLine={false}
                              tickLine={false}
                              tick={{ fontSize: 12, fill: '#6B7280' }}
                            />
                            <YAxis 
                              axisLine={false}
                              tickLine={false}
                              tick={{ fontSize: 12, fill: '#6B7280' }}
                            />
                            <Tooltip 
                              contentStyle={{
                                backgroundColor: 'rgba(255, 255, 255, 0.95)',
                                border: 'none',
                                borderRadius: '12px',
                                boxShadow: '0 10px 25px rgba(0, 0, 0, 0.1)'
                              }}
                            />
                            <Bar 
                              dataKey="count" 
                              fill="url(#blueGradient)"
                              radius={[4, 4, 0, 0]}
                              className="hover:opacity-80 transition-opacity cursor-pointer"
                            />
                            <defs>
                              <linearGradient id="blueGradient" x1="0" y1="0" x2="0" y2="1">
                                <stop offset="0%" stopColor="#3B82F6" />
                                <stop offset="100%" stopColor="#1D4ED8" />
                              </linearGradient>
                            </defs>
                          </BarChart>
                        </ResponsiveContainer>
                      </motion.div>
                    </CardContent>
                  </Card>
                </div>
              </motion.div>

              {/* カテゴリ詳細テーブル */}
              <motion.div 
                initial={{ opacity: 0, y: 30 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, ease: "easeOut" }}
              >
                <Card className="modern-card">
                  <CardHeader>
                    <CardTitle className="flex items-center text-xl font-bold">
                      <Activity className="mr-2 h-5 w-5 text-blue-500" />
                      カテゴリ詳細統計
                    </CardTitle>
                    <CardDescription className="text-gray-600 dark:text-gray-400">
                      各カテゴリの記録数、割合、トレンド情報
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-3">
                      {categoryData.map((item, index) => (
                        <motion.div 
                          key={index} 
                          initial={{ opacity: 0, x: -20 }}
                          animate={{ opacity: 1, x: 0 }}
                          transition={{ delay: index * 0.1, duration: 0.5 }}
                          className="group flex items-center justify-between p-4 bg-gray-50/50 dark:bg-gray-800/50 hover:bg-gray-100/50 dark:hover:bg-gray-700/50 rounded-xl border transition-all duration-300 hover:shadow-md"
                        >
                          <div className="flex items-center gap-4">
                            <motion.div 
                              className="w-5 h-5 rounded-full shadow-sm"
                              style={{ backgroundColor: COLORS[item.category as keyof typeof COLORS] }}
                              whileHover={{ scale: 1.2 }}
                              transition={{ duration: 0.2 }}
                            />
                            <div>
                              <span className="font-semibold text-gray-900 dark:text-white group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">
                                {item.category}
                              </span>
                              <div className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                                全体の{item.percentage}%を占める
                              </div>
                            </div>
                          </div>
                          <div className="text-right">
                            <div className="text-2xl font-bold text-gray-900 dark:text-white">
                              {item.count}
                              <span className="text-sm font-normal text-gray-500 dark:text-gray-400 ml-1">件</span>
                            </div>
                            <div className="text-sm font-medium" style={{ color: COLORS[item.category as keyof typeof COLORS] }}>
                              {item.percentage}%
                            </div>
                          </div>
                        </motion.div>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              </motion.div>
            </motion.div>
          )}
        </motion.div>
      </div>
    </div>
  )
}