"use client"
import { signOut } from 'firebase/auth'
import Link from 'next/link'
import { getAuthInstance } from '@/lib/firebase'
import { useAuth } from '@/components/providers/AuthProvider'
import { Button } from '@/components/ui/Button'

export function Topbar() {
  const { role } = useAuth()
  return (
    <header className="h-14 border-b flex items-center px-4 justify-between">
      <div className="flex items-center gap-4">
        <Link href="/admin/overview" className="font-semibold">Admin</Link>
        <span className="text-xs text-gray-500">Role: {role}</span>
      </div>
      <div>
        <Button onClick={() => signOut(getAuthInstance())}>Sign out</Button>
      </div>
    </header>
  )
}
