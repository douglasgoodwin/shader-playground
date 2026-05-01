# Exporting ProRes for Festival Delivery

Festivals (Bijou, in this case) typically request Apple ProRes 422, ProRes 422 HQ, or ProRes 4444 as a delivery format. The Shader Playground recorder cannot write ProRes directly — no browser can. This document explains why, and lays out the two practical paths to a ProRes master.

## Why the browser can't write ProRes

The recorder uses the WebCodecs API (`VideoEncoder`) with an MP4 muxer. WebCodecs is the only standardized way for browsers to access hardware-accelerated video encoding, and the spec only supports a fixed set of codecs:

- H.264 (AVC)
- H.265 (HEVC)
- VP8
- VP9
- AV1

ProRes is Apple's proprietary intermediate codec. No browser implements a ProRes encoder, and the MP4 container we mux into can't wrap ProRes anyway (ProRes lives in a `.mov` QuickTime container).

The realistic path is: **record a high-quality intermediate in the browser, then transcode to ProRes locally with ffmpeg.** ffmpeg has had a mature ProRes encoder (`prores_ks`) for over a decade.

## Option A — H.264 master → ProRes transcode

This is the easy path and is good enough for almost all festival use.

### 1. Record at high bitrate

The recorder defaults to 30 Mbps H.264. For a clean ProRes master, push it higher so the transcode isn't amplifying compression artifacts. 80–100 Mbps is a safe target — H.264 at that bitrate is visually transparent for shader content.

In `src/recorder.js`, the bitrate is set in the constructor:

```js
this.bitrate = options.bitrate || 30_000_000
```

Pass a higher value when constructing the recorder, or bump the default for festival exports.

### 2. Transcode with ffmpeg

Install ffmpeg (`brew install ffmpeg` on macOS), then run one of:

```bash
# ProRes 422 HQ (festival default — good quality/size balance)
ffmpeg -i shader-XXXX.mp4 -c:v prores_ks -profile:v 3 -pix_fmt yuv422p10le out.mov

# ProRes 422 (smaller, slightly lower quality)
ffmpeg -i shader-XXXX.mp4 -c:v prores_ks -profile:v 2 -pix_fmt yuv422p10le out.mov

# ProRes 4444 (highest quality, supports alpha, much larger files)
ffmpeg -i shader-XXXX.mp4 -c:v prores_ks -profile:v 4 -pix_fmt yuva444p10le out.mov
```

Profile numbers for `prores_ks`:

| Profile | Name        | Use case                                     |
|---------|-------------|----------------------------------------------|
| 0       | Proxy       | Offline editing only                         |
| 1       | LT          | Lightweight delivery                         |
| 2       | 422         | Standard broadcast                           |
| 3       | 422 HQ      | **Festival default**                         |
| 4       | 4444        | Mastering, alpha, color-critical work        |
| 5       | 4444 XQ     | Highest quality, rarely required             |

### Tradeoff

You're transcoding from a lossy source (H.264). The ProRes file will be visually identical to the H.264 master at 80+ Mbps, but it inherits any compression decisions the H.264 encoder made. For typical shader content this is invisible. For tight gradients or fine high-frequency detail, see Option B.

## Option B — PNG frame sequence → ProRes (implemented for slit-scan)

This is the lossless path. Use it when color fidelity matters or the shader has fine detail (stippling, slit-scan, anything where banding would be visible on a large screen).

### How it works

Instead of encoding video in the browser, the recorder writes each frame as a numbered PNG. PNG is lossless, so the ProRes encoder receives pristine pixels. The shader is also **frame-stepped** — its time uniform comes from a virtual frame counter (`frameIndex / fps`) rather than `performance.now()` — so the result is fully deterministic and independent of how fast your machine renders.

The implementation lives in `src/frame-recorder.js` (the `FrameRecorder` class). It is wired into the slit-scan page; other pages can adopt it by following the same pattern.

### Browser requirement

PNG sequence export uses the **File System Access API** (`window.showDirectoryPicker`). That's Chrome or Edge on desktop only. Safari and Firefox will show an alert and refuse — use Chrome for ProRes captures.

### Capturing on the slit-scan page

