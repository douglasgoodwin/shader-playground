precision mediump float;

uniform vec2 u_resolution;
uniform float u_cells;
uniform float u_seed;

float hash(vec2 p) {
    return fract(sin(dot(p + u_seed, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    vec2 cell = floor(p * u_cells);
    float v = hash(cell);
    gl_FragColor = vec4(vec3(v), 1.0);
}
