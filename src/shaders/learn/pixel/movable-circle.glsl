precision mediump float;

uniform vec2 u_resolution;
uniform float u_cx;
uniform float u_cy;
uniform float u_radius;

void main() {
    vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    vec2 center = vec2(u_cx, u_cy);
    float d = length(p - center);
    float circle = 1.0 - smoothstep(u_radius - 0.02, u_radius + 0.02, d);
    gl_FragColor = vec4(vec3(circle), 1.0);
}
