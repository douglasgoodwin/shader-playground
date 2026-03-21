// Flow-field scribble: traces a continuous pen path through a noise field,
// with loop density driven by image luminance.
// Dark areas → tight chaotic loops, light areas → sparse open curves.

// ---- Perlin Noise ----
const P = new Uint8Array(512)
const G = [[1,1],[-1,1],[1,-1],[-1,-1],[1,0],[-1,0],[0,1],[0,-1]]
{
    const p = Array.from({ length: 256 }, (_, i) => i)
    let s = 42
    for (let i = 255; i > 0; i--) {
        s = (s * 16807) % 2147483647
        const j = s % (i + 1)
        ;[p[i], p[j]] = [p[j], p[i]]
    }
    for (let i = 0; i < 512; i++) P[i] = p[i & 255]
}

function fade(t) { return t * t * t * (t * (t * 6 - 15) + 10) }

function noise(x, y) {
    const X = Math.floor(x), Y = Math.floor(y)
    const xi = X & 255, yi = Y & 255
    const xf = x - X, yf = y - Y
    const u = fade(xf), v = fade(yf)
    const g00 = G[P[P[xi] + yi] & 7]
    const g10 = G[P[P[xi + 1] + yi] & 7]
    const g01 = G[P[P[xi] + yi + 1] & 7]
    const g11 = G[P[P[xi + 1] + yi + 1] & 7]
    const n00 = g00[0] * xf + g00[1] * yf
    const n10 = g10[0] * (xf - 1) + g10[1] * yf
    const n01 = g01[0] * xf + g01[1] * (yf - 1)
    const n11 = g11[0] * (xf - 1) + g11[1] * (yf - 1)
    const nx0 = n00 + u * (n10 - n00)
    const nx1 = n01 + u * (n11 - n01)
    return nx0 + v * (nx1 - nx0)
}

function fbm(x, y, octaves) {
    let val = 0, amp = 1, max = 0
    for (let i = 0; i < octaves; i++) {
        val += noise(x, y) * amp
        max += amp
        amp *= 0.5
        x *= 2.0; y *= 2.0
    }
    return val / max
}

// ---- Luminance extraction ----
// Downsamples to maxWidth for performance (especially for video frames)
const _offscreen = document.createElement('canvas')
const _offCtx = _offscreen.getContext('2d')

export function extractLuminance(source, contrast = 1.5, maxWidth = 512) {
    const sw = source.width || source.videoWidth
    const sh = source.height || source.videoHeight
    const scale = Math.min(1, maxWidth / sw)
    const w = Math.round(sw * scale)
    const h = Math.round(sh * scale)
    _offscreen.width = w; _offscreen.height = h
    _offCtx.drawImage(source, 0, 0, w, h)
    const { data } = _offCtx.getImageData(0, 0, w, h)
    const lum = new Float32Array(w * h)
    for (let i = 0; i < w * h; i++) {
        let l = 0.299 * data[i * 4] / 255 + 0.587 * data[i * 4 + 1] / 255 + 0.114 * data[i * 4 + 2] / 255
        l = (l - 0.5) * contrast + 0.5
        lum[i] = Math.max(0, Math.min(1, l))
    }
    return { luminance: lum, width: w, height: h }
}

// ---- Sample darkness with cover-mode aspect correction ----
function sampleDarkness(lumData, x, y, W, H) {
    if (!lumData) return 0.3
    const { luminance, width: iw, height: ih } = lumData
    let u = x / W, v = y / H
    const ca = W / H, ta = iw / ih
    if (ca > ta) { v = (v - 0.5) * (ta / ca) + 0.5 }
    else { u = (u - 0.5) * (ca / ta) + 0.5 }
    u = Math.max(0, Math.min(0.9999, u))
    v = Math.max(0, Math.min(0.9999, v))
    return 1.0 - luminance[~~(v * ih) * iw + ~~(u * iw)]
}

