'use client'

import * as React from 'react'
import { Moon, Sun } from 'lucide-react'
import { useTheme } from 'next-themes'
import { motion } from 'framer-motion'

import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'

export function ThemeToggle() {
  const { setTheme } = useTheme()

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="outline"
          size="icon"
          className="relative overflow-hidden bg-gradient-to-br from-white to-gray-50 dark:from-gray-900 dark:to-gray-800 border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600 transition-all duration-300"
        >
          <div className="relative w-[1.2rem] h-[1.2rem]">
            <Sun className="absolute inset-0 h-[1.2rem] w-[1.2rem] rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
            <Moon className="absolute inset-0 h-[1.2rem] w-[1.2rem] rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
          </div>
          <span className="sr-only">テーマ切り替え</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent 
        align="end"
        className="bg-white/80 dark:bg-gray-900/80 backdrop-blur-md border-gray-200 dark:border-gray-700"
      >
        <DropdownMenuItem 
          onClick={() => setTheme('light')}
          className="hover:bg-gray-100/80 dark:hover:bg-gray-800/80 transition-colors cursor-pointer"
        >
          <Sun className="mr-2 h-4 w-4" />
          ライト
        </DropdownMenuItem>
        <DropdownMenuItem 
          onClick={() => setTheme('dark')}
          className="hover:bg-gray-100/80 dark:hover:bg-gray-800/80 transition-colors cursor-pointer"
        >
          <Moon className="mr-2 h-4 w-4" />
          ダーク
        </DropdownMenuItem>
        <DropdownMenuItem 
          onClick={() => setTheme('system')}
          className="hover:bg-gray-100/80 dark:hover:bg-gray-800/80 transition-colors cursor-pointer"
        >
          <Sun className="mr-2 h-4 w-4" />
          システム
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}