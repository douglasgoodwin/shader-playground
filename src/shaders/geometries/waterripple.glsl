// Water Ripple Text - Letters distorted by water droplet ripples
// Click/move mouse to create ripple origin point

precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_density;
uniform float u_harmonics;

#include "../lygia/math/const.glsl"
#include "../lygia/generative/random.glsl"

// Character patterns - each is a 5x5 bitmap encoded in bits
// Returns 1.0 if pixel is "on" for the character
float getChar(int charIndex, vec2 uv) {
    // Flip Y so characters render right-side up
    uv.y = 1.0 - uv.y;

    int x = int(uv.x * 5.0);
    int y = int(uv.y * 5.0);

    if (x < 0 || x > 4 || y < 0 || y > 4) return 0.0;

    int bit = y * 5 + x;
    int pattern = 0;

    // Define some letters: A, B, C, D, E, F, O, W, R, T, I, P, L, S
    if (charIndex == 0) { // A
        pattern = 0x1F8A7E2; // 0b00100 01010 11111 10001 10001
        if (bit == 2 || bit == 6 || bit == 8 || bit == 10 || bit == 11 || bit == 12 || bit == 13 || bit == 14 || bit == 15 || bit == 19 || bit == 20 || bit == 24) return 1.0;
    } else if (charIndex == 1) { // B
        if (bit == 0 || bit == 1 || bit == 2 || bit == 3 || bit == 4 || bit == 5 || bit == 9 || bit == 10 || bit == 11 || bit == 12 || bit == 13 || bit == 15 || bit == 19 || bit == 20 || bit == 21 || bit == 22 || bit == 23 || bit == 24) return 1.0;
    } else if (charIndex == 2) { // C
        if (bit == 1 || bit == 2 || bit == 3 || bit == 4 || bit == 5 || bit == 10 || bit == 15 || bit == 20 || bit == 21 || bit == 22 || bit == 23 || bit == 24) return 1.0;
    } else if (charIndex == 3) { // D
        if (bit == 0 || bit == 1 || bit == 2 || bit == 3 || bit == 4 || bit == 5 || bit == 9 || bit == 14 || bit == 15 || bit == 19 || bit == 20 || bit == 21 || bit == 22 || bit == 23) return 1.0;
    } else if (charIndex == 4) { // E
        if (bit == 0 || bit == 1 || bit == 2 || bit == 3 || bit == 4 || bit == 5 || bit == 10 || bit == 11 || bit == 12 || bit == 15 || bit == 20 || bit == 21 || bit == 22 || bit == 23 || bit == 24) return 1.0;
    } else if (charIndex == 5) { // O
        if (bit == 1 || bit == 2 || bit == 3 || bit == 5 || bit == 9 || bit == 10 || bit == 14 || bit == 15 || bit == 19 || bit == 21 || bit == 22 || bit == 23) return 1.0;
    } else if (charIndex == 6) { // W
        if (bit == 0 || bit == 4 || bit == 5 || bit == 9 || bit == 10 || bit == 12 || bit == 14 || bit == 15 || bit == 17 || bit == 19 || bit == 20 || bit == 22 || bit == 24) return 1.0;
    } else if (charIndex == 7) { // R
        if (bit == 0 || bit == 1 || bit == 2 || bit == 3 || bit == 5 || bit == 9 || bit == 10 || bit == 11 || bit == 12 || bit == 15 || bit == 17 || bit == 20 || bit == 19 || bit == 24) return 1.0;
    } else if (charIndex == 8) { // T
        if (bit == 0 || bit == 1 || bit == 2 || bit == 3 || bit == 4 || bit == 7 || bit == 12 || bit == 17 || bit == 22) return 1.0;
    } else if (charIndex == 9) { // I
        if (bit == 0 || bit == 1 || bit == 2 || bit == 3 || bit == 4 || bit == 7 || bit == 12 || bit == 17 || bit == 20 || bit == 21 || bit == 22 || bit == 23 || bit == 24) return 1.0;
    } else if (charIndex == 10) { // P
        if (bit == 0 || bit == 1 || bit == 2 || bit == 3 || bit == 5 || bit == 9 || bit == 10 || bit == 11 || bit == 12 || bit == 15 || bit == 20) return 1.0;
    } else if (charIndex == 11) { // L
        if (bit == 0 || bit == 5 || bit == 10 || bit == 15 || bit == 20 || bit == 21 || bit == 22 || bit == 23 || bit == 24) return 1.0;
    } else if (charIndex == 12) { // S
        if (bit == 1 || bit == 2 || bit == 3 || bit == 4 || bit == 5 || bit == 10 || bit == 11 || bit == 12 || bit == 13 || bit == 19 || bit == 20 || bit == 21 || bit == 22 || bit == 23) return 1.0;
    } else if (charIndex == 13) { // N
        if (bit == 0 || bit == 4 || bit == 5 || bit == 6 || bit == 9 || bit == 10 || bit == 12 || bit == 14 || bit == 15 || bit == 18 || bit == 19 || bit == 20 || bit == 24) return 1.0;
    }

    return 0.0;
}

