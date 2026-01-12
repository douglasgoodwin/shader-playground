// "Penrose Flower" by Andrea Bovo/spleennooname
// https://github.com/spleennooname
// License: CC BY-NC-ND
// Adapted from Shadertoy

precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

void main() {
    vec2 R = u_resolution;
    vec2 I = gl_FragCoord.xy;

    vec2 p = 2.0 * I / R.y - R.xy / R.y;
    p *= u_scale;

    float t = u_time * u_speed;
    float a = max(abs(p.x) + p.y, -p.y) - 0.5;
    float y = atan(p.x, p.y);

    vec4 s = 0.25 * u_intensity * cos(vec4(25.0 * log(t + 0.1) * sin(0.25 * t) / (t + 0.1), 1.0, 2.0, 0.0) + t - y);
    vec4 e = s.yzxy;
    vec4 f = clamp(min(vec4(a) - s, e - vec4(a)) * 100.0, 0.0, 1.0);
    vec4 g = (e - 0.1) * dot(f, 20.0 * (s - e));

    vec4 O = vec4(1.0, 0.0, 0.0, 1.0) - 0.2 * g.x - 0.7 * g.y - 0.07 * g.z - g.w;

    vec3 color = O.rgb;

    // Ripple effect
    vec2 uv = gl_FragCoord.xy / u_resolution;
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
