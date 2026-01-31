precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

// =============================================================================
// DAVE HOSKINS' HASH: A More Reliable Approach
// =============================================================================
//
// The simple sin-based hash breaks down with large input values.
// GPU sin() functions lose precision at high numbers, creating artifacts.
//
// Dave Hoskins created "Hash without Sine" - a more robust alternative
// that uses only multiply and fract operations. It's widely used and
// released under Creative Commons Attribution-ShareAlike 4.0.
//
// This is the hash you'll find in advanced shaders like "Desert Passage II"
// and throughout Shadertoy.
//
// Source: https://www.shadertoy.com/view/4djSRW
// =============================================================================

// Hash without Sine - by Dave Hoskins
// More reliable with large values than sin-based hashes
float hash12(vec2 p) {
    // These magic numbers were carefully chosen to minimize patterns
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Returns a vec2 of pseudo-random values
vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

// Returns a vec3 of pseudo-random values (useful for colors)
vec3 hash32(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // Create a grid
    float scale = 10.0;
    vec2 cell = floor(uv * scale);

    // Compare the two hash methods
    // Left half: sin-based hash
    // Right half: Hoskins hash

    vec3 col;

    if (uv.x < 0.5) {
        // Simple sin-based hash (for comparison)
        float h = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
        col = vec3(h);
    } else {
        // Dave Hoskins hash
        float h = hash12(cell);
        col = vec3(h);
    }

    // Draw a dividing line
    if (abs(uv.x - 0.5) < 0.002) {
        col = vec3(1.0, 0.0, 0.0);
    }

    // =================================================================
    // EXPERIMENTS TO TRY:
    // =================================================================
    //
    // 1. Use hash32 for random colors:
    //    col = hash32(cell);
    //
    // 2. Add large offset to see sin hash break down:
    //    vec2 cell = floor(uv * scale) + 10000.0;
    //    (The sin version will show patterns, Hoskins stays random)
    //
    // 3. Use hash22 for position offsets:
    //    vec2 offset = hash22(cell) - 0.5;
    //    // Use offset to jitter something
    //
    // 4. Animate with time:
    //    vec2 cell = floor(uv * scale + u_time);
    //
    // =================================================================

    gl_FragColor = vec4(col, 1.0);
}
