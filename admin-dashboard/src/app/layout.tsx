import type { Metadata } from 'next'
import './globals.css'
import { ReactQueryProvider } from '@/components/providers/ReactQueryProvider'

export const metadata: Metadata = {
  title: 'Creator Club Admin',
  description: 'Admin dashboard for Creator Club',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="h-full">
      <body className="min-h-full bg-white text-gray-900">
        <ReactQueryProvider>
          {children}
        </ReactQueryProvider>
      </body>
    </html>
  )
}
