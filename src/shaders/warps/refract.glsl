precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform sampler2D u_texture;
uniform sampler2D u_bgTexture;
uniform vec2 u_textureSize;
uniform vec2 u_bgTextureSize;
uniform float u_deform;
uniform float u_geometry;
uniform float u_speed;
uniform int u_hasTexture;
uniform int u_hasBgTexture;

#include "/lygia/math/rotate3dX.glsl"
#include "/lygia/math/rotate3dY.glsl"
#include "/lygia/generative/snoise.glsl"
#include "/lygia/sdf/sphereSDF.glsl"

// Smooth min for organic merging
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// Glass vessel scene
float map(vec3 p) {
    float t = u_time * u_speed * 0.3;
    float geo = u_geometry;

    // Slow rotation
    p = rotate3dY(t * 0.2) * p;

    // Main body — slightly flattened sphere
    vec3 ps = p;
    ps.y *= 1.15;
    float body = sphereSDF(ps, 0.55 * geo);

    // Organic bulge that breathes
    float breathe = 0.95 + 0.05 * sin(t * 1.5);
    vec3 p2 = p - vec3(0.0, -0.1, 0.0);
    float bulge = sphereSDF(p2, 0.45 * geo * breathe);
    body = smin(body, bulge, 0.3 * geo);

    // Flowing protrusion
    vec3 p3 = p - vec3(
        sin(t * 0.5) * 0.25,
        0.3 + sin(t * 0.7) * 0.1,
        cos(t * 0.5) * 0.2
    ) * geo;
    float lobe = sphereSDF(p3, 0.25 * geo);
    body = smin(body, lobe, 0.35 * geo);

    // Second lobe
    vec3 p4 = p - vec3(
        -sin(t * 0.6 + 1.0) * 0.2,
        -0.25 + cos(t * 0.4) * 0.1,
        cos(t * 0.6 + 1.0) * 0.25
    ) * geo;
    float lobe2 = sphereSDF(p4, 0.2 * geo);
    body = smin(body, lobe2, 0.3 * geo);

    // Surface ripples
    float ripple = snoise(p * 2.5 + t * 0.3) * 0.04
                 + snoise(p * 5.0 - t * 0.2) * 0.015;
    body += ripple * u_deform;

    return body;
}

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
        float d = map(ro + rd * t);
        if (d < 0.0005) return t;
        if (t > 12.0) break;
        t += d * 0.8;
    }
    return -1.0;
}

// Cover-fit: scale UVs so texture fills canvas without letterboxing
vec2 coverUV(vec2 uv, vec2 texSize, vec2 screenSize) {
    float screenAspect = screenSize.x / screenSize.y;
    float texAspect = texSize.x / texSize.y;
    vec2 scale = vec2(1.0);
    if (texAspect > screenAspect) {
        scale.x = screenAspect / texAspect;
    } else {
        scale.y = texAspect / screenAspect;
    }
    return (uv - 0.5) * scale + 0.5;
}

// Procedural fallbacks
vec3 proceduralInner(vec2 uv) {
    float t = u_time * u_speed * 0.5;
    vec3 c1 = vec3(0.1, 0.2, 0.5);
    vec3 c2 = vec3(0.9, 0.4, 0.2);
    float n = sin(uv.x * 8.0 + t) * cos(uv.y * 6.0 - t * 0.7) * 0.5 + 0.5;
    return mix(c1, c2, n);
}

vec3 proceduralBg(vec2 uv) {
    float t = u_time * u_speed * 0.2;
    vec3 c1 = vec3(0.02, 0.03, 0.08);
    vec3 c2 = vec3(0.15, 0.08, 0.2);
    float g = length(uv - 0.5);
    return mix(c2, c1, smoothstep(0.0, 0.7, g));
}

// Sample inner video (geometry texture)
vec3 sampleInner(vec2 uv) {
    uv = clamp(uv, 0.0, 1.0);
    if (u_hasTexture == 1) {
        return texture2D(u_texture, coverUV(uv, u_textureSize, u_resolution)).rgb;
    }
    return proceduralInner(uv);
}

