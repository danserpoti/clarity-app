'use client'

import { motion } from 'framer-motion'
import { Check, Circle } from 'lucide-react'
import { cn } from '@/lib/utils'

interface Step {
  id: string
  title: string
  description?: string
  status: 'pending' | 'current' | 'completed'
}

interface ProgressIndicatorProps {
  steps: Step[]
  orientation?: 'horizontal' | 'vertical'
  variant?: 'default' | 'minimal' | 'detailed'
  className?: string
}

export function ProgressIndicator({
  steps,
  orientation = 'horizontal',
  variant = 'default',
  className
}: ProgressIndicatorProps) {
  const currentStepIndex = steps.findIndex(step => step.status === 'current')
  
  if (variant === 'minimal') {
    return (
      <div className={cn('flex items-center space-x-2', className)}>
        <div className="flex-1 bg-gray-200 dark:bg-gray-700 rounded-full h-2 overflow-hidden">
          <motion.div
            className="h-full bg-gradient-to-r from-blue-500 to-purple-600 rounded-full"
            initial={{ width: 0 }}
            animate={{ 
              width: `${((currentStepIndex + 1) / steps.length) * 100}%` 
            }}
            transition={{ duration: 0.8, ease: "easeOut" }}
          />
        </div>
        <span className="text-sm font-medium text-gray-600 dark:text-gray-400 whitespace-nowrap">
          {currentStepIndex + 1} / {steps.length}
        </span>
      </div>
    )
  }

  if (orientation === 'vertical') {
    return (
      <div className={cn('space-y-4', className)}>
        {steps.map((step, index) => (
          <div key={step.id} className="flex items-start space-x-4">
            {/* Step indicator */}
            <div className="flex flex-col items-center">
              <motion.div
                className={cn(
                  'w-8 h-8 rounded-full flex items-center justify-center border-2 transition-all duration-300',
                  step.status === 'completed' 
                    ? 'bg-green-500 border-green-500 text-white' 
                    : step.status === 'current'
                    ? 'bg-blue-500 border-blue-500 text-white'
                    : 'bg-white dark:bg-gray-800 border-gray-300 dark:border-gray-600 text-gray-400'
                )}
                initial={{ scale: 0.8, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ delay: index * 0.1 }}
              >
                {step.status === 'completed' ? (
                  <Check className="w-4 h-4" />
                ) : (
                  <span className="text-sm font-medium">{index + 1}</span>
                )}
              </motion.div>
              
              {/* Connector line */}
              {index < steps.length - 1 && (
                <motion.div
                  className={cn(
                    'w-0.5 h-8 mt-2',
                    index < currentStepIndex ? 'bg-green-500' : 'bg-gray-300 dark:bg-gray-600'
                  )}
                  initial={{ scaleY: 0 }}
                  animate={{ scaleY: 1 }}
                  transition={{ delay: index * 0.1 + 0.2 }}
                />
              )}
            </div>
            
            {/* Step content */}
            <motion.div
              className="flex-1 pb-8"
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.1 + 0.1 }}
            >
              <h3 className={cn(
                'font-medium',
                step.status === 'completed' 
                  ? 'text-green-700 dark:text-green-300'
                  : step.status === 'current'
                  ? 'text-blue-700 dark:text-blue-300'
                  : 'text-gray-500 dark:text-gray-400'
              )}>
                {step.title}
              </h3>
              {step.description && variant === 'detailed' && (
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  {step.description}
                </p>
              )}
            </motion.div>
          </div>
        ))}
      </div>
    )
  }

  // Horizontal layout (default)
  return (
    <div className={cn('w-full', className)}>
      <div className="flex items-center justify-between">
        {steps.map((step, index) => (
          <div key={step.id} className="flex flex-col items-center flex-1 relative">
            {/* Step indicator */}
            <motion.div
              className={cn(
                'w-10 h-10 rounded-full flex items-center justify-center border-2 transition-all duration-300 relative z-10',
                step.status === 'completed' 
                  ? 'bg-green-500 border-green-500 text-white shadow-lg shadow-green-500/25' 
                  : step.status === 'current'
                  ? 'bg-blue-500 border-blue-500 text-white shadow-lg shadow-blue-500/25'
                  : 'bg-white dark:bg-gray-800 border-gray-300 dark:border-gray-600 text-gray-400'
              )}
              initial={{ scale: 0.8, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ delay: index * 0.1 }}
              whileHover={{ scale: 1.05 }}
            >
              {step.status === 'completed' ? (
                <motion.div
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ delay: index * 0.1 + 0.2 }}
                >
                  <Check className="w-5 h-5" />
                </motion.div>
              ) : step.status === 'current' ? (
                <motion.div
                  animate={{ scale: [1, 1.1, 1] }}
                  transition={{ duration: 1.5, repeat: Infinity }}
                >
                  <Circle className="w-5 h-5 fill-current" />
                </motion.div>
              ) : (
                <span className="text-sm font-medium">{index + 1}</span>
              )}
            </motion.div>
            
            {/* Step label */}
            <motion.div
              className="mt-3 text-center max-w-24"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 + 0.1 }}
            >
              <h4 className={cn(
                'text-sm font-medium leading-tight',
                step.status === 'completed' 
                  ? 'text-green-700 dark:text-green-300'
                  : step.status === 'current'
                  ? 'text-blue-700 dark:text-blue-300'
                  : 'text-gray-500 dark:text-gray-400'
              )}>
                {step.title}
              </h4>
              {step.description && variant === 'detailed' && (
                <p className="text-xs text-gray-600 dark:text-gray-400 mt-1">
                  {step.description}
                </p>
              )}
            </motion.div>
            
            {/* Connector line */}
            {index < steps.length - 1 && (
              <motion.div
                className={cn(
                  'absolute top-5 left-1/2 w-full h-0.5 -z-10',
                  index < currentStepIndex ? 'bg-green-500' : 'bg-gray-300 dark:bg-gray-600'
                )}
                style={{ marginLeft: '20px', width: 'calc(100% - 40px)' }}
                initial={{ scaleX: 0 }}
                animate={{ scaleX: 1 }}
                transition={{ delay: index * 0.1 + 0.3, duration: 0.5 }}
              />
            )}
          </div>
        ))}
      </div>
    </div>
  )
}

