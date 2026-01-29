// Render fragment shader - draws bird-like triangle particles
precision highp float;

varying vec3 v_velocity;
varying vec2 v_velocity2D;
varying float v_depth;

// Signed distance to a triangle pointing up (vertices at top, bottom-left, bottom-right)
float sdTriangle(vec2 p) {
    const float k = sqrt(3.0);
    p.x = abs(p.x) - 0.5;
    p.y = p.y + 0.5 / k;
    if (p.x + k * p.y > 0.0) {
        p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
    }
    p.x -= clamp(p.x, -1.0, 0.0);
    return -length(p) * sign(p.y);
}

void main() {
    // Transform point coord to centered coordinates
    vec2 coord = gl_PointCoord - 0.5;

    // Rotate to align with velocity direction
    // v_velocity2D points in the direction of movement
    // We want the triangle to point that way
    float angle = atan(v_velocity2D.x, v_velocity2D.y);
    float c = cos(angle);
    float s = sin(angle);
    vec2 rotated = vec2(
        coord.x * c - coord.y * s,
        coord.x * s + coord.y * c
    );

    // Scale for triangle size within point sprite
    rotated *= 2.5;

    // Get distance to triangle
    float d = sdTriangle(rotated);

    // Sharp triangle edge with slight anti-aliasing
    float alpha = 1.0 - smoothstep(-0.02, 0.02, d);
    if (alpha < 0.01) discard;

    // Color based on velocity direction and depth
    float speed = length(v_velocity);
    vec3 velDir = normalize(v_velocity + vec3(0.001));

    // Dusk sky colors - starlings murmurate at twilight
    vec3 warmColor = vec3(0.15, 0.12, 0.1);   // Dark silhouette
    vec3 coolColor = vec3(0.08, 0.08, 0.12);  // Slightly blue shadow

    // Birds appear as dark silhouettes
    vec3 color = mix(warmColor, coolColor, velDir.y * 0.5 + 0.5);

    // Depth fade - farther birds are slightly lighter (atmospheric)
    float depthFade = smoothstep(2.0, 5.0, v_depth);
    color = mix(color, vec3(0.25, 0.22, 0.28), depthFade * 0.5);

    // Slight highlight on fast-moving birds
    color += vec3(0.02) * speed;

    gl_FragColor = vec4(color, alpha * 0.95);
}
