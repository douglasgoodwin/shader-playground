precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    vec3 colorA = vec3(1.0, 0.0, 0.0);  // Red
    vec3 colorB = vec3(0.0, 0.0, 1.0);  // Blue

    // mix(a, b, t) blends between a and b
    // when t=0, you get a. when t=1, you get b. when t=0.5, you get halfway.

    // TODO: Replace 0.5 with uv.x to create a gradient
    // TODO: Try uv.y instead
    // TODO: Try (uv.x + uv.y) / 2.0
    vec3 color = mix(colorA, colorB, 0.5);

    gl_FragColor = vec4(color, 1.0);
}
