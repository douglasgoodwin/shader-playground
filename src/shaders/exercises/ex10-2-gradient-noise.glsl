precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

// =============================================================================
// GRADIENT NOISE: Ken Perlin's Approach (as implemented by IQ)
// =============================================================================
//
// Value noise interpolates random VALUES at grid corners.
// Gradient noise interpolates random DIRECTIONS (gradients) instead.
//
// The process:
// 1. Assign a random gradient vector to each grid corner
// 2. For each point, compute dot products with the four corner gradients
// 3. Smoothly interpolate those dot products
//
// The result has better visual quality - less "blobby" than value noise,
// with more natural-looking features. This is what Ken Perlin invented.
//
// This implementation is based on Inigo Quilez's version, which you'll
// find throughout Shadertoy and in shaders like "Desert Passage II."
// =============================================================================

// Hash that returns a 2D gradient vector (range -1 to 1)
vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy) * 2.0 - 1.0;
}

// Gradient noise (Perlin-style)
// Based on IQ's implementation
float gradientNoise(vec2 p) {
    // Integer and fractional parts
    vec2 i = floor(p);
    vec2 f = fract(p);

    // Quintic interpolation curve
    // This has zero first AND second derivatives at 0 and 1
    // Even smoother than the cubic curve used in value noise
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    // Gradients at the four corners
    vec2 ga = hash22(i + vec2(0.0, 0.0));
    vec2 gb = hash22(i + vec2(1.0, 0.0));
    vec2 gc = hash22(i + vec2(0.0, 1.0));
    vec2 gd = hash22(i + vec2(1.0, 1.0));

    // Vectors from corners to point
    vec2 pa = f - vec2(0.0, 0.0);
    vec2 pb = f - vec2(1.0, 0.0);
    vec2 pc = f - vec2(0.0, 1.0);
    vec2 pd = f - vec2(1.0, 1.0);

    // Dot products of gradients with distance vectors
    float va = dot(ga, pa);
    float vb = dot(gb, pb);
    float vc = dot(gc, pc);
    float vd = dot(gd, pd);

    // Bilinear interpolation
    return mix(
        mix(va, vb, u.x),
        mix(vc, vd, u.x),
        u.y
    );
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float scale = 6.0;
    vec2 p = uv * scale;

    // Gradient noise returns values roughly in range -0.7 to 0.7
    // We map it to 0-1 for visualization
    float n = gradientNoise(p);
    n = n * 0.5 + 0.5; // Map to 0-1

    vec3 col = vec3(n);

    // =================================================================
    // EXPERIMENTS TO TRY:
    // =================================================================
    //
    // 1. Compare value noise vs gradient noise:
    //    // Left half: value noise, Right half: gradient noise
    //    // Notice gradient noise has more "swirly" character
    //
    // 2. Animate:
    //    vec2 p = uv * scale + vec2(u_time * 0.3, 0.0);
    //
    // 3. Use for displacement:
    //    vec2 p = uv * scale;
    //    float n = gradientNoise(p);
    //    uv += n * 0.1; // Displace UVs
    //    col = vec3(uv, 0.5);
    //
    // 4. Create terrain-like coloring:
    //    float n = gradientNoise(p) * 0.5 + 0.5;
    //    vec3 water = vec3(0.1, 0.3, 0.6);
    //    vec3 sand = vec3(0.8, 0.7, 0.5);
    //    vec3 grass = vec3(0.2, 0.5, 0.2);
    //    vec3 rock = vec3(0.4, 0.4, 0.4);
    //    col = mix(water, sand, smoothstep(0.4, 0.45, n));
    //    col = mix(col, grass, smoothstep(0.5, 0.55, n));
    //    col = mix(col, rock, smoothstep(0.7, 0.75, n));
    //
    // =================================================================

    gl_FragColor = vec4(col, 1.0);
}
