// FlowHeart Warp - Apply heart-shaped flow field to images
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform sampler2D u_texture;
uniform vec2 u_textureSize;
uniform float u_deform;
uniform float u_geometry;
uniform float u_speed;
uniform int u_hasTexture;

#include "../lygia/math/const.glsl"
#include "../lygia/generative/snoise.glsl"

// FBM using simplex noise, remapped to 0-1 range
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 5; i++) {
        value += amplitude * (snoise(p) * 0.5 + 0.5);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// Heart signed distance function
float heartSDF(vec2 p) {
    p.x = abs(p.x);

    if (p.y + p.x > 1.0) {
        return sqrt(dot(p - vec2(0.25, 0.75), p - vec2(0.25, 0.75))) - sqrt(2.0) / 4.0;
    }

    return sqrt(min(dot(p - vec2(0.0, 1.0), p - vec2(0.0, 1.0)),
                    dot(p - 0.5 * max(p.x + p.y, 0.0), p - 0.5 * max(p.x + p.y, 0.0))))
           * sign(p.x - p.y);
}

// Flowing displacement field
vec2 flowField(vec2 p, float t, float density) {
    float n1 = fbm(p * 2.0 * density + t * 0.3);
    float n2 = fbm(p * 2.0 * density + t * 0.3 + 100.0);
    return vec2(n1 - 0.5, n2 - 0.5);
}

// Rope-like distortion based on heart shape
vec2 heartDistort(vec2 p, float t, float strength) {
    float angle = atan(p.y - 0.3, p.x);

    float wave = 0.0;
    wave += 0.03 * sin(angle * 8.0 + t * 2.0);
    wave += 0.02 * sin(angle * 13.0 - t * 3.0);
    wave += 0.015 * sin(angle * 21.0 + t * 1.5);

    float n = fbm(vec2(angle * 3.0, t * 0.5));
    wave += 0.04 * (n - 0.5);

    vec2 dir = normalize(p - vec2(0.0, 0.3) + 0.001);
    return dir * wave * strength;
}

// Procedural fallback
vec3 proceduralTexture(vec2 uv) {
    vec3 col = vec3(0.5);
    col += 0.4 * cos(uv.x * 4.0 + vec3(0.0, 2.0, 4.0));
    col *= 0.5 + 0.5 * sin(uv.y * 3.0 + vec3(1.0, 3.0, 5.0));
    return col;
}

vec3 sampleTexture(vec2 uv) {
    uv = clamp(uv, 0.0, 1.0);
    if (u_hasTexture == 1) {
        return texture2D(u_texture, vec2(uv.x, 1.0 - uv.y)).rgb;
    } else {
        return proceduralTexture(uv);
    }
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    float aspect = u_resolution.x / u_resolution.y;

    // Center coordinates for heart calculation
    vec2 p = (uv - 0.5) * 2.0;
    p.x *= aspect;
    p.y -= 0.1;

    float t = u_time * u_speed;
    float deform = u_deform;
    float geo = u_geometry;

    // Calculate heart distance for masking/blending
    float heartD = heartSDF(p * 1.8);

    // Heart-shaped distortion (stronger near heart edge)
    float edgeFactor = exp(-abs(heartD) * 5.0);
    float heartMask = smoothstep(0.5, -0.2, heartD);

    // Flow field displacement - concentrated around the heart
    vec2 flow = flowField(p, t, geo) * 0.15 * deform * heartMask;

    vec2 heartWarp = heartDistort(p, t, geo) * deform * edgeFactor;

    // Combine distortions
    vec2 totalWarp = flow + heartWarp;

    // Apply to UV
    vec2 warpedUV = uv + totalWarp * 0.3;

    // Sample texture
    vec3 color = sampleTexture(warpedUV);

    // Optional: Add subtle heart glow overlay
    float heartGlow = smoothstep(0.3, -0.1, heartD);
    float pulse = 0.8 + 0.2 * sin(t * 1.5);
    vec3 glowColor = vec3(1.0, 0.3, 0.5);
    color = mix(color, color + glowColor * 0.3, heartGlow * pulse * deform * 0.5);

    // Vignette
    float vignette = 1.0 - length(uv - 0.5) * 0.5 * deform;
    color *= vignette;

    gl_FragColor = vec4(color, 1.0);
}
