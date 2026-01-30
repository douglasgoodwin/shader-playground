// Pool Water - Realistic water surface with caustics, ripples, and refraction
// Inspired by madebyevan.com/webgl-water
// Move mouse to create ripples on the water surface

precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_density;
uniform float u_harmonics;

#define PI 3.14159265359
#define TAU 6.28318530718

// Hash functions for noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

vec2 hash2(vec2 p) {
    return vec2(hash(p), hash(p + vec2(17.1, 31.7)));
}

// Smooth noise
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion for water surface
float fbm(vec2 p, float t) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p * frequency + t * 0.5);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

// Water wave function - simulates ripples
float waterWave(vec2 uv, float t) {
    float wave = 0.0;
    float waveScale = u_density * 2.0;
    float speed = u_speed * 0.5;

    // Multiple wave directions for realistic water
    wave += sin(uv.x * 8.0 * waveScale + t * speed * 3.0) * 0.1;
    wave += sin(uv.y * 6.0 * waveScale + t * speed * 2.5) * 0.12;
    wave += sin((uv.x + uv.y) * 10.0 * waveScale + t * speed * 4.0) * 0.08;
    wave += sin((uv.x - uv.y) * 7.0 * waveScale - t * speed * 3.5) * 0.09;

    // Add some turbulence
    wave += fbm(uv * 4.0 * waveScale, t * speed) * 0.15;

    return wave;
}

// Ripple from a point (mouse interaction)
float pointRipple(vec2 uv, vec2 center, float t) {
    float dist = length(uv - center);
    float rippleSpeed = u_speed * 2.0;
    float rippleFreq = 20.0 * u_density;

    // Multiple expanding rings
    float ripple = 0.0;
    for (float i = 0.0; i < 4.0; i++) {
        float phase = t * rippleSpeed - i * 0.3;
        float ring = sin(dist * rippleFreq - phase * 8.0);
        // Decay with distance and time
        float decay = exp(-dist * 3.0) * exp(-max(0.0, phase - dist * 2.0) * 0.8);
        ripple += ring * decay * 0.3;
    }
    return ripple;
}

// Caustics - light patterns on pool floor
float caustics(vec2 uv, float t) {
    float scale = u_harmonics * 3.0;
    float speed = u_speed * 0.3;

    // Layer multiple caustic patterns
    float c = 0.0;

    // First layer
    vec2 p1 = uv * scale + vec2(t * speed * 0.7, t * speed * 0.5);
    c += pow(abs(sin(p1.x * 3.0) * sin(p1.y * 3.0)), 0.5);

    // Second layer, rotated
    float angle = 0.7;
    mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    vec2 p2 = rot * uv * scale * 1.3 + vec2(-t * speed * 0.5, t * speed * 0.8);
    c += pow(abs(sin(p2.x * 2.5) * sin(p2.y * 2.5)), 0.5) * 0.8;

    // Third layer for complexity
    vec2 p3 = uv * scale * 0.8 + vec2(t * speed * 0.3, -t * speed * 0.6);
    c += pow(abs(sin(p3.x * 4.0 + sin(p3.y * 2.0)) * sin(p3.y * 3.5)), 0.6) * 0.6;

    // Voronoi-like caustic pattern
    vec2 vc = uv * scale * 2.0;
    vec2 vi = floor(vc);
    vec2 vf = fract(vc);

    float minDist = 1.0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = hash2(vi + neighbor) * 0.5 + 0.25;
            point += 0.3 * sin(t * speed + hash(vi + neighbor) * TAU);
            float d = length(vf - neighbor - point);
            minDist = min(minDist, d);
        }
    }
    c += pow(1.0 - minDist, 3.0) * 1.5;

    return c * 0.25;
}

