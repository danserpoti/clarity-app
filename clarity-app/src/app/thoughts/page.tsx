'use client'

import { useState, useEffect, useMemo } from 'react'
import Link from 'next/link'
import { motion, AnimatePresence } from 'framer-motion'
import { 
  Search, 
  Filter, 
  Plus, 
  Brain, 
  Calendar, 
  Tag, 
  TrendingUp, 
  BarChart3,
  Sparkles,
  Eye,
  Download,
  RefreshCw,
  Heart,
  MessageCircle,
  Clock,
  BookOpen,
  Target,
  Loader2,
  X
} from 'lucide-react'

import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { useToast } from '@/hooks/use-toast'
import { getThoughts, ThoughtEntry } from '@/lib/localStorage'

const fadeInUp = {
  initial: { opacity: 0, y: 30 },
  animate: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: -30 },
  transition: { duration: 0.6, ease: 'easeOut' }
}

const staggerChildren = {
  animate: {
    transition: {
      staggerChildren: 0.05
    }
  }
}

const categoryIcons = {
  '仕事': BookOpen,
  '人間関係': Heart,
  '目標管理': Target,
  '学習': TrendingUp,
  '感情': MessageCircle,
  'その他': Sparkles
}

// Notion同期ボタンコンポーネント
function NotionSyncButton({ thoughts }: { thoughts: ThoughtEntry[] }) {
  const [isLoading, setIsLoading] = useState(false)
  const { toast } = useToast()

  const handleSync = async () => {
    setIsLoading(true)

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
        toast({
          title: '✅ Notion同期完了',
          description: result.message,
          variant: 'success'
        })
      } else {
        toast({
          title: '❌ 同期エラー',
          description: result.error || 'Notion同期に失敗しました',
          variant: 'destructive'
        })
      }
    } catch (error) {
      toast({
        title: '❌ 通信エラー',
        description: 'Notion同期でエラーが発生しました',
        variant: 'destructive'
      })
    }

    setIsLoading(false)
  }

  return (
    <Button 
      variant="outline"
      onClick={handleSync}
      disabled={isLoading}
      className="flex items-center"
    >
      {isLoading ? (
        <>
          <Loader2 className="mr-2 h-4 w-4 animate-spin" />
          同期中...
        </>
      ) : (
        <>
          <BookOpen className="mr-2 h-4 w-4" />
          Notionに同期
        </>
      )}
    </Button>
  )
}

