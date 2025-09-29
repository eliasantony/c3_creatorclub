import { cn } from '@/lib/utils'
import React from 'react'

export function Card({ className, children }: { className?: string; children: React.ReactNode }) {
  return <div className={cn('rounded-lg border border-border bg-white dark:bg-neutral-900', className)}>{children}</div>
}

export function CardHeader({ className, children }: { className?: string; children: React.ReactNode }) {
  return <div className={cn('px-4 py-3 border-b border-border', className)}>{children}</div>
}

export function CardContent({ className, children }: { className?: string; children: React.ReactNode }) {
  return <div className={cn('px-4 py-4', className)}>{children}</div>
}
