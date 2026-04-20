precision highp float;

uniform vec2 u_resolution;
uniform float u_radius;
uniform float u_separation;
uniform float u_k;

float sdSphere(vec3 p, vec3 c, float r) {
    return length(p - c) - r;
}

// Inigo Quilez smooth-minimum
float smin(float a, float b, float k) {
    if (k < 0.0001) return min(a, b);
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

float sdf(vec3 p) {
    float s1 = sdSphere(p, vec3(-u_separation, 0.0, 0.0), u_radius);
    float s2 = sdSphere(p, vec3(u_separation, 0.0, 0.0), u_radius);
    return smin(s1, s2, u_k);
}

vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        sdf(p + e.xyy) - sdf(p - e.xyy),
        sdf(p + e.yxy) - sdf(p - e.yxy),
        sdf(p + e.yyx) - sdf(p - e.yyx)
    ));
}

float raymarch(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < 64; i++) {
        vec3 p = ro + rd * t;
        float d = sdf(p);
        if (d < 0.001) return t;
        t += d;
        if (t > 20.0) break;
    }
    return -1.0;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    vec3 ro = vec3(0.0, 0.0, -3.0);
    vec3 rd = normalize(vec3(uv, 1.0));

    float t = raymarch(ro, rd);
    if (t < 0.0) {
        gl_FragColor = vec4(vec3(0.0), 1.0);
        return;
    }

    vec3 p = ro + rd * t;
    vec3 n = calcNormal(p);
    vec3 lightDir = normalize(vec3(0.5, 0.7, -0.3));
    float diff = max(dot(n, lightDir), 0.0);
    vec3 color = vec3(0.9) * (diff + 0.15);
    gl_FragColor = vec4(color, 1.0);
}
