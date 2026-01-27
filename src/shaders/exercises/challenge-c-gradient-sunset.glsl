precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // Define your sunset colors
    vec3 darkBlue = vec3(0.1, 0.1, 0.3);    // Top of sky
    vec3 orange = vec3(1.0, 0.5, 0.2);       // Horizon glow
    vec3 pink = vec3(1.0, 0.6, 0.7);         // Mid sky
    vec3 darkGround = vec3(0.05, 0.05, 0.1); // Ground/bottom

    // TODO: Create horizontal bands that blend into each other
    //       The sky should transition from dark blue (top) through
    //       pink and orange (middle) to dark ground (bottom)

    // Hint: Use smoothstep() to create soft transitions
    //       smoothstep(edge0, edge1, x) returns 0 when x < edge0,
    //       1 when x > edge1, and smoothly interpolates between

    // TODO: Define transition zones
    //       Example: float t1 = smoothstep(0.0, 0.3, uv.y);  // ground to orange
    //                float t2 = smoothstep(0.3, 0.5, uv.y);  // orange to pink
    //                float t3 = smoothstep(0.5, 1.0, uv.y);  // pink to blue

    // TODO: Mix colors based on transitions
    //       Start with ground color, then mix in each layer
    vec3 color = vec3(uv.y);  // Replace with your sunset gradient

    gl_FragColor = vec4(color, 1.0);
}
