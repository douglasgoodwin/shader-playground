precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_speed;
uniform float u_blend;

float sdSphere(vec3 p, vec3 c, float r) {
    return length(p - c) - r;
}

float sdBox(vec3 p, vec3 c, vec3 b) {
    vec3 q = abs(p - c) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdFloor(vec3 p, float y) {
    return p.y - y;
}

float smin(float a, float b, float k) {
    if (k < 0.0001) return min(a, b);
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

float sdf(vec3 p) {
    float s = sdSphere(p, vec3(0.55, 0.0, 0.0), 0.5);
    float b = sdBox(p, vec3(-0.55, 0.0, 0.0), vec3(0.35));
    float shape = smin(s, b, u_blend);
    float floor = sdFloor(p, -0.55);
    return min(shape, floor);
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
    for (int i = 0; i < 96; i++) {
        vec3 p = ro + rd * t;
        float d = sdf(p);
        if (d < 0.001) return t;
        t += d;
        if (t > 30.0) break;
    }
    return -1.0;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);

    // Orbiting camera
    float angle = u_time * u_speed;
    vec3 ro = vec3(sin(angle) * 3.5, 1.1, cos(angle) * 3.5);
    vec3 target = vec3(0.0, -0.1, 0.0);

    vec3 forward = normalize(target - ro);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = cross(forward, right);
    vec3 rd = normalize(right * uv.x + up * uv.y + forward * 1.3);

    float t = raymarch(ro, rd);
    if (t < 0.0) {
        vec3 sky = mix(vec3(0.12, 0.17, 0.27), vec3(0.35, 0.43, 0.52), uv.y * 0.5 + 0.5);
        gl_FragColor = vec4(sky, 1.0);
        return;
    }

    vec3 p = ro + rd * t;
    vec3 n = calcNormal(p);
    vec3 lightDir = normalize(vec3(0.5, 0.8, -0.3));
    float diff = max(dot(n, lightDir), 0.0);
    vec3 baseColor = p.y < -0.54 ? vec3(0.42, 0.45, 0.5) : vec3(0.85, 0.7, 0.5);
    vec3 color = baseColor * (diff + 0.22);
    gl_FragColor = vec4(color, 1.0);
}
