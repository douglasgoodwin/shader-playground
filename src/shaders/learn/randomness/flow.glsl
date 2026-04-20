precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_scale;
uniform float u_speed;

float hash3(vec3 p) {
    return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

float valueNoise3D(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    vec3 u = f * f * (3.0 - 2.0 * f);

    float c000 = hash3(i);
    float c100 = hash3(i + vec3(1.0, 0.0, 0.0));
    float c010 = hash3(i + vec3(0.0, 1.0, 0.0));
    float c110 = hash3(i + vec3(1.0, 1.0, 0.0));
    float c001 = hash3(i + vec3(0.0, 0.0, 1.0));
    float c101 = hash3(i + vec3(1.0, 0.0, 1.0));
    float c011 = hash3(i + vec3(0.0, 1.0, 1.0));
    float c111 = hash3(i + vec3(1.0, 1.0, 1.0));

    return mix(
        mix(mix(c000, c100, u.x), mix(c010, c110, u.x), u.y),
        mix(mix(c001, c101, u.x), mix(c011, c111, u.x), u.y),
        u.z
    );
}

void main() {
    vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    vec3 q = vec3(p * u_scale, u_time * u_speed);
    float n = valueNoise3D(q);
    gl_FragColor = vec4(vec3(n), 1.0);
}
