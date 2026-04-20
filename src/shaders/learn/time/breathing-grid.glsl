precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_count;
uniform float u_radius;
uniform float u_speed;

void main() {
    vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    vec2 id = floor(p * u_count);
    vec2 cell = fract(p * u_count) - 0.5;
    float phase = id.x * 0.9 + id.y * 1.3;
    float r = u_radius + 0.18 * sin(u_time * u_speed + phase);
    float d = length(cell);
    float circle = 1.0 - smoothstep(r - 0.02, r + 0.02, d);
    gl_FragColor = vec4(vec3(circle), 1.0);
}
