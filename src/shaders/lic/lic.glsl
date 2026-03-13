// Line Integral Convolution — painterly flow along image edges
// Computes image gradient, then integrates color along the tangent field
// to produce Van Gogh-style brushstroke smearing.
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform sampler2D u_texture;
uniform vec2 u_textureSize;
uniform float u_length;     // integration length (number of steps)
uniform float u_strength;   // blend original vs LIC
uniform float u_contrast;
uniform float u_curvature;  // how tightly strokes follow edges

// Aspect-ratio-corrected texture sampling (cover mode)
vec2 coverUV(vec2 uv) {
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
    return clamp(texUV, 0.0, 1.0);
}

vec3 sampleImage(vec2 uv) {
    vec3 c = texture2D(u_texture, coverUV(uv)).rgb;
    c = (c - 0.5) * u_contrast + 0.5;
    return clamp(c, 0.0, 1.0);
}

float luminance(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

// Image gradient via central differences
vec2 gradient(vec2 uv, float scale) {
    vec2 e = scale / u_resolution;
    return vec2(
        luminance(sampleImage(uv + vec2(e.x, 0.0))) - luminance(sampleImage(uv - vec2(e.x, 0.0))),
        luminance(sampleImage(uv + vec2(0.0, e.y))) - luminance(sampleImage(uv - vec2(0.0, e.y)))
    );
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec3 original = sampleImage(uv);

    // Multi-scale gradient for robust edge detection
    vec2 g = gradient(uv, 1.5);
    float m1 = length(g);
    vec2 g2 = gradient(uv, 4.0);
    float m2 = length(g2);
    if (m2 > m1) g = g2;
    vec2 g3 = gradient(uv, 10.0);
    float m3 = length(g3);
    if (m3 > max(m1, m2)) g = g3;

    float gradMag = length(g);

    // Flow direction = perpendicular to gradient (tangent to edges)
    vec2 tangent = vec2(-g.y, g.x);
    if (gradMag > 0.001) {
        tangent /= gradMag;
    } else {
        // No edge: use a subtle animated flow
        float a = sin(uv.x * 3.0 + uv.y * 5.0 + u_time * 0.2) * 0.5;
        tangent = vec2(cos(a), sin(a));
    }

    // Step size in UV space
    float stepSize = 1.0 / u_resolution.x;
    int steps = int(u_length);

    // Integrate along the tangent in both directions
    vec3 accum = original;
    float weight = 1.0;
    vec2 pos = uv;

    // Forward integration
    for (int i = 1; i <= 40; i++) {
        if (i > steps) break;

        // Recompute tangent at current position for curved strokes
        vec2 localG = gradient(pos, mix(4.0, 1.5, u_curvature));
        float localMag = length(localG);
        vec2 localTangent = tangent;
        if (localMag > 0.001) {
            localTangent = normalize(vec2(-localG.y, localG.x));
            // Keep consistent direction (avoid flipping)
            if (dot(localTangent, tangent) < 0.0) localTangent = -localTangent;
        }
        tangent = normalize(mix(tangent, localTangent, u_curvature));

        pos += tangent * stepSize;
        float w = 1.0 - float(i) / float(steps + 1); // linear falloff
        accum += sampleImage(pos) * w;
        weight += w;
    }

    // Reset for backward integration
    pos = uv;
    tangent = vec2(-g.y, g.x);
    if (gradMag > 0.001) tangent /= gradMag;

    for (int i = 1; i <= 40; i++) {
        if (i > steps) break;

        vec2 localG = gradient(pos, mix(4.0, 1.5, u_curvature));
        float localMag = length(localG);
        vec2 localTangent = -tangent;
        if (localMag > 0.001) {
            localTangent = -normalize(vec2(-localG.y, localG.x));
            if (dot(localTangent, -tangent) < 0.0) localTangent = -localTangent;
        }
        tangent = -normalize(mix(-tangent, localTangent, u_curvature));

        pos -= tangent * stepSize;
        float w = 1.0 - float(i) / float(steps + 1);
        accum += sampleImage(pos) * w;
        weight += w;
    }

    vec3 lic = accum / weight;

    // Blend original and LIC result
    vec3 result = mix(original, lic, u_strength);

    gl_FragColor = vec4(result, 1.0);
}
