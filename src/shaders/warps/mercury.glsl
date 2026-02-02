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

// Rotation matrices
mat3 rotateY(float a) {
    float c = cos(a), s = sin(a);
    return mat3(c, 0, s, 0, 1, 0, -s, 0, c);
}

mat3 rotateX(float a) {
    float c = cos(a), s = sin(a);
    return mat3(1, 0, 0, 0, c, -s, 0, s, c);
}

// Smooth min for liquid blob merging - larger k = more blend
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// Simple noise functions for organic movement
float hash(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    return mix(mix(mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), f.x),
                   mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
               mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
                   mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

// SDF for sphere
float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

// Mercury blob scene - multiple spheres that merge like liquid
float map(vec3 p) {
    float t = u_time * u_speed * 0.4;
    float geo = u_geometry;

    // Slow rotation for the whole scene
    p = rotateY(t * 0.15) * p;

    // Main central blob - pulsing gently
    float pulse = 0.95 + 0.05 * sin(t * 2.0);
    float mainBlob = sdSphere(p, 0.45 * geo * pulse);

    // Orbiting blobs with different phases and speeds
    // They move in elliptical paths and bob up/down

    // Blob 1 - larger, slower orbit
    vec3 p1 = p - vec3(
        sin(t * 0.7) * 0.6,
        sin(t * 1.1) * 0.25,
        cos(t * 0.7) * 0.5
    ) * geo;
    float blob1 = sdSphere(p1, 0.28 * geo * (0.9 + 0.1 * sin(t * 1.5)));

    // Blob 2 - medium, faster orbit
    vec3 p2 = p - vec3(
        cos(t * 0.9 + 2.0) * 0.55,
        sin(t * 1.3 + 1.0) * 0.3,
        sin(t * 0.9 + 2.0) * 0.45
    ) * geo;
    float blob2 = sdSphere(p2, 0.22 * geo * (0.95 + 0.05 * sin(t * 2.1)));

    // Blob 3 - smaller, different plane
    vec3 p3 = p - vec3(
        sin(t * 1.1 + 4.0) * 0.5,
        cos(t * 0.8) * 0.4,
        cos(t * 1.1 + 4.0) * 0.35
    ) * geo;
    float blob3 = sdSphere(p3, 0.18 * geo);

    // Blob 4 - tiny, fast
    vec3 p4 = p - vec3(
        cos(t * 1.4 + 1.5) * 0.4,
        sin(t * 1.6 + 0.5) * 0.35,
        sin(t * 1.2 + 1.5) * 0.5
    ) * geo;
    float blob4 = sdSphere(p4, 0.12 * geo);

    // Blob 5 - dripping down periodically
    float dripPhase = mod(t * 0.5, 6.28);
    float dripY = -0.3 - 0.4 * smoothstep(0.0, 3.14, dripPhase) * (1.0 - smoothstep(3.14, 6.28, dripPhase));
    vec3 p5 = p - vec3(
        sin(t * 0.3) * 0.15,
        dripY,
        cos(t * 0.3) * 0.15
    ) * geo;
    float blob5 = sdSphere(p5, 0.15 * geo * (1.0 + 0.3 * sin(dripPhase)));

    // Merge all blobs with smooth minimum for liquid effect
    // Larger k value = more gooey merging
    float k = 0.25 * geo;
    float d = mainBlob;
    d = smin(d, blob1, k);
    d = smin(d, blob2, k);
    d = smin(d, blob3, k * 0.8);
    d = smin(d, blob4, k * 0.6);
    d = smin(d, blob5, k);

    // Add subtle surface ripples using noise
    float ripple = noise(p * 8.0 + t * 0.5) * 0.02;
    d += ripple * geo;

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

// Procedural fallback texture - metallic gradient
vec3 proceduralTexture(vec2 uv) {
    // Silvery metallic gradient
    vec3 col = vec3(0.75, 0.77, 0.8);
    col += 0.15 * cos(uv.x * 3.0 + vec3(0.0, 0.3, 0.6));
    col *= 0.85 + 0.15 * sin(uv.y * 4.0 + vec3(0.2, 0.4, 0.6));
    return col;
}

// Sample texture (image or procedural)
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
    vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;

    // Camera
    vec3 ro = vec3(0.0, 0.0, 2.5);
    vec3 rd = normalize(vec3(p, -1.5));

    // Mouse interaction
    if (u_mouse.x > 0.0) {
        vec2 m = u_mouse / u_resolution.xy - 0.5;
        ro = rotateY(m.x * 3.14) * rotateX(-m.y * 1.5) * ro;
        rd = rotateY(m.x * 3.14) * rotateX(-m.y * 1.5) * rd;
    }

    // Flat texture UV
    vec2 flatUV = uv;

    // Background
    vec3 color = sampleTexture(flatUV);

    // Raymarch to find geometry
    float t = raymarch(ro, rd);

    if (t > 0.0) {
        vec3 hitPos = ro + rd * t;
        vec3 normal = calcNormal(hitPos);

        // Start with flat UV
        vec2 deformedUV = flatUV;
        float deformAmount = u_deform;

        // Mercury-like UV distortion - more reflection/refraction feel
        // Offset based on normal for that liquid metal look
        deformedUV += normal.xy * deformAmount * 0.25;

        // Add subtle wobble based on surface position
        float wobble = sin(hitPos.x * 10.0 + u_time * u_speed) *
                       cos(hitPos.y * 8.0 + u_time * u_speed * 0.7);
        deformedUV += wobble * 0.02 * deformAmount;

        // Environment reflection simulation
        vec3 reflected = reflect(rd, normal);
        deformedUV += reflected.xy * deformAmount * 0.1;

        // Sample at deformed coordinates
        vec3 surfaceColor = sampleTexture(deformedUV);

        // Mercury-like lighting - highly reflective
        vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0));
        float diffuse = max(dot(normal, lightDir), 0.0);

        // Strong specular for metallic look
        vec3 halfVec = normalize(lightDir - rd);
        float spec = pow(max(dot(normal, halfVec), 0.0), 64.0);

        // Secondary light for more dimension
        vec3 lightDir2 = normalize(vec3(-0.5, 0.3, -0.8));
        float diffuse2 = max(dot(normal, lightDir2), 0.0) * 0.3;

        // Combine lighting
        float ambient = 0.2;
        float shade = ambient + diffuse * 0.5 + diffuse2;

        // Apply metallic shading
        color = surfaceColor * shade;

        // Add specular highlight
        color += vec3(1.0, 0.98, 0.95) * spec * 0.8 * deformAmount;

        // Fresnel effect - edges more reflective like real mercury
        float fresnel = pow(1.0 - max(dot(-rd, normal), 0.0), 3.0);
        vec3 fresnelColor = mix(surfaceColor, vec3(0.9, 0.92, 0.95), 0.5);
        color = mix(color, fresnelColor, fresnel * deformAmount * 0.6);

        // Subtle caustic-like patterns from internal reflections
        float caustic = pow(abs(sin(hitPos.x * 15.0 + hitPos.z * 12.0 + u_time * u_speed * 2.0)), 8.0);
        color += caustic * 0.1 * deformAmount;
    }

    gl_FragColor = vec4(color, 1.0);
}
