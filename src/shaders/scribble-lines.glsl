precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform sampler2D u_texture;
uniform vec2 u_textureSize;
uniform float u_density;
uniform float u_circleSize;  // controls line spacing scale
uniform float u_contrast;
uniform float u_jitter;
uniform float u_ellipse;     // unused, kept for uniform compatibility
uniform float u_strokeWeight;
uniform vec3 u_bgColor;

#include "/lygia/generative/random.glsl"

// Sample image luminance with aspect ratio correction
float sampleLuminance(vec2 uv) {
    float canvasAspect = u_resolution.x / u_resolution.y;
    float texAspect = u_textureSize.x / u_textureSize.y;

    vec2 texUV = uv;
    if (canvasAspect > texAspect) {
        float scale = texAspect / canvasAspect;
        texUV.x = (uv.x - 0.5) / scale + 0.5;
    } else {
        float scale = canvasAspect / texAspect;
        texUV.y = (uv.y - 0.5) / scale + 0.5;
    }

    if (texUV.x < 0.0 || texUV.x > 1.0 || texUV.y < 0.0 || texUV.y > 1.0) {
        return 1.0;
    }

    texUV.y = 1.0 - texUV.y;

    vec3 color = texture2D(u_texture, texUV).rgb;
    float lum = dot(color, vec3(0.299, 0.587, 0.114));

    lum = (lum - 0.5) * u_contrast + 0.5;
    return clamp(lum, 0.0, 1.0);
}

// Multi-scale gradient (same as scribble shader)
vec2 multiScaleGradient(vec2 uv, float cellSize) {
    vec2 best = vec2(0.0);
    float bestMag = 0.0;

    vec2 e1 = vec2(2.0) / u_resolution;
    vec2 g1 = vec2(
        sampleLuminance(uv + vec2(e1.x, 0.0)) - sampleLuminance(uv - vec2(e1.x, 0.0)),
        sampleLuminance(uv + vec2(0.0, e1.y)) - sampleLuminance(uv - vec2(0.0, e1.y))
    );
    float m1 = length(g1);
    if (m1 > bestMag) { bestMag = m1; best = g1; }

    vec2 e2 = vec2(cellSize) / u_resolution;
    vec2 g2 = vec2(
        sampleLuminance(uv + vec2(e2.x, 0.0)) - sampleLuminance(uv - vec2(e2.x, 0.0)),
        sampleLuminance(uv + vec2(0.0, e2.y)) - sampleLuminance(uv - vec2(0.0, e2.y))
    );
    float m2 = length(g2);
    if (m2 > bestMag) { bestMag = m2; best = g2; }

    vec2 e3 = vec2(cellSize * 4.0) / u_resolution;
    vec2 g3 = vec2(
        sampleLuminance(uv + vec2(e3.x, 0.0)) - sampleLuminance(uv - vec2(e3.x, 0.0)),
        sampleLuminance(uv + vec2(0.0, e3.y)) - sampleLuminance(uv - vec2(0.0, e3.y))
    );
    float m3 = length(g3);
    if (m3 > bestMag) { bestMag = m3; best = g3; }

    return best;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec2 pixel = gl_FragCoord.xy;

    vec3 finalColor = u_bgColor;

    float lum = sampleLuminance(uv);
    float darkness = 1.0 - lum;

    // Nothing to draw in light areas
    if (darkness < 0.05) {
        gl_FragColor = vec4(finalColor, 1.0);
        return;
    }

    // Gradient for line orientation
    float baseSpacing = 30.0 / u_density;
    vec2 grad = multiScaleGradient(uv, baseSpacing);
    float gradMag = length(grad);
    float edgeStrength = smoothstep(0.01, 0.15, gradMag);

    // Line direction: perpendicular to gradient (along edges)
    // Fall back to a fixed diagonal in flat areas
    float gradAngle = atan(grad.y, grad.x);
    float fallbackAngle = 0.785; // ~45 degrees
    float angle = mix(fallbackAngle, gradAngle + 1.5708, edgeStrength);

    // Animated angle wobble
    float wobble = sin(u_time * 0.8 + uv.x * 10.0 + uv.y * 10.0) * 0.05 * u_jitter;
    angle += wobble;

    // Line normal (perpendicular to line direction)
    vec2 normal = vec2(cos(angle), sin(angle));

    // Line spacing: tighter in darker areas
    float maxSpacing = baseSpacing * 2.0 * u_circleSize;
    float minSpacing = baseSpacing * 0.3 * u_circleSize;
    float spacing = mix(maxSpacing, minSpacing, darkness);

    // Animated offset along normal for movement
    float animOffset = u_time * 8.0 * u_jitter;

    // Project pixel onto normal direction
    float proj = dot(pixel, normal) + animOffset;

    // Distance to nearest line
    float d = abs(mod(proj, spacing) - spacing * 0.5);

    // Anti-aliased line
    float aa = 1.0;
    float thickness = u_strokeWeight;
    float line = 1.0 - smoothstep(thickness * 0.5 - aa, thickness * 0.5 + aa, d);

    // Fade line strength with darkness (lighter areas → thinner/fainter lines)
    line *= smoothstep(0.05, 0.3, darkness);

    if (line > 0.0) {
        finalColor = mix(finalColor, vec3(1.0), line * 0.9);
    }

    gl_FragColor = vec4(finalColor, 1.0);
}
