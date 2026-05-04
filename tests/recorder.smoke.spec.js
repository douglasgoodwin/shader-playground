import { test, expect } from '@playwright/test'

const FIXTURE = 'tests/fixtures/test.mp4'

const PAGES = [
    { path: '/kaleidoscope/', recW: 1920, recH: 1080, needsMedia: true },
    { path: '/whitney/',      recW: 1920, recH: 1080 },
    { path: '/landscape/',    recW: 1920, recH: 1080 },
    { path: '/pollen/',       recW: 1920, recH: 1080 },
    { path: '/geometries/',   recW: 1920, recH: 1080 },
    { path: '/slitscan/',     recW: 1920, recH: 1080, needsMedia: true, settleMs: 1500 },
    { path: '/warps/',        recW: 1920, recH: 1080, needsMedia: true,
      extraInputs: ['#bg-file-input'] },
]

async function loadFixture(page, selector = '#file-input') {
    await page.setInputFiles(selector, FIXTURE)
    // media-loader creates a detached <video>, so we can't query it.
    // Poll the canvas until non-black pixels appear (texture uploaded + drawn).
    await page.waitForFunction(() => {
        const c = document.querySelector('#canvas')
        const gl = c.getContext('webgl2') || c.getContext('webgl')
        const px = new Uint8Array(4)
        gl.readPixels((c.width / 2) | 0, (c.height / 2) | 0, 1, 1,
                      gl.RGBA, gl.UNSIGNED_BYTE, px)
        return px[0] + px[1] + px[2] > 30
    }, { timeout: 8000 })
}

for (const { path, recW, recH, needsMedia, extraInputs, settleMs = 300 } of PAGES) {
    test(`${path} records at ${recW}x${recH} with viewport coverage`, async ({ page }) => {
        await page.goto(path)
        await page.waitForSelector('#canvas')
        await page.waitForTimeout(400)

        if (needsMedia) {
            await loadFixture(page)
            for (const sel of extraInputs ?? []) {
                await page.setInputFiles(sel, FIXTURE)
            }
            await page.waitForTimeout(200)
        }

        const before = await page.evaluate(() => {
            const c = document.querySelector('#canvas')
            return { w: c.width, h: c.height }
        })

        await page.click('#record-btn')
        await page.waitForTimeout(settleMs)

        const after = await page.evaluate(() => {
            const c = document.querySelector('#canvas')
            const gl = c.getContext('webgl2') || c.getContext('webgl')
            const pixels = new Uint8Array(c.width * 4)
            gl.readPixels(0, (c.height / 2) | 0, c.width, 1,
                          gl.RGBA, gl.UNSIGNED_BYTE, pixels)
            let bright = 0
            for (let i = 0; i < pixels.length; i += 4) {
                if (pixels[i] + pixels[i+1] + pixels[i+2] > 30) bright++
            }
            return { w: c.width, h: c.height, brightFraction: bright / c.width }
        })

        expect(after.w).toBe(recW)
        expect(after.h).toBe(recH)
        expect(before.w).not.toBe(recW)
        expect(after.brightFraction).toBeGreaterThan(0.1)

        await page.click('#record-btn')
    })
}
