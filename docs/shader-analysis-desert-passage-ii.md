# Shader Analysis: Desert Passage II (Zoomy!)

**Author:** Farbs
**URL:** https://www.shadertoy.com/view/3cVBzy
**Type:** Raymarched tunnel flythrough with texture precalculation

---

## Overview

This is a sophisticated Shadertoy shader — a raymarched tunnel flythrough through a rocky desert landscape. It's an excellent example of advanced shader technique, and also a perfect illustration of the "artifacts" and influences discussed in the vibecoding essays.

The shader creates a procedural desert canyon with:
- A winding tunnel path through rocky terrain
- Realistic sand ripple patterns on the floor
- Volumetric rock textures using 3D Voronoi noise
- Motion blur, soft shadows, ambient occlusion
- Atmospheric fog and sky

---

## Structure

The shader has three parts:
1. **Common** — Shared functions, constants, and utility code
2. **CubeA** — The cubemap buffer that precalculates and stores 3D/2D functions at startup
3. **Image** — The main rendering pass that raymarches and reads from the cubemap

---

## The Core Innovation: Texture Precalculation

The expensive part (3D Voronoi and noise) is **precalculated once** and stored in cubemap texture faces. During realtime raymarching, it reads from the texture instead of computing on the fly. This is a significant optimization:

- **Face 0**: 3D volumetric data (100³ voxels packed into 1024² texture)
- **Face 1**: 2D surface heightmap data
- **Channel packing**: Neighboring values stored in RGBA channels, reducing texture lookups from 8 to 2 for smooth interpolation

### 3D to 2D Mapping

The `convert2DTo3D` function maps 2D texture coordinates to 3D voxel positions, allowing a 2D texture to store 3D volumetric data. From the code:

> "If you use all four channels of one 1024 by 1024 cube face, that would be 4096000 storage slots (1024*1024*4), which just so happens to be 160 cubed. In other words, you can store the isosurface values of a 160 voxel per side cube into one cube face of the cubemap."

---

## The Fingerprints: Common Solutions and Influences

This shader is a catalog of the well-documented solutions that appear throughout Shadertoy — exactly the kind of convergence we'd expect from vibecoded work:

| Technique | Source | Usage |
|-----------|--------|-------|
| Smooth min/max | Inigo Quilez | `smin`, `smax` functions — verbatim |
| Hash functions | Dave Hoskins | "Hash without Sine" — credited inline |
| Raymarching | IQ's standard approach | Sphere tracing with adaptive step size |
| Voronoi | IQ's article + Tomkh optimization | Edge distance calculation |
| Bump mapping | Standard 4-tap gradient | `doBumpMap` function |
| Soft shadows | IQ's penumbra technique | `softShadow` function |
| Ambient occlusion | IQ's 5-sample method | `calcAO` function |
| Normal calculation | IQ's tetrahedral method | Commented alternative in code |

### Explicit Credits in Code

The author credits their sources inline:

- **Inigo Quilez** — "Elevated" shader (Breakpoint 2009 winner), multiple utility functions
- **Dave Hoskins** — "Skin Peeler" coloring technique, hash functions ("Hash without Sine" under CC BY-SA 4.0)
- **Nimitz** — "Xyptonjtroz" shader, triangle wave functions
- **Tomkh** — Voronoi edge distance optimization ("Faster Voronoi Edge Distance")
- **Fizzer** — Cubemap coordinate conversion

### Referenced Shaders

From the comments:
- [Elevated - IQ](https://www.shadertoy.com/view/MdX3Rr) — "It won Breakpoint way back in 2009. For anyone not familiar with the demoscene, it's a big deal."
- [Skin Peeler - Dave Hoskins](https://www.shadertoy.com/view/XtfSWX) — "One of my favorite simple coloring jobs."
- [Xyptonjtroz - Nimitz](https://www.shadertoy.com/view/4ts3z2) — "One of my all time favorites"
- [Voronoi distances - IQ](https://www.shadertoy.com/view/ldl3W8)
- [Faster Voronoi Edge Distance - Tomkh](https://www.shadertoy.com/view/llG3zy)

---

## The Sand Pattern

The `sand()` and `sandL()` functions create realistic ripple patterns:

1. **Rotating and layering gradient lines** — Two layers rotated at different angles
2. **Perturbing with noise** — `gradN2D()` adds waviness to the lines
3. **Screen-blending layers** — `1. - (1. - grad1*a1)*(1. - grad2*a2)`
4. **Distance fade** — `return c1/(1. + gT*gT*.015)` prevents Moiré artifacts

From the comments:
> "A surprisingly simple and efficient hack to get rid of the super annoying Moiré pattern formed in the distance. Simply lessen the value when it's further away. Most people would figure this out pretty quickly, but it took me far too long before it hit me."

---

## Key Utility Functions

### Hash Functions

```glsl
// Dave Hoskins - "Hash without Sine"
// Creative Commons Attribution-ShareAlike 4.0 International Public License
vec2 hash22(vec2 p){
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 42.123);
    p = fract((p3.xx + p3.yz)*p3.zy)*2. - 1.;
    return p;
}
```

### Smooth Min/Max (IQ via Dave Smith/Media Molecule)

```glsl
// Commutative smooth minimum function. Provided by Tomkh, and taken
// from Alex Evans's (aka Statix) talk
float smin(float a, float b, float k){
   float f = max(0., 1. - abs(b - a)/k);
   return min(a, b) - k*.25*f*f;
}
```

### Gradient Noise (IQ's implementation)

```glsl
// Gradient noise. Ken Perlin came up with it, or a version of it.
// Either way, this is based on IQ's implementation.
float gradN2D(in vec2 f){
    // ... standard implementation
}
```

---

## What This Tells Us About Vibecoding Artifacts

This shader demonstrates both sides of what we discuss in the essays:

### The Convergence

Nearly every utility function (hash, noise, smooth blending, raymarching, shadows, AO) comes from the same small set of well-documented sources — primarily Inigo Quilez. A vibecoded shader would likely arrive at these same solutions because that's where the training data is densest.

### The Craft

The author knows *why* they're using these functions, credits sources, and builds something original on top of the foundation:
- The texture precalculation scheme is novel
- The sand ripple pattern is custom work
- The channel packing optimization reduces lookups from 8 to 2

### The Transparency

Every choice is visible in the code. You can trace each function to its origin. This is exactly what generative AI outputs lack — and what vibecoding preserves.

### The Epistemological Question

When vibecoding, the question becomes: if Claude suggests `smin()` or a hash function, do you recognize it as a Quilez/Hoskins standard? Do you understand why it works? Can you modify it, or is it a black box inside your otherwise transparent code?

This shader shows what deep familiarity looks like — the author has internalized these tools and uses them fluently, with attribution.

---

## Technical Notes

- **Resolution**: 1024² cubemap faces
- **Voxel dimensions**: 100³ (configurable via `dimsVox`)
- **Far plane**: 100 units
- **Raymarching**: 120 iterations max, adaptive step size
- **Shadow iterations**: 48 max
- **AO samples**: 5

---

## Related Essays

- `essay-02-grain-of-the-medium.md` — Discussion of shader artifacts and Inigo Quilez's influence
- `essay-01-vibecoding-general.md` — General introduction to vibecoding for artists