// Pool tile pattern
vec3 poolTiles(vec2 uv) {
    float tileSize = 0.08;
    vec2 tileUV = fract(uv / tileSize);
    vec2 tileID = floor(uv / tileSize);

    // Grout lines
    float grout = 0.03;
    float isGrout = step(tileUV.x, grout) + step(1.0 - grout, tileUV.x) +
                    step(tileUV.y, grout) + step(1.0 - grout, tileUV.y);
    isGrout = clamp(isGrout, 0.0, 1.0);

    // Tile color variation
    float variation = hash(tileID) * 0.1;
    vec3 tileColor = vec3(0.6 + variation, 0.75 + variation * 0.5, 0.85 + variation * 0.3);
    vec3 groutColor = vec3(0.5, 0.55, 0.6);

    return mix(tileColor, groutColor, isGrout);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    float aspect = u_resolution.x / u_resolution.y;
    vec2 aspectUV = vec2(uv.x * aspect, uv.y);

    float t = u_time;

    // Mouse position for ripple interaction
    vec2 mouse = u_mouse / u_resolution;
    mouse.x *= aspect;

    // Default center if no mouse input
    vec2 rippleCenter = mouse;
    if (length(u_mouse) < 1.0) {
        rippleCenter = vec2(aspect * 0.5, 0.5);
    }

    // Calculate water surface distortion
    float waterHeight = waterWave(aspectUV, t);
    waterHeight += pointRipple(aspectUV, rippleCenter, t);

    // Calculate water surface normal (for refraction)
    float eps = 0.01;
    float hx = waterWave(aspectUV + vec2(eps, 0.0), t) +
               pointRipple(aspectUV + vec2(eps, 0.0), rippleCenter, t);
    float hy = waterWave(aspectUV + vec2(0.0, eps), t) +
               pointRipple(aspectUV + vec2(0.0, eps), rippleCenter, t);

    vec2 normal = vec2(waterHeight - hx, waterHeight - hy) / eps;

    // Refraction offset - simulates looking through water
    float refractionStrength = 0.05 * u_harmonics;
    vec2 refractedUV = aspectUV + normal * refractionStrength;

    // Pool floor with tiles
    vec3 floorColor = poolTiles(refractedUV * 5.0);

    // Apply caustics to floor
    float causticsValue = caustics(refractedUV, t);
    floorColor += causticsValue * vec3(0.4, 0.6, 0.8);

    // Water color - depth-based tinting
    vec3 shallowWater = vec3(0.3, 0.7, 0.9);
    vec3 deepWater = vec3(0.1, 0.3, 0.6);
    float depth = 0.4 + waterHeight * 0.3;
    vec3 waterColor = mix(deepWater, shallowWater, depth);

    // Blend floor with water color (simulates water absorption)
    float waterAbsorption = 0.4;
    vec3 color = mix(floorColor, waterColor, waterAbsorption);

    // Surface highlights (fresnel-like effect)
    float fresnel = pow(1.0 - abs(waterHeight), 3.0);
    vec3 highlightColor = vec3(0.9, 0.95, 1.0);
    color += highlightColor * fresnel * 0.15;

    // Specular highlights from waves
    float specular = pow(max(0.0, dot(normalize(vec3(normal * 2.0, 1.0)),
                                       normalize(vec3(0.5, 0.5, 1.0)))), 32.0);
    color += vec3(1.0) * specular * 0.4;

    // Add ripple ring highlights near mouse
    float dist = length(aspectUV - rippleCenter);
    for (float i = 0.0; i < 3.0; i++) {
        float phase = t * u_speed * 2.0 - i * 0.4;
        float ring = abs(dist - phase * 0.15);
        float ringHighlight = smoothstep(0.015, 0.0, ring) * exp(-phase * 0.5);
        color += vec3(0.3, 0.5, 0.7) * ringHighlight * 0.5;
    }

    // Subtle vignette
    float vignette = 1.0 - length(uv - 0.5) * 0.4;
    color *= vignette;

    // Gamma correction
    color = pow(color, vec3(0.4545));

    gl_FragColor = vec4(color, 1.0);
}
