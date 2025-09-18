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
    <div className="min-h-screen grid place-items-center bg-gray-50 p-6">
      <form onSubmit={onSubmit} className="bg-white shadow rounded p-6 w-full max-w-sm space-y-3">
        <h1 className="text-xl font-semibold">Admin Login</h1>
        {err && <div className="text-sm text-red-600">{err}</div>}
        <div>
          <label className="text-sm" htmlFor="email">Email</label>
          <Input id="email" type="email" placeholder="you@example.com" {...register('email')} />
        </div>
        <div>
          <label className="text-sm" htmlFor="password">Password</label>
          <Input id="password" type="password" {...register('password')} />
        </div>
        <Button type="submit" variant="primary" disabled={isSubmitting}>{isSubmitting ? 'Signing in…' : 'Sign in'}</Button>
      </form>
    </div>
  )
}
