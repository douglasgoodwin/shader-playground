precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float result = 0.0;
    float radius = 0.08;

    // TODO: Complete the loop to draw 5 circles in a row
    for (int i = 0; i < 5; i++) {
        // Convert i to float for math
        float fi = float(i);

        // TODO: Calculate x position so circles are evenly spaced
        //       Hint: x should go from 0.1 to 0.9
        //       Try: 0.1 + fi * 0.2
        float x = 0.5;  // Replace with calculated position
        float y = 0.5;

        vec2 center = vec2(x, y);
        float dist = length(uv - center);
        float circle = 1.0 - step(radius, dist);

        // Add this circle to our result
        result = max(result, circle);
    }

    gl_FragColor = vec4(vec3(result), 1.0);
}
