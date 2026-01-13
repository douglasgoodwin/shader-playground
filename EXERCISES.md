# Shader Animation Exercises

A progressive guide to understanding and controlling shader animations.

---

## Part 1: Understanding the Basics

### Exercise 1.1: Time as a Driver

Every animation in these shaders is driven by `u_time`. Open any shader file and search for `u_time` to see how it's used.

**Try this in the Plasma shader** (`src/shaders/plasma.glsl`):

Find this line:
```glsl
float t = u_time * u_speed;
```

This multiplies time by speed. The result `t` is used throughout the shader.

**Questions to answer:**
1. What happens when `u_speed` is 0?
2. What happens when `u_speed` is negative?
3. Why multiply rather than add?

---

### Exercise 1.2: The Oscillation Toolkit

These patterns appear constantly in shader animation:

```glsl
// Pattern 1: Basic sine wave (-1 to 1)
float wave = sin(u_time);

// Pattern 2: Normalized sine (0 to 1)
float pulse = sin(u_time) * 0.5 + 0.5;

// Pattern 3: Sawtooth (0 to 1, repeating)
float saw = fract(u_time);

// Pattern 4: Triangle wave (0 to 1 to 0)
float tri = abs(fract(u_time) - 0.5) * 2.0;

// Pattern 5: Square wave (0 or 1)
float square = step(0.5, fract(u_time));
```

**Task:** Create a test shader that displays each pattern as a horizontal bar:

```glsl
void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float row = floor(uv.y * 5.0);  // 5 rows
    float t = u_time;

    float value = 0.0;
    if (row == 0.0) value = sin(t) * 0.5 + 0.5;
    if (row == 1.0) value = fract(t);
    if (row == 2.0) value = abs(fract(t) - 0.5) * 2.0;
    if (row == 3.0) value = step(0.5, fract(t));
    if (row == 4.0) value = smoothstep(0.0, 1.0, fract(t));

    float bar = step(uv.x, value);
    gl_FragColor = vec4(vec3(bar), 1.0);
}
```

---

### Exercise 1.3: Screen Coordinates

Understanding UV coordinates is essential.

```glsl
// Normalized 0-1 coordinates
vec2 uv = gl_FragCoord.xy / u_resolution;

// Centered coordinates (-0.5 to 0.5)
vec2 uv = gl_FragCoord.xy / u_resolution - 0.5;

// Aspect-corrected centered coordinates
vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution.y;
```

**Task:** Modify the last version to understand why we divide by `.y` only:
1. Try dividing by `.x` instead
2. Try dividing by the full `u_resolution`
3. Resize your browser window and observe the difference

---

## Part 2: Analyzing Existing Shaders

### Exercise 2.1: Firefly Anatomy

Open `src/shaders/firefly.glsl` and find these key sections:

**Particle Properties (lines 48-53):**
```glsl
vec2 seed = hash21(id * 13.7);           // Random position
float phase = hash11(id * 9.1) * TAU;    // Random phase offset
float blinkRate = mix(0.8, 2.2, ...);    // Blink speed
float size = mix(0.004, 0.010, ...);     // Particle size
```

**Modification challenges:**
1. Change `70.0` particles to `200.0` - what happens to performance?
2. Change the size range from `0.004, 0.010` to `0.02, 0.05`
3. Change the color from green-yellow to blue-cyan by modifying line 87:
   ```glsl
   // Original:
   vec3 firefly = mix(vec3(0.6, 1.2, 0.3), vec3(1.3, 1.0, 0.2), hueVar);
   // Try:
   vec3 firefly = mix(vec3(0.3, 0.6, 1.2), vec3(0.2, 1.0, 1.3), hueVar);
   ```

---

### Exercise 2.2: Drive Shader - Layered Effects

The Drive shader (`src/shaders/drive.glsl`) demonstrates layered composition:

