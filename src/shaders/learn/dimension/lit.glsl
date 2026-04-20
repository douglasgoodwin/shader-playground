precision highp float;

uniform vec2 u_resolution;
uniform float u_radius;
uniform float u_light_angle;

float sdf(vec3 p) {
    return length(p) - u_radius;
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
    vec3 lightDir = normalize(vec3(cos(u_light_angle), 0.5, sin(u_light_angle) - 0.5));
    float diff = max(dot(n, lightDir), 0.0);
    vec3 color = vec3(0.9) * (diff + 0.15);
    gl_FragColor = vec4(color, 1.0);
}
