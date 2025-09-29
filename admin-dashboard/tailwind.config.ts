import type { Config } from "tailwindcss"

export default {
  darkMode: ["class"],
  content: [
    "./src/pages/**/*.{ts,tsx}",
    "./src/components/**/*.{ts,tsx}",
    "./src/app/**/*.{ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          primary: 'var(--brand-primary)',
        },
        neutral: {
          0: 'var(--neutral-0)',
          900: 'var(--neutral-900)',
        },
        bg: 'var(--bg)',
        fg: 'var(--fg)',
        muted: 'var(--muted)',
        border: 'var(--border)'
      },
      fontFamily: {
        garet: ['var(--font-garet)', 'sans-serif'],
      },
    },
  },
  plugins: [],
} satisfies Config
