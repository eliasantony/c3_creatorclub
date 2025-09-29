"use client"
import { useEffect, useState } from 'react'
import { canPerform, getCurrentRole } from '@/lib/rbac'

type Props = {
  action: Parameters<typeof canPerform>[0]
  children: (allowed: boolean) => React.ReactNode
}

export function RbacGate({ action, children }: Props) {
  const [allowed, setAllowed] = useState(false)
  useEffect(() => {
    getCurrentRole().then((role) => setAllowed(canPerform(action, role)))
  }, [action])
  return <>{children(allowed)}</>
}
