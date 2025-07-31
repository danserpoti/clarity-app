'use client'

import dynamic from 'next/dynamic'
import Link from 'next/link'
import { motion } from 'framer-motion'
import { 
  Sparkles, 
  Brain, 
  TrendingUp, 
  Zap, 
  Heart, 
  BarChart3, 
  BookOpen, 
  Plus,
  ArrowRight,
  CheckCircle,
  Database,
  Palette
} from 'lucide-react'

import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'

// 動的インポートでパフォーマンス最適化
const InstallPrompt = dynamic(() => import('@/components/InstallPrompt'), {
  ssr: false,
  loading: () => <div className="h-20 bg-gray-100 rounded-lg animate-pulse shimmer" />
})

const fadeInUp = {
  initial: { opacity: 0, y: 30 },
  animate: { opacity: 1, y: 0 },
  transition: { duration: 0.6, ease: 'easeOut' }
}

const staggerChildren = {
  animate: {
    transition: {
      staggerChildren: 0.1
    }
  }
}

const scaleOnHover = {
  whileHover: { scale: 1.05 },
  whileTap: { scale: 0.95 }
}

export default function Home() {
  return (
    <div className="min-h-screen">
      {/* ヒーローセクション */}
      <section className="relative overflow-hidden pt-20 pb-32">
        {/* 背景グラデーション */}
        <div className="absolute inset-0 bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 dark:from-gray-900 dark:via-blue-900/20 dark:to-purple-900/20" />
        
        
        <div className="relative container mx-auto px-4">
          <motion.div
            className="text-center max-w-4xl mx-auto"
            initial="initial"
            animate="animate"
            variants={staggerChildren}
          >
            {/* メインタイトル */}
            <motion.div 
              variants={fadeInUp}
              className="flex justify-center items-center mb-6"
            >
              <div className="mr-4">
                <div className="rounded-full bg-gradient-to-r from-blue-500 to-purple-600 p-4">
                  <Sparkles className="h-8 w-8 text-white" />
                </div>
              </div>
              <h1 className="text-6xl md:text-7xl font-bold gradient-text">
                Clarity
              </h1>
            </motion.div>

            <motion.p 
              variants={fadeInUp}
              className="text-xl md:text-2xl text-gray-600 dark:text-gray-300 mb-4"
            >
              AI分析機能付き思考記録PWAアプリ
            </motion.p>
            
            <p className="text-lg text-gray-500 dark:text-gray-400 mb-8 max-w-2xl mx-auto">
              思考と感情を記録し、分析で新たな洞察を得るアプリです。
            </p>

            {/* CTAボタン */}
            <motion.div 
              variants={fadeInUp}
              className="flex flex-col sm:flex-row gap-4 justify-center mb-12"
            >
              <Link href="/thoughts/new">
                <Button 
                  size="lg" 
                  className="bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700 text-white px-8 py-6 text-lg"
                >
                  <Plus className="mr-2 h-5 w-5" />
                  今すぐ記録を始める
                  <ArrowRight className="ml-2 h-5 w-5" />
                </Button>
              </Link>
              
              <Link href="/analytics">
                <Button 
                  variant="outline" 
                  size="lg"
                  className="border-gray-300 dark:border-gray-600 px-8 py-6 text-lg"
                >
                  <BarChart3 className="mr-2 h-5 w-5" />
                  分析結果を見る
                </Button>
              </Link>
            </motion.div>

            {/* PWAインストールプロンプト */}
            <motion.div variants={fadeInUp}>
              <InstallPrompt />
            </motion.div>
          </motion.div>
        </div>
      </section>

      {/* 機能紹介セクション */}
      <section className="py-20">
        <div className="container mx-auto px-4">
          <motion.div
            initial="initial"
            whileInView="animate"
            viewport={{ once: true }}
            variants={staggerChildren}
            className="text-center mb-16"
          >
            <motion.h2 
              variants={fadeInUp}
              className="text-4xl font-bold text-gray-900 dark:text-white mb-4"
            >
              パワフルな機能
            </motion.h2>
            <p className="text-xl text-gray-600 dark:text-gray-300 max-w-2xl mx-auto">
              思考の記録から分析まで一つのアプリで
            </p>
          </motion.div>

          <motion.div 
            className="grid md:grid-cols-3 gap-8 max-w-6xl mx-auto"
            initial="initial"
            whileInView="animate"
            viewport={{ once: true }}
            variants={staggerChildren}
          >
            {/* 思考記録 */}
            <motion.div variants={fadeInUp}>
              <Card className="modern-card-glass group h-full hover:scale-105 transition-transform duration-300">
                <CardContent className="p-8 text-center">
                  <motion.div
                    className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gradient-to-r from-blue-500 to-blue-600 text-white mb-6 group-hover:shadow-lg group-hover:shadow-blue-500/25 transition-all duration-300"
                    whileHover={{ rotate: 360 }}
                    transition={{ duration: 0.6 }}
                  >
                    <BookOpen className="h-8 w-8" />
                  </motion.div>
                  <h3 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
                    思考記録
                  </h3>
                  <p className="text-gray-600 dark:text-gray-300 mb-6">
                    日々の思考や感情をカテゴリ分けして記録できます。
                  </p>
                  <div className="space-y-3">
                    <Link href="/thoughts/new">
                      <Button className="w-full bg-blue-500 hover:bg-blue-600">
                        <Plus className="mr-2 h-4 w-4" />
                        新しい記録を作成
                      </Button>
                    </Link>
                    <Link href="/thoughts">
                      <Button variant="outline" className="w-full">
                        <BookOpen className="mr-2 h-4 w-4" />
                        記録一覧を見る
                      </Button>
                    </Link>
                  </div>
                </CardContent>
              </Card>
            </motion.div>

            {/* AI分析 */}
            <motion.div variants={fadeInUp}>
              <Card className="modern-card-glass group h-full hover:scale-105 transition-transform duration-300">
                <CardContent className="p-8 text-center">
                  <motion.div
                    className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gradient-to-r from-purple-500 to-purple-600 text-white mb-6 group-hover:shadow-lg group-hover:shadow-purple-500/25 transition-all duration-300"
                    whileHover={{ scale: 1.1 }}
                  >
                    <Brain className="h-8 w-8" />
                  </motion.div>
                  <h3 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
                    AI分析
                  </h3>
                  <p className="text-gray-600 dark:text-gray-300 mb-6">
                    AIが感情やテーマを自動分析します。
                  </p>
                  <div className="flex items-center justify-center space-x-2 text-amber-500 mb-4">
                    <Zap className="h-5 w-5" />
                    <span className="text-sm font-medium">利用可能</span>
                  </div>
                  <Link href="/analytics">
                    <Button className="w-full bg-purple-500 hover:bg-purple-600">
                      <Brain className="mr-2 h-4 w-4" />
                      AI分析を見る
                    </Button>
                  </Link>
                </CardContent>
              </Card>
            </motion.div>

            {/* データ可視化 */}
            <motion.div variants={fadeInUp}>
              <Card className="modern-card-glass group h-full hover:scale-105 transition-transform duration-300">
                <CardContent className="p-8 text-center">
                  <motion.div
                    className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gradient-to-r from-emerald-500 to-emerald-600 text-white mb-6 group-hover:shadow-lg group-hover:shadow-emerald-500/25 transition-all duration-300"
                    whileHover={{ y: -5 }}
                  >
                    <TrendingUp className="h-8 w-8" />
                  </motion.div>
                  <h3 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
                    データ可視化
                  </h3>
                  <p className="text-gray-600 dark:text-gray-300 mb-6">
                    チャートとグラフで思考パターンを可視化します。
                  </p>
                  <Link href="/analytics">
                    <Button className="w-full bg-emerald-500 hover:bg-emerald-600">
                      <BarChart3 className="mr-2 h-4 w-4" />
                      分析結果を見る
                    </Button>
                  </Link>
                </CardContent>
              </Card>
            </motion.div>
          </motion.div>
        </div>
      </section>

    </div>
  )
}