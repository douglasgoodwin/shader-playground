precision mediump float;

uniform vec2 u_resolution;
uniform float u_radius;
uniform float u_softness;
uniform float u_hue_in;
uniform float u_hue_out;

vec3 hue(float h) {
    h = fract(h);
    vec3 k = vec3(1.0, 2.0 / 3.0, 1.0 / 3.0);
    vec3 p = abs(fract(vec3(h) + k) * 6.0 - 3.0);
    return clamp(p - 1.0, 0.0, 1.0);
}

void main() {
    vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    float d = length(p);
    float edge = max(u_softness, 0.001);
    float mask = 1.0 - smoothstep(u_radius - edge, u_radius + edge, d);

    vec3 inside = hue(u_hue_in);
    vec3 outside = hue(u_hue_out);
    vec3 color = mix(outside, inside, mask);

    gl_FragColor = vec4(color, 1.0);
}
