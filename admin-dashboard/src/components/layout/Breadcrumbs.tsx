"use client"
import Link from 'next/link'
import { usePathname } from 'next/navigation'

function labelFor(seg: string): string {
  if (!seg) return ''
  const map: Record<string, string> = {
    admin: 'Admin',
    overview: 'Overview',
    users: 'Users',
    bookings: 'Bookings',
    workspaces: 'Workspaces',
    moderation: 'Moderation',
  }
  return map[seg] ?? seg.replace(/-/g, ' ').replace(/\b\w/g, (m) => m.toUpperCase())
}

export function Breadcrumbs() {
  const pathname = usePathname() || '/'
  const parts = pathname.split('/').filter(Boolean)
  const acc: { href: string; label: string }[] = []
  let href = ''
  for (let i = 0; i < parts.length; i++) {
    href += `/${parts[i]}`
    const label = labelFor(parts[i])
    acc.push({ href, label })
  }

  if (!acc.length) return null

  return (
    <nav aria-label="Breadcrumb" className="text-sm text-muted">
      <ol className="inline-flex items-center gap-1">
        {acc.map((c, idx) => {
          const last = idx === acc.length - 1
          return (
            <li key={c.href} className="inline-flex items-center gap-1">
              {!last ? (
                <Link href={c.href} className="hover:text-fg">
                  {c.label}
                </Link>
              ) : (
                <span aria-current="page" className="text-fg/70">{c.label}</span>
              )}
              {!last && <span className="text-muted">/</span>}
            </li>
          )
        })}
      </ol>
    </nav>
  )
}
