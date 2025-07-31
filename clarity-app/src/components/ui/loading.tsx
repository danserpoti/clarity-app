'use client'

import { motion } from 'framer-motion'
import { Loader2, Brain, Sparkles } from 'lucide-react'
import { cn } from '@/lib/utils'

interface LoadingProps {
  variant?: 'default' | 'dots' | 'pulse' | 'brain' | 'minimal'
  size?: 'sm' | 'md' | 'lg' | 'xl'
  text?: string
  className?: string
}

const sizeClasses = {
  sm: 'w-4 h-4',
  md: 'w-6 h-6', 
  lg: 'w-8 h-8',
  xl: 'w-12 h-12'
}

const textSizeClasses = {
  sm: 'text-sm',
  md: 'text-base',
  lg: 'text-lg', 
  xl: 'text-xl'
}

export function Loading({ 
  variant = 'default', 
  size = 'md', 
  text,
  className 
}: LoadingProps) {
  const iconSize = sizeClasses[size]
  const textSize = textSizeClasses[size]

  if (variant === 'dots') {
    return (
      <div className={cn('flex items-center justify-center space-x-1', className)}>
        {[0, 1, 2].map((i) => (
          <motion.div
            key={i}
            className={cn('bg-blue-500 rounded-full', 
              size === 'sm' ? 'w-2 h-2' : 
              size === 'md' ? 'w-3 h-3' :
              size === 'lg' ? 'w-4 h-4' : 'w-5 h-5'
            )}
            animate={{
              scale: [1, 1.2, 1],
              opacity: [0.7, 1, 0.7]
            }}
            transition={{
              duration: 1.4,
              repeat: Infinity,
              delay: i * 0.2
            }}
          />
        ))}
        {text && (
          <motion.span 
            className={cn('ml-3 text-gray-600 dark:text-gray-400', textSize)}
            animate={{ opacity: [0.5, 1, 0.5] }}
            transition={{ duration: 2, repeat: Infinity }}
          >
            {text}
          </motion.span>
        )}
      </div>
    )
  }

  if (variant === 'pulse') {
    return (
      <div className={cn('flex flex-col items-center justify-center space-y-4', className)}>
        <div className="relative">
          <motion.div
            className={cn('rounded-full bg-gradient-to-r from-blue-500 to-purple-600', iconSize)}
            animate={{
              scale: [1, 1.2, 1],
            }}
            transition={{
              duration: 1.5,
              repeat: Infinity,
              ease: "easeInOut"
            }}
          />
          <motion.div
            className={cn('absolute inset-0 rounded-full bg-gradient-to-r from-blue-500 to-purple-600 opacity-30', iconSize)}
            animate={{
              scale: [1, 1.8, 1],
              opacity: [0.3, 0, 0.3]
            }}
            transition={{
              duration: 1.5,
              repeat: Infinity,
              ease: "easeInOut"
            }}
          />
        </div>
        {text && (
          <motion.p 
            className={cn('text-gray-600 dark:text-gray-400 font-medium', textSize)}
            animate={{ opacity: [0.7, 1, 0.7] }}
            transition={{ duration: 2, repeat: Infinity }}
          >
            {text}
          </motion.p>
        )}
      </div>
    )
  }

  if (variant === 'brain') {
    return (
      <div className={cn('flex flex-col items-center justify-center space-y-4', className)}>
        <div className="relative">
          <motion.div
            className="relative inline-flex items-center justify-center"
            animate={{ rotate: 360 }}
            transition={{ duration: 3, repeat: Infinity, ease: "linear" }}
          >
            <div className={cn('rounded-full bg-gradient-to-r from-purple-500 to-pink-600 flex items-center justify-center', iconSize)}>
              <Brain className={cn('text-white', 
                size === 'sm' ? 'w-2 h-2' : 
                size === 'md' ? 'w-3 h-3' :
                size === 'lg' ? 'w-4 h-4' : 'w-6 h-6'
              )} />
            </div>
          </motion.div>
          <motion.div
            className="absolute -top-1 -right-1"
            animate={{ 
              scale: [1, 1.3, 1],
              rotate: [0, 180, 360]
            }}
            transition={{ 
              duration: 2, 
              repeat: Infinity,
              delay: 0.5
            }}
          >
            <Sparkles className={cn('text-yellow-400',
              size === 'sm' ? 'w-2 h-2' : 
              size === 'md' ? 'w-3 h-3' :
              size === 'lg' ? 'w-4 h-4' : 'w-5 h-5'
            )} />
          </motion.div>
        </div>
        {text && (
          <motion.p 
            className={cn('text-gray-600 dark:text-gray-400 font-medium text-center', textSize)}
            animate={{ opacity: [0.7, 1, 0.7] }}
            transition={{ duration: 2, repeat: Infinity }}
          >
            {text}
          </motion.p>
        )}
      </div>
    )
  }

  if (variant === 'minimal') {
    return (
      <div className={cn('flex items-center justify-center space-x-2', className)}>
        <Loader2 className={cn('animate-spin text-blue-500', iconSize)} />
        {text && (
          <span className={cn('text-gray-600 dark:text-gray-400', textSize)}>
            {text}
          </span>
        )}
      </div>
    )
  }

  // Default variant
  return (
    <div className={cn('flex flex-col items-center justify-center space-y-4', className)}>
      <motion.div
        className="relative"
        animate={{ rotate: 360 }}
        transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
      >
        <Loader2 className={cn('text-blue-500', iconSize)} />
      </motion.div>
      {text && (
        <motion.p 
          className={cn('text-gray-600 dark:text-gray-400 font-medium', textSize)}
          animate={{ opacity: [0.7, 1, 0.7] }}
          transition={{ duration: 2, repeat: Infinity }}
        >
          {text}
        </motion.p>
      )}
    </div>
  )
}

// Full screen loading overlay
interface LoadingOverlayProps {
  isVisible: boolean
  text?: string
  variant?: LoadingProps['variant']
}

export function LoadingOverlay({ isVisible, text = "読み込み中...", variant = 'brain' }: LoadingOverlayProps) {
  if (!isVisible) return null

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm z-50 flex items-center justify-center"
    >
      <motion.div
        initial={{ scale: 0.9, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.9, opacity: 0 }}
        className="bg-white dark:bg-gray-900 rounded-2xl shadow-2xl p-8 border border-gray-200/50 dark:border-gray-700/50"
      >
        <Loading variant={variant} size="lg" text={text} />
      </motion.div>
    </motion.div>
  )
}