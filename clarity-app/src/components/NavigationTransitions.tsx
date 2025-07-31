'use client'

import { motion, AnimatePresence } from 'framer-motion'
import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { ReactNode, useState } from 'react'
import { cn } from '@/lib/utils'

// Enhanced Link component with loading state
interface TransitionLinkProps {
  href: string
  children: ReactNode
  className?: string
  showLoader?: boolean
  onClick?: () => void
}

export function TransitionLink({ 
  href, 
  children, 
  className, 
  showLoader = true,
  onClick 
}: TransitionLinkProps) {
  const [isLoading, setIsLoading] = useState(false)
  const router = useRouter()
  const pathname = usePathname()
  const isActive = pathname === href

  const handleClick = async (e: React.MouseEvent) => {
    e.preventDefault()
    
    if (isActive) return
    
    onClick?.()
    
    if (showLoader) {
      setIsLoading(true)
    }
    
    // Add a small delay for better UX
    await new Promise(resolve => setTimeout(resolve, 100))
    
    router.push(href)
    
    // Reset loading state after navigation
    setTimeout(() => setIsLoading(false), 500)
  }

  return (
    <motion.div
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
      className="relative inline-block"
    >
      <Link
        href={href}
        onClick={handleClick}
        className={cn(
          'relative inline-flex items-center transition-colors duration-200',
          isActive && 'text-blue-600 dark:text-blue-400',
          className
        )}
      >
        {children}
        
        {/* Active indicator */}
        {isActive && (
          <motion.div
            layoutId="activeIndicator"
            className="absolute -bottom-1 left-0 right-0 h-0.5 bg-blue-600 dark:bg-blue-400 rounded-full"
            initial={false}
            transition={{ type: "spring", stiffness: 300, damping: 30 }}
          />
        )}
        
        {/* Loading indicator */}
        <AnimatePresence>
          {isLoading && (
            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.8 }}
              className="absolute inset-0 flex items-center justify-center bg-white/80 dark:bg-gray-900/80 rounded"
            >
              <div className="flex space-x-1">
                {[0, 1, 2].map((i) => (
                  <motion.div
                    key={i}
                    className="w-1 h-1 bg-blue-600 dark:bg-blue-400 rounded-full"
                    animate={{
                      scale: [1, 1.5, 1],
                      opacity: [0.5, 1, 0.5]
                    }}
                    transition={{
                      duration: 0.8,
                      repeat: Infinity,
                      delay: i * 0.1
                    }}
                  />
                ))}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </Link>
    </motion.div>
  )
}

// Breadcrumb component with animations
interface BreadcrumbItem {
  label: string
  href?: string
}

interface BreadcrumbProps {
  items: BreadcrumbItem[]
  separator?: ReactNode
  className?: string
}

export function AnimatedBreadcrumb({ 
  items, 
  separator = '/', 
  className 
}: BreadcrumbProps) {
  return (
    <motion.nav
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      className={cn('flex items-center space-x-2 text-sm', className)}
    >
      {items.map((item, index) => (
        <motion.div
          key={index}
          initial={{ opacity: 0, x: -10 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: index * 0.1 }}
          className="flex items-center space-x-2"
        >
          {item.href ? (
            <TransitionLink
              href={item.href}
              className="text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
              showLoader={false}
            >
              {item.label}
            </TransitionLink>
          ) : (
            <span className="text-gray-900 dark:text-white font-medium">
              {item.label}
            </span>
          )}
          
          {index < items.length - 1 && (
            <motion.span
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: index * 0.1 + 0.05 }}
              className="text-gray-400 dark:text-gray-600"
            >
              {separator}
            </motion.span>
          )}
        </motion.div>
      ))}
    </motion.nav>
  )
}

// Tab navigation with smooth indicator
interface Tab {
  id: string
  label: string
  content?: ReactNode
}

interface AnimatedTabsProps {
  tabs: Tab[]
  activeTab: string
  onTabChange: (tabId: string) => void
  className?: string
}

