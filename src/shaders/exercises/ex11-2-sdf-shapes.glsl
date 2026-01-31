precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

// =============================================================================
// SDF SHAPES: The Building Blocks of Raymarching
// =============================================================================
//
// Signed Distance Functions (SDFs) return the distance from a point to a shape.
// Negative = inside, Zero = on surface, Positive = outside.
//
// These functions are the vocabulary of raymarching. Inigo Quilez (IQ) has
// documented dozens of them at: https://iquilezles.org/articles/distfunctions/
//
// Most advanced shaders use IQ's SDF library - you'll recognize these
// functions in code throughout Shadertoy, including "Desert Passage II."
// =============================================================================

// --- BASIC SHAPES (from IQ's library) ---

// Sphere
float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

// Box (exact)
float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

// Torus
float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

// Cylinder (capped)
float sdCylinder(vec3 p, float r, float h) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

// Plane (infinite, pointing up)
float sdPlane(vec3 p) {
    return p.y;
}

// --- THE SCENE ---

float map(vec3 p) {
    // TODO: Change which shape is rendered by uncommenting different lines

    // Sphere
    float d = sdSphere(p, 1.0);

    // Box
    // float d = sdBox(p, vec3(0.75));

    // Torus (donut)
    // float d = sdTorus(p, vec2(1.0, 0.3));

    // Cylinder
    // float d = sdCylinder(p, 0.5, 1.0);

    // Floor plane
    // float d = sdPlane(p + vec3(0.0, 1.0, 0.0));

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

    // Rotating camera
    float angle = u_time * 0.5;
    vec3 ro = vec3(sin(angle) * 4.0, 2.0, cos(angle) * 4.0);
    vec3 target = vec3(0.0);

    // Camera matrix (look-at)
    vec3 forward = normalize(target - ro);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = cross(forward, right);
    vec3 rd = normalize(forward + uv.x * right + uv.y * up);

    float t = raymarch(ro, rd);

    vec3 col = vec3(0.1, 0.1, 0.15);  // Background

    if (t < 20.0) {
        vec3 p = ro + rd * t;
        vec3 n = calcNormal(p);

        // Lighting
        vec3 lightDir = normalize(vec3(1.0, 2.0, -1.0));
        float diff = max(dot(n, lightDir), 0.0);
        float amb = 0.2;

        // Color based on normal (shows shape nicely)
        vec3 baseCol = n * 0.5 + 0.5;
        col = baseCol * (diff + amb);
    }

    // =================================================================
    // EXPERIMENTS TO TRY:
    // =================================================================
    //
    // 1. Combine two shapes with min() (union):
    //    float d = min(sdSphere(p, 1.0), sdPlane(p + vec3(0, 1, 0)));
    //
    // 2. Animate shape parameters:
    //    float d = sdTorus(p, vec2(1.0 + 0.3*sin(u_time), 0.3));
    //
    // 3. Repeat shapes infinitely:
    //    vec3 q = mod(p + 2.0, 4.0) - 2.0;  // Repeat every 4 units
    //    float d = sdSphere(q, 0.5);
    //
    // 4. Stretch a shape:
    //    vec3 q = p * vec3(1.0, 2.0, 1.0);  // Stretch in Y
    //    float d = sdSphere(q, 1.0) / 2.0;  // Divide to correct distance
    //
    // =================================================================

    gl_FragColor = vec4(col, 1.0);
}
