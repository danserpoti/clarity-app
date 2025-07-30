'use client'

import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

interface BeforeInstallPromptEvent extends Event {
  prompt(): Promise<void>
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>
}

export default function InstallPrompt() {
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(null)
  const [showInstallPrompt, setShowInstallPrompt] = useState(false)
  const [isInstalled, setIsInstalled] = useState(false)

  useEffect(() => {
    // PWAがすでにインストールされているかチェック
    if (window.matchMedia('(display-mode: standalone)').matches) {
      setIsInstalled(true)
      return
    }

    // beforeinstallprompt イベントをキャッチ
    const handleBeforeInstallPrompt = (e: Event) => {
      e.preventDefault()
      setDeferredPrompt(e as BeforeInstallPromptEvent)
      setShowInstallPrompt(true)
    }

    // PWAインストール完了の検知
    const handleAppInstalled = () => {
      console.log('[PWA] App installed')
      setIsInstalled(true)
      setShowInstallPrompt(false)
      setDeferredPrompt(null)
    }

    window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt)
    window.addEventListener('appinstalled', handleAppInstalled)

    return () => {
      window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt)
      window.removeEventListener('appinstalled', handleAppInstalled)
    }
  }, [])

  const handleInstallClick = async () => {
    if (!deferredPrompt) return

    try {
      await deferredPrompt.prompt()
      const { outcome } = await deferredPrompt.userChoice
      
      console.log('[PWA] User choice:', outcome)
      
      if (outcome === 'accepted') {
        console.log('[PWA] User accepted the install prompt')
      } else {
        console.log('[PWA] User dismissed the install prompt')
      }
    } catch (error) {
      console.error('[PWA] Error during installation:', error)
    }

    setDeferredPrompt(null)
    setShowInstallPrompt(false)
  }

  const handleDismiss = () => {
    setShowInstallPrompt(false)
  }

  // すでにインストール済みの場合は何も表示しない
  if (isInstalled) {
    return null
  }

  // インストールプロンプトが表示可能な場合のみ表示
  if (!showInstallPrompt || !deferredPrompt) {
    return null
  }

  return (
    <Card className="border-blue-200 bg-blue-50">
      <CardHeader>
        <CardTitle className="text-lg text-blue-800 flex items-center gap-2">
          📱 アプリをインストール
        </CardTitle>
        <CardDescription className="text-blue-600">
          Clarityをホーム画面に追加して、より快適にご利用いただけます
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="bg-white border border-blue-200 rounded-lg p-4">
          <h4 className="font-semibold text-blue-800 mb-2">📈 PWAの利点</h4>
          <ul className="text-sm text-blue-700 space-y-1">
            <li>• オフラインでも記録の閲覧が可能</li>
            <li>• アプリのような操作感</li>
            <li>• 高速な起動とスムーズな動作</li>
            <li>• ブラウザのアドレスバーが非表示</li>
          </ul>
        </div>
        
        <div className="flex gap-3">
          <Button 
            onClick={handleInstallClick}
            className="flex-1"
          >
            📱 インストール
          </Button>
          <Button 
            onClick={handleDismiss}
            variant="outline"
            className="flex-1"
          >
            後で
          </Button>
        </div>
        
        <p className="text-xs text-blue-600 text-center">
          インストール後もブラウザ版は引き続きご利用いただけます
        </p>
      </CardContent>
    </Card>
  )
}