export function AnimatedTabs({ 
  tabs, 
  activeTab, 
  onTabChange, 
  className 
}: AnimatedTabsProps) {
  return (
    <div className={cn('w-full', className)}>
      <div className="relative border-b border-gray-200 dark:border-gray-700">
        <div className="flex space-x-8">
          {tabs.map((tab) => (
            <motion.button
              key={tab.id}
              onClick={() => onTabChange(tab.id)}
              className={cn(
                'relative py-2 px-1 text-sm font-medium transition-colors duration-200',
                activeTab === tab.id
                  ? 'text-blue-600 dark:text-blue-400'
                  : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'
              )}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              {tab.label}
              
              {activeTab === tab.id && (
                <motion.div
                  layoutId="tabIndicator"
                  className="absolute bottom-0 left-0 right-0 h-0.5 bg-blue-600 dark:bg-blue-400"
                  initial={false}
                  transition={{ type: "spring", stiffness: 300, damping: 30 }}
                />
              )}
            </motion.button>
          ))}
        </div>
      </div>
      
      {/* Tab content */}
      <div className="mt-4">
        <AnimatePresence mode="wait">
          {tabs.map((tab) => (
            activeTab === tab.id && tab.content && (
              <motion.div
                key={tab.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                transition={{ duration: 0.2 }}
              >
                {tab.content}
              </motion.div>
            )
          ))}
        </AnimatePresence>
      </div>
    </div>
  )
}

// Mobile menu with slide animation
interface MobileMenuProps {
  isOpen: boolean
  onClose: () => void
  children: ReactNode
  className?: string
}

export function MobileMenu({ isOpen, onClose, children, className }: MobileMenuProps) {
  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/50 backdrop-blur-sm z-40"
            onClick={onClose}
          />
          
          {/* Menu */}
          <motion.div
            initial={{ x: '100%' }}
            animate={{ x: 0 }}
            exit={{ x: '100%' }}
            transition={{ type: 'tween', duration: 0.3 }}
            className={cn(
              'fixed top-0 right-0 h-full w-80 bg-white dark:bg-gray-900 shadow-xl z-50 overflow-y-auto',
              className
            )}
          >
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.1 }}
              className="p-6"
            >
              {children}
            </motion.div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}

// Page loading indicator
export function PageLoadingIndicator({ isLoading }: { isLoading: boolean }) {
  return (
    <AnimatePresence>
      {isLoading && (
        <motion.div
          initial={{ scaleX: 0 }}
          animate={{ scaleX: 1 }}
          exit={{ scaleX: 0 }}
          transition={{ duration: 0.3 }}
          className="fixed top-0 left-0 right-0 h-1 bg-gradient-to-r from-blue-500 to-purple-600 z-50 origin-left"
        />
      )}
    </AnimatePresence>
  )
}

// Floating action button with smooth animations
interface FloatingActionButtonProps {
  onClick: () => void
  icon: ReactNode
  label?: string
  position?: 'bottom-right' | 'bottom-left'
  className?: string
}

export function FloatingActionButton({
  onClick,
  icon,
  label,
  position = 'bottom-right',
  className
}: FloatingActionButtonProps) {
  const [isHovered, setIsHovered] = useState(false)

  const positionClasses = {
    'bottom-right': 'bottom-6 right-6',
    'bottom-left': 'bottom-6 left-6'
  }

  return (
    <motion.button
      onClick={onClick}
      onHoverStart={() => setIsHovered(true)}
      onHoverEnd={() => setIsHovered(false)}
      className={cn(
        'fixed z-50 flex items-center space-x-2 bg-gradient-to-r from-blue-500 to-purple-600 text-white rounded-full shadow-lg hover:shadow-xl transition-shadow duration-200',
        positionClasses[position],
        className
      )}
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
    >
      <motion.div
        className="p-4"
        animate={{ rotate: isHovered ? 180 : 0 }}
        transition={{ duration: 0.3 }}
      >
        {icon}
      </motion.div>
      
      <AnimatePresence>
        {label && isHovered && (
          <motion.span
            initial={{ opacity: 0, width: 0 }}
            animate={{ opacity: 1, width: 'auto' }}
            exit={{ opacity: 0, width: 0 }}
            transition={{ duration: 0.2 }}
            className="pr-4 text-sm font-medium whitespace-nowrap overflow-hidden"
          >
            {label}
          </motion.span>
        )}
      </AnimatePresence>
    </motion.button>
  )
}