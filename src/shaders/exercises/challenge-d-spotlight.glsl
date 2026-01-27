precision mediump float;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // TODO: Convert mouse position to UV coordinates (0-1 range)
    //       u_mouse gives pixel coordinates, divide by resolution
    vec2 mouseUV = u_mouse / u_resolution;

    // TODO: Calculate distance from current pixel to mouse position
    float dist = length(uv - mouseUV);

    // TODO: Create a spotlight effect
    //       Pixels close to mouse should be bright
    //       Pixels far from mouse should be dim
    //       Hint: Use smoothstep() for a soft edge
    //       Example: float spotlight = 1.0 - smoothstep(0.0, 0.3, dist);
    float spotlight = 1.0;  // Replace with distance-based brightness

    // Create a base scene to illuminate (simple gradient or pattern)
    vec3 sceneColor = vec3(uv.x, uv.y, 0.5);

    // TODO: Apply the spotlight to the scene
    //       Multiply scene color by spotlight brightness
    //       Add a minimum ambient light so it's not completely black
    float ambient = 0.1;
    vec3 finalColor = sceneColor;  // Replace with spotlight applied

    gl_FragColor = vec4(finalColor, 1.0);
}