// Sample background video
vec3 sampleBg(vec2 uv) {
    uv = clamp(uv, 0.0, 1.0);
    if (u_hasBgTexture == 1) {
        return texture2D(u_bgTexture, coverUV(uv, u_bgTextureSize, u_resolution)).rgb;
    }
    return proceduralBg(uv);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;

    // Camera
    vec3 ro = vec3(0.0, 0.0, 2.8);
    vec3 rd = normalize(vec3(p, -1.5));

    // Mouse orbit
    if (u_mouse.x > 0.0) {
        vec2 m = u_mouse / u_resolution.xy - 0.5;
        mat3 rotY = mat3(rotate3dY(m.x * 3.14));
        mat3 rotX = mat3(rotate3dX(-m.y * 1.5));
        ro = rotY * rotX * ro;
        rd = rotY * rotX * rd;
    }

    // Background
    vec3 color = sampleBg(uv);

    float t = raymarch(ro, rd);

    if (t > 0.0) {
        vec3 hitPos = ro + rd * t;
        vec3 normal = calcNormal(hitPos);

        float deformAmount = u_deform;

        // Fresnel — edges reflect more, center is see-through
        float fresnel = pow(1.0 - max(dot(-rd, normal), 0.0), 3.5);

        // --- Refraction: bend the background through the glass ---
        float ior = 1.0 + deformAmount * 0.5;
        vec3 refracted = refract(rd, normal, 1.0 / ior);
        if (length(refracted) < 0.001) refracted = reflect(rd, normal);

        // Refracted background — the background seen through the glass, distorted
        vec2 refractedBgUV = uv + refracted.xy * 0.12 * deformAmount;
        float spread = 0.012 * deformAmount;
        vec3 refractedBg;
        refractedBg.r = sampleBg(refractedBgUV + vec2(spread, 0.0)).r;
        refractedBg.g = sampleBg(refractedBgUV).g;
        refractedBg.b = sampleBg(refractedBgUV - vec2(spread, 0.0)).b;

        // Inner video — mapped inside the object volume
        vec3 innerPoint = hitPos + refracted * 0.5 * u_geometry;
        vec2 innerUV = innerPoint.xy * 0.4 + 0.5;
        vec3 innerColor;
        innerColor.r = sampleInner(innerUV + vec2(spread, 0.0)).r;
        innerColor.g = sampleInner(innerUV).g;
        innerColor.b = sampleInner(innerUV - vec2(spread, 0.0)).b;

        // --- Reflection: background distorted on the surface ---
        vec3 reflected = reflect(rd, normal);
        vec2 reflectUV = reflected.xy * 0.35 + 0.5;
        reflectUV += sin(hitPos.yz * 8.0 + u_time * u_speed) * 0.01 * deformAmount;
        vec3 reflColor = sampleBg(reflectUV);

        // --- Compose layers ---
        // The glass is mostly transparent: blend refracted bg + inner video
        // Inner video is layered on top of the refracted background at low opacity
        float innerOpacity = 0.35;
        vec3 throughGlass = mix(refractedBg, innerColor, innerOpacity);

        // Mix see-through vs reflection based on Fresnel (edges reflect more)
        vec3 glassColor = mix(throughGlass, reflColor, fresnel * 0.5);

        // Specular highlights
        vec3 lightDir = normalize(vec3(0.6, 0.8, 0.5));
        vec3 halfVec = normalize(lightDir - rd);
        float spec = pow(max(dot(normal, halfVec), 0.0), 80.0);

        vec3 lightDir2 = normalize(vec3(-0.5, 0.3, -0.7));
        float spec2 = pow(max(dot(normal, normalize(lightDir2 - rd)), 0.0), 40.0) * 0.4;

        // Caustic shimmer
        float caustic = pow(abs(sin(
            hitPos.x * 12.0 + hitPos.z * 10.0 + u_time * u_speed * 1.5
        )), 10.0);
        caustic += pow(abs(sin(
            hitPos.y * 14.0 - hitPos.x * 8.0 + u_time * u_speed * 1.2
        )), 12.0) * 0.5;

        // Very subtle glass tint
        vec3 glassTint = vec3(0.96, 0.98, 1.0);
        color = glassColor * glassTint;

        // Specular on top
        color += vec3(1.0, 0.98, 0.96) * (spec + spec2) * 0.5;

        // Faint caustics
        color += vec3(0.3, 0.5, 0.7) * caustic * 0.04 * deformAmount;

        // Subtle edge glow so you can still see the shape
        color += vec3(0.4, 0.6, 0.9) * fresnel * 0.08;
    }

    gl_FragColor = vec4(color, 1.0);
}
