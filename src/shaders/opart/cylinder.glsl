// Bridget Riley-inspired Op-Art Cylinder
// Creates an optical illusion of a 3D cylinder with scrolling stripes

precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_density;
uniform float u_harmonics;

void main() {
    vec2 u = gl_FragCoord.xy / u_resolution.xy;
    vec2 mouse = u_mouse / u_resolution;
    float t = u_time * u_speed;

    // Warp x apart at the top - creates perspective
    float x = u.x - 0.1 * (u.x - 0.5) * u.y;

    // Warp away from center point (0.5, 0.25) - creates cylinder bulge
    float z = 0.3 + 0.6 * (x - smoothstep(0.0, 0.75 / (0.5 - abs(x - 0.5)),
                                          1.0 - abs(u.y - 0.25)));

    // Horizontal stripes that scroll
    float stripeCount = 7.0 * u_harmonics;
    float f = fract(x * stripeCount + t * 0.14);

    // The magic: creates the 3D cylinder illusion
    float ff = f;
    float zz = z;
    float pattern = mod(u.y / 0.1 - min(f / z, --ff / --zz), 0.4);
    float bw = pattern > 0.2 ? 1.0 : 0.0;

    // Base color with intensity control
    vec3 color = vec3(bw) * u_density;

    // Subtle cool tint
    color *= vec3(0.95, 0.95, 1.0);

    // Mouse glow effect
    float mouseDist = distance(u, mouse);
    color += 0.15 * u_density / (mouseDist + 0.3) * vec3(0.3, 0.5, 1.0);

    gl_FragColor = vec4(color, 1.0);
}
