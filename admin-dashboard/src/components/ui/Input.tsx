"use client"
import * as React from 'react'

export const Input = React.forwardRef<HTMLInputElement, React.ComponentProps<'input'>>(
  ({ className = '', ...props }, ref) => (
    <input
      ref={ref}
      className={`w-full rounded-md border border-border bg-white dark:bg-[color:var(--surface-alt)] px-3 py-2 text-sm text-[color:var(--fg)] placeholder:text-[color:var(--fg-muted)] shadow-sm focus:outline-none focus:ring-2 focus:ring-[color:var(--ring)] focus:border-[color:var(--ring)] disabled:opacity-50 disabled:cursor-not-allowed ${className}`}
      {...props}
    />
  )
)
Input.displayName = 'Input'
