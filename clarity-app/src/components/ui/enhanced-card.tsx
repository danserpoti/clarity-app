'use client'

import { motion } from 'framer-motion'
import { cn } from '@/lib/utils'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './card'
import { ReactNode } from 'react'

interface EnhancedCardProps {
  children: ReactNode
  title?: string
  description?: string
  icon?: ReactNode
  variant?: 'default' | 'glass' | 'gradient' | 'elevated' | 'minimal'
  size?: 'sm' | 'md' | 'lg'
  interactive?: boolean
  loading?: boolean
  disabled?: boolean
  className?: string
  onClick?: () => void
  onHover?: () => void
}

const variantClasses = {
  default: 'bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-700',
  glass: 'bg-white/80 dark:bg-gray-900/80 backdrop-blur-md border border-gray-200/50 dark:border-gray-700/50',
  gradient: 'bg-gradient-to-br from-white to-gray-50 dark:from-gray-900 dark:to-gray-800 border border-gray-200/50 dark:border-gray-700/50',
  elevated: 'bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-700 shadow-lg',
  minimal: 'bg-transparent border-none'
}

const sizeClasses = {
  sm: 'p-4',
  md: 'p-6',
  lg: 'p-8'
}

export function EnhancedCard({
  children,
  title,
  description,
  icon,
  variant = 'default',
  size = 'md',
  interactive = false,
  loading = false,
  disabled = false,
  className,
  onClick,
  onHover
}: EnhancedCardProps) {
  const cardVariants = {
    initial: { opacity: 0, y: 20, scale: 0.95 },
    animate: { 
      opacity: 1, 
      y: 0, 
      scale: 1
    },
    hover: interactive ? {
      y: -4,
      scale: 1.02
    } : {},
    tap: interactive ? { scale: 0.98 } : {}
  }

  const contentVariants = {
    initial: { opacity: 0 },
    animate: { 
      opacity: 1,
      transition: { delay: 0.1, duration: 0.3 }
    }
  }

  const loadingVariants = {
    animate: {
      opacity: [0.5, 1, 0.5]
    }
  }

  const CardComponent = motion(Card)

  return (
    <CardComponent
      variants={cardVariants}
      initial="initial"
      animate={loading ? "animate" : "animate"}
      whileHover={!disabled && !loading ? "hover" : undefined}
      whileTap={!disabled && !loading && interactive ? "tap" : undefined}
      className={cn(
        'rounded-xl transition-all duration-300 relative overflow-hidden',
        variantClasses[variant],
        interactive && !disabled && !loading && 'cursor-pointer',
        disabled && 'opacity-60 cursor-not-allowed',
        variant === 'elevated' && 'hover:shadow-xl',
        variant === 'glass' && 'hover:bg-white/90 dark:hover:bg-gray-900/90',
        className
      )}
      onClick={!disabled && !loading ? onClick : undefined}
      onHoverStart={!disabled && !loading ? onHover : undefined}
    >
      {loading && (
        <motion.div
          variants={loadingVariants}
          animate="animate"
          className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent -skew-x-12"
          style={{
            background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent)'
          }}
        />
      )}

      {(title || description || icon) && (
        <CardHeader className={cn(sizeClasses[size], 'pb-3')}>
          <motion.div variants={contentVariants} className="flex items-start space-x-3">
            {icon && (
              <motion.div
                className="flex-shrink-0"
                whileHover={{ scale: 1.1, rotate: 5 }}
                transition={{ duration: 0.2 }}
              >
                {icon}
              </motion.div>
            )}
            <div className="flex-1 min-w-0">
              {title && (
                <CardTitle className="text-lg font-semibold text-gray-900 dark:text-white">
                  {title}
                </CardTitle>
              )}
              {description && (
                <CardDescription className="text-gray-600 dark:text-gray-400 mt-1">
                  {description}
                </CardDescription>
              )}
            </div>
          </motion.div>
        </CardHeader>
      )}

      <CardContent className={cn(
        (title || description || icon) ? 'pt-0' : '',
        sizeClasses[size]
      )}>
        <motion.div variants={contentVariants}>
          {loading && (
            <div className="space-y-3">
              <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded animate-pulse" />
              <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded animate-pulse w-3/4" />
              <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded animate-pulse w-1/2" />
            </div>
          )}
          {!loading && children}
        </motion.div>
      </CardContent>
    </CardComponent>
  )
}

