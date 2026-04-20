precision mediump float;

uniform vec2 u_resolution;
uniform float u_fov;

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    vec3 rd = normalize(vec3(uv, u_fov));
    gl_FragColor = vec4(rd * 0.5 + 0.5, 1.0);
}
