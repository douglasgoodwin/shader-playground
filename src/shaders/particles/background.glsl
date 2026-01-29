// Twilight sky background for murmuration
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // Gradient from horizon to sky
    vec3 horizonColor = vec3(0.85, 0.55, 0.35);  // Warm orange
    vec3 midColor = vec3(0.55, 0.40, 0.50);       // Dusty pink
    vec3 skyColor = vec3(0.25, 0.28, 0.45);       // Deep blue
    vec3 zenithColor = vec3(0.12, 0.14, 0.25);    // Dark blue

    // Multi-stop gradient
    vec3 color;
    if (uv.y < 0.3) {
        color = mix(horizonColor, midColor, uv.y / 0.3);
    } else if (uv.y < 0.6) {
        color = mix(midColor, skyColor, (uv.y - 0.3) / 0.3);
    } else {
        color = mix(skyColor, zenithColor, (uv.y - 0.6) / 0.4);
    }

    // Subtle sun glow near horizon
    vec2 sunPos = vec2(0.3, 0.1);
    float sunDist = distance(uv, sunPos);
    vec3 sunColor = vec3(1.0, 0.7, 0.4);
    color += sunColor * exp(-sunDist * 3.0) * 0.4;

    // Subtle cloud wisps
    float cloud = sin(uv.x * 8.0 + u_time * 0.02) * sin(uv.y * 3.0 + uv.x * 2.0);
    cloud = smoothstep(0.3, 0.8, cloud * 0.5 + 0.5);
    color = mix(color, color + vec3(0.1, 0.08, 0.06), cloud * 0.15 * (1.0 - uv.y));

    // Vignette
    float vignette = 1.0 - length(uv - 0.5) * 0.5;
    color *= vignette;

    gl_FragColor = vec4(color, 1.0);
}
