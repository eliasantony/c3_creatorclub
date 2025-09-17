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
        indigo: {
          700: '#3533CD',
        },
        gray: {
          800: '#363433',
        },
      },
      fontFamily: {
        garet: ['var(--font-garet)', 'sans-serif'],
      },
    },
  },
  plugins: [],
} satisfies Config
