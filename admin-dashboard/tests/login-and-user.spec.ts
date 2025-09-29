import { test, expect } from '@playwright/test'

test('login flow then open user details (if creds provided)', async ({ page }) => {
  const email = process.env.PW_ADMIN_EMAIL
  const password = process.env.PW_ADMIN_PASSWORD
  if (!email || !password) test.skip(true, 'No creds provided for E2E login')
  const e = email as string
  const p = password as string

  await page.goto('/login')
  await page.getByLabel('Email').fill(e)
  await page.getByLabel('Password').fill(p)
  await page.getByRole('button', { name: 'Sign in' }).click()

  await page.waitForURL(/\/admin\/overview/)
  await expect(page.getByText(/Role:/)).toBeVisible()

  // Navigate to users. If a specific user id is provided, open it directly
  const userId = process.env.PW_TEST_USER_ID
  if (userId) {
    await page.goto(`/admin/users/${userId}`)
    await expect(page.getByText('User Details')).toBeVisible()
  }
})
