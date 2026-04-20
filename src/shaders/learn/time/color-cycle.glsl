precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_speed;
uniform float u_saturation;

vec3 hue(float h) {
    h = fract(h);
    vec3 k = vec3(1.0, 2.0 / 3.0, 1.0 / 3.0);
    vec3 p = abs(fract(vec3(h) + k) * 6.0 - 3.0);
    return clamp(p - 1.0, 0.0, 1.0);
}

void main() {
    vec3 color = hue(u_time * u_speed);
    float gray = dot(color, vec3(0.3333));
    color = mix(vec3(gray), color, u_saturation);
    gl_FragColor = vec4(color, 1.0);
}
