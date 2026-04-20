precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_scale;
uniform float u_amplitude;
uniform float u_speed;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = smoothstep(0.0, 1.0, f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
    float sum = 0.0;
    float amp = 1.0;
    float total = 0.0;
    for (int i = 0; i < 5; i++) {
        sum += valueNoise(p) * amp;
        total += amp;
        p *= 2.0;
        amp *= 0.5;
    }
    return sum / total;
}

float terrainHeight(vec2 xz) {
    return fbm(xz * u_scale) * u_amplitude - 0.5;
}

float raymarchTerrain(vec3 ro, vec3 rd) {
    float t = 0.05;
    for (int i = 0; i < 160; i++) {
        vec3 p = ro + rd * t;
        float h = terrainHeight(p.xz);
        float delta = p.y - h;
        if (delta < 0.01) return t;
        t += max(delta * 0.4, 0.02);
        if (t > 25.0) break;
    }
    return -1.0;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);

    // Flying camera, moving forward slowly
    float t = u_time * u_speed;
    vec3 ro = vec3(t, 0.9, 0.0);
    vec3 target = vec3(t + 3.0, 0.3, 0.0);

    vec3 forward = normalize(target - ro);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = cross(forward, right);
    vec3 rd = normalize(right * uv.x + up * uv.y + forward * 1.3);

    float tt = raymarchTerrain(ro, rd);
    if (tt < 0.0) {
        vec3 sky = mix(vec3(0.6, 0.72, 0.88), vec3(0.95, 0.83, 0.68), smoothstep(-0.2, 0.4, rd.y));
        gl_FragColor = vec4(sky, 1.0);
        return;
    }

    vec3 p = ro + rd * tt;
    float eps = 0.04;
    vec3 n = normalize(vec3(
        terrainHeight(p.xz - vec2(eps, 0.0)) - terrainHeight(p.xz + vec2(eps, 0.0)),
        2.0 * eps,
        terrainHeight(p.xz - vec2(0.0, eps)) - terrainHeight(p.xz + vec2(0.0, eps))
    ));

    vec3 lightDir = normalize(vec3(-0.3, 0.6, 0.5));
    float diff = max(dot(n, lightDir), 0.0);

    // Height-based ground color
    float height = p.y + 0.5;
    vec3 baseColor = mix(vec3(0.42, 0.38, 0.28), vec3(0.88, 0.82, 0.68), smoothstep(-0.15, 0.45, height));
    vec3 color = baseColor * (diff + 0.28);

    // Distance fog
    float fog = 1.0 - exp(-tt * 0.045);
    vec3 sky = vec3(0.7, 0.76, 0.82);
    color = mix(color, sky, fog);

    gl_FragColor = vec4(color, 1.0);
}
