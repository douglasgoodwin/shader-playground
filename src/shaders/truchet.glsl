precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

#include "/lygia/generative/random.glsl"

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec2 mouse = u_mouse / u_resolution;
    float t = u_time * u_speed;

    // Scale the grid
    float gridSize = 10.0 * u_scale;
    vec2 st = uv * gridSize;
    vec2 i_st = floor(st);
    vec2 f_st = fract(st);

    // Random rotation per tile (0, 90, 180, or 270 degrees)
    float tileRand = random(i_st + floor(t * 0.2));

    // Rotate the local coordinates
    if (tileRand > 0.75) {
        f_st = vec2(1.0 - f_st.y, f_st.x);
    } else if (tileRand > 0.5) {
        f_st = vec2(1.0 - f_st.x, 1.0 - f_st.y);
    } else if (tileRand > 0.25) {
        f_st = vec2(f_st.y, 1.0 - f_st.x);
    }

    // Draw quarter circles from corners
    float d1 = distance(f_st, vec2(0.0, 0.0));
    float d2 = distance(f_st, vec2(1.0, 1.0));

    // Arc parameters
    float arcRadius = 0.5;
    float arcWidth = 0.1 / u_scale;

    // Create arcs
    float arc1 = smoothstep(arcWidth, 0.0, abs(d1 - arcRadius));
    float arc2 = smoothstep(arcWidth, 0.0, abs(d2 - arcRadius));
    float pattern = arc1 + arc2;

    // Animate colors along the paths
    float flow1 = sin(d1 * 20.0 - t * 3.0) * 0.5 + 0.5;
    float flow2 = sin(d2 * 20.0 - t * 3.0 + 3.14159) * 0.5 + 0.5;

    // Base color from tile position
    vec3 tileColor = vec3(
        0.5 + 0.5 * sin(i_st.x * 0.5 + t),
        0.5 + 0.5 * sin(i_st.y * 0.5 + t * 0.7),
        0.5 + 0.5 * sin((i_st.x + i_st.y) * 0.3 + t * 1.3)
    );

    // Background
    vec3 bgColor = vec3(0.05, 0.05, 0.1);

    // Mix arc colors with flow animation
    vec3 arcColor1 = mix(tileColor, tileColor.gbr, flow1) * u_intensity;
    vec3 arcColor2 = mix(tileColor.brg, tileColor, flow2) * u_intensity;

    vec3 color = bgColor;
    color = mix(color, arcColor1, arc1);
    color = mix(color, arcColor2, arc2);

    // Mouse glow
    float mouseDist = distance(uv, mouse);
    color += 0.1 * u_intensity / (mouseDist + 0.1) * tileColor;

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
