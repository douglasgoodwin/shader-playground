precision mediump float;

uniform vec2 u_resolution;
uniform float u_scale;

void main() {
    vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    float d = length(p) * u_scale;
    gl_FragColor = vec4(vec3(d), 1.0);
}
