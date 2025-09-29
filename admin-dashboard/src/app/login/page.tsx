"use client"
import { z } from 'zod'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { signInWithEmailAndPassword } from 'firebase/auth'
import { getAuthInstance } from '@/lib/firebase'
import { useRouter } from 'next/navigation'
import { useState } from 'react'
import { Input } from '@/components/ui/Input'
import { Button } from '@/components/ui/Button'

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
})

export default function LoginPage() {
  const router = useRouter()
  const [err, setErr] = useState<string | null>(null)
  const { register, handleSubmit, formState: { isSubmitting } } = useForm<z.infer<typeof schema>>({ resolver: zodResolver(schema) })

  const onSubmit = handleSubmit(async ({ email, password }) => {
    setErr(null)
    try {
      await signInWithEmailAndPassword(getAuthInstance(), email, password)
      router.push('/admin/overview')
    } catch (e: any) {
      setErr(e?.message ?? 'Login failed')
    }
  })

  return (
    <div className="min-h-screen flex items-center justify-center p-6 bg-[radial-gradient(circle_at_30%_20%,#3533CD33,#3533CD08_60%),linear-gradient(#f7f8fb,#ffffff)]">
      <div className="w-full max-w-sm">
        <form onSubmit={onSubmit} className="bg-white/90 backdrop-blur-sm border border-border shadow-sm rounded-xl px-6 py-7 space-y-5">
          <div className="space-y-1">
            <h1 className="text-2xl font-semibold tracking-tight text-neutral-900">Welcome back</h1>
            <p className="text-sm text-muted">Sign in to the Creator Club admin dashboard</p>
          </div>
          {err && <div className="text-sm rounded border border-red-200 bg-red-50 px-3 py-2 text-red-700" role="alert">{err}</div>}
          <div className="space-y-1.5">
            <label className="text-xs font-medium uppercase tracking-wide text-muted" htmlFor="email">Email</label>
            <Input id="email" type="email" placeholder="you@example.com" className="w-full focus:outline-none focus:ring-2 focus:ring-brand-primary/60" {...register('email')} />
          </div>
          <div className="space-y-1.5">
            <label className="text-xs font-medium uppercase tracking-wide text-muted" htmlFor="password">Password</label>
            <Input id="password" type="password" className="w-full focus:outline-none focus:ring-2 focus:ring-brand-primary/60" {...register('password')} />
          </div>
          <Button type="submit" variant="primary" className="w-full font-medium shadow hover:brightness-110 transition" disabled={isSubmitting}>{isSubmitting ? 'Signing in…' : 'Sign in'}</Button>
          <p className="pt-2 text-[11px] text-center text-muted">Protected by Firebase App Check</p>
        </form>
      </div>
    </div>
  )
}
