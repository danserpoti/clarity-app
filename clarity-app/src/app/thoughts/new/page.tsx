'use client'

import React, { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { motion, AnimatePresence } from 'framer-motion'
import { 
  Brain, 
  Sparkles, 
  Save, 
  Loader2, 
  CheckCircle2, 
  ArrowLeft,
  Lightbulb,
  Heart,
  TrendingUp,
  BookOpen,
  MessageCircle,
  Target,
  Zap,
  Tag,
  Clock
} from 'lucide-react'

import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { useToast } from '@/hooks/use-toast'
import { saveThoughtWithAnalysis } from '@/lib/supabase'
import { ThoughtAnalysis } from '@/lib/openai'

const fadeInUp = {
  initial: { opacity: 0, y: 30 },
  animate: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: -30 },
  transition: { duration: 0.6, ease: 'easeOut' }
}

const staggerChildren = {
  animate: {
    transition: {
      staggerChildren: 0.1
    }
  }
}

const categoryIcons = {
  '仕事': BookOpen,
  '人間関係': Heart,
  '目標管理': Target,
  '応募': TrendingUp,
  '感情': MessageCircle,
  'その他': Sparkles
}

export default function NewThought() {
  const [content, setContent] = useState('')
  const [category, setCategory] = useState('')
  const [isSubmitted, setIsSubmitted] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [analysis, setAnalysis] = useState<ThoughtAnalysis | null>(null)
  const [isAnalyzing, setIsAnalyzing] = useState(false)
  const [step, setStep] = useState(1) // 1: 入力, 2: 分析, 3: 完了
  
  const { toast } = useToast()
  const router = useRouter()

  const handleSubmit = async () => {
    if (content.trim() === '') {
      toast({
        title: '⚠️ 入力エラー',
        description: '思考内容を入力してください',
        variant: 'destructive'
      })
      return
    }
    if (category === '') {
      toast({
        title: '⚠️ 選択エラー',
        description: 'カテゴリを選択してください',
        variant: 'destructive'
      })
      return
    }
    
    setIsLoading(true)

    try {
      const result = await saveThoughtWithAnalysis(content, category, analysis || undefined)
      
      if (result.success) {
        setIsSubmitted(true)
        setStep(3)
        toast({
          title: '✅ 保存完了',
          description: '思考記録がデータベースに保存されました',
          variant: 'success'
        })
      } else {
        toast({
          title: '❌ 保存エラー',
          description: '保存に失敗しました。もう一度お試しください',
          variant: 'destructive'
        })
      }
    } catch (error) {
      toast({
        title: '❌ エラー',
        description: 'システムエラーが発生しました',
        variant: 'destructive'
      })
    }
    
    setIsLoading(false)
  }

  const handleAnalyze = async () => {
    if (content.trim() === '') {
      toast({
        title: '⚠️ 入力エラー',
        description: '分析する内容を入力してください',
        variant: 'destructive'
      })
      return
    }

    setIsAnalyzing(true)
    setStep(2)

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
        toast({
          title: '🤖 分析完了',
          description: 'AI分析が完了しました',
          variant: 'success'
        })
      } else {
        toast({
          title: '❌ 分析エラー',
          description: data.error || 'AI分析に失敗しました',
          variant: 'destructive'
        })
        setStep(1)
      }
    } catch (error) {
      toast({
        title: '❌ 通信エラー',
        description: 'AI分析の通信に失敗しました',
        variant: 'destructive'
      })
      setStep(1)
    }

    setIsAnalyzing(false)
  }

  const handleNewEntry = () => {
    setIsSubmitted(false)
    setContent('')
    setCategory('')
    setAnalysis(null)
    setStep(1)
  }

  const getEmotionEmoji = (emotion: string) => {
    switch (emotion) {
      case 'positive': return '😊'
      case 'negative': return '😔'
      case 'mixed': return '😐'
      default: return '😌'
    }
  }

  const getEmotionTheme = (emotion: string) => {
    switch (emotion) {
      case 'positive': return 'emotion-positive'
      case 'negative': return 'emotion-negative' 
      case 'mixed': return 'emotion-mixed'
      default: return 'emotion-neutral'
    }
  }

  if (isSubmitted) {
    return (
      <div className="min-h-screen pt-20 pb-32">
        <div className="container mx-auto px-4 max-w-4xl">
          <motion.div
            initial="initial"
            animate="animate"
            variants={staggerChildren}
            className="space-y-8"
          >
            {/* ヘッダー */}
            <motion.div variants={fadeInUp} className="text-center">
              <motion.div
                className="inline-flex items-center justify-center w-20 h-20 rounded-full bg-gradient-to-r from-green-500 to-emerald-600 text-white mb-6"
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: 0.2, type: "spring", stiffness: 300 }}
              >
                <CheckCircle2 className="h-10 w-10" />
              </motion.div>
              <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-4">
                記録完了！
              </h1>
              <p className="text-xl text-gray-600 dark:text-gray-300">
                思考記録がデータベースに安全に保存されました
              </p>
            </motion.div>

            {/* 保存された内容 */}
            <motion.div variants={fadeInUp}>
              <Card className="modern-card">
                <CardHeader>
                  <CardTitle className="flex items-center text-green-600 dark:text-green-400">
                    <CheckCircle2 className="mr-2 h-5 w-5" />
                    保存された記録
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-6">
                  <div>
                    <div className="flex items-center mb-2">
                      {categoryIcons[category as keyof typeof categoryIcons] && (
                        React.createElement(categoryIcons[category as keyof typeof categoryIcons], {
                          className: "h-5 w-5 mr-2 text-blue-500"
                        })
                      )}
                      <span className="font-semibold text-gray-700 dark:text-gray-300">カテゴリ:</span>
                    </div>
                    <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200">
                      <Tag className="mr-1 h-3 w-3" />
                      {category}
                    </span>
                  </div>

                  <div>
                    <h3 className="font-semibold text-gray-700 dark:text-gray-300 mb-2">記録内容:</h3>
                    <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-4 border-l-4 border-blue-500">
                      <p className="text-gray-700 dark:text-gray-300 whitespace-pre-wrap leading-relaxed">
                        {content}
                      </p>
                    </div>
                  </div>

                  {/* AI分析結果の表示 */}
                  {analysis && (
                    <motion.div
                      initial={{ opacity: 0, scale: 0.95 }}
                      animate={{ opacity: 1, scale: 1 }}
                      className={`modern-card ${getEmotionTheme(analysis.emotion)}`}
                    >
                      <div className="p-6">
                        <h3 className="flex items-center text-xl font-bold mb-4">
                          <Brain className="mr-2 h-6 w-6 text-purple-600" />
                          AI分析結果
                        </h3>
                        
                        <div className="grid md:grid-cols-2 gap-6">
                          <div className="space-y-4">
                            <div>
                              <span className="text-sm font-medium text-gray-600 dark:text-gray-400">感情分析</span>
                              <div className="flex items-center mt-1">
                                <span className="text-2xl mr-2">{getEmotionEmoji(analysis.emotion)}</span>
                                <span className="font-semibold capitalize">{analysis.emotion}</span>
                                <span className="ml-2 text-sm text-gray-500">
                                  ({Math.round(analysis.emotionScore * 100)}%)
                                </span>
                              </div>
                            </div>

                            <div>
                              <span className="text-sm font-medium text-gray-600 dark:text-gray-400">主要テーマ</span>
                              <div className="flex flex-wrap gap-2 mt-2">
                                {analysis.themes.slice(0, 3).map((theme, index) => (
                                  <span 
                                    key={index} 
                                    className="px-3 py-1 bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200 rounded-full text-sm font-medium"
                                  >
                                    {theme}
                                  </span>
                                ))}
                              </div>
                            </div>
                          </div>

                          <div className="space-y-4">
                            <div>
                              <span className="text-sm font-medium text-gray-600 dark:text-gray-400">要約</span>
                              <p className="mt-1 text-gray-700 dark:text-gray-300 text-sm leading-relaxed">
                                {analysis.summary}
                              </p>
                            </div>

                            <div>
                              <span className="text-sm font-medium text-gray-600 dark:text-gray-400">アドバイス</span>
                              <p className="mt-1 text-gray-700 dark:text-gray-300 text-sm leading-relaxed">
                                {analysis.suggestion}
                              </p>
                            </div>
                          </div>
                        </div>
                      </div>
                    </motion.div>
                  )}

                  {/* アクションボタン */}
                  <div className="flex flex-col sm:flex-row gap-4 pt-6">
                    <Button 
                      onClick={handleNewEntry} 
                      className="flex-1 bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700"
                    >
                      <Sparkles className="mr-2 h-4 w-4" />
                      新しい記録を作成
                    </Button>
                    <Link href="/thoughts" className="flex-1">
                      <Button variant="outline" className="w-full">
                        <BookOpen className="mr-2 h-4 w-4" />
                        記録一覧を見る
                      </Button>
                    </Link>
                    <Link href="/analytics" className="flex-1">
                      <Button variant="outline" className="w-full">
                        <TrendingUp className="mr-2 h-4 w-4" />
                        分析結果を見る
                      </Button>
                    </Link>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          </motion.div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen pt-20 pb-32">
      <div className="container mx-auto px-4 max-w-4xl">
        <motion.div
          initial="initial"
          animate="animate"
          variants={staggerChildren}
          className="space-y-8"
        >
          {/* ヘッダー */}
          <motion.div variants={fadeInUp} className="text-center">
            <Link href="/" className="inline-flex items-center text-blue-600 dark:text-blue-400 hover:text-blue-700 mb-6 group">
              <ArrowLeft className="mr-2 h-4 w-4 group-hover:-translate-x-1 transition-transform" />
              ホームに戻る
            </Link>
            <motion.div
              className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gradient-to-r from-blue-500 to-purple-600 text-white mb-6"
              whileHover={{ scale: 1.1, rotate: 360 }}
              transition={{ duration: 0.6 }}
            >
              <Sparkles className="h-8 w-8" />
            </motion.div>
            <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-4">
              思考を記録しよう
            </h1>
            <p className="text-xl text-gray-600 dark:text-gray-300 max-w-2xl mx-auto">
              あなたの心の声を記録し、AIが分析して新たな洞察を提供します
            </p>
          </motion.div>

          {/* プログレスインジケーター */}
          <motion.div variants={fadeInUp}>
            <div className="flex items-center justify-center space-x-4 mb-8">
              <div className={`flex items-center ${step >= 1 ? 'text-blue-600' : 'text-gray-400'}`}>
                <div className={`w-8 h-8 rounded-full flex items-center justify-center ${step >= 1 ? 'bg-blue-600 text-white' : 'bg-gray-200'}`}>
                  1
                </div>
                <span className="ml-2 text-sm font-medium">記録入力</span>
              </div>
              <div className={`w-12 h-1 ${step >= 2 ? 'bg-blue-600' : 'bg-gray-200'} rounded-full`} />
              <div className={`flex items-center ${step >= 2 ? 'text-blue-600' : 'text-gray-400'}`}>
                <div className={`w-8 h-8 rounded-full flex items-center justify-center ${step >= 2 ? 'bg-blue-600 text-white' : 'bg-gray-200'}`}>
                  2
                </div>
                <span className="ml-2 text-sm font-medium">AI分析</span>
              </div>
              <div className={`w-12 h-1 ${step >= 3 ? 'bg-blue-600' : 'bg-gray-200'} rounded-full`} />
              <div className={`flex items-center ${step >= 3 ? 'text-blue-600' : 'text-gray-400'}`}>
                <div className={`w-8 h-8 rounded-full flex items-center justify-center ${step >= 3 ? 'bg-blue-600 text-white' : 'bg-gray-200'}`}>
                  3
                </div>
                <span className="ml-2 text-sm font-medium">保存完了</span>
              </div>
            </div>
          </motion.div>

          {/* メインフォーム */}
          <motion.div variants={fadeInUp}>
            <Card className="modern-card">
              <CardHeader>
                <CardTitle className="flex items-center text-2xl">
                  <BookOpen className="mr-3 h-6 w-6 text-blue-600" />
                  思考記録フォーム
                </CardTitle>
                <CardDescription className="text-lg">
                  思考と感情を自由に記録し、AIによる分析で新たな気づきを得ましょう
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-8">
                {/* カテゴリ選択 */}
                <div>
                  <label className="flex items-center text-lg font-semibold mb-4 text-gray-700 dark:text-gray-300">
                    <Tag className="mr-2 h-5 w-5" />
                    カテゴリ
                  </label>
                  <Select value={category} onValueChange={setCategory}>
                    <SelectTrigger className="h-12 text-lg">
                      <SelectValue placeholder="記録のカテゴリを選択してください" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="仕事">
                        <div className="flex items-center">
                          <BookOpen className="mr-2 h-4 w-4" />
                          仕事
                        </div>
                      </SelectItem>
                      <SelectItem value="人間関係">
                        <div className="flex items-center">
                          <Heart className="mr-2 h-4 w-4" />
                          人間関係
                        </div>
                      </SelectItem>
                      <SelectItem value="目標管理">
                        <div className="flex items-center">
                          <Target className="mr-2 h-4 w-4" />
                          目標管理
                        </div>
                      </SelectItem>
                      <SelectItem value="応募">
                        <div className="flex items-center">
                          <TrendingUp className="mr-2 h-4 w-4" />
                          応募
                        </div>
                      </SelectItem>
                      <SelectItem value="感情">
                        <div className="flex items-center">
                          <MessageCircle className="mr-2 h-4 w-4" />
                          感情
                        </div>
                      </SelectItem>
                      <SelectItem value="その他">
                        <div className="flex items-center">
                          <Sparkles className="mr-2 h-4 w-4" />
                          その他
                        </div>
                      </SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {/* 思考内容入力 */}
                <div>
                  <label className="flex items-center text-lg font-semibold mb-4 text-gray-700 dark:text-gray-300">
                    <MessageCircle className="mr-2 h-5 w-5" />
                    思考内容
                  </label>
                  <Textarea
                    placeholder="今考えていることや感じていることを自由に書いてください...&#10;&#10;例：&#10;- 今日のプレゼンテーションがうまくいかなかった&#10;- 新しいプロジェクトのアイデアを思いついた&#10;- 最近疲れていて集中できない"
                    value={content}
                    onChange={(e) => setContent(e.target.value)}
                    rows={8}
                    disabled={isLoading || isAnalyzing}
                    className="text-lg resize-none"
                  />
                  <div className="flex items-center justify-between mt-2 text-sm text-gray-500">
                    <span>文字数: {content.length}</span>
                    {content.length > 50 && (
                      <span className="text-green-600 flex items-center">
                        <CheckCircle2 className="mr-1 h-3 w-3" />
                        AI分析に十分な文字数です
                      </span>
                    )}
                  </div>
                </div>

                {/* アクションボタン */}
                <div className="flex flex-col sm:flex-row gap-4">
                  <Button 
                    onClick={handleAnalyze} 
                    variant="outline"
                    size="lg"
                    className="flex-1 h-12 modern-card-glass hover:scale-105 transition-all duration-300"
                    disabled={isAnalyzing || isLoading || content.trim() === ''}
                  >
                    {isAnalyzing ? (
                      <motion.div
                        className="flex items-center"
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        transition={{ duration: 0.3 }}
                      >
                        <motion.div
                          animate={{ rotate: 360 }}
                          transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
                          className="mr-2"
                        >
                          <Brain className="h-5 w-5 text-purple-600" />
                        </motion.div>
                        <div className="flex flex-col items-start">
                          <span>AI分析中...</span>
                          <motion.div
                            className="w-20 h-1 bg-gradient-to-r from-blue-500 to-purple-600 rounded-full"
                            animate={{ scale: [1, 1.1, 1] }}
                            transition={{ duration: 1.5, repeat: Infinity }}
                          />
                        </div>
                      </motion.div>
                    ) : (
                      <>
                        <Brain className="mr-2 h-5 w-5" />
                        AI分析を実行
                      </>
                    )}
                  </Button>
                  <Button 
                    onClick={handleSubmit} 
                    size="lg"
                    className="flex-1 h-12 bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700"
                    disabled={isLoading || isAnalyzing}
                  >
                    {isLoading ? (
                      <>
                        <Loader2 className="mr-2 h-5 w-5 animate-spin" />
                        保存中...
                      </>
                    ) : (
                      <>
                        <Save className="mr-2 h-5 w-5" />
                        {analysis ? '分析結果も一緒に保存' : 'データベースに保存'}
                      </>
                    )}
                  </Button>
                </div>

                {/* 推奨ワークフロー */}
                <div className="bg-gradient-to-r from-amber-50 to-orange-50 dark:from-amber-900/20 dark:to-orange-900/20 border border-amber-200 dark:border-amber-800 rounded-xl p-6">
                  <h4 className="flex items-center font-semibold text-amber-800 dark:text-amber-200 mb-4">
                    <Lightbulb className="mr-2 h-5 w-5" />
                    推奨ワークフロー
                  </h4>
                  <div className="grid md:grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <div className="flex items-center text-amber-700 dark:text-amber-300">
                        <div className="w-6 h-6 rounded-full bg-amber-200 dark:bg-amber-800 flex items-center justify-center text-xs font-bold mr-3">1</div>
                        カテゴリを選択
                      </div>
                      <div className="flex items-center text-amber-700 dark:text-amber-300">
                        <div className="w-6 h-6 rounded-full bg-amber-200 dark:bg-amber-800 flex items-center justify-center text-xs font-bold mr-3">2</div>
                        思考内容を自由に入力
                      </div>
                    </div>
                    <div className="space-y-2">
                      <div className="flex items-center text-amber-700 dark:text-amber-300">
                        <div className="w-6 h-6 rounded-full bg-amber-200 dark:bg-amber-800 flex items-center justify-center text-xs font-bold mr-3">3</div>
                        AI分析を実行（推奨）
                      </div>
                      <div className="flex items-center text-amber-700 dark:text-amber-300">
                        <div className="w-6 h-6 rounded-full bg-amber-200 dark:bg-amber-800 flex items-center justify-center text-xs font-bold mr-3">4</div>
                        結果を確認して保存
                      </div>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </motion.div>

          {/* AI分析結果表示 */}
          <AnimatePresence>
            {analysis && (
              <motion.div
                initial={{ opacity: 0, y: 30, scale: 0.95 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: -30, scale: 0.95 }}
                transition={{ duration: 0.6 }}
              >
                <Card className={`modern-card ${getEmotionTheme(analysis.emotion)}`}>
                  <CardHeader>
                    <CardTitle className="flex items-center text-2xl">
                      <Brain className="mr-3 h-7 w-7 text-purple-600" />
                      AI分析結果
                      <motion.div
                        className="ml-3"
                        animate={{ rotate: [0, 360] }}
                        transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
                      >
                        <Sparkles className="h-5 w-5 text-purple-500" />
                      </motion.div>
                    </CardTitle>
                    <CardDescription className="text-lg">
                      保存ボタンを押すと、この分析結果もデータベースに保存されます
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="grid md:grid-cols-2 gap-8">
                      {/* 左カラム */}
                      <div className="space-y-6">
                        <div>
                          <h4 className="flex items-center font-semibold text-gray-700 dark:text-gray-300 mb-3">
                            <Heart className="mr-2 h-5 w-5 text-pink-500" />
                            感情分析
                          </h4>
                          <div className="flex items-center space-x-4">
                            <div className="text-4xl">{getEmotionEmoji(analysis.emotion)}</div>
                            <div>
                              <div className="text-xl font-bold capitalize">{analysis.emotion}</div>
                              <div className="text-sm text-gray-500">
                                信頼度: {Math.round(analysis.emotionScore * 100)}%
                              </div>
                            </div>
                          </div>
                        </div>

                        <div>
                          <h4 className="flex items-center font-semibold text-gray-700 dark:text-gray-300 mb-3">
                            <Tag className="mr-2 h-5 w-5 text-blue-500" />
                            主要テーマ
                          </h4>
                          <div className="flex flex-wrap gap-2">
                            {analysis.themes.map((theme, index) => (
                              <motion.span 
                                key={index} 
                                initial={{ opacity: 0, scale: 0 }}
                                animate={{ opacity: 1, scale: 1 }}
                                transition={{ delay: index * 0.1 }}
                                className="px-3 py-2 bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200 rounded-full text-sm font-medium"
                              >
                                {theme}
                              </motion.span>
                            ))}
                          </div>
                        </div>

                        <div>
                          <h4 className="flex items-center font-semibold text-gray-700 dark:text-gray-300 mb-3">
                            <Zap className="mr-2 h-5 w-5 text-yellow-500" />
                            キーワード
                          </h4>
                          <div className="flex flex-wrap gap-2">
                            {analysis.keywords.map((keyword, index) => (
                              <motion.span 
                                key={index}
                                initial={{ opacity: 0, x: -10 }}
                                animate={{ opacity: 1, x: 0 }}
                                transition={{ delay: index * 0.05 }}
                                className="px-2 py-1 bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300 rounded-md text-sm"
                              >
                                {keyword}
                              </motion.span>
                            ))}
                          </div>
                        </div>
                      </div>

                      {/* 右カラム */}
                      <div className="space-y-6">
                        <div>
                          <h4 className="flex items-center font-semibold text-gray-700 dark:text-gray-300 mb-3">
                            <BookOpen className="mr-2 h-5 w-5 text-green-500" />
                            要約
                          </h4>
                          <div className="bg-green-50 dark:bg-green-900/20 border-l-4 border-green-500 p-4 rounded-r-lg">
                            <p className="text-gray-700 dark:text-gray-300 leading-relaxed">
                              {analysis.summary}
                            </p>
                          </div>
                        </div>

                        <div>
                          <h4 className="flex items-center font-semibold text-gray-700 dark:text-gray-300 mb-3">
                            <Lightbulb className="mr-2 h-5 w-5 text-yellow-500" />
                            アドバイス
                          </h4>
                          <div className="bg-yellow-50 dark:bg-yellow-900/20 border-l-4 border-yellow-500 p-4 rounded-r-lg">
                            <p className="text-gray-700 dark:text-gray-300 leading-relaxed">
                              {analysis.suggestion}
                            </p>
                          </div>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </motion.div>
            )}
          </AnimatePresence>

          {/* セキュリティ情報 */}
          <motion.div variants={fadeInUp}>
            <div className="glass p-6 rounded-xl text-center">
              <div className="flex items-center justify-center mb-3">
                <div className="w-8 h-8 rounded-full bg-gray-100 dark:bg-gray-800 flex items-center justify-center mr-3">
                  <Clock className="h-4 w-4 text-gray-600 dark:text-gray-400" />
                </div>
                <span className="text-sm font-medium text-gray-600 dark:text-gray-400">
                  安全なクラウド保存
                </span>
              </div>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                🔒 記録内容とAI分析結果はSupabaseクラウドデータベースに暗号化されて安全に保存されます
              </p>
            </div>
          </motion.div>
        </motion.div>
      </div>
    </div>
  )
}