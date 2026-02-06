// Phyllotaxis - John Edmark-inspired blooming sculpture
// Rotating golden angle arrangement creates apparent spiral motion

precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_density;
uniform float u_harmonics;

#define PI 3.14159265359
#define TAU 6.28318530718
#define GOLDEN_ANGLE 2.39996323
#define MAX_STEPS 80
#define MAX_DIST 30.0
#define SURF_DIST 0.0005

mat3 rotateY(float a) {
    float c = cos(a), s = sin(a);
    return mat3(c, 0, s, 0, 1, 0, -s, 0, c);
}

// Smooth min
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// Track hit info for coloring
float hitIndex = -1.0;
float hitLayer = 0.0;

float scene(vec3 p) {
    float t = u_time * u_speed;

    // Edmark's key insight: rotate the whole sculpture
    // At golden-angle-synced speed, elements appear to spiral outward
    p = rotateY(t * GOLDEN_ANGLE * 0.15) * p;

    float d = MAX_DIST;

    // Number of elements
    int numElements = int(60.0 * u_density);

    // Multiple layers like Edmark's stacked sculptures
    for (int layer = 0; layer < 3; layer++) {
        float layerOffset = float(layer) * 0.8;
        float layerScale = 1.0 - float(layer) * 0.15;

        for (int i = 0; i < 100; i++) {
            if (i >= numElements) break;

            float fi = float(i);

            // Golden angle arrangement
            float angle = fi * GOLDEN_ANGLE;

            // Radius increases with sqrt for even packing
            float radius = (0.3 + layerOffset * 0.1) * sqrt(fi + 1.0) * u_harmonics * layerScale;

            // Height follows a dome/spiral - this creates the blooming effect
            float maxR = 0.3 * sqrt(float(numElements)) * u_harmonics;
            float normalizedR = min(radius / maxR, 1.0);

            // Dome shape with spiral lift
            float baseHeight = (1.0 - normalizedR * normalizedR) * 2.5;
            // Add helical rise - key to Edmark's flowing look
            float helixHeight = fi * 0.02 * u_harmonics;
            float y = baseHeight + helixHeight + layerOffset;

            // Position
            float x = cos(angle) * radius;
            float z = sin(angle) * radius;
            vec3 pos = vec3(x, y, z);

            // Sphere size varies - larger toward outside
            float sphereR = (0.12 + normalizedR * 0.08) * layerScale;

            float sphere = length(p - pos) - sphereR;

            if (sphere < d) {
                hitIndex = fi;
                hitLayer = float(layer);
            }

            d = smin(d, sphere, 0.02);
        }
    }

    // Central core/stem
    float stemR = 0.2;
    float stem = length(p.xz) - stemR;
    stem = max(stem, -p.y - 0.5);
    stem = max(stem, p.y - 3.5 * u_harmonics);

    if (stem < d) {
        hitIndex = -1.0;
    }
    d = smin(d, stem, 0.15);

    return d;
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        scene(p + e.xyy) - scene(p - e.xyy),
        scene(p + e.yxy) - scene(p - e.yxy),
        scene(p + e.yyx) - scene(p - e.yyx)
    ));
}

float getAO(vec3 p, vec3 n) {
    float ao = 0.0;
    float scale = 1.0;
    for (int i = 0; i < 3; i++) {
        float dist = 0.05 + 0.1 * float(i);
        ao += (dist - scene(p + n * dist)) * scale;
        scale *= 0.5;
    }
    return clamp(1.0 - ao * 3.0, 0.0, 1.0);
}

float raymarch(vec3 ro, vec3 rd) {
    float d = 0.0;

    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d;
        float ds = scene(p);
        d += ds * 0.7;
        if (abs(ds) < SURF_DIST || d > MAX_DIST) break;
    }

    return d;
}