// Render a character at a cell
float renderChar(vec2 cellUV, int charIndex) {
    // Add some padding
    vec2 paddedUV = (cellUV - 0.1) / 0.8;
    if (paddedUV.x < 0.0 || paddedUV.x > 1.0 || paddedUV.y < 0.0 || paddedUV.y > 1.0) return 0.0;

    return getChar(charIndex, paddedUV);
}

// Water ripple displacement
vec2 rippleDisplace(vec2 uv, vec2 center, float time) {
    vec2 delta = uv - center;
    float dist = length(delta);

    // Multiple ripple waves
    float numWaves = 3.0 * u_harmonics;
    float waveSpeed = 0.8 * u_speed;
    float waveFreq = 15.0 * u_density;
    float amplitude = 0.03 / (1.0 + dist * 2.0); // Amplitude decreases with distance

    float displacement = 0.0;
    for (float i = 0.0; i < 3.0; i++) {
        float phase = time * waveSpeed - i * 0.5;
        float wave = sin(dist * waveFreq - phase * 5.0);
        // Damping based on distance and wave age
        float damping = exp(-dist * 1.5) * exp(-max(0.0, phase - dist) * 0.5);
        displacement += wave * damping * amplitude;
    }

    // Displace in radial direction
    vec2 dir = dist > 0.001 ? normalize(delta) : vec2(0.0);
    return displacement * dir;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    float aspect = u_resolution.x / u_resolution.y;

    // Adjust UV for aspect ratio
    vec2 aspectUV = uv;
    aspectUV.x *= aspect;

    // Ripple center - follows mouse, or uses center with animated offset
    vec2 mouse = u_mouse / u_resolution;
    mouse.x *= aspect;

    // If mouse hasn't moved, use an animated center point
    vec2 center = mouse;
    if (length(u_mouse) < 1.0) {
        center = vec2(aspect * 0.5, 0.5);
    }

    float t = u_time * u_speed;

    // Apply ripple displacement to UV
    vec2 displaced = aspectUV + rippleDisplace(aspectUV, center, t);

    // Add subtle continuous ripple from center
    displaced += rippleDisplace(aspectUV, vec2(aspect * 0.5, 0.5), t * 0.7) * 0.5;

    // Grid of characters
    float gridSize = 12.0 * u_density;
    vec2 gridUV = displaced * gridSize;
    vec2 cellID = floor(gridUV);
    vec2 cellUV = fract(gridUV);

    // Pick a random character for each cell
    float randVal = random(cellID);
    int charIndex = int(randVal * 14.0);

    // Render the character
    float char = renderChar(cellUV, charIndex);

    // Color based on position and time
    vec3 waterColor1 = vec3(0.1, 0.3, 0.5);
    vec3 waterColor2 = vec3(0.2, 0.5, 0.7);
    vec3 textColor = vec3(0.9, 0.95, 1.0);

    // Background gradient with subtle wave pattern
    float bgWave = sin(uv.x * 10.0 + t) * sin(uv.y * 8.0 + t * 0.7) * 0.1;
    vec3 bg = mix(waterColor1, waterColor2, uv.y + bgWave);

    // Add ripple highlights to background
    float rippleHighlight = 0.0;
    vec2 delta = aspectUV - center;
    float dist = length(delta);
    for (float i = 0.0; i < 3.0; i++) {
        float phase = t * 0.8 * u_speed - i * 0.5;
        float ring = abs(dist - phase * 0.2);
        rippleHighlight += smoothstep(0.02, 0.0, ring) * exp(-phase * 0.5) * 0.3;
    }
    bg += rippleHighlight;

    // Combine
    vec3 color = mix(bg, textColor, char * 0.85);

    // Add depth effect - characters further from ripple center appear slightly different
    float depthFactor = 1.0 - smoothstep(0.0, 1.5, dist);
    color = mix(color, color * 1.2, depthFactor * char * 0.3);

    // Vignette
    float vignette = 1.0 - length(uv - 0.5) * 0.5;
    color *= vignette;

    // Gamma correction
    color = pow(color, vec3(0.4545));

    gl_FragColor = vec4(color, 1.0);
}
