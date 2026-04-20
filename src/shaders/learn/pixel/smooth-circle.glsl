precision mediump float;

uniform vec2 u_resolution;
uniform float u_radius;
uniform float u_softness;

void main() {
    vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    float d = length(p);
    float edge = max(u_softness, 0.001);
    float circle = 1.0 - smoothstep(u_radius - edge, u_radius + edge, d);
    gl_FragColor = vec4(vec3(circle), 1.0);
}
