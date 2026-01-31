precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

// =============================================================================
// HASH FUNCTIONS: The Foundation of Procedural Graphics
// =============================================================================
//
// A hash function takes an input and returns a "random-looking" output.
// But it's not truly random - the same input always gives the same output.
// This is called "deterministic randomness" and it's essential for shaders.
//
// Why? Because shaders run independently for each pixel. There's no shared
// state, no random seed that persists. If you want "random" variation,
// you need a function that generates it from the pixel's position.
//
// This is the simplest hash - it uses sin() with a large multiplier.
// The fract() keeps only the decimal part, giving us 0.0 to 1.0.
// =============================================================================

// Simple hash: position -> pseudo-random number
float hash(vec2 p) {
    // The "magic number" 43758.5453 is chosen because:
    // - It's large (creates rapid oscillation in sin)
    // - It's irrational-ish (avoids patterns)
    // - It's been used so often it's become a standard
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // Scale up to see the pattern
    // TODO: Try changing 10.0 to other values (1, 5, 20, 50, 100)
    vec2 scaledUV = floor(uv * 10.0);

    // Get a "random" value for this grid cell
    float h = hash(scaledUV);

    // Visualize the hash output as grayscale
    vec3 col = vec3(h);

    // =================================================================
    // EXPERIMENTS TO TRY:
    // =================================================================
    //
    // 1. Remove the floor() - what happens?
    //    vec2 scaledUV = uv * 10.0;
    //
    // 2. Add time to make it animate:
    //    float h = hash(scaledUV + u_time);
    //
    // 3. Use the hash for color instead of grayscale:
    //    vec3 col = vec3(hash(scaledUV),
    //                    hash(scaledUV + 1.0),
    //                    hash(scaledUV + 2.0));
    //
    // 4. Threshold the hash to make a pattern:
    //    float h = step(0.5, hash(scaledUV));
    //
    // =================================================================

    gl_FragColor = vec4(col, 1.0);
}
