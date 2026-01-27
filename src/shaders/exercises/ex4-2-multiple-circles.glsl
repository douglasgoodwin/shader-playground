precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // TODO: Create three circles at different positions
    //       Hint: copy the circle code three times with different centers

    vec2 center1 = vec2(0.3, 0.5);
    vec2 center2 = vec2(0.5, 0.5);  // TODO: Change position
    vec2 center3 = vec2(0.7, 0.5);  // TODO: Change position
    float radius = 0.15;

    float circle1 = 1.0 - step(radius, length(uv - center1));
    float circle2 = 0.0;  // TODO: Calculate like circle1
    float circle3 = 0.0;  // TODO: Calculate like circle1

    // Combine: if any circle contains this pixel, show white
    float result = max(circle1, max(circle2, circle3));

    gl_FragColor = vec4(vec3(result), 1.0);
}
