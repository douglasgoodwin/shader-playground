// Soft animated color field - landing page background
precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float t = u_time * 0.15;

    // Soft gradient colors that shift slowly
    vec3 color1 = vec3(0.05, 0.08, 0.15); // Deep blue
    vec3 color2 = vec3(0.12, 0.06, 0.18); // Deep purple
    vec3 color3 = vec3(0.08, 0.12, 0.14); // Teal

    // Animated blend factors
    float blend1 = sin(uv.x * 2.0 + t) * 0.5 + 0.5;
    float blend2 = sin(uv.y * 2.0 + t * 0.7 + 1.0) * 0.5 + 0.5;
    float blend3 = sin((uv.x + uv.y) * 1.5 + t * 0.5) * 0.5 + 0.5;

    // Mix colors
    vec3 color = mix(color1, color2, blend1);
    color = mix(color, color3, blend2 * 0.5);

    // Add subtle noise/texture
    float noise = fract(sin(dot(uv * 100.0, vec2(12.9898, 78.233))) * 43758.5453);
    color += noise * 0.015;

    // Subtle vignette
    float vignette = 1.0 - length(uv - 0.5) * 0.5;
    color *= vignette;

    gl_FragColor = vec4(color, 1.0);
}
