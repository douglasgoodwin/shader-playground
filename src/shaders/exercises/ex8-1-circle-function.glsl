precision mediump float;
uniform vec2 u_resolution;

// TODO: Complete this function that returns 1.0 inside the circle, 0.0 outside
float drawCircle(vec2 uv, vec2 center, float radius) {
    float dist = length(uv - center);
    // TODO: Return the circle value using step()
    return 0.0;  // Replace this
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // Once your function works, these should draw three circles
    float c1 = drawCircle(uv, vec2(0.25, 0.5), 0.15);
    float c2 = drawCircle(uv, vec2(0.5, 0.5), 0.15);
    float c3 = drawCircle(uv, vec2(0.75, 0.5), 0.15);

    float result = max(c1, max(c2, c3));

    gl_FragColor = vec4(vec3(result), 1.0);
}
