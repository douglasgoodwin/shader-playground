precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_base_radius;
uniform float u_amplitude;
uniform float u_speed;

void main() {
    vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    float r = u_base_radius + u_amplitude * sin(u_time * u_speed);
    float d = length(p);
    float circle = 1.0 - smoothstep(r - 0.01, r + 0.01, d);
    gl_FragColor = vec4(vec3(circle), 1.0);
}
