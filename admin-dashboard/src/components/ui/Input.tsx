"use client"
import * as React from 'react'

export const Input = React.forwardRef<HTMLInputElement, React.ComponentProps<'input'>>(
  ({ className = '', ...props }, ref) => (
    <input ref={ref} className={`border rounded px-2 py-1 ${className}`} {...props} />
  )
)
Input.displayName = 'Input'
