precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_radius;
uniform float u_orbit;
uniform float u_speed;

void main() {
    vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    vec2 center = u_orbit * vec2(sin(u_time * u_speed), cos(u_time * u_speed));
    float d = length(p - center);
    float circle = 1.0 - smoothstep(u_radius - 0.01, u_radius + 0.01, d);
    gl_FragColor = vec4(vec3(circle), 1.0);
}
