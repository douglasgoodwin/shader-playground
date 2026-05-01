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

## Option B — PNG frame sequence → ProRes

This is the lossless path. Use it when color fidelity matters or the shader has fine detail (stippling, slit-scan, anything where banding would be visible).

### How it works

Instead of encoding video in the browser, we write each frame as a numbered PNG. PNG is lossless, so the ProRes encoder receives pristine pixels.

This is **not implemented in the recorder yet.** Adding it means a new mode that, per frame:

1. Calls `canvas.toBlob(blob => ..., 'image/png')`.
2. Saves it as `frame_00001.png`, `frame_00002.png`, etc. (likely via `showSaveFilePicker` or auto-download per frame to a chosen folder).

### Tradeoff

PNG encoding is slow — a single 3888×1080 frame takes 100ms+ to encode in software. The page can't run at 24 fps in realtime while writing PNGs. This is fine for deterministic shaders that can be stepped frame-by-frame (advance the clock by 1/24s, render, save, repeat) but breaks anything driven by realtime input (audio, MIDI, mouse).

If we add this mode, we should pair it with a "deterministic time" toggle: instead of `performance.now()`, the shader's time uniform comes from the frame counter. That guarantees reproducibility and decouples capture from realtime performance.

### Transcode

```bash
ffmpeg -framerate 24 -i frame_%05d.png \
  -c:v prores_ks -profile:v 3 -pix_fmt yuv422p10le out.mov
```

For 4444 with alpha (if the shader writes alpha):

```bash
ffmpeg -framerate 24 -i frame_%05d.png \
  -c:v prores_ks -profile:v 4 -pix_fmt yuva444p10le -alpha_bits 16 out.mov
```

## Recommendation for Bijou

Start with Option A at 80–100 Mbps. The visual difference after ProRes transcode is negligible for shader content unless the festival is projecting onto something very large or requesting alpha. If a specific piece shows banding or detail loss in review, escalate that one to Option B.

## Sample festival-master command

End-to-end, assuming the recorder is bumped to 100 Mbps and produces `shader-20260430T120000.mp4`:

```bash
ffmpeg -i shader-20260430T120000.mp4 \
  -c:v prores_ks -profile:v 3 -pix_fmt yuv422p10le \
  -vendor apl0 \
  shader-20260430T120000-prores422hq.mov
```

The `-vendor apl0` tag makes the file identify as Apple-authored, which some older NLEs check for.
