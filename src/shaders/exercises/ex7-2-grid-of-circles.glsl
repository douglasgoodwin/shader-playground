precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float result = 0.0;
    float radius = 0.05;

    // TODO: Nested loops for a 4x4 grid
    //       Outer loop for rows (y), inner loop for columns (x)
    for (int row = 0; row < 4; row++) {
        for (int col = 0; col < 4; col++) {
            float x = 0.0;  // TODO: Calculate based on col
            float y = 0.0;  // TODO: Calculate based on row

            vec2 center = vec2(x, y);
            float dist = length(uv - center);
            float circle = 1.0 - step(radius, dist);
            result = max(result, circle);
        }
    }

    gl_FragColor = vec4(vec3(result), 1.0);
}
