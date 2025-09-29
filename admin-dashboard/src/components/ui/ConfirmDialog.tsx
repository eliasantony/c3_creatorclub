"use client"
import { useState } from 'react'

type Props = {
  title: string
  description?: string
  confirmText?: string
  onConfirm: () => Promise<void> | void
  children: (open: () => void) => React.ReactNode
}

export function ConfirmDialog({ title, description, confirmText = 'Confirm', onConfirm, children }: Props) {
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const handle = async () => {
    setLoading(true)
    try {
      await onConfirm()
    } finally {
      setLoading(false)
      setOpen(false)
    }
  }
  return (
    <>
      {children(() => setOpen(true))}
      {open && (
        <div className="fixed inset-0 z-50 grid place-items-center bg-black/40">
          <div className="bg-white rounded shadow max-w-md w-full p-6">
            <h2 className="text-lg font-semibold mb-2">{title}</h2>
            {description && <p className="text-sm text-gray-600 mb-4">{description}</p>}
            <div className="flex justify-end gap-2">
              <button className="px-3 py-2 border rounded" onClick={() => setOpen(false)} disabled={loading}>Cancel</button>
              <button className="px-3 py-2 bg-red-600 text-white rounded" onClick={handle} disabled={loading}>
                {loading ? 'Working…' : confirmText}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
