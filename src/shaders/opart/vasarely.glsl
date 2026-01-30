// Vasarely Sphere - Op-art spherical bulge with circles and diamonds
// Inspired by Victor Vasarely's "Vega" series

precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_density;
uniform float u_harmonics;

#define PI 3.14159265359

// Signed distance to a circle
float circleSDF(vec2 p, float r) {
    return length(p) - r;
}

// Signed distance to a rotated square (diamond)
float diamondSDF(vec2 p, float s) {
    p = abs(p);
    return (p.x + p.y - s) * 0.7071; // 1/sqrt(2)
}

// Spherical bulge distortion
vec2 sphereDistort(vec2 uv, vec2 center, float strength, float radius) {
    vec2 delta = uv - center;
    float dist = length(delta);

    if (dist < radius) {
        // Attempt to simulate sphere surface projection
        float normalizedDist = dist / radius;

        // Create bulge effect - stronger distortion toward edges of sphere
        float z = sqrt(1.0 - normalizedDist * normalizedDist);
        float bulge = 1.0 + strength * (1.0 - z);

        return center + delta * bulge;
    }
    return uv;
}

// Get the "depth" of the sphere at a point (for shading)
float sphereDepth(vec2 uv, vec2 center, float radius) {
    vec2 delta = uv - center;
    float dist = length(delta);

    if (dist < radius) {
        float normalizedDist = dist / radius;
        return sqrt(1.0 - normalizedDist * normalizedDist);
    }
    return 0.0;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    float aspect = u_resolution.x / u_resolution.y;

    // Center and correct aspect ratio
    vec2 p = uv - 0.5;
    p.x *= aspect;

    // Animation - subtle breathing
    float t = u_time * u_speed * 0.3;
    float breathe = 1.0 + 0.05 * sin(t);

    // Mouse interaction for sphere center
    vec2 center = vec2(0.0);
    if (length(u_mouse) > 1.0) {
        vec2 mouse = u_mouse / u_resolution - 0.5;
        mouse.x *= aspect;
        center = mouse * 0.3; // Subtle follow
    }

    // Sphere parameters
    float sphereRadius = 0.4 * u_harmonics * breathe;
    float bulgeStrength = 0.8 * u_density;

    // Apply spherical distortion
    vec2 distorted = sphereDistort(p, center, bulgeStrength, sphereRadius);

    // Get depth for shading
    float depth = sphereDepth(p, center, sphereRadius);

    // Grid parameters
    float gridSize = 12.0 * u_density;
    vec2 gridUV = distorted * gridSize;

    // Cell coordinates
    vec2 cellID = floor(gridUV);
    vec2 cellUV = fract(gridUV) - 0.5; // Center cell UV at origin

    // Checkerboard pattern
    float checker = mod(cellID.x + cellID.y, 2.0);

    // Calculate local distortion amount for ellipse effect
    vec2 deltaFromCenter = (cellID + 0.5) / gridSize - center;
    float distFromCenter = length(deltaFromCenter);

    // Stretch factors based on position relative to sphere center
    vec2 stretch = vec2(1.0);
    if (distFromCenter < sphereRadius && distFromCenter > 0.001) {
        // Radial stretch direction
        vec2 radialDir = normalize(deltaFromCenter);
        float stretchAmount = distFromCenter / sphereRadius;
        stretchAmount = pow(stretchAmount, 0.5) * bulgeStrength * 0.5;

        // Apply stretch perpendicular to radius (tangential compression)
        float angle = atan(radialDir.y, radialDir.x);
        float ca = cos(angle), sa = sin(angle);
        mat2 rot = mat2(ca, -sa, sa, ca);
        mat2 rotInv = mat2(ca, sa, -sa, ca); // transpose of rotation = inverse
        vec2 localUV = rot * cellUV;
        localUV.x *= 1.0 + stretchAmount;
        localUV.y *= 1.0 - stretchAmount * 0.3;
        cellUV = rotInv * localUV;
    }

    // Shape sizes
    float circleRadius = 0.42;
    float diamondSize = 0.35;

    // Distance to shapes
    float circle = circleSDF(cellUV, circleRadius);
    float diamond = diamondSDF(cellUV, diamondSize);

    // Smooth edges
    float aa = 0.02;
    float circleShape = 1.0 - smoothstep(-aa, aa, circle);
    float diamondShape = 1.0 - smoothstep(-aa, aa, diamond);

    // Color palette - grays with depth-based contrast
    float contrast = 0.3 + 0.7 * depth; // More contrast in center

    // Base colors
    float bgLight = 0.85;
    float bgDark = 0.65;
    float shapeLight = 0.95;
    float shapeMid = 0.5;
    float shapeDark = 0.1;

    // Apply contrast
    bgLight = mix(0.8, bgLight, contrast);
    bgDark = mix(0.7, bgDark, contrast);
    shapeDark = mix(0.3, shapeDark, contrast);

    // Build up the image layer by layer
    float color;

    // Background checkerboard
    color = mix(bgLight, bgDark, checker);

    // Circle layer
    float circleColor = mix(shapeMid, shapeLight, checker);
    // Add gradient to circle based on position
    circleColor -= 0.1 * (cellUV.x + cellUV.y);
    color = mix(color, circleColor, circleShape);

    // Diamond layer (on top)
    float diamondColor = mix(shapeDark, shapeMid, checker);
    // Slight gradient
    diamondColor += 0.05 * depth;
    color = mix(color, diamondColor, diamondShape);

    // Add subtle sphere shading
    if (depth > 0.0) {
        // Darken edges of sphere slightly
        float sphereShade = 0.95 + 0.05 * depth;
        color *= sphereShade;
    }

    // Very subtle animation - shifting light
    float lightShift = 0.02 * sin(t * 2.0 + p.x * 3.0);
    color += lightShift * depth;

    // Output
    gl_FragColor = vec4(vec3(color), 1.0);
}
