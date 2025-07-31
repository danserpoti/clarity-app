'use client'

import { useState } from 'react'
import Link from 'next/link'
import { motion } from 'framer-motion'
import { 
  ArrowLeft,
  Settings as SettingsIcon,
  Moon,
  Sun,
  Monitor,
  Palette,
  Bell,
  Shield,
  Database,
  Download,
  Upload,
  Trash2,
  RefreshCw,
  Check,
  X,
  Info,
  Sparkles,
  User,
  Globe,
  Volume2,
  Eye,
  Lock
} from 'lucide-react'

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Switch } from '@/components/ui/switch'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Separator } from '@/components/ui/separator'
import { Badge } from '@/components/ui/badge'
import { useTheme } from 'next-themes'
import { useToast } from '@/hooks/use-toast'
import { FadeIn, StaggerContainer, StaggerItem, HoverEffect } from '@/components/MicroAnimations'
import { Modal, ConfirmationDialog } from '@/components/ui/modal'

const fadeInUp = {
  initial: { opacity: 0, y: 30 },
  animate: { opacity: 1, y: 0 },
  transition: { duration: 0.6, ease: 'easeOut' }
}

export default function SettingsPage() {
  const { theme, setTheme } = useTheme()
  const { toast } = useToast()
  
  // 設定状態
  const [settings, setSettings] = useState({
    notifications: {
      push: true,
      email: false,
      aiAnalysis: true,
      weeklyReport: true,
    },
    privacy: {
      dataCollection: true,
      analytics: false,
      sharing: false,
    },
    preferences: {
      language: 'ja',
      timezone: 'Asia/Tokyo',
      dateFormat: 'japanese',
      autoSave: true,
      soundEffects: true,
    },
    ai: {
      autoAnalysis: true,
      emotionTracking: true,
      insights: true,
      model: 'gpt-4',
    }
  })

  // モーダル状態
  const [showExportModal, setShowExportModal] = useState(false)
  const [showImportModal, setShowImportModal] = useState(false)
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)
  const [isExporting, setIsExporting] = useState(false)
  const [isImporting, setIsImporting] = useState(false)

  const handleSettingChange = (section: string, key: string, value: any) => {
    setSettings(prev => ({
      ...prev,
      [section]: {
        ...prev[section as keyof typeof prev],
        [key]: value
      }
    }))
    
    toast({
      title: '設定を更新しました',
      description: '変更が保存されました。',
      variant: 'success'
    })
  }

  const handleExport = async () => {
    setIsExporting(true)
    // シミュレートされたエクスポート処理
    await new Promise(resolve => setTimeout(resolve, 2000))
    
    toast({
      title: '✅ エクスポート完了',
      description: 'データがダウンロードされました。',
      variant: 'success'
    })
    
    setIsExporting(false)
    setShowExportModal(false)
  }

  const handleDataReset = async () => {
    // シミュレートされたリセット処理
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    toast({
      title: '🗑️ データをリセットしました',
      description: 'すべてのデータが削除されました。',
      variant: 'success'
    })
    
    setShowDeleteConfirm(false)
  }

  const getThemeIcon = () => {
    switch (theme) {
      case 'light': return Sun
      case 'dark': return Moon
      default: return Monitor
    }
  }

  const ThemeIcon = getThemeIcon()

  return (
    <div className="min-h-screen pt-20 pb-32">
      <div className="container mx-auto px-4 max-w-4xl">
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
              <SettingsIcon className="h-8 w-8" />
            </motion.div>
            <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-4">設定</h1>
            <p className="text-xl text-gray-600 dark:text-gray-300 max-w-2xl mx-auto">
              アプリの動作をカスタマイズして、あなたに最適な体験を作りましょう
            </p>
          </motion.div>

          <StaggerContainer className="space-y-8">
            {/* テーマ設定 */}
            <StaggerItem>
              <Card className="modern-card-glass hover:scale-105 transition-all duration-300">
                <CardHeader>
                  <CardTitle className="flex items-center text-xl font-bold">
                    <Palette className="mr-2 h-5 w-5 text-purple-500" />
                    外観
                  </CardTitle>
                  <CardDescription>
                    テーマとデザインの設定を調整できます
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-3">
                      <ThemeIcon className="h-5 w-5 text-gray-600 dark:text-gray-400" />
                      <div>
                        <p className="font-medium">テーマ</p>
                        <p className="text-sm text-gray-500 dark:text-gray-400">
                          アプリの外観を選択
                        </p>
                      </div>
                    </div>
                    <Select value={theme} onValueChange={setTheme}>
                      <SelectTrigger className="w-40">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="light">
                          <div className="flex items-center">
                            <Sun className="mr-2 h-4 w-4" />
                            ライト
                          </div>
                        </SelectItem>
                        <SelectItem value="dark">
                          <div className="flex items-center">
                            <Moon className="mr-2 h-4 w-4" />
                            ダーク
                          </div>
                        </SelectItem>
                        <SelectItem value="system">
                          <div className="flex items-center">
                            <Monitor className="mr-2 h-4 w-4" />
                            システム
                          </div>
                        </SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </CardContent>
              </Card>
            </StaggerItem>

            {/* 通知設定 */}
            <StaggerItem>
              <Card className="modern-card-glass hover:scale-105 transition-all duration-300">
                <CardHeader>
                  <CardTitle className="flex items-center text-xl font-bold">
                    <Bell className="mr-2 h-5 w-5 text-orange-500" />
                    通知
                  </CardTitle>
                  <CardDescription>
                    受け取りたい通知の種類を選択できます
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                  {[
                    { key: 'push', label: 'プッシュ通知', desc: 'ブラウザ通知を受け取る', icon: Bell },
                    { key: 'email', label: 'メール通知', desc: 'メールで更新情報を受け取る', icon: Globe },
                    { key: 'aiAnalysis', label: 'AI分析完了', desc: 'AI分析が完了したときに通知', icon: Sparkles },
                    { key: 'weeklyReport', label: '週次レポート', desc: '週末に分析レポートを受け取る', icon: User }
                  ].map((item) => (
                    <div key={item.key} className="flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        <item.icon className="h-5 w-5 text-gray-600 dark:text-gray-400" />
                        <div>
                          <p className="font-medium">{item.label}</p>
                          <p className="text-sm text-gray-500 dark:text-gray-400">
                            {item.desc}
                          </p>
                        </div>
                      </div>
                      <Switch
                        checked={settings.notifications[item.key as keyof typeof settings.notifications]}
                        onCheckedChange={(checked) => 
                          handleSettingChange('notifications', item.key, checked)
                        }
                      />
                    </div>
                  ))}
                </CardContent>
              </Card>
            </StaggerItem>

            {/* AI設定 */}
            <StaggerItem>
              <Card className="modern-card-glass hover:scale-105 transition-all duration-300">
                <CardHeader>
                  <CardTitle className="flex items-center text-xl font-bold">
                    <Sparkles className="mr-2 h-5 w-5 text-purple-500" />
                    AI機能
                  </CardTitle>
                  <CardDescription>
                    AI分析機能の動作設定をカスタマイズできます
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                  {[
                    { key: 'autoAnalysis', label: '自動分析', desc: '記録時に自動でAI分析を実行' },
                    { key: 'emotionTracking', label: '感情トラッキング', desc: '感情の変化を継続的に追跡' },
                    { key: 'insights', label: 'インサイト生成', desc: 'パターンから洞察を自動生成' }
                  ].map((item) => (
                    <div key={item.key} className="flex items-center justify-between">
                      <div>
                        <p className="font-medium">{item.label}</p>
                        <p className="text-sm text-gray-500 dark:text-gray-400">
                          {item.desc}
                        </p>
                      </div>
                      <Switch
                        checked={Boolean(settings.ai[item.key as keyof typeof settings.ai])}
                        onCheckedChange={(checked) => 
                          handleSettingChange('ai', item.key, checked)
                        }
                      />
                    </div>
                  ))}

                  <Separator />

                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-medium">AIモデル</p>
                      <p className="text-sm text-gray-500 dark:text-gray-400">
                        使用するAIモデルを選択
                      </p>
                    </div>
                    <Select 
                      value={settings.ai.model} 
                      onValueChange={(value) => handleSettingChange('ai', 'model', value)}
                    >
                      <SelectTrigger className="w-32">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="gpt-4">GPT-4</SelectItem>
                        <SelectItem value="gpt-3.5">GPT-3.5</SelectItem>
                        <SelectItem value="claude">Claude</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </CardContent>
              </Card>
            </StaggerItem>

            {/* プライバシー設定 */}
            <StaggerItem>
              <Card className="modern-card-glass hover:scale-105 transition-all duration-300">
                <CardHeader>
                  <CardTitle className="flex items-center text-xl font-bold">
                    <Shield className="mr-2 h-5 w-5 text-green-500" />
                    プライバシー
                  </CardTitle>
                  <CardDescription>
                    データの取り扱いとプライバシー設定を管理できます
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                  {[
                    { key: 'dataCollection', label: 'データ収集', desc: '使用状況データの収集を許可', icon: Database },
                    { key: 'analytics', label: '分析データ', desc: '匿名化された分析データの共有', icon: Eye },
                    { key: 'sharing', label: 'データ共有', desc: '第三者とのデータ共有を許可', icon: Lock }
                  ].map((item) => (
                    <div key={item.key} className="flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        <item.icon className="h-5 w-5 text-gray-600 dark:text-gray-400" />
                        <div>
                          <p className="font-medium">{item.label}</p>
                          <p className="text-sm text-gray-500 dark:text-gray-400">
                            {item.desc}
                          </p>
                        </div>
                      </div>
                      <Switch
                        checked={settings.privacy[item.key as keyof typeof settings.privacy]}
                        onCheckedChange={(checked) => 
                          handleSettingChange('privacy', item.key, checked)
                        }
                      />
                    </div>
                  ))}
                </CardContent>
              </Card>
            </StaggerItem>

            {/* データ管理 */}
            <StaggerItem>
              <Card className="modern-card-glass hover:scale-105 transition-all duration-300">
                <CardHeader>
                  <CardTitle className="flex items-center text-xl font-bold">
                    <Database className="mr-2 h-5 w-5 text-blue-500" />
                    データ管理
                  </CardTitle>
                  <CardDescription>
                    データのバックアップ、復元、削除を管理できます
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="grid md:grid-cols-2 gap-4">
                    <HoverEffect effect="lift">
                      <Button
                        variant="outline"
                        className="w-full h-auto p-4 flex flex-col items-start space-y-2"
                        onClick={() => setShowExportModal(true)}
                      >
                        <Download className="h-5 w-5 text-green-600" />
                        <div className="text-left">
                          <p className="font-medium">データエクスポート</p>
                          <p className="text-sm text-gray-500">
                            全データをJSON形式でダウンロード
                          </p>
                        </div>
                      </Button>
                    </HoverEffect>

                    <HoverEffect effect="lift">
                      <Button
                        variant="outline"
                        className="w-full h-auto p-4 flex flex-col items-start space-y-2"
                        onClick={() => setShowImportModal(true)}
                      >
                        <Upload className="h-5 w-5 text-blue-600" />
                        <div className="text-left">
                          <p className="font-medium">データインポート</p>
                          <p className="text-sm text-gray-500">
                            バックアップファイルから復元
                          </p>
                        </div>
                      </Button>
                    </HoverEffect>

                    <HoverEffect effect="lift">
                      <Button
                        variant="outline"
                        className="w-full h-auto p-4 flex flex-col items-start space-y-2"
                        onClick={() => window.location.reload()}
                      >
                        <RefreshCw className="h-5 w-5 text-purple-600" />
                        <div className="text-left">
                          <p className="font-medium">キャッシュクリア</p>
                          <p className="text-sm text-gray-500">
                            アプリのキャッシュをクリア
                          </p>
                        </div>
                      </Button>
                    </HoverEffect>

                    <HoverEffect effect="lift">
                      <Button
                        variant="outline"
                        className="w-full h-auto p-4 flex flex-col items-start space-y-2 border-red-200 dark:border-red-800 hover:border-red-300 dark:hover:border-red-600"
                        onClick={() => setShowDeleteConfirm(true)}
                      >
                        <Trash2 className="h-5 w-5 text-red-600" />
                        <div className="text-left">
                          <p className="font-medium text-red-600">全データ削除</p>
                          <p className="text-sm text-gray-500">
                            すべての記録を完全削除
                          </p>
                        </div>
                      </Button>
                    </HoverEffect>
                  </div>
                </CardContent>
              </Card>
            </StaggerItem>

            {/* アプリ情報 */}
            <StaggerItem>
              <Card className="modern-card-glass hover:scale-105 transition-all duration-300">
                <CardHeader>
                  <CardTitle className="flex items-center text-xl font-bold">
                    <Info className="mr-2 h-5 w-5 text-gray-500" />
                    アプリ情報
                  </CardTitle>
                  <CardDescription>
                    バージョン情報とサポート情報
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="flex items-center justify-between">
                    <span className="font-medium">バージョン</span>
                    <Badge variant="outline">v1.0.0</Badge>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="font-medium">最終更新</span>
                    <span className="text-sm text-gray-500">2024年1月</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="font-medium">開発者</span>
                    <span className="text-sm text-gray-500">Clarity Team</span>
                  </div>
                  <Separator />
                  <div className="flex space-x-4">
                    <Button variant="outline" size="sm">
                      利用規約
                    </Button>
                    <Button variant="outline" size="sm">
                      プライバシーポリシー
                    </Button>
                    <Button variant="outline" size="sm">
                      サポート
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </StaggerItem>
          </StaggerContainer>
        </motion.div>
      </div>

      {/* エクスポートモーダル */}
      <Modal
        isOpen={showExportModal}
        onClose={() => setShowExportModal(false)}
        title="データエクスポート"
        description="すべての思考記録とAI分析結果をJSONファイルとしてダウンロードします。"
      >
        <div className="space-y-4">
          <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
            <h4 className="font-medium text-blue-800 dark:text-blue-200 mb-2">
              エクスポート内容
            </h4>
            <ul className="text-sm text-blue-700 dark:text-blue-300 space-y-1">
              <li>• すべての思考記録</li>
              <li>• AI分析結果</li>
              <li>• カテゴリ設定</li>
              <li>• アプリ設定</li>
            </ul>
          </div>
          <div className="flex space-x-3">
            <Button
              variant="outline"
              onClick={() => setShowExportModal(false)}
              className="flex-1"
            >
              キャンセル
            </Button>
            <Button
              onClick={handleExport}
              disabled={isExporting}
              className="flex-1"
            >
              {isExporting ? (
                <>
                  <RefreshCw className="mr-2 h-4 w-4 animate-spin" />
                  エクスポート中...
                </>
              ) : (
                <>
                  <Download className="mr-2 h-4 w-4" />
                  エクスポート
                </>
              )}
            </Button>
          </div>
        </div>
      </Modal>

      {/* データ削除確認モーダル */}
      <ConfirmationDialog
        isOpen={showDeleteConfirm}
        onClose={() => setShowDeleteConfirm(false)}
        onConfirm={handleDataReset}
        title="全データ削除の確認"
        description="この操作により、すべての思考記録とAI分析結果が完全に削除されます。この操作は取り消すことができません。"
        confirmText="削除"
        cancelText="キャンセル"
        variant="destructive"
      />
    </div>
  )
}