precision mediump float;

uniform vec2 u_resolution;
uniform float u_cx;
uniform float u_radius;

void main() {
    vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    vec2 q = vec2(abs(p.x), p.y);
    float d = length(q - vec2(u_cx, 0.0));
    float circle = 1.0 - smoothstep(u_radius - 0.01, u_radius + 0.01, d);
    gl_FragColor = vec4(vec3(circle), 1.0);
}
