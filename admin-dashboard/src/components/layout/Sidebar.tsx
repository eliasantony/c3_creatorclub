"use client"
import Link from 'next/link'
import { usePathname } from 'next/navigation'

const links = [
  { href: '/admin', label: 'Dashboard' },
  { href: '/admin/overview', label: 'Overview' },
  { href: '/admin/users', label: 'Users' },
  { href: '/admin/workspaces', label: 'Workspaces' },
  { href: '/admin/bookings', label: 'Bookings' },
  { href: '/admin/moderation', label: 'Moderation' },
]

export function Sidebar() {
  const pathname = usePathname()
  return (
    <aside className="w-60 bg-indigo-700 text-white min-h-screen p-4">
      <div className="text-xl font-bold mb-6">Creator Club</div>
      <nav className="space-y-1">
        {links.map((l) => {
          const active = pathname === l.href
          return (
            <Link
              key={l.href}
              href={l.href}
              className={`block rounded px-3 py-2 hover:bg-white/10 ${active ? 'bg-white/10' : ''}`}
            >
              {l.label}
            </Link>
          )
        })}
      </nav>
    </aside>
  )
}