```glsl
// Layer 1: Street lights (static positions, moving past)
col += StreetLights(i, t);

// Layer 2: Oncoming headlights
col += HeadLights(i + n * 0.125 * .7, t);

// Layer 3: Environment (buildings, signs)
col += EnvironmentLights(i, t);

// Layer 4: Tail lights (cars ahead)
col += TailLights(0., t);
col += TailLights(.5, t);
```

**Task:** Comment out each layer one at a time to understand its contribution.

**Advanced:** Add a new layer - airplane lights in the sky:
```glsl
vec3 PlaneLights(float i, float t) {
    float z = fract(i - t * 0.1);  // Slow movement
    vec3 p = vec3(sin(i * 10.0) * 3.0, 2.0 + i, z * 100.0);
    float d = length(p - ro);
    float m = BokehMask(ro, rd, p, 0.02 * d, 0.1);

    // Blinking
    m *= step(0.5, fract(t * 2.0 + i * 7.0));

    return vec3(1.0, 0.0, 0.0) * m * 0.3;  // Red light
}
```

---

### Exercise 2.3: Noise Shader - Nested Functions

The Noise shader (`src/shaders/noise.glsl`) uses nested noise for organic movement:

```glsl
float innerNoise = fractalNoise(rd * 2.0 + vec3(0.0, 0.0, -t * 0.1));
float n = fractalNoise(p * 4.0 * u_scale + t * 0.01 + vec3(innerNoise));
```

**Understand the nesting:**
1. `innerNoise` depends on ray direction (view-dependent)
2. Main noise `n` depends on position + time + innerNoise
3. This creates the "boiling" effect as you rotate

**Task:** Remove the nesting and compare:
```glsl
// Simpler version:
float n = fractalNoise(p * 4.0 * u_scale + t * 0.1);
```

What's lost? What's gained?

---

## Part 3: Common Techniques

### Exercise 3.1: Distance Fields

Many shaders use signed distance functions (SDFs):

```glsl
// Circle
float d = length(uv) - radius;

// Rectangle
vec2 q = abs(uv) - size;
float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);

// Combining shapes
float d = min(d1, d2);      // Union
float d = max(d1, d2);      // Intersection
float d = max(d1, -d2);     // Subtraction
```

**Task:** In the Raymarch shader (`src/shaders/geometries/raymarch.glsl`), find the `smin` function:
```glsl
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}
```

This creates smooth blending between shapes. Try changing `k` from `0.5` to `0.1` and `1.0`.

---

### Exercise 3.2: Color Palettes

The Fractal shader uses a popular cosine palette:

```glsl
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);        // Offset
    vec3 b = vec3(0.5, 0.5, 0.5);        // Amplitude
    vec3 c = vec3(1.0, 1.0, 1.0);        // Frequency
    vec3 d = vec3(0.263, 0.416, 0.557);  // Phase

    return a + b * cos(6.28318 * (c * t + d));
}
```

**Task:** Create different palettes by changing `d`:
```glsl
// Warm sunset
vec3 d = vec3(0.0, 0.33, 0.67);

// Cool ocean
vec3 d = vec3(0.5, 0.6, 0.7);

// Rainbow
vec3 d = vec3(0.0, 0.33, 0.67);  // with c = vec3(1.0, 1.0, 1.0)

// Monochrome
vec3 b = vec3(0.3, 0.3, 0.3);  // Reduce amplitude
```

Interactive palette designer: https://iquilezles.org/articles/palettes/

---

### Exercise 3.3: Repetition and Tiling

The Ropes shader uses `mod` for infinite repetition:

```glsl
p.xz = mod(p.xz + 1.0, 2.0) - 1.0;
```

This creates a repeating grid from -1 to 1.

**General pattern:**
```glsl
// Repeat space every `period` units, centered
p = mod(p + period * 0.5, period) - period * 0.5;
```

**Task:** In TriVoronoi, change the cell pattern:
```glsl
// Original hexagonal
g /= u_resolution.y / (5.0 * u_density);

// Try: rectangular grid
g /= u_resolution.y / (3.0 * u_density);
g.x *= 0.5;  // Stretch horizontally
```

