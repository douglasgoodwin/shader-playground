precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

// =============================================================================
// HASH APPLICATIONS: What Can You Do With Random Numbers?
// =============================================================================
//
// Hash functions are the foundation for:
// - Noise (gradient noise, value noise, Voronoi)
// - Procedural textures (wood grain, marble, terrain)
// - Particle systems (random positions, velocities)
// - Stippling and dithering effects
// - Randomizing grid patterns to look organic
//
// This exercise shows practical applications of hash functions.
// =============================================================================

// Dave Hoskins hash functions
float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

vec3 hash32(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec3 col = vec3(0.0);

    // =================================================================
    // APPLICATION 1: Stipple / Noise Dither
    // =================================================================
    // Random dots based on brightness threshold

    float brightness = uv.x; // Gradient from dark to light
    float noise = hash12(gl_FragCoord.xy); // Random per pixel

    // If the random value is less than brightness, draw white
    // This creates more dots where it's brighter
    col = vec3(step(noise, brightness));

    // =================================================================
    // APPLICATION 2: Jittered Grid (uncomment to try)
    // =================================================================
    // A grid where each cell's content is randomly offset
    /*
    float scale = 15.0;
    vec2 cell = floor(uv * scale);
    vec2 cellUV = fract(uv * scale);

    // Random offset for this cell (range: -0.3 to 0.3)
    vec2 offset = (hash22(cell) - 0.5) * 0.6;

    // Draw a circle at the jittered position
    float dist = length(cellUV - 0.5 + offset);
    col = vec3(1.0 - smoothstep(0.1, 0.15, dist));
    */

    // =================================================================
    // APPLICATION 3: Random Colors Per Cell (uncomment to try)
    // =================================================================
    /*
    float scale = 8.0;
    vec2 cell = floor(uv * scale);
    col = hash32(cell); // Random RGB per cell
    */

    // =================================================================
    // APPLICATION 4: Animated Sparkle (uncomment to try)
    // =================================================================
    /*
    float scale = 50.0;
    vec2 cell = floor(uv * scale);

    // Hash changes over time (floor to make discrete changes)
    float sparkle = hash12(cell + floor(u_time * 3.0));

    // Only some cells sparkle (threshold)
    sparkle = step(0.95, sparkle);

    col = vec3(sparkle);
    */

    // =================================================================
    // APPLICATION 5: Organic Stippling (uncomment to try)
    // =================================================================
    // Multiple scales of stippling for a hand-drawn look
    /*
    float n1 = hash12(floor(gl_FragCoord.xy / 1.0));
    float n2 = hash12(floor(gl_FragCoord.xy / 2.0));
    float n3 = hash12(floor(gl_FragCoord.xy / 4.0));

    // Combine scales
    float stipple = n1 * 0.5 + n2 * 0.3 + n3 * 0.2;

    // Threshold against a gradient
    float threshold = uv.x;
    col = vec3(step(stipple, threshold));
    */

    gl_FragColor = vec4(col, 1.0);
}
