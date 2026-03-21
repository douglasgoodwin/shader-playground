// Flow-field scribble — continuous scribble lines warped through a turbulent
// noise field, with line density driven by image luminance.
// Dark areas → dense tangled scribbles, light areas → sparse open loops.
// Black line on white background, inspired by Jonathan Bachrach's scribbling machine.
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform sampler2D u_texture;
uniform vec2 u_textureSize;
uniform float u_density;       // line count (scanline spacing)
uniform float u_circleSize;    // warp amount (scribble amplitude)
uniform float u_contrast;
uniform float u_jitter;        // animation speed
uniform float u_ellipse;       // noise scale / turbulence
uniform float u_strokeWeight;
uniform vec3 u_bgColor;

#include "/lygia/generative/snoise.glsl"

// Aspect-ratio-corrected texture sampling (cover mode)
float sampleLuminance(vec2 uv) {
    float canvasAspect = u_resolution.x / u_resolution.y;
    float texAspect = u_textureSize.x / u_textureSize.y;

    vec2 texUV = uv;
    if (canvasAspect > texAspect) {
        float scale = texAspect / canvasAspect;
        texUV.y = (uv.y - 0.5) * scale + 0.5;
    } else {
        float scale = canvasAspect / texAspect;
        texUV.x = (uv.x - 0.5) * scale + 0.5;
    }
    texUV = clamp(texUV, 0.0, 1.0);

    vec3 color = texture2D(u_texture, texUV).rgb;
    float lum = dot(color, vec3(0.299, 0.587, 0.114));
    lum = (lum - 0.5) * u_contrast + 0.5;
    return clamp(lum, 0.0, 1.0);
}

// Turbulent warp: the scribble line at (x, row) gets displaced in Y
// by a chaotic noise field. Multiple octaves + curl-like displacement
// in X create the loopy, doubling-back character.
vec2 scribbleWarp(vec2 p, float amplitude) {
    float t = u_time * u_jitter * 0.2;

    // Base turbulence — large loops
    float n1 = snoise(p + t);
    float n2 = snoise(p * 1.0 + vec2(7.3, 3.7) + t * 0.7);

    // Medium detail — tighter scribbles
    float n3 = snoise(p * 2.7 + vec2(13.1, 17.3) + t * 1.1);
    float n4 = snoise(p * 2.7 + vec2(23.7, 11.1) + t * 0.9);

    // Fine detail — small jittery loops
    float n5 = snoise(p * 5.5 + vec2(31.0, 7.0) + t * 1.5);
    float n6 = snoise(p * 5.5 + vec2(41.0, 19.0) + t * 1.3);

    // Combine as 2D displacement (both X and Y warp)
    vec2 warp = vec2(
        n1 * 0.5 + n3 * 0.3 + n5 * 0.2,
        n2 * 0.5 + n4 * 0.3 + n6 * 0.2
    ) * amplitude;

    return warp;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec2 pixel = gl_FragCoord.xy;

    // Sample luminance at this pixel
    float lum = sampleLuminance(uv);
    float darkness = 1.0 - lum;

    // Number of scanline rows — more in dark areas, fewer in light
    float baseLineCount = 30.0 * u_density;
    float spacing = u_resolution.y / baseLineCount;

    // Noise field parameters
    float noiseScale = 3.0 * u_ellipse;
    // Warp amplitude: large enough to create loops that cross adjacent lines
    float warpAmount = spacing * 3.0 * u_circleSize;

    // Stroke thickness — thin pen line
    float thickness = u_strokeWeight * 0.5;

    // For each pixel, find distance to nearest warped scanline.
    // Check wider neighborhood since warps can be large.
    float minDist = 1e5;
    float baseRow = floor(pixel.y / spacing);

    for (int i = -4; i <= 4; i++) {
        float row = baseRow + float(i);
        float baseY = (row + 0.5) * spacing;

        // Noise coordinate: X varies continuously along the line,
        // each row gets a unique Y seed
        vec2 noiseCoord = vec2(
            pixel.x / u_resolution.y * noiseScale,
            row * 0.61
        );

        // Get 2D warp — displaces the line in both X and Y
        vec2 warp = scribbleWarp(noiseCoord, warpAmount);

        // The line's position at this X coordinate
        vec2 linePos = vec2(pixel.x + warp.x, baseY + warp.y);

        // Distance from pixel to this point on the warped line
        // We only care about Y distance since the line is continuous in X,
        // but X warp creates the visual impression of loops
        float d = abs(pixel.y - linePos.y);
        minDist = min(minDist, d);
    }

    // Anti-aliased thin line
    float aa = 1.0;
    float line = 1.0 - smoothstep(thickness - aa, thickness + aa, minDist);

    // In light areas, suppress lines (fewer scribbles = lighter tone)
    // In dark areas, lines stay fully visible
    // Use a soft threshold so there's a gradient of density
    float densityMask = smoothstep(0.02, 0.5, darkness);
    line *= densityMask;

    // Also: in medium-light areas, make lines thinner/fainter
    float fadeAlpha = mix(0.3, 1.0, smoothstep(0.1, 0.6, darkness));
    line *= fadeAlpha;

    // Black line on white background
    vec3 finalColor = mix(vec3(1.0), vec3(0.0), line);

    gl_FragColor = vec4(finalColor, 1.0);
}
