precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    vec2 center = vec2(0.5, 0.5);

    // TODO: Make the radius change over time
    //       sin(u_time) goes from -1 to 1
    //       We want radius to go from 0.1 to 0.4
    //       Formula: base + amplitude * sin(u_time)
    //       Try: 0.25 + 0.15 * sin(u_time)
    float radius = 0.3;  // Replace with animated version

    float dist = length(uv - center);
    float circle = 1.0 - step(radius, dist);

    gl_FragColor = vec4(vec3(circle), 1.0);
}
