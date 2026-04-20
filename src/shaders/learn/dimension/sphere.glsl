precision highp float;

uniform vec2 u_resolution;
uniform float u_radius;
uniform float u_distance;

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float raymarch(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < 64; i++) {
        vec3 p = ro + rd * t;
        float d = sdSphere(p, u_radius);
        if (d < 0.001) return t;
        t += d;
        if (t > 20.0) break;
    }
    return -1.0;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    vec3 ro = vec3(0.0, 0.0, -u_distance);
    vec3 rd = normalize(vec3(uv, 1.0));

    float t = raymarch(ro, rd);
    float hit = (t > 0.0) ? 1.0 : 0.0;
    gl_FragColor = vec4(vec3(hit), 1.0);
}
