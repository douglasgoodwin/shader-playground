import { defineConfig } from '@playwright/test'

export default defineConfig({
    testDir: './tests',
    webServer: {
        command: 'npm run dev',
        url: 'http://localhost:5173',
        reuseExistingServer: true,
    },
    use: {
        baseURL: 'http://localhost:5173',
        acceptDownloads: false,
    },
    projects: [{ name: 'chromium', use: { browserName: 'chromium' } }],
})
