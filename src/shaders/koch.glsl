// Koch Snowflake - fractal curve using iterative transformation
precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

#define PI 3.14159265359

// Fold space to create Koch curve pattern
// Based on the iterative subdivision principle
vec2 kochFold(vec2 p) {
    // Fold along 60-degree lines (Koch angle)
    p.x = abs(p.x);

    // First fold at 60 degrees
    vec2 n1 = vec2(0.5, 0.866); // normal for 60 deg line
    p -= 2.0 * min(0.0, dot(p, n1)) * n1;

    // Second fold at -60 degrees
    vec2 n2 = vec2(0.5, -0.866);
    p -= 2.0 * min(0.0, dot(p, n2)) * n2;

    return p;
}

// Distance to Koch curve edge
float kochDistance(vec2 p, int iterations) {
    float scale = 1.0;

    for (int i = 0; i < 8; i++) {
        if (i >= iterations) break;

        // Apply Koch fold
        p = kochFold(p);

        // Scale and translate for next iteration
        p.x -= 1.0;
        p *= 3.0;
        scale *= 3.0;
    }

    // Distance to vertical line segment
    p.x = max(0.0, p.x - 0.5);
    return length(p) / scale;
}

// Full Koch snowflake (3 Koch curves forming triangle)
float kochSnowflake(vec2 p, int iterations) {
    float d = 1e10;

    // Three sides of the snowflake
    for (int i = 0; i < 3; i++) {
        float angle = float(i) * PI * 2.0 / 3.0 + PI / 6.0;
        vec2 rotP = vec2(
            p.x * cos(angle) - p.y * sin(angle),
            p.x * sin(angle) + p.y * cos(angle)
        );
        rotP.y -= 0.5; // offset to form triangle
        d = min(d, kochDistance(rotP, iterations));
    }

    return d;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    uv *= 2.0 / u_scale;

    float t = u_time * u_speed * 0.5;

    // Gentle rotation
    float rotAngle = t * 0.1;
    uv = vec2(
        uv.x * cos(rotAngle) - uv.y * sin(rotAngle),
        uv.x * sin(rotAngle) + uv.y * cos(rotAngle)
    );

    // Number of iterations (more = finer detail)
    int iterations = int(3.0 + 3.0 * u_intensity);

    // Distance to Koch snowflake
    float d = kochSnowflake(uv, iterations);

    // Create glow effect
    float glow = 0.003 / (d + 0.003);

    // Edge line
    float edge = smoothstep(0.008, 0.002, d);

    // Color
    vec3 glowColor = vec3(0.3, 0.6, 1.0) + 0.3 * sin(t + vec3(0.0, 2.0, 4.0));
    vec3 edgeColor = vec3(0.9, 0.95, 1.0);

    vec3 color = glow * glowColor * 0.5 + edge * edgeColor;

    // Inner fill with subtle pattern
    float inside = smoothstep(0.01, 0.0, d);
    vec3 fillColor = vec3(0.05, 0.1, 0.15) + 0.05 * sin(length(uv) * 20.0 - t * 2.0);
    color = mix(color, fillColor, inside * 0.5);

    // Mouse glow
    vec2 mouse = (u_mouse - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    mouse *= 2.0 / u_scale;
    float mouseDist = length(uv - mouse);
    color += 0.02 / (mouseDist + 0.1) * vec3(0.5, 0.7, 1.0);

    // Ripples
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

    // Background
    vec3 bg = vec3(0.02, 0.03, 0.05);
    color = max(color, bg);

    gl_FragColor = vec4(color, 1.0);
}