vec3 getColor(vec3 p, vec3 n) {
    float t = u_time * u_speed;

    if (hitIndex < 0.0) {
        // Stem - warm wood tone
        return vec3(0.35, 0.25, 0.15);
    }

    // Edmark's sculptures are often single material (3D printed)
    // but we can add subtle variation based on spiral position

    // Base color - creamy white like his prints
    vec3 baseColor = vec3(0.95, 0.92, 0.88);

    // Subtle warm/cool variation based on spiral arm
    float spiral = mod(hitIndex, 13.0) / 13.0;
    vec3 warmTint = vec3(1.0, 0.95, 0.9);
    vec3 coolTint = vec3(0.9, 0.95, 1.0);
    baseColor *= mix(warmTint, coolTint, spiral);

    // Darken inner layers slightly for depth
    baseColor *= 1.0 - hitLayer * 0.08;

    return baseColor;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

    float t = u_time * u_speed;

    // Camera - subtle orbit, mostly front view like Edmark's videos
    vec2 mouse = u_mouse / u_resolution - 0.5;
    float camAngle = mouse.x * 1.5 + 0.5;
    float camHeight = 1.5 + mouse.y * 2.0;
    float camDist = 6.0;

    vec3 ro = vec3(
        sin(camAngle) * camDist,
        camHeight,
        cos(camAngle) * camDist
    );

    vec3 target = vec3(0.0, 1.2, 0.0);
    vec3 forward = normalize(target - ro);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = cross(forward, right);

    vec3 rd = normalize(forward + uv.x * right + uv.y * up);

    // Reset tracking
    hitIndex = -1.0;
    hitLayer = 0.0;

    float d = raymarch(ro, rd);

    // Clean gradient background
    vec3 bgTop = vec3(0.15, 0.17, 0.2);
    vec3 bgBot = vec3(0.08, 0.08, 0.1);
    vec3 color = mix(bgBot, bgTop, uv.y + 0.5);

    if (d < MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = getNormal(p);

        // Re-evaluate for correct hit info
        scene(p);

        vec3 baseColor = getColor(p, n);

        // Soft studio lighting like Edmark's presentation
        vec3 lightDir1 = normalize(vec3(0.5, 1.0, 0.8));
        vec3 lightDir2 = normalize(vec3(-0.7, 0.3, -0.5));
        vec3 lightDir3 = normalize(vec3(0.0, -0.5, 1.0)); // Rim from below

        float diff1 = max(dot(n, lightDir1), 0.0);
        float diff2 = max(dot(n, lightDir2), 0.0) * 0.4;
        float diff3 = max(dot(n, lightDir3), 0.0) * 0.2;

        // Soft specular
        vec3 viewDir = normalize(ro - p);
        vec3 h1 = normalize(lightDir1 + viewDir);
        float spec = pow(max(dot(n, h1), 0.0), 16.0) * 0.3;

        // Ambient occlusion for depth in crevices
        float ao = getAO(p, n);

        // Fresnel rim
        float fresnel = pow(1.0 - max(dot(n, viewDir), 0.0), 4.0);

        // Combine - aim for that clean 3D print look
        vec3 ambient = vec3(0.25, 0.23, 0.22) * ao;
        color = baseColor * (ambient + diff1 * 0.6 + diff2 + diff3);
        color += vec3(1.0, 0.98, 0.95) * spec;
        color += vec3(0.3, 0.35, 0.4) * fresnel * 0.4;

        // Subtle subsurface for organic feel
        float sss = pow(max(dot(viewDir, -lightDir1), 0.0), 2.0) * 0.1;
        color += baseColor * sss;

        // Distance fog
        float fog = 1.0 - exp(-d * 0.08);
        color = mix(color, mix(bgBot, bgTop, 0.5), fog * 0.5);
    }

    // Subtle vignette
    float vignette = 1.0 - length(uv) * 0.3;
    color *= vignette;

    // Gamma
    color = pow(color, vec3(0.4545));

    gl_FragColor = vec4(color, 1.0);
}
