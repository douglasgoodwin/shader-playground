precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

// =============================================================================
// VALUE NOISE: Smoothly Interpolated Random Values
// =============================================================================
//
// Hash functions give us random values per grid cell, but the result is blocky.
// Value noise smooths between those random values using interpolation.
//
// The process:
// 1. Divide space into a grid
// 2. Assign a random value to each grid corner (using hash)
// 3. Smoothly interpolate between the four corners
//
// This creates organic-looking patterns used for terrain, clouds, textures.
// It's the simplest form of "smooth noise."
// =============================================================================

// Dave Hoskins hash
float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Value noise - interpolated random values
float valueNoise(vec2 p) {
    // Integer part (which cell we're in)
    vec2 i = floor(p);
    // Fractional part (where in the cell)
    vec2 f = fract(p);

    // Get random values at the four corners of the cell
    float a = hash12(i + vec2(0.0, 0.0)); // bottom-left
    float b = hash12(i + vec2(1.0, 0.0)); // bottom-right
    float c = hash12(i + vec2(0.0, 1.0)); // top-left
    float d = hash12(i + vec2(1.0, 1.0)); // top-right

    // Smooth interpolation curve
    // This "smoothstep" curve (3f² - 2f³) has zero derivatives at 0 and 1
    // which prevents visible grid lines
    vec2 u = f * f * (3.0 - 2.0 * f);

    // Bilinear interpolation using the smooth curve
    // mix(a, b, t) = a + t * (b - a)
    return mix(
        mix(a, b, u.x),  // interpolate bottom edge
        mix(c, d, u.x),  // interpolate top edge
        u.y              // interpolate between edges
    );
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // Scale the UV to see the noise pattern
    // TODO: Try different scales (2, 4, 8, 16, 32)
    float scale = 8.0;
    vec2 p = uv * scale;

    // Get the noise value
    float n = valueNoise(p);

    // Visualize as grayscale
    vec3 col = vec3(n);

    // =================================================================
    // EXPERIMENTS TO TRY:
    // =================================================================
    //
    // 1. Animate the noise:
    //    vec2 p = uv * scale + u_time * 0.5;
    //
    // 2. Compare smooth vs linear interpolation:
    //    // Replace the smoothstep line with:
    //    vec2 u = f;  // Linear - you'll see grid artifacts
    //
    // 3. Use noise for color:
    //    float n1 = valueNoise(p);
    //    float n2 = valueNoise(p + 100.0);
    //    float n3 = valueNoise(p + 200.0);
    //    vec3 col = vec3(n1, n2, n3);
    //
    // 4. Threshold the noise:
    //    float n = step(0.5, valueNoise(p));
    //
    // 5. Create contour lines:
    //    float n = valueNoise(p);
    //    n = fract(n * 10.0); // 10 bands
    //    col = vec3(step(0.9, n)); // thin lines
    //
    // =================================================================

    gl_FragColor = vec4(col, 1.0);
}
