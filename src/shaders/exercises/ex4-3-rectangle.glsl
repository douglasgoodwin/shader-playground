precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // A rectangle: x must be between left and right edges
    //              AND y must be between bottom and top edges

    float left = 0.3;
    float right = 0.7;
    float bottom = 0.4;
    float top = 0.6;

    // TODO: Complete these checks using step()
    // step(edge, x) returns 1.0 when x >= edge
    float insideLeft = step(left, uv.x);     // 1 if we're past the left edge
    float insideRight = 0.0;   // TODO: 1 if we're before the right edge
                               // Hint: 1.0 - step(right, uv.x)
    float insideBottom = 0.0;  // TODO: similar for bottom
    float insideTop = 0.0;     // TODO: similar for top

    // All conditions must be true (multiply them)
    float rect = insideLeft * insideRight * insideBottom * insideTop;

    gl_FragColor = vec4(vec3(rect), 1.0);
}
