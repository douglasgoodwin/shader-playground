precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // step(edge, x) returns 0.0 if x < edge, 1.0 if x >= edge
    // It's like asking: "is x past the edge?"

    // TODO: Change 0.5 to 0.3, then 0.7 - what moves?
    float cutoff = step(0.5, uv.x);

    // TODO: Make a horizontal line instead (hint: use uv.y)

    // TODO: Combine both to make a corner:
    //       float corner = step(0.5, uv.x) * step(0.5, uv.y);

    gl_FragColor = vec4(vec3(cutoff), 1.0);
}
