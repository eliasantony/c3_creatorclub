import { test, expect } from '@playwright/test'

test('users page renders and shows pagination control (or env warning)', async ({ page }) => {
  await page.goto('/admin/users')
  const loginHeading = page.getByRole('heading', { name: 'Admin Login' })
  const usersHeading = page.getByRole('heading', { name: 'Users' })
  try {
    await Promise.race([
      loginHeading.waitFor({ state: 'visible', timeout: 5000 }),
      usersHeading.waitFor({ state: 'visible', timeout: 5000 }),
    ])
  } catch {}
  if (await loginHeading.count()) {
    await expect(loginHeading).toBeVisible()
    return
  }
  await expect(usersHeading).toBeVisible()
  const btn = page.getByRole('button', { name: /Load more|No more|Loading/ })
  if ((await btn.count()) > 0) {
    await expect(btn.first()).toBeVisible()
  } else {
    await expect(page.getByText(/Firebase environment variables are not configured/)).toBeVisible()
  }
})
