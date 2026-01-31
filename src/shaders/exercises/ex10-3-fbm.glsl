precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

// =============================================================================
// FBM: Fractal Brownian Motion (Layered Noise)
// =============================================================================
//
// A single layer of noise looks too uniform for natural phenomena.
// Real clouds, terrain, and textures have detail at multiple scales.
//
// FBM (Fractal Brownian Motion) layers noise at different frequencies:
// - Start with a base noise (low frequency, high amplitude)
// - Add higher frequency noise with lower amplitude
// - Repeat, typically 4-8 times ("octaves")
//
// Each layer:
// - Doubles the frequency (more detail)
// - Halves the amplitude (less influence)
//
// This is THE technique for procedural terrain, clouds, and organic textures.
// You'll see it in almost every advanced shader.
// =============================================================================

// Hash for gradient noise
vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy) * 2.0 - 1.0;
}

// Gradient noise (from previous exercise)
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    vec2 ga = hash22(i + vec2(0.0, 0.0));
    vec2 gb = hash22(i + vec2(1.0, 0.0));
    vec2 gc = hash22(i + vec2(0.0, 1.0));
    vec2 gd = hash22(i + vec2(1.0, 1.0));

    float va = dot(ga, f - vec2(0.0, 0.0));
    float vb = dot(gb, f - vec2(1.0, 0.0));
    float vc = dot(gc, f - vec2(0.0, 1.0));
    float vd = dot(gd, f - vec2(1.0, 1.0));

    return mix(mix(va, vb, u.x), mix(vc, vd, u.x), u.y);
}

// FBM - Fractal Brownian Motion
// octaves: number of noise layers (more = more detail, but slower)
float fbm(vec2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;  // How much each layer contributes
    float frequency = 1.0;  // Scale of the noise

    for (int i = 0; i < 8; i++) {
        if (i >= octaves) break;

        value += amplitude * noise(p * frequency);

        frequency *= 2.0;   // Double frequency (more detail)
        amplitude *= 0.5;   // Halve amplitude (less influence)
    }

    return value;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float scale = 3.0;
    vec2 p = uv * scale;

    // TODO: Try changing octaves from 1 to 8
    // Watch how detail increases with each layer
    int octaves = 5;

    float n = fbm(p, octaves);
    n = n * 0.5 + 0.5; // Map to 0-1

    vec3 col = vec3(n);

    // =================================================================
    // EXPERIMENTS TO TRY:
    // =================================================================
    //
    // 1. Animate (slowly drifting clouds):
    //    vec2 p = uv * scale + vec2(u_time * 0.1, 0.0);
    //
    // 2. Show individual octaves side by side:
    //    int octaves = int(uv.x * 7.0) + 1;
    //
    // 3. Turbulence (absolute value creates sharper features):
    //    // Replace noise() call in fbm with:
    //    value += amplitude * abs(noise(p * frequency));
    //
    // 4. Ridged noise (inverted turbulence - mountain ridges):
    //    // In fbm loop:
    //    value += amplitude * (1.0 - abs(noise(p * frequency)));
    //
    // 5. Domain warping (use noise to distort itself):
    //    vec2 q = vec2(fbm(p, 4), fbm(p + vec2(5.2, 1.3), 4));
    //    float n = fbm(p + q * 2.0, 4);
    //
    // 6. Terrain coloring:
    //    float n = fbm(p, 6) * 0.5 + 0.5;
    //    vec3 deep = vec3(0.0, 0.1, 0.3);
    //    vec3 shallow = vec3(0.0, 0.4, 0.6);
    //    vec3 sand = vec3(0.9, 0.8, 0.6);
    //    vec3 grass = vec3(0.2, 0.6, 0.2);
    //    vec3 rock = vec3(0.5, 0.4, 0.4);
    //    vec3 snow = vec3(1.0);
    //    col = mix(deep, shallow, smoothstep(0.0, 0.3, n));
    //    col = mix(col, sand, smoothstep(0.3, 0.35, n));
    //    col = mix(col, grass, smoothstep(0.4, 0.5, n));
    //    col = mix(col, rock, smoothstep(0.6, 0.75, n));
    //    col = mix(col, snow, smoothstep(0.85, 0.9, n));
    //
    // =================================================================

    gl_FragColor = vec4(col, 1.0);
}
