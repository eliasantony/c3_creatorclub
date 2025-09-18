"use client"
import { createContext, useContext, useEffect, useMemo, useState } from 'react'
import { onAuthStateChanged, type User } from 'firebase/auth'
import { getAuthInstance } from '@/lib/firebase'
import { getCurrentRole, type Role } from '@/lib/rbac'

type AuthState = {
  user: User | null
  role: Role
  loading: boolean
}

const Ctx = createContext<AuthState>({ user: null, role: 'viewer', loading: true })

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [role, setRole] = useState<Role>('viewer')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const auth = getAuthInstance()
    const unsub = onAuthStateChanged(auth, async (u) => {
      setUser(u)
      const r = await getCurrentRole()
      setRole(r)
      document.cookie = `cc_role=${r}; path=/; SameSite=Lax`
      setLoading(false)
    })
    return () => unsub()
  }, [])

  const value = useMemo(() => ({ user, role, loading }), [user, role, loading])
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>
}

export function useAuth() {
  return useContext(Ctx)
}
