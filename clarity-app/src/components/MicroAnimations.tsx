'use client'

import { motion, useInView, useScroll, useTransform } from 'framer-motion'
import { ReactNode, useRef } from 'react'
import { cn } from '@/lib/utils'

// Fade in animation when element comes into view
interface FadeInProps {
  children: ReactNode
  direction?: 'up' | 'down' | 'left' | 'right'
  delay?: number
  duration?: number
  className?: string
}

export function FadeIn({ 
  children, 
  direction = 'up', 
  delay = 0, 
  duration = 0.6,
  className 
}: FadeInProps) {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true, margin: '-100px' })
  
  const directionOffset = {
    up: { y: 50 },
    down: { y: -50 },
    left: { x: 50 },
    right: { x: -50 }
  }

  return (
    <motion.div
      ref={ref}
      initial={{ 
        opacity: 0, 
        ...directionOffset[direction]
      }}
      animate={isInView ? { 
        opacity: 1, 
        y: 0, 
        x: 0 
      } : {}}
      transition={{ 
        duration, 
        delay,
        ease: 'easeOut'
      }}
      className={className}
    >
      {children}
    </motion.div>
  )
}

// Stagger animation for list items
interface StaggerContainerProps {
  children: ReactNode
  staggerDelay?: number
  className?: string
}

export function StaggerContainer({ 
  children, 
  staggerDelay = 0.1,
  className 
}: StaggerContainerProps) {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true })

  return (
    <motion.div
      ref={ref}
      initial="hidden"
      animate={isInView ? "visible" : "hidden"}
      variants={{
        hidden: { opacity: 0 },
        visible: {
          opacity: 1,
          transition: {
            staggerChildren: staggerDelay
          }
        }
      }}
      className={className}
    >
      {children}
    </motion.div>
  )
}

export function StaggerItem({ children, className }: { children: ReactNode, className?: string }) {
  return (
    <motion.div
      variants={{
        hidden: { opacity: 0, y: 20 },
        visible: { 
          opacity: 1, 
          y: 0,
          transition: {
            duration: 0.5,
            ease: 'easeOut'
          }
        }
      }}
      className={className}
    >
      {children}
    </motion.div>
  )
}

// Hover effects for interactive elements
interface HoverEffectProps {
  children: ReactNode
  effect?: 'lift' | 'scale' | 'glow' | 'tilt' | 'bounce'
  className?: string
}

export function HoverEffect({ children, effect = 'lift', className }: HoverEffectProps) {
  const effects = {
    lift: {
      whileHover: { y: -4, transition: { duration: 0.2 } },
      whileTap: { y: -2, transition: { duration: 0.1 } }
    },
    scale: {
      whileHover: { scale: 1.05, transition: { duration: 0.2 } },
      whileTap: { scale: 0.98, transition: { duration: 0.1 } }
    },
    glow: {
      whileHover: { 
        boxShadow: '0 0 20px rgba(59, 130, 246, 0.3)',
        transition: { duration: 0.2 }
      }
    },
    tilt: {
      whileHover: { 
        rotateZ: 2,
        scale: 1.02,
        transition: { duration: 0.2 }
      },
      whileTap: { rotateZ: 0, scale: 1 }
    },
    bounce: {
      whileHover: { 
        y: [-2, -6, -2],
        transition: { 
          duration: 0.6,
          repeat: Infinity,
          repeatType: 'loop' as const
        }
      }
    }
  }

  return (
    <motion.div
      {...effects[effect]}
      className={className}
    >
      {children}
    </motion.div>
  )
}

// Parallax effect for background elements
interface ParallaxProps {
  children: ReactNode
  offset?: number
  className?: string
}

export function Parallax({ children, offset = 50, className }: ParallaxProps) {
  const ref = useRef(null)
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start end", "end start"]
  })
  
  const y = useTransform(scrollYProgress, [0, 1], [0, offset])

  return (
    <motion.div
      ref={ref}
      style={{ y }}
      className={className}
    >
      {children}
    </motion.div>
  )
}

