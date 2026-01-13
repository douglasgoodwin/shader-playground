// Triangular Voronoi - based on Shadertoy by FabriceNeyret2
// Animated triangular cell pattern with edge coloring

precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_density;
uniform float u_harmonics;

void main() {
    vec2 g = gl_FragCoord.xy;
    g /= u_resolution.y / (5.0 * u_density);

    vec2 p;
    float fx = 9.0;
    float fy;
    vec2 fzw;

    float t = u_time * u_speed * 0.1;

    // Search neighboring cells for closest triangular distance
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            p = vec2(float(x), float(y));

            // Animated cell centers using hash
            vec2 cellId = floor(g) + p;
            mat2 hashMat = mat2(2.0, 5.0, 5.0, 2.0);
            vec2 hash = fract(sin(cellId * hashMat) * 43758.5453);

            p += 0.5 + 0.5 * sin(t * 10.0 * u_harmonics + 9.0 * hash) - fract(g);

            // Triangular distance (hexagonal metric)
            fy = max(abs(p.x) * 0.866 - p.y * 0.5, p.y);

            if (fy < fx) {
                fx = fy;
                fzw = p;
            }
        }
    }

    // Determine which edge we're closest to
    vec3 n = vec3(0.0);

    float edge1 = fx - (-fzw.x * 0.866 - fzw.y * 0.5);
    float edge2 = fx - (fzw.x * 0.866 - fzw.y * 0.5);
    float edge3 = fx - fzw.y;

    if (edge1 < 0.001) n = vec3(1.0, 0.0, 0.0);
    if (edge2 < 0.001) n = vec3(0.0, 1.0, 0.0);
    if (edge3 < 0.001) n = vec3(0.0, 0.0, 1.0);

    // Create color based on edge direction (replacing texture lookup)
    vec3 edgeColor = vec3(0.0);

    // Time-varying color palette
    float ct = t * 2.0;
    vec3 col1 = 0.5 + 0.5 * cos(ct + vec3(0.0, 2.0, 4.0));
    vec3 col2 = 0.5 + 0.5 * cos(ct + vec3(2.0, 4.0, 0.0));
    vec3 col3 = 0.5 + 0.5 * cos(ct + vec3(4.0, 0.0, 2.0));

    edgeColor = n.x * col1 + n.y * col2 + n.z * col3;

    // If no edge detected, use distance-based gradient
    if (length(n) < 0.5) {
        edgeColor = 0.5 + 0.5 * cos(ct + fx * 3.0 + vec3(0.0, 2.0, 4.0));
    }

    // Final color with distance fade
    vec3 finalColor = sqrt(edgeColor * fx * 1.5);

    // Add subtle cell interior shading
    finalColor += vec3(0.02) / (fx + 0.1);

    // Mouse interaction
    vec2 mouse = u_mouse / u_resolution;
    vec2 uv = gl_FragCoord.xy / u_resolution;
    float mouseDist = length(uv - mouse);
    finalColor += vec3(0.3, 0.4, 0.5) * 0.03 / (mouseDist + 0.2);

    gl_FragColor = vec4(finalColor, 1.0);
}
