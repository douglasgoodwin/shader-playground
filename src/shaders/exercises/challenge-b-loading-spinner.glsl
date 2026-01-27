precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

#define PI 3.14159265359

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // Center the coordinates so (0,0) is at screen center
    vec2 centered = uv - 0.5;

    // TODO: Calculate distance from center
    float dist = length(centered);

    // TODO: Create a ring (visible between inner and outer radius)
    float innerRadius = 0.2;
    float outerRadius = 0.3;
    float ring = 0.0;  // Use step() to create the ring shape

    // TODO: Calculate the angle of each pixel using atan(y, x)
    //       atan() returns values from -PI to PI
    float angle = atan(centered.y, centered.x);

    // TODO: Create a rotating threshold
    //       The "lit" portion of the ring rotates over time
    //       Hint: Compare angle to a rotating value based on u_time
    float rotatingAngle = u_time;  // Adjust speed with multiplier

    // TODO: Only show part of the ring (like a pac-man shape that rotates)
    //       Hint: Use step() or smoothstep() to compare angle to rotatingAngle
    float spinner = 0.0;

    // Combine ring shape with spinner mask
    float result = ring * spinner;

    gl_FragColor = vec4(vec3(result), 1.0);
}
