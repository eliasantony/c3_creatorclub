"use client"
import { signOut } from 'firebase/auth'
import Link from 'next/link'
import { getAuthInstance } from '@/lib/firebase'
import { useAuth } from '@/components/providers/AuthProvider'
import { Button } from '@/components/ui/Button'
import { ThemeToggle } from '@/components/theme/ThemeToggle'
import { Breadcrumbs } from '@/components/layout/Breadcrumbs'

export function Topbar() {
  const { role, user } = useAuth()
  return (
    <header className="h-14 border-b flex items-center px-4 justify-between">
      <div className="flex items-center gap-4">
        <Link href="/admin/overview" className="font-semibold">Creator Club Admin</Link>
        <Breadcrumbs />
      </div>
      <div className="flex items-center gap-3">
        <ThemeToggle />
        <span className="text-xs text-muted">{user?.email ?? '—'}</span>
        <Button onClick={() => signOut(getAuthInstance())}>Sign out</Button>
      </div>
    </header>
  )
}
