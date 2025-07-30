'use client'

import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import Link from 'next/link'

export default function OfflinePage() {
  const handleRetry = () => {
    window.location.reload()
  }

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <Card className="max-w-md w-full">
        <CardHeader className="text-center">
          <div className="mx-auto mb-4 w-16 h-16 bg-gray-200 rounded-full flex items-center justify-center">
            <span className="text-2xl">📡</span>
          </div>
          <CardTitle className="text-xl text-gray-800">
            オフラインです
          </CardTitle>
          <CardDescription className="text-gray-600">
            インターネット接続を確認してください
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <h3 className="font-semibold text-blue-800 mb-2">
              📱 オフライン機能
            </h3>
            <ul className="text-sm text-blue-700 space-y-1">
              <li>• 過去に閲覧したページは表示できます</li>
              <li>• 思考記録の閲覧は可能です</li>
              <li>• AI分析は接続復旧後に利用可能です</li>
            </ul>
          </div>
          
          <div className="bg-amber-50 border border-amber-200 rounded-lg p-4">
            <h3 className="font-semibold text-amber-800 mb-2">
              💡 できること
            </h3>
            <ul className="text-sm text-amber-700 space-y-1">
              <li>• キャッシュされたページの閲覧</li>
              <li>• ローカルデータの確認</li>
              <li>• 接続復旧を待つ</li>
            </ul>
          </div>
          
          <div className="space-y-3">
            <Button 
              onClick={handleRetry} 
              className="w-full"
            >
              🔄 再接続を試す
            </Button>
            
            <div className="flex gap-2">
              <Link href="/" className="flex-1">
                <Button variant="outline" className="w-full">
                  🏠 ホーム
                </Button>
              </Link>
              <Link href="/thoughts" className="flex-1">
                <Button variant="outline" className="w-full">
                  📝 記録一覧
                </Button>
              </Link>
            </div>
          </div>
          
          <div className="text-center">
            <p className="text-xs text-gray-500">
              このページは Clarity PWA の一部として
              <br />
              オフラインでも表示されます
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}