precision highp float;

varying vec2 v_uv;

uniform sampler2D u_prev;
uniform float u_time;
uniform float u_decay;
uniform float u_radius;
uniform float u_hue;
uniform vec2 u_resolution;

vec3 palette(float t) {
    return 0.55 + 0.45 * cos(6.2831853 * (t + vec3(0.0, 0.33, 0.67)));
}

void main() {
    // previous frame, faded
    vec3 faded = texture2D(u_prev, v_uv).rgb * u_decay;

    // aspect-correct space so the orbit is circular, not squashed
    float aspect = u_resolution.x / u_resolution.y;
    vec2 p = (v_uv - 0.5) * vec2(aspect, 1.0);

    // Lissajous pen position (two frequencies, slight detune for drift)
    float t = u_time;
    vec2 pen = 0.38 * vec2(sin(t * 1.00), sin(t * 1.37 + 1.1));

    // soft circular stamp
    float d = length(p - pen);
    float shape = smoothstep(u_radius, 0.0, d);

    // hue drifts slowly over time so the trail cycles color
    vec3 ink = palette(u_hue + t * 0.03);

    vec3 color = faded + ink * shape;

    gl_FragColor = vec4(color, 1.0);
}
