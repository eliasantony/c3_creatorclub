import type { Metadata } from 'next'
import './globals.css'
import { ReactQueryProvider } from '@/components/providers/ReactQueryProvider'
import { AuthProvider } from '@/components/providers/AuthProvider'
import { ThemeProvider } from '@/components/providers/ThemeProvider'
import { Toaster } from 'sonner'

export const metadata: Metadata = {
  title: 'Creator Club Admin',
  description: 'Admin dashboard for Creator Club',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="h-full" suppressHydrationWarning>
      <body className="min-h-full bg-bg text-fg">
        <ReactQueryProvider>
          <ThemeProvider>
            <AuthProvider>
              {children}
              <Toaster position="top-right" richColors />
            </AuthProvider>
          </ThemeProvider>
        </ReactQueryProvider>
      </body>
    </html>
  )
}
