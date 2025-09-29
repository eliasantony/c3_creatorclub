"use client"
import * as React from 'react'

type Props = React.ButtonHTMLAttributes<HTMLButtonElement> & { variant?: 'primary' | 'outline' | 'danger' | 'ghost' }

export const Button = React.forwardRef<HTMLButtonElement, Props>(({ className = '', variant = 'outline', ...props }, ref) => {
  const base = 'inline-flex items-center justify-center gap-1 whitespace-nowrap rounded-md px-3 py-2 text-sm font-medium transition shadow-sm focus:outline-none focus:ring-2 focus:ring-[color:var(--ring)] disabled:opacity-50 disabled:cursor-not-allowed'
  const variants: Record<NonNullable<Props['variant']>, string> = {
    primary: 'bg-[color:var(--accent)] text-white hover:brightness-110',
    outline: 'border border-border bg-[color:var(--surface)] text-[color:var(--fg)] hover:bg-[color:var(--surface-hover)]',
    danger: 'bg-red-600 text-white hover:bg-red-500',
    ghost: 'text-[color:var(--fg-muted)] hover:text-[color:var(--fg)] hover:bg-[color:var(--surface-hover)]',
  }
  return <button ref={ref} className={`${base} ${variants[variant]} ${className}`} {...props} />
})
Button.displayName = 'Button'
