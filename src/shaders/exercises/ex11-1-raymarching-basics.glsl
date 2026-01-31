precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

// =============================================================================
// RAYMARCHING: Sphere Tracing Through Distance Fields
// =============================================================================
//
// Raymarching is a technique for rendering 3D scenes without polygons.
// Instead of triangles, we define shapes using "signed distance functions" (SDFs)
// that tell us how far any point is from the nearest surface.
//
// The algorithm:
// 1. Cast a ray from the camera through each pixel
// 2. "March" along the ray in steps
// 3. At each step, ask "how far am I from the nearest surface?"
// 4. Step forward by that distance (safe - we won't overshoot)
// 5. Repeat until we're very close to a surface (hit) or too far away (miss)
//
// This is called "sphere tracing" because at each step we're inside a sphere
// of empty space with radius = distance to nearest surface.
//
// This technique powers most of the impressive shaders on Shadertoy.
// =============================================================================

// Signed Distance Function for a sphere
// Returns: negative inside, zero on surface, positive outside
float sdSphere(vec3 p, float radius) {
    return length(p) - radius;
}

// The scene - returns distance to nearest surface
float map(vec3 p) {
    // A sphere of radius 1.0 at the origin
    return sdSphere(p, 1.0);
}

// Calculate surface normal using gradient of the distance field
vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

void main() {
    // Normalized coordinates (-1 to 1, aspect corrected)
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;

    // Camera setup
    vec3 ro = vec3(0.0, 0.0, -3.0);  // Ray origin (camera position)
    vec3 rd = normalize(vec3(uv, 1.0));  // Ray direction

    // Raymarching
    float t = 0.0;  // Distance traveled along ray
    float tMax = 20.0;  // Maximum distance

    for (int i = 0; i < 100; i++) {
        vec3 p = ro + rd * t;  // Current position
        float d = map(p);       // Distance to nearest surface

        if (d < 0.001) break;   // Hit! (close enough to surface)
        if (t > tMax) break;    // Miss (too far away)

        t += d;  // Step forward by the safe distance
    }

    // Coloring
    vec3 col = vec3(0.0);  // Background (black)

    if (t < tMax) {
        // We hit something!
        vec3 p = ro + rd * t;      // Hit position
        vec3 n = calcNormal(p);     // Surface normal

        // Simple diffuse lighting
        vec3 lightDir = normalize(vec3(1.0, 1.0, -1.0));
        float diff = max(dot(n, lightDir), 0.0);

        col = vec3(1.0, 0.5, 0.3) * (diff * 0.8 + 0.2);  // Orange sphere
    }

    // =================================================================
    // EXPERIMENTS TO TRY:
    // =================================================================
    //
    // 1. Move the sphere:
    //    float sdSphere(vec3 p, float radius) {
    //        return length(p - vec3(0.5, 0.0, 0.0)) - radius;
    //    }
    //
    // 2. Animate the sphere:
    //    vec3 center = vec3(sin(u_time), 0.0, 0.0);
    //    return length(p - center) - radius;
    //
    // 3. Change sphere size:
    //    return sdSphere(p, 0.5 + 0.3 * sin(u_time));
    //
    // 4. Move the camera:
    //    vec3 ro = vec3(sin(u_time) * 3.0, 0.0, cos(u_time) * -3.0);
    //
    // 5. Add fog (distance fade):
    //    col = mix(col, vec3(0.1, 0.1, 0.2), 1.0 - exp(-0.1 * t));
    //
    // =================================================================

    gl_FragColor = vec4(col, 1.0);
}
