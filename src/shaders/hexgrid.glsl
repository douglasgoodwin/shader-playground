precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

// Hexagonal grid functions
vec4 hexCoords(vec2 uv) {
    vec2 r = vec2(1.0, 1.732);
    vec2 h = r * 0.5;
    vec2 a = mod(uv, r) - h;
    vec2 b = mod(uv - h, r) - h;
    vec2 gv = length(a) < length(b) ? a : b;
    vec2 id = uv - gv;
    return vec4(gv.x, gv.y, id.x, id.y);
}

float hexDist(vec2 p) {
    p = abs(p);
    return max(dot(p, normalize(vec2(1.0, 1.732))), p.x);
}

#include "/lygia/generative/random.glsl"

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec2 mouse = u_mouse / u_resolution;
    float t = u_time * u_speed;

    // Scale and aspect correct
    float gridScale = 8.0 * u_scale;
    vec2 st = uv * gridScale;
    st.x *= u_resolution.x / u_resolution.y;

    // Get hex coordinates
    vec4 hex = hexCoords(st);
    vec2 gv = hex.xy;  // Local coords within hex
    vec2 id = hex.zw;  // Hex cell ID

    // Distance to hex edge
    float d = hexDist(gv);

    // Per-cell random value
    float cellRand = random(id);

    // Animated cell height/value
    float wave = sin(id.x * 0.5 + t) * sin(id.y * 0.5 + t * 0.7);
    float pulse = sin(t * 2.0 + cellRand * 6.28) * 0.5 + 0.5;

    // Mouse distance to this cell
    vec2 mouseScaled = mouse * gridScale;
    mouseScaled.x *= u_resolution.x / u_resolution.y;
    float mouseDist = distance(id, mouseScaled);
    float mouseInfluence = 1.0 / (mouseDist * 0.3 + 1.0);

    // Cell color based on position and animation
    vec3 cellColor = vec3(
        0.5 + 0.5 * sin(cellRand * 6.28 + t + wave),
        0.5 + 0.5 * sin(cellRand * 6.28 + t * 0.7 + 2.094),
        0.5 + 0.5 * sin(cellRand * 6.28 + t * 1.3 + 4.188)
    );

    // Brighten cells near mouse
    cellColor += mouseInfluence * 0.5 * u_intensity;

    // Edge glow
    float edge = smoothstep(0.5, 0.45, d);
    float edgeGlow = smoothstep(0.5, 0.3, d) - smoothstep(0.45, 0.25, d);

    // Inner pattern - concentric hex rings
    float rings = sin(d * 20.0 - t * 3.0) * 0.5 + 0.5;

    // Combine
    vec3 color = cellColor * edge * (0.6 + 0.4 * rings) * u_intensity;

    // Add bright edge outline
    color += edgeGlow * vec3(1.0) * 0.5 * u_intensity;

    // Pulsing cells
    color += pulse * mouseInfluence * cellColor * 0.3;

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
