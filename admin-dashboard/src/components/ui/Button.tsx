"use client"
import * as React from 'react'

type Props = React.ButtonHTMLAttributes<HTMLButtonElement> & { variant?: 'primary' | 'outline' | 'danger' }

export const Button = React.forwardRef<HTMLButtonElement, Props>(({ className = '', variant = 'outline', ...props }, ref) => {
  const base = 'px-3 py-2 rounded disabled:opacity-50 disabled:cursor-not-allowed'
  const variants: Record<NonNullable<Props['variant']>, string> = {
    outline: 'border',
    primary: 'bg-indigo-700 text-white',
    danger: 'bg-red-600 text-white',
  }
  return <button ref={ref} className={`${base} ${variants[variant]} ${className}`} {...props} />
})
Button.displayName = 'Button'
