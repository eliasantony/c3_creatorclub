"use client"
import { Sidebar } from '@/components/layout/Sidebar'
import { Topbar } from '@/components/layout/Topbar'
import { useAuth } from '@/components/providers/AuthProvider'
import { useEffect } from 'react'
import { useRouter } from 'next/navigation'

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth()
  const router = useRouter()
  useEffect(() => {
    if (!loading && !user) router.replace('/login')
  }, [loading, user, router])

  if (loading) return <div className="p-6">Loading…</div>
  if (!user) return null

  return (
    <div className="flex">
      <Sidebar />
      <div className="flex-1 min-h-screen">
        <Topbar />
        <main className="p-6">{children}</main>
      </div>
    </div>
  )
}
