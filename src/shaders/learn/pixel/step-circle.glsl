precision mediump float;

uniform vec2 u_resolution;
uniform float u_radius;

void main() {
    vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    float d = length(p);
    float circle = 1.0 - step(u_radius, d);
    gl_FragColor = vec4(vec3(circle), 1.0);
}