// ---- Zigzag simulation (original) ----
export function runSimulation(canvas, lumData, params = {}) {
    const {
        lineCount = 40,
        noiseFreq = 0.008,
        loopStrength = 1.0,
        strokeWeight = 0.8,
        time = 0,
    } = params

    const ctx = canvas.getContext('2d')
    const W = canvas.width, H = canvas.height

    ctx.fillStyle = 'white'
    ctx.fillRect(0, 0, W, H)

    const spacing = H / lineCount
    const rows = Math.ceil(lineCount) + 1
    const speed = 1.5

    ctx.strokeStyle = 'rgba(0, 0, 0, 0.6)'
    ctx.lineWidth = strokeWeight
    ctx.lineCap = 'round'
    ctx.lineJoin = 'round'
    ctx.beginPath()

    let first = true

    for (let row = 0; row < rows; row++) {
        const right = row % 2 === 0
        const baseY = (row + 0.5) * spacing
        let px = right ? -5 : W + 5
        let py = baseY

        if (first) { ctx.moveTo(px, py); first = false }
        else { ctx.lineTo(px, py) }

        const maxSteps = W * 8

        for (let s = 0; s < maxSteps; s++) {
            const dark = sampleDarkness(lumData, px, py, W, H)

            // Noise-based angle with time offset for animation
            const f = noiseFreq
            const t = time
            const a1 = fbm(px * f + t * 0.3, py * f + t * 0.2, 3) * Math.PI * 4
            const a2 = noise(px * f * 3.1 + 73 + t * 0.5, py * f * 3.1 + 37 + t * 0.3) * Math.PI * 2

            const angle = a1 + a2 * dark * 0.7

            const fwd = 0.15 + (1.0 - dark) * 0.85
            const loop = dark * 1.3 * loopStrength

            const baseAngle = right ? 0 : Math.PI
            const dx = Math.cos(baseAngle) * fwd + Math.cos(angle) * loop
            const dy = Math.sin(angle) * loop

            const mag = Math.sqrt(dx * dx + dy * dy) || 1
            px += (dx / mag) * speed
            py += (dy / mag) * speed

            ctx.lineTo(px, py)

            if (right && px > W + 5) break
            if (!right && px < -5) break
        }
    }

    ctx.stroke()
}

// ---- Curl noise walk simulation ----
// A single pen follows a curl noise velocity field.
// Coverage comes from a gentle drift toward a zigzag target.
// Dark areas: curl dominates → organic loops. Light areas: drift dominates → sparse passes.
export function runCurlSimulation(canvas, lumData, params = {}) {
    const {
        lineCount = 40,
        noiseFreq = 0.008,
        loopStrength = 1.0,
        strokeWeight = 0.8,
        time = 0,
    } = params

    const ctx = canvas.getContext('2d')
    const W = canvas.width, H = canvas.height

    ctx.fillStyle = 'white'
    ctx.fillRect(0, 0, W, H)

    // Total steps scales with canvas area and density
    const totalSteps = Math.round(W * H * 0.15 * lineCount / 30)

    // Coverage: target follows a zigzag path across the canvas
    const rows = Math.max(Math.round(lineCount), 5)
    const spacing = H / rows

    function zigzagTarget(progress) {
        const seg = progress * rows
        const idx = Math.min(~~seg, rows - 1)
        const t = seg - idx
        const right = idx % 2 === 0
        return {
            x: right ? t * W : (1 - t) * W,
            y: (idx + 0.5) * spacing,
        }
    }

    const f = noiseFreq
    const ne = 0.01 // epsilon for curl derivative

    // Start near top-left
    let px = 10, py = spacing * 0.5

    ctx.strokeStyle = 'rgba(0, 0, 0, 0.6)'
    ctx.lineWidth = strokeWeight
    ctx.lineCap = 'round'
    ctx.lineJoin = 'round'
    ctx.beginPath()
    ctx.moveTo(px, py)

    for (let s = 0; s < totalSteps; s++) {
        const dark = sampleDarkness(lumData, px, py, W, H)
        const progress = s / totalSteps

        // Coverage target
        const target = zigzagTarget(progress)
        const tdx = target.x - px
        const tdy = target.y - py
        const tdist = Math.sqrt(tdx * tdx + tdy * tdy) || 1

        // True curl noise: velocity from potential field gradient
        const nx = px * f + time * 0.2
        const ny = py * f + time * 0.15
        const dPdy = (fbm(nx, ny + ne, 2) - fbm(nx, ny - ne, 2)) / (2 * ne)
        const dPdx = (fbm(nx + ne, ny, 2) - fbm(nx - ne, ny, 2)) / (2 * ne)
        let curlVx = dPdy
        let curlVy = -dPdx
        const cmag = Math.sqrt(curlVx * curlVx + curlVy * curlVy) || 1
        curlVx /= cmag
        curlVy /= cmag

        // Dark areas: curl dominates (organic loops)
        // Light areas: drift dominates (follows coverage target)
        const curlWeight = dark * loopStrength * 2.5
        const driftWeight = 0.2 + (1 - dark) * 0.8

        let vx = (tdx / tdist) * driftWeight + curlVx * curlWeight
        let vy = (tdy / tdist) * driftWeight + curlVy * curlWeight

        // Speed: slower in dark areas (tight loops), faster in light
        const speed = 2.0 + (1 - dark) * 4.0
        const mag = Math.sqrt(vx * vx + vy * vy) || 1
        px += (vx / mag) * speed
        py += (vy / mag) * speed

        // Soft boundary clamping
        if (px < 0) px = 1
        if (px > W) px = W - 1
        if (py < 0) py = 1
        if (py > H) py = H - 1

        ctx.lineTo(px, py)
    }

    ctx.stroke()
}

