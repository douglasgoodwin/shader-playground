precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // uv.x goes from 0 (left) to 1 (right)
    // uv.y goes from 0 (bottom) to 1 (top)

    // TODO: Change uv.x to uv.y - what happens?
    // TODO: Try (uv.x + uv.y) / 2.0 - what does this create?
    // TODO: Try 1.0 - uv.x - what changes?
    float brightness = uv.x;

    gl_FragColor = vec4(vec3(brightness), 1.0);
}
