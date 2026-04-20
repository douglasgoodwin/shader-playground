precision mediump float;

uniform vec2 u_resolution;
uniform float u_count;
uniform float u_radius;

void main() {
    vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    vec2 cell = fract(p * u_count) - 0.5;
    float d = length(cell);
    float circle = 1.0 - smoothstep(u_radius - 0.02, u_radius + 0.02, d);
    gl_FragColor = vec4(vec3(circle), 1.0);
}
