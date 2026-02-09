precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

#include "lygia/generative/random.glsl"

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec2 mouse = u_mouse / u_resolution;
    float t = u_time * u_speed;

    float cellScale = 5.0 * u_scale;
    vec2 st = uv * cellScale;
    vec2 i_st = floor(st);
    vec2 f_st = fract(st);

    float minDist = 1.0;
    vec2 minPoint;

    // Find closest point
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = random2(i_st + neighbor);

            // Animate points
            point = 0.5 + 0.5 * sin(t * 0.5 + 6.2831 * point);

            // Mouse attraction
            vec2 worldPoint = (i_st + neighbor + point) / cellScale;
            float mouseInfluence = 0.1 * u_intensity / (distance(worldPoint, mouse) + 0.1);
            point += (mouse * cellScale - i_st - neighbor - point) * mouseInfluence * 0.1;

            vec2 diff = neighbor + point - f_st;
            float dist = length(diff);

            if (dist < minDist) {
                minDist = dist;
                minPoint = point;
            }
        }
    }

    // Color based on cell
    vec3 color = vec3(
        0.5 + 0.5 * sin(minPoint.x * 6.28 + t),
        0.5 + 0.5 * sin(minPoint.y * 6.28 + t * 0.7),
        0.5 + 0.5 * sin((minPoint.x + minPoint.y) * 3.14 + t * 1.3)
    );

    // Edge highlight
    color += (1.0 - smoothstep(0.0, 0.05, minDist)) * 0.5 * u_intensity;

    // Ripple effect
    for (int i = 0; i < 10; i++) {
        vec2 ripplePos = u_ripples[i].xy / u_resolution;
        float rippleTime = u_ripples[i].z;

        if (rippleTime > 0.0) {
            float age = u_time - rippleTime;
            float rippleDist = distance(uv, ripplePos);
            float radius = age * 0.5 * u_speed;
            float ring = abs(rippleDist - radius);
            float ripple = smoothstep(0.05, 0.0, ring) * exp(-age * 2.0 / u_intensity);
            color += ripple * u_rippleColors[i] * u_intensity;
        }
    }

    gl_FragColor = vec4(color, 1.0);
}
