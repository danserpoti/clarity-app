'use client'

import { useState } from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { motion, AnimatePresence } from 'framer-motion'
import { 
  Brain, 
  BookOpen, 
  BarChart3, 
  Plus, 
  Menu, 
  X,
  Sparkles,
  Settings
} from 'lucide-react'

import { Button } from '@/components/ui/button'
import { ThemeToggle } from '@/components/ui/theme-toggle'
import { TransitionLink, MobileMenu } from '@/components/NavigationTransitions'
import { HoverEffect, Magnetic } from '@/components/MicroAnimations'
import { cn } from '@/lib/utils'

const navItems = [
  {
    name: 'ホーム',
    href: '/',
    icon: Brain,
    description: 'メインダッシュボード'
  },
  {
    name: '記録一覧',
    href: '/thoughts',
    icon: BookOpen,
    description: '思考記録を閲覧'
  },
  {
    name: '分析',
    href: '/analytics',
    icon: BarChart3,
    description: 'AI分析結果'
  },
  {
    name: '設定',
    href: '/settings',
    icon: Settings,
    description: 'アプリ設定'
  },
  {
    name: '新規記録',
    href: '/thoughts/new',
    icon: Plus,
    description: '新しい思考を記録',
    highlight: true
  }
]

export function Navigation() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
  const pathname = usePathname()

  return (
    <>
      {/* デスクトップナビゲーション */}
      <nav className="sticky top-0 z-40 w-full bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-800"
      >
        <div className="container flex h-16 items-center justify-between px-4">
          {/* ロゴ */}
          <Link href="/" className="flex items-center space-x-2">
            <div className="rounded-full bg-gradient-to-r from-blue-500 to-purple-600 p-2">
              <Sparkles className="h-5 w-5 text-white" />
            </div>
            <span className="text-xl font-bold text-gray-900 dark:text-white">
              Clarity
            </span>
          </Link>

          {/* デスクトップメニュー */}
          <div className="hidden md:flex items-center space-x-1">
            {navItems.map((item) => {
              const isActive = pathname === item.href
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={cn(
                    "inline-flex items-center px-4 py-2 rounded-md text-sm font-medium transition-colors",
                    isActive 
                      ? "bg-blue-500 text-white" 
                      : "text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800",
                    item.highlight && !isActive && "border border-blue-200 dark:border-blue-800"
                  )}
                >
                  <item.icon className="mr-2 h-4 w-4" />
                  {item.name}
                </Link>
              )
            })}
          </div>

          {/* 右側のアクション */}
          <div className="flex items-center space-x-2">
            <ThemeToggle />
            
            {/* モバイルメニューボタン */}
            <Button
              variant="ghost"
              size="icon"
              className="md:hidden"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            >
              {mobileMenuOpen ? (
                <X className="h-5 w-5" />
              ) : (
                <Menu className="h-5 w-5" />
              )}
            </Button>
          </div>
        </div>
      </nav>

      {/* モバイルメニュー */}
      <MobileMenu 
        isOpen={mobileMenuOpen} 
        onClose={() => setMobileMenuOpen(false)}
        className="md:hidden w-full"
      >
        <div className="space-y-2">
          {navItems.map((item, index) => {
            const isActive = pathname === item.href
            return (
              <motion.div
                key={item.href}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.05 }}
              >
                <HoverEffect effect="scale">
                  <TransitionLink
                    href={item.href}
                    onClick={() => setMobileMenuOpen(false)}
                    className={cn(
                      "flex items-center space-x-3 px-4 py-3 rounded-lg transition-all duration-300 w-full",
                      isActive
                        ? "bg-gradient-to-r from-blue-500 to-purple-600 text-white shadow-lg"
                        : "hover:bg-gray-100/80 dark:hover:bg-gray-800/80",
                      item.highlight && !isActive && "border border-blue-200 dark:border-blue-800"
                    )}
                  >
                    <motion.div
                      whileHover={{ 
                        rotate: item.highlight ? 360 : 0,
                        scale: 1.1
                      }}
                      transition={{ duration: 0.6 }}
                    >
                      <item.icon className={cn(
                        "h-5 w-5",
                        item.highlight && !isActive && "text-blue-500 dark:text-blue-400"
                      )} />
                    </motion.div>
                    <div>
                      <div className="font-medium">{item.name}</div>
                      <div className={cn(
                        "text-sm",
                        isActive ? "text-white/80" : "text-gray-500 dark:text-gray-400"
                      )}>
                        {item.description}
                      </div>
                    </div>
                  </TransitionLink>
                </HoverEffect>
              </motion.div>
            )
          })}
        </div>
      </MobileMenu>
    </>
  )
}