precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // TODO: Make the center move over time
    //       sin(u_time) for x, cos(u_time) for y creates a circular path
    //       Scale it down: 0.5 + 0.2 * sin(u_time)
    vec2 center = vec2(0.5, 0.5);  // Replace with animated version

    float radius = 0.1;
    float dist = length(uv - center);
    float circle = 1.0 - step(radius, dist);

    gl_FragColor = vec4(vec3(circle), 1.0);
}
