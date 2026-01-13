precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

#define MAX_STEPS 100
#define MAX_DIST 100.0
#define SURF_DIST 0.001

mat2 rot2D(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

// Signed distance functions
float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

// Smooth minimum for blending shapes
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// Scene distance function
float map(vec3 p) {
    float t = u_time * u_speed * 0.5;

    // Rotating torus
    vec3 torusP = p;
    torusP.xz *= rot2D(t);
    torusP.xy *= rot2D(t * 0.7);
    float torus = sdTorus(torusP, vec2(1.0, 0.3) * u_scale);

    // Orbiting spheres
    float spheres = MAX_DIST;
    for (int i = 0; i < 4; i++) {
        float angle = t + float(i) * 1.5708;
        vec3 spherePos = vec3(cos(angle), sin(angle * 0.5) * 0.5, sin(angle)) * 1.5 * u_scale;
        spheres = min(spheres, sdSphere(p - spherePos, 0.25 * u_scale));
    }

    // Central pulsing sphere
    float pulse = 0.3 + 0.1 * sin(t * 3.0);
    float centerSphere = sdSphere(p, pulse * u_scale);

    // Combine with smooth blending
    float d = smin(torus, spheres, 0.5);
    d = smin(d, centerSphere, 0.3);

    // Floor plane
    float floor = p.y + 2.0;
    d = min(d, floor);

    return d;
}

// Calculate normal using gradient
vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

// Raymarching - half steps for smooth blended shapes
float rayMarch(vec3 ro, vec3 rd) {
    float d = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d;
        float ds = map(p);
        d += ds * 0.5;  // Smooth min can reduce gradient
        if (d > MAX_DIST || ds < SURF_DIST) break;
    }
    return d;
}

// Soft shadows
float softShadow(vec3 ro, vec3 rd, float mint, float maxt, float k) {
    float res = 1.0;
    float t = mint;
    for (int i = 0; i < 32; i++) {
        float h = map(ro + rd * t);
        res = min(res, k * h / t);
        t += clamp(h, 0.02, 0.1);
        if (h < 0.001 || t > maxt) break;
    }
    return clamp(res, 0.0, 1.0);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;
    vec2 mouse = u_mouse / u_resolution - 0.5;
    float t = u_time * u_speed;

    // Camera setup - mouse controls view angle
    vec3 ro = vec3(0.0, 0.0, -5.0); // Ray origin (camera position)

    // Rotate camera based on mouse
    ro.xz *= rot2D(mouse.x * 3.14159);
    ro.y += mouse.y * 3.0;

    // Look at origin
    vec3 lookAt = vec3(0.0);
    vec3 forward = normalize(lookAt - ro);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = cross(forward, right);

    // Ray direction
    vec3 rd = normalize(uv.x * right + uv.y * up + 1.5 * forward);

    // Raymarch
    float d = rayMarch(ro, rd);

    vec3 color = vec3(0.02, 0.02, 0.05); // Background

    if (d < MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = calcNormal(p);

        // Lighting
        vec3 lightPos = vec3(3.0 * sin(t * 0.3), 3.0, -3.0 * cos(t * 0.3));
        vec3 lightDir = normalize(lightPos - p);

        // Diffuse
        float diff = max(dot(n, lightDir), 0.0);

        // Specular
        vec3 viewDir = normalize(ro - p);
        vec3 reflectDir = reflect(-lightDir, n);
        float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);

        // Shadow
        float shadow = softShadow(p + n * 0.02, lightDir, 0.02, 10.0, 8.0);

        // Ambient occlusion (simple)
        float ao = 1.0 - 0.5 * (1.0 - map(p + n * 0.1) / 0.1);
        ao = clamp(ao, 0.0, 1.0);

        // Material color based on position
        vec3 matColor = vec3(
            0.5 + 0.5 * sin(p.x * 2.0 + t),
            0.5 + 0.5 * sin(p.y * 2.0 + t * 0.7 + 2.094),
            0.5 + 0.5 * sin(p.z * 2.0 + t * 1.3 + 4.188)
        );

        // Floor is darker
        if (p.y < -1.9) {
            matColor = vec3(0.2);
            // Checkerboard pattern
            float checker = mod(floor(p.x) + floor(p.z), 2.0);
            matColor *= 0.5 + 0.5 * checker;
        }

        // Combine lighting
        vec3 ambient = 0.1 * matColor;
        vec3 diffuse = diff * matColor * shadow;
        vec3 specular = spec * vec3(1.0) * shadow;

        color = (ambient + diffuse + specular * 0.5) * ao * u_intensity;

        // Fog
        float fog = exp(-d * 0.05);
        color = mix(vec3(0.02, 0.02, 0.05), color, fog);
    }

    // Ripple effect (screen space)
    vec2 uvNorm = gl_FragCoord.xy / u_resolution;
    for (int i = 0; i < 10; i++) {
        vec2 ripplePos = u_ripples[i].xy / u_resolution;
        float rippleTime = u_ripples[i].z;

        if (rippleTime > 0.0) {
            float age = u_time - rippleTime;
            float rippleDist = distance(uvNorm, ripplePos);
            float radius = age * 0.5 * u_speed;
            float ring = abs(rippleDist - radius);
            float ripple = smoothstep(0.05, 0.0, ring) * exp(-age * 2.0 / u_intensity);
            color += ripple * u_rippleColors[i] * u_intensity;
        }
    }

    // Gamma correction
    color = pow(color, vec3(0.4545));

    gl_FragColor = vec4(color, 1.0);
}
