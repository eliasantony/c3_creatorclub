"use client"
import { useTheme } from 'next-themes'

export function ThemeToggle() {
  const { theme, setTheme, systemTheme } = useTheme()
  const effective = theme === 'system' ? systemTheme : theme
  return (
    <div className="flex items-center gap-2 text-sm">
      <select
        aria-label="Theme"
        className="border rounded px-2 py-1"
        value={theme}
        onChange={(e) => setTheme(e.target.value)}
      >
        <option value="system">System ({systemTheme ?? '…'})</option>
        <option value="light">Light</option>
        <option value="dark">Dark</option>
      </select>
      <span className="text-gray-500">{effective ?? '—'}</span>
    </div>
  )
}