1. Open `/slitscan/` in Chrome.
2. Set up the shot — load the source image/video, dial in slit position, decay, sweep, etc.
3. Click the **square (blue) button** in the top-right, or press **`P`**.
4. The browser will prompt you to choose an output folder. Pick or create an empty one (e.g. `~/captures/bijou-2026/scene1/`).
5. **Priming phase.** The recorder first runs the shader without saving until the feedback buffer is full. The counter shows `priming 1234/1944 (63%)`. This is necessary because the feedback FBO starts black — the first ~3888 frames at `speed=1` (or ~1944 at `speed=2`, etc.) are mostly empty. Prime is auto-computed from the current `speed` slider and orientation.
6. **Capture phase.** Once priming completes, the counter switches to `frame 240 · 10.00s` and PNGs start landing in the chosen folder.
7. When you have enough footage, click the button again or press **`P`** to stop. The canvas resizes back to your window.

The folder will fill with `frame_000000.png`, `frame_000001.png`, ... at 3888×1080. Note: priming uses the slider values *at the moment you start*. If you change `speed` mid-capture the prime estimate doesn't adjust — start over if you want a different speed primed.

### Performance expectations

PNG encoding at 3888×1080 is heavy — expect roughly 0.5–2 seconds of wall-clock time per captured frame depending on your machine. Plan accordingly:

| Captured length | Frames | Wall clock (rough) | Disk (rough)    |
|-----------------|--------|--------------------|-----------------|
| 5 sec           | 120    | 1–4 min            | 0.6–1.8 GB      |
| 30 sec          | 720    | 6–24 min           | 3.6–11 GB       |
| 60 sec          | 1440   | 12–48 min          | 7–22 GB         |

The capture is deterministic — leave it running, come back when it's done. If you stop early the frames you already wrote are valid; they're written one-by-one.

### Transcoding to ProRes

After capture, in the folder of PNGs:

```bash
# ProRes 422 HQ — festival default
ffmpeg -framerate 24 -i frame_%06d.png \
  -c:v prores_ks -profile:v 3 -pix_fmt yuv422p10le \
  -vendor apl0 \
  bijou-scene1-prores422hq.mov

# ProRes 4444 — color-critical, larger files
ffmpeg -framerate 24 -i frame_%06d.png \
  -c:v prores_ks -profile:v 4 -pix_fmt yuv444p10le \
  -vendor apl0 \
  bijou-scene1-prores4444.mov
```

If your shader writes alpha and you want it preserved (rare for festival masters, useful for compositing):

```bash
ffmpeg -framerate 24 -i frame_%06d.png \
  -c:v prores_ks -profile:v 4 -pix_fmt yuva444p10le \
  -alpha_bits 16 -vendor apl0 out.mov
```

### Why this is the right path for a 33×11 ft screen

H.264 at any bitrate uses chroma subsampling (4:2:0) and DCT-domain compression that smears fine high-frequency detail. On a phone or laptop monitor this is invisible. At 33 ft × 11 ft, individual pixels are roughly the size of a quarter, and any compression artifact — banding in slit-scan smears, blocking on motion edges, chroma bleed on saturated colors — becomes a visible defect. The PNG-sequence path delivers full 8-bit-per-channel RGB to the ProRes encoder, and ProRes 422 HQ then preserves it at 10-bit 4:2:2 (220 Mbps for HD-ish, scales up for the 3888×1080 canvas). Nothing in the chain throws away spatial detail.

## Recommendation for Bijou

Use **Option B** — Bijou is projecting onto a 33×11 ft screen, which is exactly the case where H.264 compression artifacts become visible. The slit-scan page has the PNG sequence recorder wired up; press `P` to start.

## Sample festival-master command

End-to-end, assuming the recorder is bumped to 100 Mbps and produces `shader-20260430T120000.mp4`:

```bash
ffmpeg -i shader-20260430T120000.mp4 \
  -c:v prores_ks -profile:v 3 -pix_fmt yuv422p10le \
  -vendor apl0 \
  shader-20260430T120000-prores422hq.mov
```

The `-vendor apl0` tag makes the file identify as Apple-authored, which some older NLEs check for.
