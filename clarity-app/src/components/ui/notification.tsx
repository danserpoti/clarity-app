'use client'

import { motion, AnimatePresence } from 'framer-motion'
import { X, Check, AlertCircle, Info, AlertTriangle } from 'lucide-react'
import { cn } from '@/lib/utils'
import { Button } from './button'
import { useEffect, useState } from 'react'

export interface NotificationProps {
  id?: string
  title: string
  description?: string
  variant?: 'default' | 'success' | 'warning' | 'error' | 'info'
  duration?: number
  persistent?: boolean
  actionLabel?: string
  onAction?: () => void
  onClose?: () => void
  className?: string
}

const variantConfig = {
  default: {
    icon: Info,
    bgColor: 'bg-white dark:bg-gray-900',
    borderColor: 'border-gray-200 dark:border-gray-700',
    iconColor: 'text-blue-500',
    titleColor: 'text-gray-900 dark:text-white'
  },
  success: {
    icon: Check,
    bgColor: 'bg-green-50 dark:bg-green-900/20',
    borderColor: 'border-green-200 dark:border-green-800',
    iconColor: 'text-green-500',
    titleColor: 'text-green-800 dark:text-green-200'
  },
  warning: {
    icon: AlertTriangle,
    bgColor: 'bg-yellow-50 dark:bg-yellow-900/20',
    borderColor: 'border-yellow-200 dark:border-yellow-800',
    iconColor: 'text-yellow-500',
    titleColor: 'text-yellow-800 dark:text-yellow-200'
  },
  error: {
    icon: AlertCircle,
    bgColor: 'bg-red-50 dark:bg-red-900/20',
    borderColor: 'border-red-200 dark:border-red-800',
    iconColor: 'text-red-500',
    titleColor: 'text-red-800 dark:text-red-200'
  },
  info: {
    icon: Info,
    bgColor: 'bg-blue-50 dark:bg-blue-900/20',
    borderColor: 'border-blue-200 dark:border-blue-800',
    iconColor: 'text-blue-500',
    titleColor: 'text-blue-800 dark:text-blue-200'
  }
}

export function Notification({
  id,
  title,
  description,
  variant = 'default',
  duration = 5000,
  persistent = false,
  actionLabel,
  onAction,
  onClose,
  className
}: NotificationProps) {
  const [isVisible, setIsVisible] = useState(true)
  const [progress, setProgress] = useState(100)

  const config = variantConfig[variant]
  const IconComponent = config.icon

  useEffect(() => {
    if (persistent || !duration) return

    const progressInterval = setInterval(() => {
      setProgress(prev => {
        const newProgress = prev - (100 / (duration / 50))
        if (newProgress <= 0) {
          clearInterval(progressInterval)
          setIsVisible(false)
          setTimeout(() => onClose?.(), 300)
          return 0
        }
        return newProgress
      })
    }, 50)

    return () => clearInterval(progressInterval)
  }, [duration, persistent, onClose])

  const handleClose = () => {
    setIsVisible(false)
    setTimeout(() => onClose?.(), 300)
  }

  const notificationVariants = {
    initial: { 
      opacity: 0, 
      y: 50, 
      scale: 0.9 
    },
    animate: { 
      opacity: 1, 
      y: 0, 
      scale: 1,
      transition: {
        duration: 0.3
      }
    },
    exit: { 
      opacity: 0, 
      y: 20, 
      scale: 0.9,
      transition: {
        duration: 0.3
      }
    }
  }

  return (
    <AnimatePresence>
      {isVisible && (
        <motion.div
          variants={notificationVariants}
          initial="initial"
          animate="animate"
          exit="exit"
          className={cn(
            'relative max-w-sm w-full rounded-xl shadow-lg border backdrop-blur-sm overflow-hidden',
            config.bgColor,
            config.borderColor,
            className
          )}
        >
          {/* Progress bar */}
          {!persistent && duration && (
            <motion.div
              className={cn('absolute top-0 left-0 h-1', config.iconColor.replace('text-', 'bg-'))}
              initial={{ width: '100%' }}
              animate={{ width: `${progress}%` }}
              transition={{ duration: 0.1 }}
            />
          )}

          <div className="p-4">
            <div className="flex items-start space-x-3">
              {/* Icon */}
              <motion.div
                className={cn('flex-shrink-0', config.iconColor)}
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: 0.1, duration: 0.3 }}
              >
                <IconComponent className="w-5 h-5" />
              </motion.div>

              {/* Content */}
              <div className="flex-1 min-w-0">
                <motion.h4
                  className={cn('text-sm font-semibold', config.titleColor)}
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.15 }}
                >
                  {title}
                </motion.h4>
                {description && (
                  <motion.p
                    className="text-sm text-gray-600 dark:text-gray-400 mt-1"
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.2 }}
                  >
                    {description}
                  </motion.p>
                )}

                {/* Action button */}
                {actionLabel && onAction && (
                  <motion.div
                    className="mt-3"
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    transition={{ delay: 0.25 }}
                  >
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={onAction}
                      className="text-xs"
                    >
                      {actionLabel}
                    </Button>
                  </motion.div>
                )}
              </div>

              {/* Close button */}
              <motion.div
                initial={{ opacity: 0, scale: 0 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.1 }}
              >
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={handleClose}
                  className="h-6 w-6 p-0 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 group"
                >
                  <X className="h-3 w-3 group-hover:rotate-90 transition-transform duration-200" />
                </Button>
              </motion.div>
            </div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}

// Notification container for managing multiple notifications
export interface NotificationData {
  id: string
  title: string
  description?: string
  variant?: NotificationProps['variant']
  duration?: number
  persistent?: boolean
  actionLabel?: string
  onAction?: () => void
}

interface NotificationContainerProps {
  notifications: NotificationData[]
  onRemove: (id: string) => void
  position?: 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left' | 'top-center' | 'bottom-center'
  maxNotifications?: number
}

const positionClasses = {
  'top-right': 'top-4 right-4',
  'top-left': 'top-4 left-4',
  'bottom-right': 'bottom-4 right-4',
  'bottom-left': 'bottom-4 left-4',
  'top-center': 'top-4 left-1/2 transform -translate-x-1/2',
  'bottom-center': 'bottom-4 left-1/2 transform -translate-x-1/2'
}

export function NotificationContainer({
  notifications,
  onRemove,
  position = 'top-right',
  maxNotifications = 5
}: NotificationContainerProps) {
  const visibleNotifications = notifications.slice(0, maxNotifications)

  return (
    <div className={cn('fixed z-50 space-y-3 pointer-events-none', positionClasses[position])}>
      <AnimatePresence>
        {visibleNotifications.map((notification, index) => (
          <motion.div
            key={notification.id}
            initial={{ opacity: 0, y: position.includes('top') ? -50 : 50 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: position.includes('top') ? -50 : 50 }}
            transition={{ delay: index * 0.1 }}
            className="pointer-events-auto"
          >
            <Notification
              {...notification}
              onClose={() => onRemove(notification.id)}
            />
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  )
}