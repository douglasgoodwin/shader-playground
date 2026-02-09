precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform sampler2D u_texture;
uniform vec2 u_textureSize;
uniform float u_deform;
uniform float u_geometry;
uniform float u_speed;
uniform int u_hasTexture;

#include "../lygia/math/rotate3dX.glsl"
#include "../lygia/math/rotate3dY.glsl"
#include "../lygia/sdf/sphereSDF.glsl"
#include "../lygia/sdf/boxSDF.glsl"
#include "../lygia/sdf/torusSDF.glsl"

// Smooth min for blending shapes
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// Scene - geometry that deforms the texture
float map(vec3 p) {
    float t = u_time * u_speed * 0.3;
    float geo = u_geometry;

    // Rotate
    p = rotate3dY(t * 0.5) * rotate3dX(t * 0.3) * p;

    // Base box
    float box = boxSDF(p, vec3(0.6, 0.4, 0.5));

    // Spherical bumps
    float bumps = 1e10;
    bumps = min(bumps, sphereSDF(p - vec3(0.5, 0.3, 0.4) * geo, 0.25 * geo));
    bumps = min(bumps, sphereSDF(p - vec3(-0.4, -0.2, 0.5) * geo, 0.3 * geo));
    bumps = min(bumps, sphereSDF(p - vec3(0.3, -0.4, -0.3) * geo, 0.2 * geo));
    bumps = min(bumps, sphereSDF(p - vec3(-0.5, 0.4, -0.2) * geo, 0.28 * geo));

    // Torus ring
    float torus = torusSDF(p, vec2(0.5 * geo, 0.15));

    // Blend together
    float d = smin(box, bumps, 0.2);
    d = smin(d, torus, 0.15);

    return d;
}

// Calculate surface normal
vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

// Raymarch
float raymarch(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < 80; i++) {
        vec3 p = ro + rd * t;
        float d = map(p);
        if (d < 0.001) return t;
        if (t > 10.0) break;
        t += d;
    }
    return -1.0;
}

// Procedural fallback texture
vec3 proceduralTexture(vec2 uv) {
    vec3 col = vec3(0.5);
    col += 0.4 * cos(uv.x * 4.0 + vec3(0.0, 2.0, 4.0));
    col *= 0.5 + 0.5 * sin(uv.y * 3.0 + vec3(1.0, 3.0, 5.0));
    float stripe = sin((uv.x + uv.y) * 15.0) * 0.5 + 0.5;
    col = mix(col, col * 1.2, stripe * 0.3);
    return col;
}

// Sample texture (image or procedural)
vec3 sampleTexture(vec2 uv) {
    // Clamp UV to 0-1 range (no tiling)
    uv = clamp(uv, 0.0, 1.0);

    if (u_hasTexture == 1) {
        // Flip Y for image textures
        return texture2D(u_texture, vec2(uv.x, 1.0 - uv.y)).rgb;
    } else {
        return proceduralTexture(uv);
    }
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;

    // Camera
    vec3 ro = vec3(0.0, 0.0, 2.5);
    vec3 rd = normalize(vec3(p, -1.5));

    // Mouse interaction
    if (u_mouse.x > 0.0) {
        vec2 m = u_mouse / u_resolution.xy - 0.5;
        ro = rotate3dY(m.x * 3.14) * rotate3dX(-m.y * 1.5) * ro;
        rd = rotate3dY(m.x * 3.14) * rotate3dX(-m.y * 1.5) * rd;
    }

    // Flat texture UV (screen space)
    vec2 flatUV = uv;

    // Background - sample flat texture
    vec3 color = sampleTexture(flatUV);

    // Raymarch to find geometry
    float t = raymarch(ro, rd);

    if (t > 0.0) {
        vec3 hitPos = ro + rd * t;
        vec3 normal = calcNormal(hitPos);

        // Start with flat UV
        vec2 deformedUV = flatUV;

        // Apply deformation based on 3D surface
        float deformAmount = u_deform;

        // Offset UV based on hit position (draping effect)
        deformedUV += hitPos.xy * deformAmount * 0.3;

        // Normal-based distortion
        deformedUV += normal.xy * deformAmount * 0.15;

        // Depth stretch
        deformedUV += (hitPos.z + 1.0) * rd.xy * deformAmount * 0.1;

        // Sample at deformed coordinates
        vec3 surfaceColor = sampleTexture(deformedUV);

        // Subtle shading to reveal 3D form
        float diffuse = max(dot(normal, normalize(vec3(1.0, 1.0, 1.0))), 0.0);
        float ambient = 0.3;
        float shade = mix(1.0, ambient + diffuse * 0.7, deformAmount * 0.5);

        color = surfaceColor * shade;

        // Edge darkening (fresnel)
        float fresnel = pow(1.0 - max(dot(-rd, normal), 0.0), 2.0);
        color = mix(color, color * 0.6, fresnel * deformAmount * 0.4);
    }

    gl_FragColor = vec4(color, 1.0);
}
