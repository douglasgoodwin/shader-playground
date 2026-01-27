precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float value = 0.0;

    // These lines run in order, top to bottom
    // TODO: Predict what color you'll see, then run it
    // TODO: Swap lines A and B - what changes?

    value = uv.x;        // Line A
    value = value * 2.0; // Line B
    value = value - 0.5;

    gl_FragColor = vec4(vec3(value), 1.0);
}
