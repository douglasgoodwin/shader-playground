# Shader Playground

Research and experiments for a CalArts course in vibecoding shaders.

## About

This project explores real-time GLSL shader programming through interactive visualizations, with a focus on computational cinema pioneers like John and James Whitney.

## Structure

- **/** - Landing page with animated color field
- **/playground/** - Interactive shader effects with parameter controls
- **/geometries/** - Raymarched 3D geometry explorations
- **/whitney/** - Collection inspired by Whitney brothers' computational films
- **/glyphs/** - ASCII art rendering and symbol morphing
- **/tiles/** - Voronoi, hexgrid, and tiling patterns
- **/stipple/** - Hodgin-style stippling for webcam/images
- **/particles/** - GPU particle simulations (boids, physics)
- **/characters/** - Animated shader creatures
- **/landscape/** - Raymarched terrain with lightning storms
- **/displace/** - Vertex displacement with image textures
- **/warps/** - Image warping effects
- **/exercises/** - Scaffolded shader exercises for learning GLSL
- **/docs/** - Course notes and reference materials

## Playground Effects

8 shader effects exploring 2D patterns and simulations:

| Effect | Description |
|--------|-------------|
| Ripple | Concentric waves from center |
| Plasma | Classic demoscene color cycling |
| Warp | Distorted UV coordinates |
| Kaleidoscope | Radial symmetry reflections |
| Noise | Fractal noise on a sphere ("boiling methane sea") |
| Drive | Rainy night driving with bokeh lights |
| Firefly | Particle fireflies with blinking |
| Phyllotaxis | Golden angle (137.5°) seed arrangement pattern |

## Geometries

12 shaders exploring signed distance functions and procedural effects:

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
| WaterRipple | Text grid distorted by water droplet ripples |
| PoolWater | Caustic light patterns through water |
| FlowHeart | Morphing heart with flow field |
| Phyllotaxis | Golden angle (137.5°) 3D seed dome |

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

## Glyphs

5 modes exploring ASCII art, letterforms, and symbol morphing:

| Mode | Description |
|------|-------------|
| Waves | Animated ASCII wave pattern with split-screen comparison |
| Image | Convert any image to ASCII (drag/drop or URL) |
| Platonic | Raymarched Platonic solids in ASCII |
| Cube | Rotating cube with per-face characters |
| Glyphs | SDF symbols (circle, cross, triangle, diamond, star) morphing between forms |

### How It Works

Instead of mapping brightness to character density (`. : - = + * # @`), this approach uses **6D shape vectors** that describe WHERE the density is within each character cell:

1. Divide each cell into 6 regions (2x3 staggered grid)
2. Sample brightness at each region
3. Find the character whose shape vector is closest (Euclidean distance in 6D space)
4. Render using a font texture atlas for crisp, readable characters

This allows ASCII characters to follow contours and edges, not just represent overall darkness.

### Resources

- [Alex Harri - Rethinking Text Rendering](https://alexharri.com/blog/ascii-rendering) - The technique implemented here

## Tiles

4 tiling and cellular pattern effects:

| Effect | Description |
|--------|-------------|
| Voronoi | Cellular noise pattern |
| HexGrid | Hexagonal tiling |
| Tiles | Geometric tile patterns with rotation |
| Varitiles | Grid of tiles with per-cell random shape, rotation, color, and scale |

## Stipple Renderer

Real-time stippling effect inspired by Robert Hodgin's (flight404) magnetic particle algorithm from ~2009.

| Mode | Description |
|------|-------------|
| Webcam | Live stippling of webcam feed |
| Image | Stipple any image (drag/drop or URL) |

### Hodgin's Original Algorithm

Hodgin's approach used physics simulation:
1. Populate space with magnetic particles that repel each other
2. Each particle checks the underlying image brightness
3. **Dark areas**: particles shrink, magnetic charge weakens, allowing tighter packing
4. **Light areas**: particles grow larger, stronger charge pushes them apart
5. Particles settle organically into a stippled pattern
6. Optional: draw thin lines between nearby particles

### Shader Approximation

Since real-time particle simulation isn't feasible in a fragment shader, this implementation approximates the effect:

1. **Multi-scale grids** - Three overlapping grids at different densities. Finer grids only activate in darker areas, mimicking how smaller particles pack tightly
2. **Luminance-based sizing** - Dot radius scales with local brightness (larger dots = more ink in dark areas)
3. **Pseudo-random jitter** - Hash-based offsets break grid regularity for organic feel
4. **Grey background** - Middle-value canvas allows dots to paint both light and dark
5. **Optional line connections** - Thin lines between nearby dots in dark regions

### Controls

- **Density** - Grid resolution (more/fewer dots)
- **Dot Size** - Overall scale multiplier
- **Contrast** - Boost luminance range of source
- **Lines** - Toggle connecting lines between nearby dots
- **Invert** - White dots on dark background

### Resources

- [Robert Hodgin's Stippling](http://roberthodgin.com/project/stippling) - Original inspiration

## Characters

Animated shader creatures using 2D distance fields and procedural animation.

| Character | Description |
|-----------|-------------|
| Frightened | Six pastel blobs with repulsion physics, nervously huddling together |
| Stickfolk | Stick figures from line/circle SDFs — walking, waving, jumping |

### Techniques

**Frightened:**
- **Repulsion physics** - Blobs push away from each other to avoid overlap
- **Procedural animation** - Nervous trembling, orbital movement, individual jitter
- **Per-creature eyes** - Each blob has its own pair of eyes looking the same direction

**Stickfolk:**
- **Line-segment SDFs** - Body, arms, and legs built from line segments with rounded caps
- **Action cycling** - Each figure walks, waves, or jumps based on its phase offset
- **Mouse tracking** - Heads turn toward the cursor

## Landscape

Raymarched terrain scenes.

| Piece | Description |
|-------|-------------|
| Lightning | Multi-plane dark landscape illuminated by simplex noise lightning bolts |
| Sand | Procedural sand dunes with wavy ripple texture, slow circular pan (adapted from Shane's "Desert Sand") |

### Techniques

**Lightning:**
- **Multi-plane compositing** - Three depth layers (sky → far hills → near hills) with the lightning bolt rendered between them for a theatrical silhouette effect
- **Simplex noise bolts** - Vertical lightning generated from 3D simplex FBM, producing organic, jagged bolt shapes
- **Flash timing** - Three overlapping strike intervals create irregular, natural-feeling lightning patterns with sharp attack and exponential decay
- **Terrain raymarching** - Two independent noise-based heightfields at different scales and offsets for foreground and background hill layers

**Sand:**
- **Dune generation** - Layered smoothstep noise with triangle-wave ridgelines for rounded dune shapes
- **Sand ripple texture** - Two rotated gradient line layers perturbed by noise and screen-blended for realistic wavy sand patterns
- **Bump-mapped surface** - Ripple pattern follows terrain contours via terrain-gradient perturbation
- **Circular panning camera** - Slow orbit over the dunes with terrain-following height, no flying

### Controls

- **Speed** - Animation rate (storm timing / camera orbit speed)
- **Intensity** - Lightning flash brightness / sun scatter strength
- **Near Hills** - Terrain height scale
- **Camera Height** - Raise or lower the viewpoint

## Displace

Vertex-displaced subdivided plane with image texture mapping — the first section using true 3D geometry rather than fullscreen quads.

| Piece | Description |
|-------|-------------|
| Terrain | 128x128 subdivided plane with simplex FBM vertex displacement |

### Techniques

- **Subdivided plane mesh** - 129x129 vertices (16,641) with indexed triangles via `gl.drawElements`, generated in JS
- **Simplex noise displacement** - 3D simplex FBM (4 octaves) pushes vertices along Y based on XZ position + time
- **Finite-difference normals** - Normals computed in the vertex shader by sampling noise at nearby points for accurate directional lighting
- **Minimal matrix math** - Perspective projection and lookAt view matrix implemented without dependencies (~30 lines)
- **Orbiting camera** - Slow automatic orbit around the terrain
- **Image texture mapping** - Upload/drop an image to map it onto the deformed surface; fallback gradient (blue → sand → snow) when no image is loaded

### Controls

- **Displacement** - Height of the noise-based vertex displacement
- **Noise Scale** - Frequency of the noise pattern (higher = more detailed terrain)
- **Speed** - Animation speed of the noise displacement

## Particles

GPU-accelerated particle simulations using ping-pong framebuffer techniques.

| Simulation | Description |
|------------|-------------|
| Murmuration | Starling flock using Boids algorithm (separation, alignment, cohesion) |
| Ragdoll | Verlet integration physics with distance constraints |

### How It Works

Both simulations store particle state in textures and update via fragment shaders:

1. **Ping-pong buffers** - Two textures alternate as read/write targets each frame
2. **Position/velocity encoding** - Particle data packed into RGBA channels
3. **GPU parallelism** - Each texel computes one particle independently

**Murmuration (Boids):**
- 4,096 particles (64x64 texture)
- Each particle samples neighbors and applies three steering forces
- Hartman & Benes "change of leadership" — random birds temporarily become leaders who suppress cohesion/alignment and steer independently, pulling nearby birds along and creating organic flock splitting/reforming
- Leadership timer stored in velocity texture alpha channel (no extra textures needed)
- Triangular sprites oriented to velocity direction
- Twilight sky background with atmospheric depth

**Ragdoll (Verlet):**
- 64 stick figures, 16 joints each
- Verlet integration: `newPos = pos + (pos - prevPos) * damping + accel * dt²`
- Data-driven constraint table — skeleton topology defined once as a `vec3` array, iterated with a loop instead of per-particle if/else branching
- 8 constraint-solving passes per frame to maintain bone lengths
- Floor collision and mouse repulsion

### Controls

- **Murmuration**: Separation, Cohesion, Alignment sliders
- **Ragdoll**: Gravity, Damping sliders
- Mouse interaction affects both simulations

## Exercises

Scaffolded shader exercises for learning GLSL fundamentals, organized by concept:

| Group | Exercises | Concepts |
|-------|-----------|----------|
| Basics | Color Mixing, Gradient | `gl_FragColor`, `gl_FragCoord`, RGB |
| Variables | Store & Reuse, Order | Variable declaration, operation order |
| Math | Sin Wave, Mix, Step | `sin()`, `mix()`, `step()`, `smoothstep()` |
| Shapes | Circle, Circles, Rectangle | Distance fields, `length()`, coordinate math |
| Animation | Pulse, Move, Color Cycle | `u_time`, animated parameters |
| Symmetry | Halves, Quadrants | `abs()`, coordinate mirroring |
| Grids | Row, Grid | `fract()`, `mod()`, tiling |
| Functions | Circle Fn, Ring Fn | Reusable GLSL functions |
| Challenges | Traffic Light, Spinner, Sunset, Spotlight | Combined techniques |
| Hash | Basics, Hoskins, Applications | Procedural randomness foundations |
| Noise | Value, Gradient, FBM | Smooth noise and layered fractals |
| Raymarching | Basics, SDF Shapes, Smooth Blend | 3D rendering with distance fields |

### Progression

Exercises build incrementally:
1. Start with basic color output
2. Add position-based gradients
3. Introduce math functions for curves
4. Build shapes using distance
5. Animate with time
6. Create patterns with repetition
7. Abstract into reusable functions
8. Combine everything in challenges
9. **Intermediate**: Hash functions—the foundation for noise, Voronoi, and procedural textures

Each exercise is a complete, runnable shader demonstrating one concept.

### Intermediate Track

The intermediate exercises are based on techniques from advanced Shadertoy shaders like ["Desert Passage II" by Farbs](https://www.shadertoy.com/view/3cVBzy). They bridge the gap between basic exercises and professional shader code.

#### Hash Functions (Level 9)
Deterministic randomness—the foundation of all procedural graphics.

- **ex9-1 Basics**: Simple sin-based hash, magic numbers (43758.5453), grid visualization
- **ex9-2 Hoskins**: Dave Hoskins' "Hash without Sine"—why it's more reliable with large values
- **ex9-3 Applications**: Stippling, jittered grids, sparkle effects, multi-scale patterns

#### Noise (Level 10)
Smooth, organic patterns for terrain, clouds, and textures.

- **ex10-1 Value Noise**: Interpolated random values with cubic smoothstep
- **ex10-2 Gradient Noise**: Ken Perlin's approach via IQ's implementation (quintic smoothing)
- **ex10-3 FBM**: Fractal Brownian Motion—layered octaves (2× frequency, 0.5× amplitude)

#### Raymarching (Level 11)
3D rendering with distance fields instead of polygons.

- **ex11-1 Basics**: Sphere tracing algorithm, camera setup, diffuse lighting
- **ex11-2 SDF Shapes**: IQ's distance functions (sphere, box, torus, cylinder, plane)
- **ex11-3 Smooth Blend**: `smin()`/`smax()` for organic metaball-style blending

#### Why These Techniques Matter

These nine exercises cover the core toolkit used in professional shader code:

| Desert Passage II Function | Exercise | What You Learn |
|---------------------------|----------|----------------|
| `hash22()` | ex9-2 | Dave Hoskins' reliable hash |
| `gradN2D()` | ex10-2 | Gradient noise for perturbation |
| `fBm()` | ex10-3 | Layered noise for terrain/clouds |
| `trace()` | ex11-1 | Raymarching loop (120 iterations) |
| `sdSphere()`, `sdBox()` | ex11-2 | Signed distance functions |
| `smax()` | ex11-3 | Smooth blending for terrain |

After completing these exercises, you'll be able to read and understand most advanced Shadertoy shaders.

**Coming soon**: Voronoi, lighting, shadows, the sand ripple pattern

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
