precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

// Helper function to draw a circle
float drawCircle(vec2 uv, vec2 center, float radius) {
    float dist = length(uv - center);
    return 1.0 - step(radius, dist);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // TODO: Create three circles stacked vertically
    //       Red at top (y = 0.75)
    //       Yellow in middle (y = 0.5)
    //       Green at bottom (y = 0.25)
    float radius = 0.12;

    float redLight = drawCircle(uv, vec2(0.5, 0.75), radius);
    float yellowLight = 0.0;  // TODO: Create yellow light circle
    float greenLight = 0.0;   // TODO: Create green light circle

    // TODO: Use u_time to determine which light is "on"
    //       Hint: mod(u_time, 3.0) gives a value that cycles 0->3
    //       0-1: red on, 1-2: yellow on, 2-3: green on
    float cycle = mod(u_time, 3.0);

    float redOn = 0.0;     // TODO: 1.0 when cycle < 1.0
    float yellowOn = 0.0;  // TODO: 1.0 when cycle >= 1.0 && < 2.0
    float greenOn = 0.0;   // TODO: 1.0 when cycle >= 2.0

    // Dim brightness for "off" lights, full brightness for "on"
    float dimLevel = 0.2;

    // TODO: Combine everything into final color
    //       Red channel = redLight * (redOn ? 1.0 : dimLevel)
    //       Green channel = greenLight * (greenOn ? 1.0 : dimLevel)
    //       etc.
    vec3 color = vec3(0.0);

    gl_FragColor = vec4(color, 1.0);
}
