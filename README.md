# Shader Playground

Research and experiments for a CalArts course in vibecoding shaders.

## About

This project explores real-time GLSL shader programming through interactive visualizations, with a focus on computational cinema pioneers like John and James Whitney.

## Structure

- **/** - Landing page with animated color field
- **/playground/** - Interactive shader effects with parameter controls
- **/whitney/** - Collection inspired by Whitney brothers' computational films

## Playground Effects

15 shader effects including ripples, plasma, voronoi, truchet tiles, raymarching, Mandelbulb fractal, hyperbolic geometry, reaction-diffusion, and more.

## Whitney Collection

8 pieces exploring harmonic motion and "differential dynamics":

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
