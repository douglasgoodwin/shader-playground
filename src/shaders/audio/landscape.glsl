// Audio-reactive raymarched terrain
// Frequency spectrum drives terrain height, waveform adds surface detail

precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_intensity;
uniform sampler2D u_audioFreq;
uniform sampler2D u_audioWave;
uniform float u_audioEnergy;
uniform float u_bassEnergy;

#define MAX_STEPS 80
#define MAX_DIST 60.0
#define SURF_DIST 0.002

// Hash for noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 2D value noise
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

// Sample frequency spectrum — maps world x to frequency bin
float getFreqHeight(float x) {
    // Map x from world space to 0-1 UV for the frequency texture
    // Low frequencies on the left, high on the right
    float u = clamp(x / 40.0 + 0.5, 0.0, 1.0);
    return texture2D(u_audioFreq, vec2(u, 0.5)).r;
}

// Sample waveform for surface detail
float getWaveRipple(float z) {
    float u = fract(z * 0.05);
    return texture2D(u_audioWave, vec2(u, 0.5)).r * 2.0 - 1.0;
}

// Terrain height function
float terrain(vec2 p) {
    // Base terrain from frequency data
    float freq = getFreqHeight(p.x);

    // Amplitude scaled by intensity
    float h = freq * 4.0 * u_intensity;

    // Bass energy pulses overall height
    h *= (1.0 + u_bassEnergy * 1.5);

    // Add waveform ripple as surface detail
    float ripple = getWaveRipple(p.y) * 0.3 * u_intensity;
    h += ripple;

    // Add subtle noise for organic feel
    h += noise(p * 2.0) * 0.3;
    h += noise(p * 5.0) * 0.1;

    return h;
}

// Scene SDF: terrain as heightfield
float map(vec3 p) {
    return p.y - terrain(p.xz);
}

// Normal via central differences
vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.05, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

// Raymarch
float raymarch(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * t;
        float d = map(p);
        if (d < SURF_DIST * (1.0 + t * 0.05)) break;
        t += d * 0.5; // conservative step for heightfield
        if (t > MAX_DIST) break;
    }
    return min(t, MAX_DIST);
}

// Color based on frequency position and energy
vec3 audioColor(vec3 p) {
    // Map x position to frequency band
    float u = clamp(p.x / 40.0 + 0.5, 0.0, 1.0);
    float freq = getFreqHeight(p.x);

    // Bass = warm (orange/red), mids = cyan/green, treble = blue/purple
    vec3 bassCol = vec3(1.0, 0.4, 0.1);
    vec3 midCol = vec3(0.1, 0.8, 0.6);
    vec3 trebleCol = vec3(0.4, 0.2, 0.9);

    vec3 col;
    if (u < 0.33) {
        col = mix(bassCol, midCol, u / 0.33);
    } else if (u < 0.66) {
        col = mix(midCol, trebleCol, (u - 0.33) / 0.33);
    } else {
        col = trebleCol;
    }

    // Brightness from amplitude
    col *= 0.4 + freq * 1.2;

    return col;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - u_resolution.xy * 0.5) / u_resolution.y;
    float t_anim = u_time * u_speed * 0.3;

    // Camera: slow orbit
    float camRadius = 15.0;
    float camAngle = t_anim * 0.5;
    float camY = 6.0 + u_bassEnergy * 3.0;

    vec3 ro = vec3(
        cos(camAngle) * camRadius,
        camY,
        sin(camAngle) * camRadius
    );

    // Look at center, slightly ahead of orbit
    vec3 lookAt = vec3(
        cos(camAngle + 0.5) * camRadius * 0.3,
        1.0 + u_audioEnergy * 2.0,
        sin(camAngle + 0.5) * camRadius * 0.3
    );

    // Camera matrix
    vec3 forward = normalize(lookAt - ro);
    vec3 right = normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
    vec3 up = cross(right, forward);

    float fov = 1.2;
    vec3 rd = normalize(forward * fov + right * uv.x + up * uv.y);

    // Raymarch
    float t = raymarch(ro, rd);
    vec3 col = vec3(0.0);

    if (t < MAX_DIST) {
        vec3 p = ro + rd * t;
        vec3 n = calcNormal(p);

        // Base color from audio frequency mapping
        vec3 baseCol = audioColor(p);

        // Directional light
        vec3 lightDir = normalize(vec3(0.5, 0.8, -0.3));
        float diff = max(dot(n, lightDir), 0.0);
        float amb = 0.15;

        col = baseCol * (diff * 0.7 + amb);

        // Specular highlight
        vec3 h = normalize(lightDir - rd);
        float spec = pow(max(dot(n, h), 0.0), 32.0);
        col += vec3(1.0) * spec * 0.3;

        // Energy-reactive emissive glow
        float freq = getFreqHeight(p.x);
        col += baseCol * freq * u_audioEnergy * 1.5;

        // Fog to dark background
        float fogAmount = 1.0 - exp(-t * 0.04);
        vec3 fogCol = vec3(0.02, 0.02, 0.05);
        col = mix(col, fogCol, fogAmount);
    } else {
        // Dark background with subtle gradient
        col = vec3(0.02, 0.02, 0.05);
        col += vec3(0.03, 0.01, 0.05) * (1.0 - abs(uv.y));

        // Subtle energy-reactive background pulse
        col += vec3(0.05, 0.02, 0.08) * u_audioEnergy;
    }

    // Vignette
    vec2 vig = gl_FragCoord.xy / u_resolution.xy;
    col *= pow(16.0 * vig.x * vig.y * (1.0 - vig.x) * (1.0 - vig.y), 0.15);

    // Gamma
    col = pow(clamp(col, 0.0, 1.0), vec3(0.4545));

    gl_FragColor = vec4(col, 1.0);
}
