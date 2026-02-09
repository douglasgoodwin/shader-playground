precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

#define MAX_STEPS 150
#define MAX_DIST 10.0
#define SURF_DIST 0.0005

#include "../lygia/math/rotate2d.glsl"

// Mandelbulb distance estimator
vec2 mandelbulb(vec3 p) {
    vec3 z = p;
    float dr = 1.0;
    float r = 0.0;
    float power = 8.0 + sin(u_time * u_speed * 0.2) * 2.0; // Animated power
    int iterations = 0;

    for (int i = 0; i < 15; i++) {
        iterations = i;
        r = length(z);
        if (r > 2.0) break;

        // Convert to polar coordinates
        float theta = acos(z.z / r);
        float phi = atan(z.y, z.x);
        dr = pow(r, power - 1.0) * power * dr + 1.0;

        // Scale and rotate
        float zr = pow(r, power);
        theta = theta * power;
        phi = phi * power;

        // Convert back to cartesian
        z = zr * vec3(
            sin(theta) * cos(phi),
            sin(phi) * sin(theta),
            cos(theta)
        );
        z += p;
    }

    float dist = 0.5 * log(r) * r / dr;
    return vec2(dist, float(iterations));
}

// Scene with scaled Mandelbulb
vec2 map(vec3 p) {
    // Rotate the whole thing
    float t = u_time * u_speed * 0.1;
    p.xz *= rotate2d(t);
    p.xy *= rotate2d(t * 0.7);

    // Scale
    p /= u_scale;
    vec2 mb = mandelbulb(p);
    mb.x *= u_scale;

    return mb;
}

// Calculate normal
vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p + e.xyy).x - map(p - e.xyy).x,
        map(p + e.yxy).x - map(p - e.yxy).x,
        map(p + e.yyx).x - map(p - e.yyx).x
    ));
}

// Raymarching - smaller steps for fractal detail
vec2 rayMarch(vec3 ro, vec3 rd) {
    float d = 0.0;
    float iterations = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d;
        vec2 ds = map(p);
        if (ds.x < SURF_DIST) {
            iterations = ds.y;
            break;
        }
        if (d > MAX_DIST) break;
        d += ds.x * 0.5;  // Half steps for fractal accuracy
        iterations = ds.y;
    }
    return vec2(d, iterations);
}

// Ambient occlusion
float calcAO(vec3 p, vec3 n) {
    float occ = 0.0;
    float sca = 1.0;
    for (int i = 0; i < 5; i++) {
        float h = 0.01 + 0.12 * float(i) / 4.0;
        float d = map(p + h * n).x;
        occ += (h - d) * sca;
        sca *= 0.95;
    }
    return clamp(1.0 - 3.0 * occ, 0.0, 1.0);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;
    vec2 mouse = u_mouse / u_resolution - 0.5;

    // Camera setup
    float camDist = 3.0;
    vec3 ro = vec3(0.0, 0.0, -camDist);

    // Mouse controls camera orbit
    ro.xz *= rotate2d(mouse.x * 6.28);
    ro.y += mouse.y * 2.0;
    ro = normalize(ro) * camDist;

    // Look at center
    vec3 lookAt = vec3(0.0);
    vec3 forward = normalize(lookAt - ro);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = cross(forward, right);

    // Ray direction
    vec3 rd = normalize(uv.x * right + uv.y * up + 1.5 * forward);

    // Background gradient
    vec3 color = mix(
        vec3(0.1, 0.05, 0.15),
        vec3(0.02, 0.02, 0.05),
        uv.y + 0.5
    );

    // Raymarch
    vec2 result = rayMarch(ro, rd);
    float d = result.x;
    float iter = result.y;

    if (d < MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = calcNormal(p);

        // Lighting
        vec3 lightPos = vec3(2.0, 3.0, -2.0);
        vec3 lightDir = normalize(lightPos - p);
        vec3 viewDir = normalize(ro - p);
        vec3 halfDir = normalize(lightDir + viewDir);

        // Diffuse and specular
        float diff = max(dot(n, lightDir), 0.0);
        float spec = pow(max(dot(n, halfDir), 0.0), 64.0);

        // Fresnel
        float fresnel = pow(1.0 - max(dot(n, viewDir), 0.0), 3.0);

        // Ambient occlusion
        float ao = calcAO(p, n);

        // Color based on iteration count and position
        float t = u_time * u_speed * 0.3;
        vec3 matColor = vec3(
            0.5 + 0.5 * sin(iter * 0.3 + t),
            0.5 + 0.5 * sin(iter * 0.3 + t + 2.094),
            0.5 + 0.5 * sin(iter * 0.3 + t + 4.188)
        );

        // Add position-based color variation
        matColor *= 0.7 + 0.3 * vec3(
            sin(p.x * 5.0 + t),
            sin(p.y * 5.0 + t * 1.1),
            sin(p.z * 5.0 + t * 0.9)
        );

        // Combine lighting
        vec3 ambient = 0.15 * matColor;
        vec3 diffuse = diff * matColor * 0.8;
        vec3 specular = spec * vec3(1.0, 0.9, 0.8) * 0.5;
        vec3 rim = fresnel * vec3(0.3, 0.4, 0.8) * 0.4;

        color = (ambient + diffuse + specular + rim) * ao * u_intensity;

        // Fog
        float fog = exp(-d * 0.3);
        color = mix(vec3(0.02, 0.02, 0.05), color, fog);
    }

    // Ripple effect
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
