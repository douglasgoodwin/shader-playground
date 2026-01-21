# Shader Playground

Research and experiments for a CalArts course in vibecoding shaders.

## About

This project explores real-time GLSL shader programming through interactive visualizations, with a focus on computational cinema pioneers like John and James Whitney.

## Structure

- **/** - Landing page with animated color field
- **/playground/** - Interactive shader effects with parameter controls
- **/geometries/** - Raymarched 3D geometry explorations
- **/whitney/** - Collection inspired by Whitney brothers' computational films
- **/ascii/** - ASCII art rendering using 6D shape vectors

## Playground Effects

10 shader effects exploring 2D patterns and simulations:

| Effect | Description |
|--------|-------------|
| Ripple | Concentric waves from center |
| Plasma | Classic demoscene color cycling |
| Warp | Distorted UV coordinates |
| Voronoi | Cellular noise pattern |
| HexGrid | Hexagonal tiling |
| Tiles | Geometric tile patterns |
| Kaleidoscope | Radial symmetry reflections |
| Noise | Fractal noise on a sphere ("boiling methane sea") |
| Drive | Rainy night driving with bokeh lights |
| Firefly | Particle fireflies with blinking |

## Geometries

8 raymarched 3D shaders exploring signed distance functions:

| Piece | Description |
|-------|-------------|
| Gyroid | Triply periodic minimal surface |
| Penrose | Impossible triangle construction |
| Mandelbulb | 3D fractal extension of Mandelbrot |
| Cylinder | Infinite cylindrical tunnels |
| Raymarch | Smooth-blended primitive shapes |
| Oscillate | Pulsing sphere with displacement |
| Kelp | Underwater ribbon strands (modified Ropes) |
| TriVoronoi | Animated triangular Voronoi cells |

### Raymarching Notes

These shaders use sphere tracing to render implicit surfaces. Key parameters:

- **Step size** (`t += min(h.x, 0.3) * 0.5`) - smaller = smoother but slower
- **MAX_STEPS** - more iterations reach further, cost performance
- **Spacing** (in `mod()`) - controls density of repeated geometry
- **Fog** (`exp(-0.08 * res.x)`) - distance fade intensity

## Whitney Collection

9 pieces exploring harmonic motion and "differential dynamics":

| Piece | Source |
|-------|--------|
| Lapis | Inspired by James Whitney's 1966 film |
| Permutations | John Whitney's rainbow Lissajous patterns |
| Matrix | Grid transformations |
| Arabesque | From "Digital Harmony" (Rother/Whitney) |
| Columna | From "Digital Harmony" (Rother/Whitney) |
| Spiral | From "Digital Harmony" (Rother/Whitney) |
| Music Box | Jim Bumgardner's interpretation |
| Trails | Music Box with motion blur |
| Fractal | Iterative UV fractal with cosine palette |

## ASCII Renderer

4 modes exploring ASCII art rendering using Alex Harri's 6D shape vector approach:

| Mode | Description |
|------|-------------|
| Waves | Animated wave pattern with split-screen comparison |
| Image | Convert any image to ASCII (drag/drop or URL) |
| Platonic | Raymarched Platonic solids in ASCII |
| Cube | Rotating cube with per-face characters |

### How It Works

Instead of mapping brightness to character density (`. : - = + * # @`), this approach uses **6D shape vectors** that describe WHERE the density is within each character cell:

1. Divide each cell into 6 regions (2x3 staggered grid)
2. Sample brightness at each region
3. Find the character whose shape vector is closest (Euclidean distance in 6D space)
4. Render using a font texture atlas for crisp, readable characters

This allows ASCII characters to follow contours and edges, not just represent overall darkness.

### Resources

- [Alex Harri - Rethinking Text Rendering](https://alexharri.com/blog/ascii-rendering) - The technique implemented here

## Recording

All shader pages support MP4 video recording:
- Click the red record button (top-right)
- Or press **R** to toggle recording
- Uses WebCodecs API for hardware-accelerated H.264 encoding

## Running Locally

```bash
npm install
npm run dev
```

## Resources

- [The Book of Shaders](https://thebookofshaders.com)
- [Whitney Music Box Examples](https://github.com/jbum/Whitney-Music-Box-Examples)
- [Inigo Quilez - Shader Articles](https://iquilezles.org/articles/)
- [Shadertoy](https://www.shadertoy.com)

## Tech

- Vite + vite-plugin-glsl
- WebGL 1.0
- GLSL ES 1.0
