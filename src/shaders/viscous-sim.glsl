precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform sampler2D u_buffer;
uniform int u_frame;
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

#define T(d) texture2D(u_buffer, (gl_FragCoord.xy + d) / u_resolution)

// Hash function for initial noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
        f.y
    );
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 U = gl_FragCoord.xy;
    vec2 R = u_resolution;

    float _K0 = -20.0 / 6.0;
    float _K1 = 4.0 / 6.0;
    float _K2 = 1.0 / 6.0;
    float cs = 0.25 * u_intensity;
    float ls = 0.24;
    float ps = -0.06 * u_scale;
    float ds = -0.08 * u_scale;
    float pwr = 0.2;
    float amp = 1.0;
    float sq2 = 0.7;

    vec4 uv = T(vec2(0.0));
    vec4 n  = T(vec2(0.0, 1.0));
    vec4 e  = T(vec2(1.0, 0.0));
    vec4 s  = T(vec2(0.0, -1.0));
    vec4 w  = T(vec2(-1.0, 0.0));
    vec4 nw = T(vec2(-1.0, 1.0));
    vec4 sw = T(vec2(-1.0, -1.0));
    vec4 ne = T(vec2(1.0, 1.0));
    vec4 se = T(vec2(1.0, -1.0));

    vec4 lapl = _K0 * uv + _K1 * (n + e + w + s) + _K2 * (nw + sw + ne + se);
    float sp = ps * lapl.z;

    float curl = n.x - s.x - e.y + w.y
        + sq2 * (nw.x + nw.y + ne.x - ne.y + sw.y - sw.x - se.y - se.x);

    float a = cs * sign(curl) * pow(abs(curl), pwr);

    float div = s.y - n.y - e.x + w.x
        + sq2 * (nw.x - nw.y - ne.x - ne.y + sw.x + sw.y + se.y - se.x);
    float sd = ds * div;

    vec2 norm = length(uv.xy) > 0.0 ? normalize(uv.xy) : vec2(0.0);

    vec2 t = (amp * uv.xy + ls * lapl.xy + uv.xy * sd) + norm * sp;
    float ca = cos(a);
    float sa = sin(a);
    t = mat2(ca, -sa, sa, ca) * t;

    vec4 O;
    if (u_frame < 10) {
        // Initialize with noise
        vec2 p = U / R;
        float n1 = fbm(p * 8.0 + u_time * 0.1);
        float n2 = fbm(p * 8.0 + 100.0 + u_time * 0.1);
        O = vec4(n1 - 0.5, n2 - 0.5, 0.0, 0.0);
    } else {
        O = clamp(vec4(t, div, 0.0), -1.0, 1.0);
    }

    gl_FragColor = O;
}
