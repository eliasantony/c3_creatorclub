import { test, expect } from '@playwright/test'

test('users page renders and shows pagination control', async ({ page }) => {
  await page.goto('/admin/users')
  await expect(page.getByRole('heading', { name: 'Users' })).toBeVisible()
  await expect(page.getByRole('button', { name: /Load more|No more|Loading/ })).toBeVisible()
})