// スケルトンローディング
function ThoughtSkeleton() {
  return (
    <Card className="modern-card">
      <CardHeader>
        <div className="flex justify-between items-start">
          <div className="flex items-center gap-2">
            <div className="w-16 h-6 bg-gray-200 dark:bg-gray-700 rounded-full shimmer" />
            <div className="w-20 h-6 bg-gray-200 dark:bg-gray-700 rounded-full shimmer" />
          </div>
          <div className="w-24 h-4 bg-gray-200 dark:bg-gray-700 rounded shimmer" />
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="bg-gray-100 dark:bg-gray-800 rounded-lg p-4">
          <div className="space-y-2">
            <div className="w-full h-4 bg-gray-200 dark:bg-gray-700 rounded shimmer" />
            <div className="w-3/4 h-4 bg-gray-200 dark:bg-gray-700 rounded shimmer" />
            <div className="w-1/2 h-4 bg-gray-200 dark:bg-gray-700 rounded shimmer" />
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

export default function ThoughtsPage() {
  const [thoughts, setThoughts] = useState<ThoughtEntry[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState('')
  const [searchTerm, setSearchTerm] = useState('')
  const [categoryFilter, setCategoryFilter] = useState('all')
  const [emotionFilter, setEmotionFilter] = useState('all')
  const [sortBy, setSortBy] = useState('newest')
  
  const { toast } = useToast()

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
      toast({
        title: '❌ データ取得エラー',
        description: 'データの取得に失敗しました',
        variant: 'destructive'
      })
    }
    
    setIsLoading(false)
  }

  // フィルタリングとソート
  const filteredAndSortedThoughts = useMemo(() => {
    let filtered = thoughts

    // 検索フィルター
    if (searchTerm) {
      filtered = filtered.filter(thought => 
        thought.content.toLowerCase().includes(searchTerm.toLowerCase()) ||
        thought.category.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (thought.ai_themes && thought.ai_themes.some((theme: string) => 
          theme.toLowerCase().includes(searchTerm.toLowerCase())
        )) ||
        (thought.ai_keywords && thought.ai_keywords.some((keyword: string) => 
          keyword.toLowerCase().includes(searchTerm.toLowerCase())
        ))
      )
    }

    // カテゴリフィルター
    if (categoryFilter !== 'all') {
      filtered = filtered.filter(thought => thought.category === categoryFilter)
    }

    // 感情フィルター
    if (emotionFilter !== 'all') {
      if (emotionFilter === 'analyzed') {
        filtered = filtered.filter(thought => thought.ai_emotion)
      } else if (emotionFilter === 'unanalyzed') {
        filtered = filtered.filter(thought => !thought.ai_emotion)
      } else {
        filtered = filtered.filter(thought => thought.ai_emotion === emotionFilter)
      }
    }

    // ソート
    filtered.sort((a, b) => {
      switch (sortBy) {
        case 'newest':
          return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
        case 'oldest':
          return new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
        case 'category':
          return a.category.localeCompare(b.category)
        case 'emotion':
          if (!a.ai_emotion && !b.ai_emotion) return 0
          if (!a.ai_emotion) return 1
          if (!b.ai_emotion) return -1
          return a.ai_emotion.localeCompare(b.ai_emotion)
        default:
          return 0
      }
    })

    return filtered
  }, [thoughts, searchTerm, categoryFilter, emotionFilter, sortBy])

  // カテゴリごとの色分け
  const getCategoryColor = (category: string) => {
    const colors: { [key: string]: string } = {
      '仕事': 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200',
      '人間関係': 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
      '目標管理': 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200',
      '学習': 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200',
      '感情': 'bg-pink-100 text-pink-800 dark:bg-pink-900 dark:text-pink-200',
      'その他': 'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200'
    }
    return colors[category] || 'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200'
  }

  // カードスタイルを感情に応じて変更
  const getCardStyle = (thought: ThoughtEntry) => {
    if (thought.ai_emotion) {
      const emotion = thought.ai_emotion.toLowerCase()
      if (emotion.includes('positive') || emotion.includes('ポジティブ')) {
        return 'modern-card-glass border-l-4 border-l-green-400 dark:border-l-green-500'
      } else if (emotion.includes('negative') || emotion.includes('ネガティブ')) {
        return 'modern-card-glass border-l-4 border-l-red-400 dark:border-l-red-500'
      } else if (emotion.includes('mixed') || emotion.includes('複雑')) {
        return 'modern-card-glass border-l-4 border-l-orange-400 dark:border-l-orange-500'
      }
    }
    return 'modern-card-glass'
  }

  // 感情に応じた絵文字と色
  const getEmotionDisplay = (emotion?: string) => {
    if (!emotion) return null
    
    const emotions = {
      'positive': { emoji: '😊', color: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200', label: 'ポジティブ' },
      'negative': { emoji: '😔', color: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200', label: 'ネガティブ' },
      'neutral': { emoji: '😌', color: 'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200', label: 'ニュートラル' },
      'mixed': { emoji: '😐', color: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200', label: 'ミックス' }
    }
    
    return emotions[emotion as keyof typeof emotions] || null
  }

  const getEmotionTheme = (emotion?: string) => {
    if (!emotion) return ''
    switch (emotion) {
      case 'positive': return 'emotion-positive'
      case 'negative': return 'emotion-negative'
      case 'mixed': return 'emotion-mixed'
      default: return 'emotion-neutral'
    }
  }

  // 日付フォーマット
  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    const now = new Date()
    const diffTime = now.getTime() - date.getTime()
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24))

    if (diffDays === 0) {
      return date.toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit' })
    } else if (diffDays === 1) {
      return '昨日'
    } else if (diffDays < 7) {
      return `${diffDays}日前`
    } else {
      return date.toLocaleDateString('ja-JP', { month: 'short', day: 'numeric' })
    }
  }

  // 統計計算
  const stats = useMemo(() => {
    const analyzedCount = thoughts.filter(thought => thought.ai_emotion).length
    const analysisRate = thoughts.length > 0 ? Math.round((analyzedCount / thoughts.length) * 100) : 0
    
    const emotionCounts = thoughts.reduce((acc, thought) => {
      if (thought.ai_emotion) {
        acc[thought.ai_emotion] = (acc[thought.ai_emotion] || 0) + 1
      }
      return acc
    }, {} as Record<string, number>)

    const mostCommonEmotion = Object.entries(emotionCounts).reduce((a, b) => 
      emotionCounts[a[0]] > emotionCounts[b[0]] ? a : b, ['', 0]
    )[0]

    return {
      total: thoughts.length,
      analyzed: analyzedCount,
      analysisRate,
      mostCommonEmotion
    }
  }, [thoughts])

  const clearFilters = () => {
    setSearchTerm('')
    setCategoryFilter('all')
    setEmotionFilter('all')
    setSortBy('newest')
  }

  if (isLoading) {
    return (
      <div className="min-h-screen pt-20 pb-32">
        <div className="container mx-auto px-4 max-w-6xl">
          <motion.div
            initial="initial"
            animate="animate"
            variants={staggerChildren}
            className="space-y-8"
          >
            {/* ヘッダースケルトン */}
            <motion.div variants={fadeInUp} className="text-center">
              <div className="w-64 h-10 bg-gray-200 dark:bg-gray-700 rounded mx-auto mb-4 shimmer" />
              <div className="w-96 h-6 bg-gray-200 dark:bg-gray-700 rounded mx-auto shimmer" />
            </motion.div>

            {/* コンテンツスケルトン */}
            <div className="grid md:grid-cols-2 xl:grid-cols-3 gap-6">
              {Array.from({ length: 6 }).map((_, index) => (
                <ThoughtSkeleton key={index} />
              ))}
            </div>
          </motion.div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen pt-20 pb-32">
      <div className="container mx-auto px-4 max-w-6xl">
        <motion.div
          initial="initial"
          animate="animate"
          variants={staggerChildren}
          className="space-y-8"
        >
          {/* ヘッダー */}
          <motion.div variants={fadeInUp} className="text-center">
            <motion.div
              className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gradient-to-r from-blue-500 to-purple-600 text-white mb-6"
              whileHover={{ scale: 1.1, rotate: 360 }}
              transition={{ duration: 0.6 }}
            >
              <BookOpen className="h-8 w-8" />
            </motion.div>
            <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-4">
              思考記録一覧
            </h1>
            <p className="text-xl text-gray-600 dark:text-gray-300 max-w-2xl mx-auto">
              記録された思考を振り返り、成長の軌跡を確認しましょう
            </p>
          </motion.div>

          {/* 統計ダッシュボード */}
          <motion.div variants={fadeInUp}>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
              <Card className="modern-card-glass text-center hover:scale-105 transition-transform duration-300">
                <CardContent className="p-6">
                  <div className="text-3xl font-bold text-blue-600 mb-2">{stats.total}</div>
                  <div className="text-sm text-gray-600 dark:text-gray-400">総記録数</div>
                </CardContent>
              </Card>
              <Card className="modern-card-glass text-center hover:scale-105 transition-transform duration-300">
                <CardContent className="p-6">
                  <div className="text-3xl font-bold text-green-600 mb-2">{stats.analyzed}</div>
                  <div className="text-sm text-gray-600 dark:text-gray-400">AI分析済み</div>
                </CardContent>
              </Card>
              <Card className="modern-card-glass text-center hover:scale-105 transition-transform duration-300">
                <CardContent className="p-6">
                  <div className="text-3xl font-bold text-purple-600 mb-2">{stats.analysisRate}%</div>
                  <div className="text-sm text-gray-600 dark:text-gray-400">分析率</div>
                </CardContent>
              </Card>
              <Card className="modern-card-glass text-center hover:scale-105 transition-transform duration-300">
                <CardContent className="p-6">
                  <div className="text-3xl mb-2">
                    {stats.mostCommonEmotion ? getEmotionDisplay(stats.mostCommonEmotion)?.emoji : '📝'}
                  </div>
                  <div className="text-sm text-gray-600 dark:text-gray-400">最多感情</div>
                </CardContent>
              </Card>
            </div>
          </motion.div>

          {/* フィルターと検索 */}
          <motion.div variants={fadeInUp}>
            <Card className="modern-card-glass">
              <CardContent className="p-6">
                <div className="flex flex-col lg:flex-row gap-4 items-center">
                  {/* 検索 */}
                  <div className="relative flex-1 min-w-0">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                    <Input
                      placeholder="記録内容、カテゴリ、テーマ、キーワードで検索..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="pl-10"
                    />
                  </div>

                  {/* フィルター */}
                  <div className="flex flex-wrap gap-3">
                    <Select value={categoryFilter} onValueChange={setCategoryFilter}>
                      <SelectTrigger className="w-40">
                        <SelectValue placeholder="カテゴリ" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">すべてのカテゴリ</SelectItem>
                        <SelectItem value="仕事">仕事</SelectItem>
                        <SelectItem value="人間関係">人間関係</SelectItem>
                        <SelectItem value="目標管理">目標管理</SelectItem>
                        <SelectItem value="学習">学習</SelectItem>
                        <SelectItem value="感情">感情</SelectItem>
                        <SelectItem value="その他">その他</SelectItem>
                      </SelectContent>
                    </Select>

                    <Select value={emotionFilter} onValueChange={setEmotionFilter}>
                      <SelectTrigger className="w-40">
                        <SelectValue placeholder="感情" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">すべての感情</SelectItem>
                        <SelectItem value="analyzed">分析済み</SelectItem>
                        <SelectItem value="unanalyzed">未分析</SelectItem>
                        <SelectItem value="positive">ポジティブ</SelectItem>
                        <SelectItem value="negative">ネガティブ</SelectItem>
                        <SelectItem value="neutral">ニュートラル</SelectItem>
                        <SelectItem value="mixed">ミックス</SelectItem>
                      </SelectContent>
                    </Select>

                    <Select value={sortBy} onValueChange={setSortBy}>
                      <SelectTrigger className="w-32">
                        <SelectValue placeholder="並び順" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="newest">新しい順</SelectItem>
                        <SelectItem value="oldest">古い順</SelectItem>
                        <SelectItem value="category">カテゴリ順</SelectItem>
                        <SelectItem value="emotion">感情順</SelectItem>
                      </SelectContent>
                    </Select>

                    {(searchTerm || categoryFilter !== 'all' || emotionFilter !== 'all' || sortBy !== 'newest') && (
                      <Button variant="outline" onClick={clearFilters} size="sm">
                        <X className="h-4 w-4 mr-2" />
                        クリア
                      </Button>
                    )}
                  </div>
                </div>

                {/* アクションボタン */}
                <div className="flex flex-wrap gap-3 mt-6">
                  <Link href="/thoughts/new">
                    <Button className="bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700">
                      <Plus className="mr-2 h-4 w-4" />
                      新しい記録
                    </Button>
                  </Link>
                  <Link href="/analytics">
                    <Button variant="outline">
                      <BarChart3 className="mr-2 h-4 w-4" />
                      分析結果
                    </Button>
                  </Link>
                  <Button variant="outline" onClick={fetchThoughts}>
                    <RefreshCw className="mr-2 h-4 w-4" />
                    更新
                  </Button>
                  {thoughts.length > 0 && <NotionSyncButton thoughts={thoughts} />}
                  {thoughts.length > 0 && (
                    <Button 
                      variant="outline" 
                      onClick={() => window.open('/api/export?format=csv', '_blank')}
                    >
                      <Download className="mr-2 h-4 w-4" />
                      エクスポート
                    </Button>
                  )}
                </div>
              </CardContent>
            </Card>
          </motion.div>

          {/* エラー表示 */}
          {error && (
            <motion.div variants={fadeInUp}>
              <Card className="modern-card border-red-200 dark:border-red-800">
                <CardContent className="p-6">
                  <div className="flex items-center text-red-600 dark:text-red-400">
                    <span className="text-2xl mr-3">❌</span>
                    <div>
                      <h3 className="font-semibold">エラーが発生しました</h3>
                      <p className="text-sm">{error}</p>
                    </div>
                  </div>
                  <Button onClick={fetchThoughts} variant="outline" className="mt-4">
                    再読み込み
                  </Button>
                </CardContent>
              </Card>
            </motion.div>
          )}

          {/* 記録カード一覧 */}
          <motion.div variants={fadeInUp}>
            <div className="mb-4 flex items-center justify-between">
              <p className="text-sm text-gray-600 dark:text-gray-400">
                {filteredAndSortedThoughts.length}件の記録
                {filteredAndSortedThoughts.length !== thoughts.length && 
                  ` (全${thoughts.length}件中)`
                }
              </p>
            </div>

            {filteredAndSortedThoughts.length === 0 ? (
              <Card className="modern-card-glass">
                <CardContent className="text-center py-16">
                  <div className="text-6xl mb-4">📝</div>
                  <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
                    {thoughts.length === 0 ? '記録がありません' : '該当する記録がありません'}
                  </h3>
                  <p className="text-gray-600 dark:text-gray-400 mb-6">
                    {thoughts.length === 0 
                      ? '最初の記録を作成してみましょう' 
                      : 'フィルター条件を変更してお試しください'
                    }
                  </p>
                  {thoughts.length === 0 ? (
                    <Link href="/thoughts/new">
                      <Button className="bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700">
                        <Plus className="mr-2 h-4 w-4" />
                        最初の記録を作成
                      </Button>
                    </Link>
                  ) : (
                    <Button onClick={clearFilters} variant="outline">
                      フィルターをクリア
                    </Button>
                  )}
                </CardContent>
              </Card>
            ) : (
              <motion.div
                className="grid md:grid-cols-2 xl:grid-cols-3 gap-6"
                variants={staggerChildren}
              >
                <AnimatePresence>
                  {filteredAndSortedThoughts.map((thought, index) => {
                    const emotionDisplay = getEmotionDisplay(thought.ai_emotion)
                    const hasAnalysis = Boolean(thought.ai_emotion)
                    const IconComponent = categoryIcons[thought.category as keyof typeof categoryIcons]
                    
                    return (
                      <motion.div
                        key={thought.id}
                        variants={fadeInUp}
                        layout
                        className="h-fit"
                      >
                        <Card className={`${getCardStyle(thought)} group hover:scale-105 transition-all duration-300`}>
                          <CardHeader className="pb-3">
                            <div className="flex justify-between items-start">
                              <div className="flex items-center gap-2 flex-wrap">
                                <Badge className={getCategoryColor(thought.category)}>
                                  {IconComponent && <IconComponent className="w-3 h-3 mr-1" />}
                                  {thought.category}
                                </Badge>
                                
                                {emotionDisplay && (
                                  <Badge className={emotionDisplay.color}>
                                    {emotionDisplay.emoji} {emotionDisplay.label}
                                  </Badge>
                                )}

                                {thought.ai_emotion_score !== null && thought.ai_emotion_score !== undefined && (
                                  <Badge variant="outline">
                                    {Math.round(thought.ai_emotion_score * 100)}%
                                  </Badge>
                                )}
                              </div>
                              <div className="flex items-center text-sm text-gray-500 dark:text-gray-400 shrink-0 ml-2">
                                <Clock className="w-3 h-3 mr-1" />
                                {formatDate(thought.created_at)}
                              </div>
                            </div>
                          </CardHeader>
                          
                          <CardContent className="space-y-4">
                            {/* 思考内容 */}
                            <div className="bg-gray-50 dark:bg-gray-800/50 rounded-lg p-4 border-l-4 border-blue-500">
                              <p className="text-gray-800 dark:text-gray-200 leading-relaxed line-clamp-4">
                                {thought.content}
                              </p>
                            </div>
                            
                            {/* AI分析結果 */}
                            {hasAnalysis && (
                              <motion.div
                                initial={{ opacity: 0, height: 0 }}
                                animate={{ opacity: 1, height: 'auto' }}
                                className="bg-gradient-to-br from-blue-50 to-purple-50 dark:from-blue-900/20 dark:to-purple-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4 space-y-3"
                              >
                                <h4 className="flex items-center text-sm font-semibold text-blue-800 dark:text-blue-200">
                                  <Brain className="mr-2 h-4 w-4" />
                                  AI分析結果
                                </h4>
                                
                                {/* テーマ */}
                                {thought.ai_themes && Array.isArray(thought.ai_themes) && thought.ai_themes.length > 0 && (
                                  <div>
                                    <span className="text-xs font-medium text-blue-700 dark:text-blue-300">テーマ</span>
                                    <div className="flex flex-wrap gap-1 mt-1">
                                      {thought.ai_themes.slice(0, 3).map((theme, themeIndex) => (
                                        <span key={themeIndex} className="bg-blue-100 text-blue-800 dark:bg-blue-800 dark:text-blue-200 px-2 py-1 rounded text-xs">
                                          {theme}
                                        </span>
                                      ))}
                                    </div>
                                  </div>
                                )}
                                
                                {/* 要約 */}
                                {thought.ai_summary && (
                                  <div>
                                    <span className="text-xs font-medium text-blue-700 dark:text-blue-300">要約</span>
                                    <p className="text-xs text-blue-600 dark:text-blue-400 mt-1 line-clamp-2">
                                      {thought.ai_summary}
                                    </p>
                                  </div>
                                )}
                              </motion.div>
                            )}
                          </CardContent>
                        </Card>
                      </motion.div>
                    )
                  })}
                </AnimatePresence>
              </motion.div>
            )}
          </motion.div>

          {/* 推奨アクション */}
          {thoughts.length > 0 && (
            <motion.div variants={fadeInUp}>
              <Card className="modern-card bg-gradient-to-r from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20 border-green-200 dark:border-green-800">
                <CardHeader>
                  <CardTitle className="flex items-center text-green-800 dark:text-green-200">
                    <Sparkles className="mr-2 h-5 w-5" />
                    次のステップ
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="grid md:grid-cols-3 gap-4">
                    <Link href="/thoughts/new" className="group">
                      <div className="bg-white dark:bg-gray-900 rounded-lg p-4 border transition-all duration-300 group-hover:shadow-md group-hover:-translate-y-1">
                        <div className="text-blue-600 mb-2">
                          <Plus className="h-6 w-6" />
                        </div>
                        <h4 className="font-medium mb-1">新しい記録を作成</h4>
                        <p className="text-sm text-gray-600 dark:text-gray-400">
                          今の思考を記録してAI分析を受ける
                        </p>
                      </div>
                    </Link>
                    
                    <Link href="/analytics" className="group">
                      <div className="bg-white dark:bg-gray-900 rounded-lg p-4 border transition-all duration-300 group-hover:shadow-md group-hover:-translate-y-1">
                        <div className="text-purple-600 mb-2">
                          <BarChart3 className="h-6 w-6" />
                        </div>
                        <h4 className="font-medium mb-1">詳細分析を見る</h4>
                        <p className="text-sm text-gray-600 dark:text-gray-400">
                          感情の推移やテーマ分析をチェック
                        </p>
                      </div>
                    </Link>
                    
                    <div className="group">
                      <div className="bg-white dark:bg-gray-900 rounded-lg p-4 border">
                        <div className="text-green-600 mb-2">
                          <TrendingUp className="h-6 w-6" />
                        </div>
                        <h4 className="font-medium mb-1">成長を実感</h4>
                        <p className="text-sm text-gray-600 dark:text-gray-400">
                          記録を振り返って自分の変化を確認
                        </p>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          )}
        </motion.div>
      </div>
    </div>
  )
}