// Specialized card variants
export function GlassCard(props: Omit<EnhancedCardProps, 'variant'>) {
  return <EnhancedCard {...props} variant="glass" />
}

export function InteractiveCard(props: Omit<EnhancedCardProps, 'interactive'>) {
  return <EnhancedCard {...props} interactive />
}

export function LoadingCard(props: Omit<EnhancedCardProps, 'loading'>) {
  return <EnhancedCard {...props} loading />
}

// Card grid component for consistent layouts
interface CardGridProps {
  children: ReactNode
  cols?: 1 | 2 | 3 | 4
  gap?: 'sm' | 'md' | 'lg'
  className?: string
}

const gridClasses = {
  1: 'grid-cols-1',
  2: 'grid-cols-1 md:grid-cols-2',
  3: 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3',
  4: 'grid-cols-1 md:grid-cols-2 lg:grid-cols-4'
}

const gapClasses = {
  sm: 'gap-4',
  md: 'gap-6',
  lg: 'gap-8'
}

export function CardGrid({ 
  children, 
  cols = 3, 
  gap = 'md', 
  className 
}: CardGridProps) {
  const containerVariants = {
    initial: { opacity: 0 },
    animate: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1
      }
    }
  }

  return (
    <motion.div
      variants={containerVariants}
      initial="initial"
      animate="animate"
      className={cn(
        'grid',
        gridClasses[cols],
        gapClasses[gap],
        className
      )}
    >
      {children}
    </motion.div>
  )
}

// Statistics card component
interface StatsCardProps {
  title: string
  value: string | number
  change?: {
    value: number
    type: 'increase' | 'decrease' | 'neutral'
  }
  icon?: ReactNode
  variant?: 'default' | 'success' | 'warning' | 'error'
  className?: string
}

export function StatsCard({
  title,
  value,
  change,
  icon,
  variant = 'default',
  className
}: StatsCardProps) {
  const getVariantColor = () => {
    switch (variant) {
      case 'success':
        return 'text-green-600 dark:text-green-400'
      case 'warning':
        return 'text-yellow-600 dark:text-yellow-400'
      case 'error':
        return 'text-red-600 dark:text-red-400'
      default:
        return 'text-blue-600 dark:text-blue-400'
    }
  }

  const getChangeColor = () => {
    switch (change?.type) {
      case 'increase':
        return 'text-green-600 dark:text-green-400'
      case 'decrease':
        return 'text-red-600 dark:text-red-400'
      default:
        return 'text-gray-600 dark:text-gray-400'
    }
  }

  return (
    <EnhancedCard variant="glass" className={className}>
      <div className="flex items-center justify-between">
        <div className="flex-1">
          <p className="text-sm font-medium text-gray-600 dark:text-gray-400">
            {title}
          </p>
          <motion.p
            className={cn('text-3xl font-bold', getVariantColor())}
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ delay: 0.2, type: "spring", stiffness: 200 }}
          >
            {value}
          </motion.p>
          {change && (
            <motion.p
              className={cn('text-sm font-medium mt-1', getChangeColor())}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
            >
              {change.type === 'increase' ? '↗' : change.type === 'decrease' ? '↘' : '→'} {Math.abs(change.value)}%
            </motion.p>
          )}
        </div>
        {icon && (
          <motion.div
            className={cn('text-2xl', getVariantColor())}
            initial={{ scale: 0, rotate: -180 }}
            animate={{ scale: 1, rotate: 0 }}
            transition={{ delay: 0.1, type: "spring", stiffness: 200 }}
          >
            {icon}
          </motion.div>
        )}
      </div>
    </EnhancedCard>
  )
}