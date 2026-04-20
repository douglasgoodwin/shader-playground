precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

void main() {
    float v = 0.5 + 0.5 * sin(u_time);
    gl_FragColor = vec4(vec3(v), 1.0);
}
