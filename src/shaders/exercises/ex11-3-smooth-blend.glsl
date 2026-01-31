precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

// =============================================================================
// SMOOTH BLENDING: IQ's Smooth Min/Max
// =============================================================================
//
// In raymarching, min(a, b) creates a union of two shapes - but the join
// is sharp. For organic shapes (creatures, terrain, metaballs), we need
// shapes that flow into each other smoothly.
//
// Inigo Quilez's smooth minimum function solves this. It's one of the most
// important and widely-used functions in shader programming.
//
// The "k" parameter controls blend radius:
// - k = 0: same as regular min (sharp)
// - k = 0.5: gentle blend
// - k = 2.0: very smooth, blobby blend
//
// You'll see smin() in nearly every organic raymarched shader, including
// "Desert Passage II" which uses it for terrain and rock blending.
//
// Source: https://iquilezles.org/articles/smin/
// =============================================================================

// --- IQ'S SMOOTH MINIMUM ---
// Polynomial smooth min (attempt by Media Molecule's Dave Smith)
float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

// Smooth maximum (just flip the signs)
float smax(float a, float b, float k) {
    return -smin(-a, -b, k);
}

// --- BASIC SHAPES ---

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdPlane(vec3 p) {
    return p.y;
}

// --- THE SCENE ---

float map(vec3 p) {
    // Two spheres that blend together
    float sphere1 = sdSphere(p - vec3(-0.8, 0.0, 0.0), 1.0);
    float sphere2 = sdSphere(p - vec3(0.8, 0.0, 0.0), 1.0);

    // Blend factor - try changing this! (0.1 to 2.0)
    float k = 0.5;

    // Smooth union of spheres
    float d = smin(sphere1, sphere2, k);

    // Add a floor
    float floor = sdPlane(p + vec3(0.0, 1.2, 0.0));
    d = min(d, floor);

    return d;
}

// --- RAYMARCHING INFRASTRUCTURE ---

vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

float raymarch(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < 100; i++) {
        vec3 p = ro + rd * t;
        float d = map(p);
        if (d < 0.001 || t > 20.0) break;
        t += d;
    }
    return t;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;

    // Camera
    vec3 ro = vec3(0.0, 2.0, -5.0);
    vec3 target = vec3(0.0, 0.0, 0.0);

    vec3 forward = normalize(target - ro);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = cross(forward, right);
    vec3 rd = normalize(forward + uv.x * right + uv.y * up);

    float t = raymarch(ro, rd);

    vec3 col = vec3(0.4, 0.5, 0.6);  // Sky

    if (t < 20.0) {
        vec3 p = ro + rd * t;
        vec3 n = calcNormal(p);

        vec3 lightDir = normalize(vec3(1.0, 2.0, -1.0));
        float diff = max(dot(n, lightDir), 0.0);

        // Checkerboard floor
        vec3 baseCol = vec3(0.9, 0.6, 0.4);  // Blob color
        if (p.y < -1.1) {
            float checker = mod(floor(p.x) + floor(p.z), 2.0);
            baseCol = mix(vec3(0.3), vec3(0.7), checker);
        }

        col = baseCol * (diff * 0.7 + 0.3);

        // Fog
        col = mix(col, vec3(0.4, 0.5, 0.6), 1.0 - exp(-0.05 * t));
    }

    // =================================================================
    // EXPERIMENTS TO TRY:
    // =================================================================
    //
    // 1. Animate the spheres moving apart/together:
    //    vec3(-0.8 - sin(u_time)*0.5, 0.0, 0.0)
    //    vec3(0.8 + sin(u_time)*0.5, 0.0, 0.0)
    //
    // 2. Change blend factor with time:
    //    float k = 0.3 + 0.5 * (sin(u_time) * 0.5 + 0.5);
    //
    // 3. Add a third sphere:
    //    float sphere3 = sdSphere(p - vec3(0.0, 1.0, 0.0), 0.7);
    //    float d = smin(smin(sphere1, sphere2, k), sphere3, k);
    //
    // 4. Mix different shapes:
    //    float box = sdBox(p - vec3(0.0, 0.5, 0.0), vec3(0.5));
    //    float d = smin(sphere1, box, 0.5);
    //
    // 5. Use smax for smooth intersection/carving:
    //    float d = smax(sphere1, -sphere2, 0.3);  // Carve sphere2 from sphere1
    //
    // 6. Create a metaball effect (many small spheres):
    //    float d = 1000.0;
    //    for (float i = 0.0; i < 5.0; i++) {
    //        vec3 offset = vec3(sin(i*1.3+u_time), cos(i*1.7+u_time), sin(i*2.1));
    //        d = smin(d, sdSphere(p - offset, 0.4), 0.5);
    //    }
    //
    // =================================================================

    gl_FragColor = vec4(col, 1.0);
}
