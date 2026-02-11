// Audio-reactive clear sphere with violent surface displacement
// Raymarched displaced SDF, mostly transparent with refraction

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

#define MAX_STEPS 100
#define MAX_DIST 20.0
#define SURF_DIST 0.001
#define PI 3.14159265

float freqAt(float u) {
    return texture2D(u_audioFreq, vec2(clamp(u, 0.0, 1.0), 0.5)).r;
}

float waveAt(float u) {
    return texture2D(u_audioWave, vec2(clamp(u, 0.0, 1.0), 0.5)).r;
}

// --- Noise ---

float hash(vec3 p) {
    p = fract(p * vec3(443.897, 441.423, 437.195));
    p += dot(p, p.yzx + 19.19);
    return fract((p.x + p.y) * p.z);
}

float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x),
            mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
        mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
            mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y),
        f.z
    );
}

float fbm(vec3 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = p * 2.1 + vec3(0.9, -0.9, 0.9);
        a *= 0.5;
    }
    return v;
}

// Double domain warp
float warpedNoise(vec3 p, float t) {
    float warpAmt = 2.0 + u_audioEnergy * 3.0;

    vec3 q = vec3(
        fbm(p + t * 0.2),
        fbm(p + vec3(5.2, 1.3, 2.8) + t * 0.15),
        fbm(p + vec3(1.7, 9.2, 3.4) - t * 0.12)
    );

    vec3 r = vec3(
        fbm(p + warpAmt * q + vec3(1.7, 9.2, 0.0) + t * 0.1),
        fbm(p + warpAmt * q + vec3(8.3, 2.8, 4.1) - t * 0.08),
        fbm(p + warpAmt * q + vec3(3.1, 6.5, 1.2) + t * 0.12)
    );

    return fbm(p + warpAmt * r);
}

// Displaced sphere SDF
float map(vec3 p) {
    float t = u_time * u_speed;
    float baseR = 1.0 + u_bassEnergy * 0.1;
    float d = length(p) - baseR;

    // Spherical coords for audio sampling
    vec3 n = normalize(p);
    float theta = atan(n.z, n.x) / (2.0 * PI) + 0.5;
    float phi = acos(n.y) / PI;
    float freq = freqAt(theta);
    float wave = waveAt(phi);

    // Violent displacement from domain-warped noise
    float disp = warpedNoise(p * 1.5, t) - 0.5;
    disp *= 0.6 * u_intensity;

    // Audio drives additional displacement
    disp += (freq - 0.3) * 0.35 * u_intensity;
    disp += (wave - 0.5) * 0.2 * u_intensity;

    // Bass energy adds large-scale pulsing deformation
    disp += fbm(p * 0.8 + t * 0.3) * u_bassEnergy * 0.4;

    return d - disp;
}

vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.002, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

float raymarch(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        float d = map(ro + rd * t);
        if (abs(d) < SURF_DIST) break;
        t += d * 0.6; // conservative stepping for noisy SDF
        if (t > MAX_DIST) break;
    }
    return t;
}

// Fresnel
float fresnel(float cosTheta, float f0) {
    return f0 + (1.0 - f0) * pow(1.0 - cosTheta, 5.0);
}

// Gray gradient background
vec3 background(vec3 rd) {
    float y = rd.y * 0.9 + 0.9;
    return mix(vec3(0.9), vec3(0.9), y);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - u_resolution.xy * 0.5) / u_resolution.y;
    float t = u_time * u_speed;

    // Camera - gentle slow orbit
    float camDist = 3.5;
    float angle = t * 0.12;
    vec3 ro = vec3(cos(angle) * camDist, sin(t * 0.08) * 0.2, sin(angle) * camDist);
    vec3 lookAt = vec3(0.0);

    vec3 forward = normalize(lookAt - ro);
    vec3 right = normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
    vec3 up = cross(right, forward);
    vec3 rd = normalize(forward * 1.8 + right * uv.x + up * uv.y);

    vec3 col = background(rd);

    // Raymarch the displaced sphere
    float dist = raymarch(ro, rd);

    if (dist < MAX_DIST) {
        vec3 p = ro + rd * dist;
        vec3 n = calcNormal(p);

        float NdotV = max(dot(n, -rd), 0.0);
        float fres = fresnel(NdotV, 0.04);

        // Refraction and reflection
        vec3 refracted = refract(rd, n, 1.0 / 1.45);
        vec3 reflected = reflect(rd, n);

        // Refracted background — this is what makes it look clear
        vec3 refractedBg = background(refracted);

        // Second refraction: trace through interior to back face
        // Approximate by sampling background at a more distorted angle
        vec3 refracted2 = refract(refracted, -n, 1.45);
        if (length(refracted2) > 0.0) {
            refractedBg = background(refracted2);
        }

        // Very subtle interior tint — almost none for clarity
        float interiorDepth = length(p) / 1.5;
        refractedBg *= mix(vec3(1.0), vec3(0.97, 0.97, 0.98), interiorDepth * 0.3);

        // Reflected environment
        vec3 reflectedCol = background(reflected);

        // Glass composition: mostly refraction, some reflection at edges
        col = mix(refractedBg, reflectedCol, fres);

        // Lighting
        vec3 lightDir = normalize(vec3(0.5, 0.8, -0.3));
        float diff = max(dot(n, lightDir), 0.0);

        // Specular highlights — sharp, glassy
        vec3 h = normalize(lightDir - rd);
        float spec = pow(max(dot(n, h), 0.0), 200.0);
        col += vec3(1.0) * spec * 0.8;

        vec3 lightDir2 = normalize(vec3(-0.6, 0.3, 0.8));
        float spec2 = pow(max(dot(n, normalize(lightDir2 - rd)), 0.0), 120.0);
        col += vec3(0.9) * spec2 * 0.3;

        // Very subtle diffuse fill
        col += vec3(0.95) * diff * 0.05;

        // Rim brightening
        float rim = pow(1.0 - NdotV, 3.0);
        col += vec3(0.8, 0.8, 0.78) * rim * 0.9;

        // Edge definition
        float edge = smoothstep(0.12, 0.0, NdotV);
        col = mix(col, vec3(0.5), edge * 0.1);

        // The displaced normals catch light in complex ways —
        // add subtle caustic-like brightness variation from normal complexity
        float normalVar = length(n - normalize(p));
        col += vec3(1.0) * normalVar * 0.15;
    }

    // Subtle vignette
    vec2 vig = gl_FragCoord.xy / u_resolution.xy;
    col *= 0.85 + 0.15 * pow(16.0 * vig.x * vig.y * (1.0 - vig.x) * (1.0 - vig.y), 0.25);

    // Gamma
    col = pow(clamp(col, 0.0, 1.0), vec3(0.4545));

    gl_FragColor = vec4(col, 1.0);
}