---

## Part 4: Build Your Own

### Exercise 4.1: Starter Template

Create a new file `src/shaders/myshader.glsl`:

```glsl
precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

#define PI 3.14159265359

void main() {
    // Centered, aspect-correct coordinates
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution.y;

    float t = u_time * u_speed;

    // Your code here!
    vec3 col = vec3(0.0);

    // Example: pulsing circle
    float d = length(uv);
    float radius = 0.3 + 0.1 * sin(t * 2.0);
    col = vec3(smoothstep(radius, radius - 0.01, d));

    gl_FragColor = vec4(col, 1.0);
}
```

To add it to the playground:
1. Import in `src/main.js`
2. Add to `shaders` object
3. Add to `effectKeys`
4. Add button in `playground/index.html`

---

### Exercise 4.2: Challenge Projects

**Beginner:**
- Concentric animated rings
- Color gradient that rotates over time
- Mouse-following spotlight

**Intermediate:**
- Starfield flying through space
- Water ripple from mouse clicks
- Morphing between circle and square

**Advanced:**
- Simple raymarched scene (sphere on plane)
- Reaction-diffusion pattern
- Audio-reactive visualization (requires additional setup)

---

## Part 5: Debugging Tips

### Common Issues

**Black screen:**
- Check for division by zero
- Check that uniforms are being passed
- Add `gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);` at the start to verify shader runs

**Flickering:**
- Usually caused by z-fighting in raymarching
- Increase `SURF_DIST` or decrease step size

**Slow performance:**
- Reduce loop iterations
- Simplify distance functions
- Lower `MAX_STEPS` in raymarching

**Weird colors:**
- Values outside 0-1 range (use `clamp` or `saturate`)
- Missing gamma correction: `col = pow(col, vec3(0.4545));`

### Print Debugging

Since you can't `console.log` in shaders, use color to debug:

```glsl
// Visualize a float value (0-1 range)
gl_FragColor = vec4(vec3(myValue), 1.0);

// Visualize a float value (any range)
gl_FragColor = vec4(vec3(fract(myValue)), 1.0);

// Visualize a vec2
gl_FragColor = vec4(myVec2, 0.0, 1.0);

// Visualize sign (negative = red, positive = green)
gl_FragColor = vec4(max(0.0, myValue), max(0.0, -myValue), 0.0, 1.0);
```

---

## Resources

- **Book of Shaders:** https://thebookofshaders.com/
- **Shadertoy:** https://www.shadertoy.com/
- **Inigo Quilez Articles:** https://iquilezles.org/articles/
- **Shader Park:** https://shaderpark.com/
- **The Art of Code (YouTube):** https://www.youtube.com/c/TheArtofCodeIsCool

---

## Quick Reference

### Uniform Controls

| Uniform | Range | Purpose |
|---------|-------|---------|
| `u_time` | 0 → ∞ | Elapsed seconds |
| `u_speed` | 0.1 - 3.0 | Animation multiplier |
| `u_intensity` | 0.1 - 3.0 | Brightness/strength |
| `u_scale` | 0.2 - 3.0 | Size/density |
| `u_mouse` | 0 - resolution | Cursor position |

### Essential Functions

```glsl
// Interpolation
mix(a, b, t)              // Linear blend
smoothstep(e0, e1, x)     // Smooth transition

// Shaping
clamp(x, 0.0, 1.0)        // Limit range
fract(x)                   // Fractional part
mod(x, y)                  // Remainder
abs(x)                     // Absolute value
sign(x)                    // -1, 0, or 1

// Trigonometry
sin(x), cos(x)            // Oscillation
atan(y, x)                // Angle from origin

// Vector
length(v)                  // Magnitude
normalize(v)               // Unit vector
dot(a, b)                  // Projection
cross(a, b)                // Perpendicular (3D)
reflect(i, n)              // Mirror direction
```
