precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform sampler2D u_video;
uniform vec2 u_videoSize;
uniform float u_dotDensity;    // Controls grid density (1.0 = default)
uniform float u_dotScale;      // Overall dot size multiplier
uniform float u_contrast;      // Contrast adjustment
uniform float u_showLines;     // 0 = no lines, 1 = show lines between nearby dots
uniform float u_invert;        // 0 = dark dots on light, 1 = light dots on dark

// Hash function for pseudo-random jitter
vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453) * 2.0 - 1.0;
}

float hash1(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Sample video luminance with aspect ratio correction
float sampleLuminance(vec2 uv) {
    // Fit video to canvas while maintaining aspect ratio
    float canvasAspect = u_resolution.x / u_resolution.y;
    float videoAspect = u_videoSize.x / u_videoSize.y;

    vec2 videoUV = uv;
    if (canvasAspect > videoAspect) {
        // Canvas is wider - letterbox on sides
        float scale = videoAspect / canvasAspect;
        videoUV.x = (uv.x - 0.5) / scale + 0.5;
    } else {
        // Canvas is taller - letterbox top/bottom
        float scale = canvasAspect / videoAspect;
        videoUV.y = (uv.y - 0.5) / scale + 0.5;
    }

    // Return grey for out of bounds
    if (videoUV.x < 0.0 || videoUV.x > 1.0 || videoUV.y < 0.0 || videoUV.y > 1.0) {
        return 0.5;
    }

    // Flip Y for webcam (mirrored)
    videoUV.y = 1.0 - videoUV.y;

    vec3 color = texture2D(u_video, videoUV).rgb;
    // Luminance formula
    float lum = dot(color, vec3(0.299, 0.587, 0.114));

    // Apply contrast
    lum = (lum - 0.5) * u_contrast + 0.5;
    lum = clamp(lum, 0.0, 1.0);

    return lum;
}

// Signed distance to a circle
float sdCircle(vec2 p, vec2 center, float radius) {
    return length(p - center) - radius;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // Base grid cell size - smaller = more dots
    float baseCellSize = 8.0 / u_dotDensity;

    // Grey background (middle value so dots can paint light and dark)
    float bgGrey = 0.5;
    if (u_invert > 0.5) {
        bgGrey = 0.1; // Dark background for inverted mode
    }
    vec3 finalColor = vec3(bgGrey);

    // We'll check multiple grid scales for better coverage
    // Finer grids only activate in darker areas (per Hodgin's approach)

    float minDist = 1000.0;
    vec3 closestDotInfo = vec3(0.0); // x,y = position, z = size

    // Check 3 grid scales
    for (int scale = 0; scale < 3; scale++) {
        float cellSize = baseCellSize / (1.0 + float(scale) * 0.5);
        float gridScale = u_resolution.y / cellSize;

        vec2 gridUV = uv * gridScale;
        vec2 cellID = floor(gridUV);
        vec2 cellUV = fract(gridUV);

        // Check 3x3 neighborhood
        for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
                vec2 neighborID = cellID + vec2(float(dx), float(dy));

                // Jitter the dot position within cell
                vec2 jitter = hash2(neighborID + float(scale) * 100.0) * 0.4;
                vec2 dotCellPos = vec2(0.5) + jitter;

                // World position of this dot
                vec2 dotGridPos = neighborID + dotCellPos;
                vec2 dotUV = dotGridPos / gridScale;

                // Sample luminance at dot position
                float lum = sampleLuminance(dotUV);

                // Per Hodgin: dark areas = small dots (weak charge, pack tight)
                //             light areas = large dots (strong charge, spread out)
                // But for visibility, we need the dots themselves to be visible

                // Probability of dot appearing based on luminance and grid scale
                float threshold = hash1(neighborID + float(scale) * 200.0);

                // For finer grids (higher scale), only spawn in darker areas
                float lumThreshold = float(scale) * 0.3;

                if (lum < (1.0 - lumThreshold) || scale == 0) {
                    // Dot size: smaller in dark areas, larger in light areas
                    // But we want MORE dots in dark areas (which happens via finer grids)
                    float dotRadius;

                    if (u_invert > 0.5) {
                        // Inverted: light dots on dark background
                        // Larger dots in lighter areas
                        dotRadius = mix(0.1, 0.45, lum) * cellSize * u_dotScale;
                    } else {
                        // Normal: dark dots on light background
                        // Larger dots in darker areas (more ink = darker)
                        dotRadius = mix(0.45, 0.1, lum) * cellSize * u_dotScale;
                    }

                    // Skip very small dots
                    if (dotRadius < 0.5) continue;

                    // Distance from current pixel to this dot
                    vec2 pixelPos = gl_FragCoord.xy;
                    vec2 dotPos = dotUV * u_resolution;
                    float dist = length(pixelPos - dotPos);

                    // Track closest dot for line drawing
                    if (dist < minDist) {
                        minDist = dist;
                        closestDotInfo = vec3(dotPos, dotRadius);
                    }

                    // Draw the dot
                    float dotDist = dist - dotRadius;
                    if (dotDist < 0.0) {
                        // Inside a dot
                        if (u_invert > 0.5) {
                            finalColor = vec3(0.95); // White dots
                        } else {
                            finalColor = vec3(0.05); // Black dots
                        }
                    } else if (dotDist < 1.0) {
                        // Anti-aliased edge
                        float alpha = 1.0 - dotDist;
                        if (u_invert > 0.5) {
                            finalColor = mix(finalColor, vec3(0.95), alpha);
                        } else {
                            finalColor = mix(finalColor, vec3(0.05), alpha);
                        }
                    }
                }
            }
        }
    }

    // Optional: Draw lines between nearby dots (Hodgin's additional feature)
    if (u_showLines > 0.5) {
        // Check nearby dots for line connections
        float lineRadius = baseCellSize * 2.5;
        vec2 pixelPos = gl_FragCoord.xy;

        float gridScale = u_resolution.y / baseCellSize;
        vec2 gridUV = uv * gridScale;
        vec2 cellID = floor(gridUV);

        // Find nearby dot pairs and draw lines
        for (int dy = -2; dy <= 2; dy++) {
            for (int dx = -2; dx <= 2; dx++) {
                vec2 neighborID1 = cellID + vec2(float(dx), float(dy));
                vec2 jitter1 = hash2(neighborID1) * 0.4;
                vec2 dot1UV = (neighborID1 + vec2(0.5) + jitter1) / gridScale;
                vec2 dot1Pos = dot1UV * u_resolution;

                // Check against other nearby dots
                for (int dy2 = -1; dy2 <= 1; dy2++) {
                    for (int dx2 = -1; dx2 <= 1; dx2++) {
                        if (dx2 == 0 && dy2 == 0) continue;

                        vec2 neighborID2 = neighborID1 + vec2(float(dx2), float(dy2));
                        vec2 jitter2 = hash2(neighborID2) * 0.4;
                        vec2 dot2UV = (neighborID2 + vec2(0.5) + jitter2) / gridScale;
                        vec2 dot2Pos = dot2UV * u_resolution;

                        float dotDist = length(dot1Pos - dot2Pos);

                        // Only draw line if dots are close enough
                        if (dotDist < lineRadius) {
                            // Distance from pixel to line segment
                            vec2 pa = pixelPos - dot1Pos;
                            vec2 ba = dot2Pos - dot1Pos;
                            float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
                            float lineDist = length(pa - ba * t);

                            // Thin line
                            float lineWidth = 0.5;
                            if (lineDist < lineWidth) {
                                float alpha = (1.0 - lineDist / lineWidth) * 0.5;
                                // Check luminance at line midpoint
                                vec2 midUV = (dot1UV + dot2UV) * 0.5;
                                float midLum = sampleLuminance(midUV);
                                // Only draw lines in darker areas
                                if (midLum < 0.5) {
                                    alpha *= (1.0 - midLum * 2.0);
                                    if (u_invert > 0.5) {
                                        finalColor = mix(finalColor, vec3(0.9), alpha);
                                    } else {
                                        finalColor = mix(finalColor, vec3(0.1), alpha);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    gl_FragColor = vec4(finalColor, 1.0);
}
