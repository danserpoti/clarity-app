'use client'

import { motion, AnimatePresence } from 'framer-motion'
import { usePathname } from 'next/navigation'
import { ReactNode } from 'react'

interface PageTransitionProps {
  children: ReactNode
}

const pageVariants = {
  initial: {
    opacity: 0,
    y: 20,
    scale: 0.98
  },
  in: {
    opacity: 1,
    y: 0,
    scale: 1
  },
  out: {
    opacity: 0,
    y: -20,
    scale: 1.02
  }
}

const pageTransition = {
  duration: 0.5
}

const pageStyle = {
  position: 'absolute' as const,
  width: '100%',
  minHeight: '100vh'
}

export function PageTransition({ children }: PageTransitionProps) {
  const pathname = usePathname()

  return (
    <AnimatePresence mode="wait" initial={false}>
      <motion.div
        key={pathname}
        initial="initial"
        animate="in"
        exit="out"
        variants={pageVariants}
        transition={pageTransition}
        style={pageStyle}
      >
        {children}
      </motion.div>
    </AnimatePresence>
  )
}

// Route-specific transitions
export const routeTransitions = {
  '/': {
    initial: { opacity: 0, scale: 0.95 },
    animate: { opacity: 1, scale: 1 },
    exit: { opacity: 0, scale: 1.05 },
    transition: { duration: 0.6 }
  },
  '/thoughts': {
    initial: { opacity: 0, x: 50 },
    animate: { opacity: 1, x: 0 },
    exit: { opacity: 0, x: -50 },
    transition: { duration: 0.5 }
  },
  '/thoughts/new': {
    initial: { opacity: 0, y: 30 },
    animate: { opacity: 1, y: 0 },
    exit: { opacity: 0, y: -30 },
    transition: { duration: 0.4 }
  },
  '/analytics': {
    initial: { opacity: 0, scale: 0.9, rotateX: 10 },
    animate: { opacity: 1, scale: 1, rotateX: 0 },
    exit: { opacity: 0, scale: 0.9, rotateX: -10 },
    transition: { duration: 0.6 }
  }
}

// Custom page transition wrapper for specific routes
interface CustomPageTransitionProps {
  children: ReactNode
  route: keyof typeof routeTransitions
}

export function CustomPageTransition({ children, route }: CustomPageTransitionProps) {
  const transition = routeTransitions[route] || routeTransitions['/']
  
  return (
    <motion.div
      initial={transition.initial}
      animate={transition.animate}
      exit={transition.exit}
      transition={transition.transition}
      className="w-full min-h-screen"
    >
      {children}
    </motion.div>
  )
}