// Simple progress bar component
interface ProgressBarProps {
  value: number
  max?: number
  variant?: 'default' | 'success' | 'warning' | 'error'
  size?: 'sm' | 'md' | 'lg'
  showPercentage?: boolean
  animated?: boolean
  className?: string
}

export function ProgressBar({
  value,
  max = 100,
  variant = 'default',
  size = 'md',
  showPercentage = false,
  animated = true,
  className
}: ProgressBarProps) {
  const percentage = Math.min((value / max) * 100, 100)
  
  const getColor = () => {
    switch (variant) {
      case 'success':
        return 'from-green-500 to-emerald-500'
      case 'warning':
        return 'from-yellow-500 to-orange-500'
      case 'error':
        return 'from-red-500 to-rose-500'
      default:
        return 'from-blue-500 to-purple-500'
    }
  }
  
  const getHeight = () => {
    switch (size) {
      case 'sm':
        return 'h-1'
      case 'lg':
        return 'h-3'
      default:
        return 'h-2'
    }
  }

  return (
    <div className={cn('w-full', className)}>
      <div className={cn(
        'bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden',
        getHeight()
      )}>
        <motion.div
          className={cn('bg-gradient-to-r rounded-full', getColor(), getHeight())}
          initial={{ width: 0 }}
          animate={{ width: `${percentage}%` }}
          transition={{
            duration: animated ? 0.8 : 0,
            ease: "easeOut"
          }}
        />
      </div>
      {showPercentage && (
        <div className="flex justify-between mt-1 text-xs text-gray-600 dark:text-gray-400">
          <span>{Math.round(percentage)}%</span>
          <span>{value} / {max}</span>
        </div>
      )}
    </div>
  )
}