// Floating animation for decorative elements
interface FloatingProps {
  children: ReactNode
  duration?: number
  offset?: number
  className?: string
}

export function Floating({ 
  children, 
  duration = 3,
  offset = 10,
  className 
}: FloatingProps) {
  return (
    <motion.div
      animate={{
        y: [-offset, offset, -offset],
        transition: {
          duration,
          repeat: Infinity,
          repeatType: 'reverse',
          ease: 'easeInOut'
        }
      }}
      className={className}
    >
      {children}
    </motion.div>
  )
}

// Pulse animation for attention-grabbing elements
interface PulseProps {
  children: ReactNode
  scale?: number
  duration?: number
  className?: string
}

export function Pulse({ 
  children, 
  scale = 1.05,
  duration = 2,
  className 
}: PulseProps) {
  return (
    <motion.div
      animate={{
        scale: [1, scale, 1],
        transition: {
          duration,
          repeat: Infinity,
          ease: 'easeInOut'
        }
      }}
      className={className}
    >
      {children}
    </motion.div>
  )
}

// Text reveal animation
interface TextRevealProps {
  text: string
  delay?: number
  className?: string
}

export function TextReveal({ text, delay = 0, className }: TextRevealProps) {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true })

  const words = text.split(' ')

  return (
    <motion.div
      ref={ref}
      initial="hidden"
      animate={isInView ? "visible" : "hidden"}
      variants={{
        hidden: {},
        visible: {
          transition: {
            staggerChildren: 0.1,
            delayChildren: delay
          }
        }
      }}
      className={cn('flex flex-wrap', className)}
    >
      {words.map((word, index) => (
        <motion.span
          key={index}
          variants={{
            hidden: { opacity: 0, y: 20 },
            visible: { 
              opacity: 1, 
              y: 0,
              transition: {
                duration: 0.5,
                ease: 'easeOut'
              }
            }
          }}
          className="inline-block mr-1"
        >
          {word}
        </motion.span>
      ))}
    </motion.div>
  )
}

// Magnetic effect for buttons and interactive elements
interface MagneticProps {
  children: ReactNode
  strength?: number
  className?: string
}

export function Magnetic({ children, strength = 20, className }: MagneticProps) {
  const ref = useRef<HTMLDivElement>(null)

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!ref.current) return

    const { clientX, clientY } = e
    const { left, top, width, height } = ref.current.getBoundingClientRect()
    
    const centerX = left + width / 2
    const centerY = top + height / 2
    
    const deltaX = (clientX - centerX) / (width / 2)
    const deltaY = (clientY - centerY) / (height / 2)
    
    ref.current.style.transform = `translate(${deltaX * strength}px, ${deltaY * strength}px)`
  }

  const handleMouseLeave = () => {
    if (!ref.current) return
    ref.current.style.transform = 'translate(0px, 0px)'
  }

  return (
    <motion.div
      ref={ref}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      transition={{ type: 'spring', stiffness: 300, damping: 30 }}
      className={className}
    >
      {children}
    </motion.div>
  )
}

// Loading dots animation
export function LoadingDots({ className }: { className?: string }) {
  return (
    <div className={cn('flex space-x-1', className)}>
      {[0, 1, 2].map((i) => (
        <motion.div
          key={i}
          className="w-2 h-2 bg-current rounded-full"
          animate={{
            scale: [1, 1.2, 1],
            opacity: [0.5, 1, 0.5]
          }}
          transition={{
            duration: 1,
            repeat: Infinity,
            delay: i * 0.2
          }}
        />
      ))}
    </div>
  )
}

// Shimmer effect for loading states
export function Shimmer({ className }: { className?: string }) {
  return (
    <motion.div
      className={cn('bg-gradient-to-r from-gray-200 via-gray-300 to-gray-200 dark:from-gray-700 dark:via-gray-600 dark:to-gray-700', className)}
      animate={{
        backgroundPosition: ['200% 0', '-200% 0']
      }}
      transition={{
        duration: 2,
        repeat: Infinity,
        ease: 'linear'
      }}
      style={{
        backgroundSize: '200% 100%'
      }}
    />
  )
}