// ---- Points simulation ----
// Scatter points, score by darkness, connect darkest via nearest-neighbor,
// draw as Catmull-Rom spline. Dark areas get dense connections, light areas sparse.
export function runPointsSimulation(canvas, lumData, params = {}) {
    const {
        lineCount = 40,
        noiseFreq = 0.008,
        loopStrength = 1.0,
        strokeWeight = 0.8,
        time = 0,
        neighborRank = 1,
    } = params

    const ctx = canvas.getContext('2d')
    const W = canvas.width, H = canvas.height

    ctx.fillStyle = 'white'
    ctx.fillRect(0, 0, W, H)

    // Seeded PRNG for reproducible jitter
    let seed = 12345 + ~~(time * 100)
    function rand() {
        seed = (seed * 16807) % 2147483647
        return (seed - 1) / 2147483646
    }

    // Generate evenly distributed points (jittered grid)
    const totalPoints = Math.round(10000 * lineCount / 30)
    const aspect = W / H
    const cols = Math.round(Math.sqrt(totalPoints * aspect))
    const rows = Math.round(totalPoints / cols)
    const cellW = W / cols
    const cellH = H / rows

    const candidates = []
    for (let r = 0; r < rows; r++) {
        for (let c = 0; c < cols; c++) {
            const jitter = 0.8
            const x = (c + 0.5 + (rand() - 0.5) * jitter) * cellW
            const y = (r + 0.5 + (rand() - 0.5) * jitter) * cellH
            const dark = sampleDarkness(lumData, x, y, W, H)
            candidates.push({ x, y, dark })
        }
    }

    // Select points probabilistically based on darkness
    const selected = candidates.filter(p => rand() < p.dark * loopStrength * 1.5)

    if (selected.length < 3) return

    // Kth-nearest-neighbor greedy path
    const n = selected.length
    const k = Math.min(neighborRank, n - 1) // can't exceed available points
    const visited = new Uint8Array(n)
    const order = new Int32Array(n)
    order[0] = 0
    visited[0] = 1

    for (let step = 1; step < n; step++) {
        const last = order[step - 1]
        const px = selected[last].x, py = selected[last].y

        // Find the k nearest unvisited neighbors
        const remaining = n - step
        const kk = Math.min(k, remaining) // clamp to available
        const topK = [] // { idx, d }, kept sorted ascending by distance

        for (let i = 0; i < n; i++) {
            if (visited[i]) continue
            const dx = selected[i].x - px
            const dy = selected[i].y - py
            const d = dx * dx + dy * dy

            if (topK.length < kk) {
                topK.push({ idx: i, d })
                // Insertion sort to keep sorted
                for (let j = topK.length - 1; j > 0 && topK[j].d < topK[j - 1].d; j--) {
                    const tmp = topK[j]; topK[j] = topK[j - 1]; topK[j - 1] = tmp
                }
            } else if (d < topK[kk - 1].d) {
                topK[kk - 1] = { idx: i, d }
                for (let j = kk - 1; j > 0 && topK[j].d < topK[j - 1].d; j--) {
                    const tmp = topK[j]; topK[j] = topK[j - 1]; topK[j - 1] = tmp
                }
            }
        }

        // Pick the Kth nearest (last in the sorted list)
        const chosen = topK[topK.length - 1]
        visited[chosen.idx] = 1
        order[step] = chosen.idx
    }

    // Build ordered point list
    const path = new Array(n)
    for (let i = 0; i < n; i++) {
        path[i] = selected[order[i]]
    }

    // Draw Catmull-Rom spline through ordered points
    const smooth = noiseFreq / 0.006 // ellipse slider controls curve smoothness

    ctx.strokeStyle = 'rgba(0, 0, 0, 0.6)'
    ctx.lineWidth = strokeWeight
    ctx.lineCap = 'round'
    ctx.lineJoin = 'round'
    ctx.beginPath()
    ctx.moveTo(path[0].x, path[0].y)

    for (let i = 0; i < n - 1; i++) {
        const p0 = path[Math.max(0, i - 1)]
        const p1 = path[i]
        const p2 = path[i + 1]
        const p3 = path[Math.min(n - 1, i + 2)]

        // Catmull-Rom to cubic bezier control points
        const t = smooth / 6
        const cp1x = p1.x + (p2.x - p0.x) * t
        const cp1y = p1.y + (p2.y - p0.y) * t
        const cp2x = p2.x - (p3.x - p1.x) * t
        const cp2y = p2.y - (p3.y - p1.y) * t

        ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, p2.x, p2.y)
    }

    ctx.stroke()
}
