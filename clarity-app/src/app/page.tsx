import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import Link from 'next/link'

export default function Home() {
  return (
    <div className="max-w-4xl mx-auto py-8 px-4">
      <div className="text-center mb-12">
        <h1 className="text-4xl font-bold text-gray-900 mb-4">
          Clarity
        </h1>
        <p className="text-xl text-gray-600 mb-8">
          思考と感情を可視化して、自分を理解するためのアプリ
        </p>
        <div className="flex justify-center space-x-4">
          <Link href="/thoughts/new">
            <Button size="lg">今すぐ思考を記録する</Button>
          </Link>
        </div>
      </div>

      <div className="grid md:grid-cols-3 gap-6">
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">📝 思考記録</CardTitle>
          </CardHeader>
          <CardContent>
            <CardDescription className="mb-4">
              日々の思考や感情を自由に記録できます
            </CardDescription>
            <div className="space-y-2">
              <Link href="/thoughts/new">
                <Button variant="outline" className="w-full">
                  新しい記録を作成
                </Button>
              </Link>
              <Link href="/thoughts">
                <Button variant="outline" className="w-full">
                  記録一覧を見る
                </Button>
              </Link>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg">🤖 AI分析</CardTitle>
          </CardHeader>
          <CardContent>
            <CardDescription className="mb-4">
              AIが自動で感情やテーマを分析します（開発予定）
            </CardDescription>
            <Button variant="outline" disabled className="w-full">
              開発中
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg">📊 可視化</CardTitle>
          </CardHeader>
          <CardContent>
            <CardDescription className="mb-4">
              データを元にグラフやチャートで分析結果を表示
            </CardDescription>
            <Link href="/analytics">
              <Button variant="outline" className="w-full">
                分析結果を見る
              </Button>
            </Link>
          </CardContent>
        </Card>
      </div>

      <div className="mt-12 text-center">
        <h2 className="text-2xl font-bold text-gray-900 mb-4">
          開発完了機能
        </h2>
        <div className="space-y-4">
          <div className="bg-green-50 border border-green-200 rounded-lg p-6">
            <h3 className="text-lg font-semibold text-green-800 mb-2">
              ✅ 思考入力機能
            </h3>
            <p className="text-green-700 mb-4">
              カテゴリ選択、テキスト入力、保存機能が完成しました
            </p>
            <Link href="/thoughts/new">
              <Button className="mr-2">記録を作成</Button>
            </Link>
            <Link href="/thoughts">
              <Button variant="outline">記録一覧</Button>
            </Link>
          </div>
          
          <div className="bg-green-50 border border-green-200 rounded-lg p-6">
            <h3 className="text-lg font-semibold text-green-800 mb-2">
              ✅ データベース保存機能
            </h3>
            <p className="text-green-700 mb-4">
              Supabaseクラウドデータベースに永続保存されます
            </p>
          </div>

          <div className="bg-green-50 border border-green-200 rounded-lg p-6">
            <h3 className="text-lg font-semibold text-green-800 mb-2">
              ✅ 可視化機能
            </h3>
            <p className="text-green-700 mb-4">
              カテゴリ別円グラフ、記録頻度チャート、サマリー分析が完成しました
            </p>
            <Link href="/analytics">
              <Button>分析を見る</Button>
            </Link>
          </div>
        </div>
      </div>
    </div>
  )
}