// Classic LIC — white noise smeared along a flow field
// Shows the vector field structure of the image gradient as visible streamlines.
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform sampler2D u_texture;
uniform vec2 u_textureSize;
uniform float u_length;
uniform float u_strength;
uniform float u_contrast;
uniform float u_curvature;

#include "/lygia/generative/random.glsl"

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

    // Multi-scale gradient
    vec2 g = gradient(uv, 1.5);
    float m1 = length(g);
    vec2 g2 = gradient(uv, 4.0);
    if (length(g2) > m1) { g = g2; m1 = length(g2); }
    vec2 g3 = gradient(uv, 10.0);
    if (length(g3) > m1) g = g3;

    float gradMag = length(g);

    vec2 tangent = vec2(-g.y, g.x);
    if (gradMag > 0.001) {
        tangent /= gradMag;
    } else {
        float a = sin(uv.x * 3.0 + uv.y * 5.0 + u_time * 0.2) * 0.5;
        tangent = vec2(cos(a), sin(a));
    }

    float stepSize = 1.0 / u_resolution.x;
    int steps = int(u_length);

    // White noise field — use high-res pixel coords for fine grain
    float accum = random(gl_FragCoord.xy * 0.73 + 0.1);
    float weight = 1.0;
    vec2 pos = uv;
    vec2 fwd = tangent;

    // Forward
    for (int i = 1; i <= 40; i++) {
        if (i > steps) break;
        vec2 localG = gradient(pos, mix(4.0, 1.5, u_curvature));
        if (length(localG) > 0.001) {
            vec2 lt = normalize(vec2(-localG.y, localG.x));
            if (dot(lt, fwd) < 0.0) lt = -lt;
            fwd = normalize(mix(fwd, lt, u_curvature));
        }
        pos += fwd * stepSize;
        float w = 1.0 - float(i) / float(steps + 1);
        accum += random(floor(pos * u_resolution) * 0.73 + 0.1) * w;
        weight += w;
    }

    // Backward
    pos = uv;
    vec2 bwd = tangent;
    for (int i = 1; i <= 40; i++) {
        if (i > steps) break;
        vec2 localG = gradient(pos, mix(4.0, 1.5, u_curvature));
        if (length(localG) > 0.001) {
            vec2 lt = -normalize(vec2(-localG.y, localG.x));
            if (dot(lt, -bwd) < 0.0) lt = -lt;
            bwd = -normalize(mix(-bwd, lt, u_curvature));
        }
        pos -= bwd * stepSize;
        float w = 1.0 - float(i) / float(steps + 1);
        accum += random(floor(pos * u_resolution) * 0.73 + 0.1) * w;
        weight += w;
    }

    float lic = accum / weight;

    // Tint the LIC noise with the original image color
    float lum = luminance(original);
    vec3 tinted = original * (0.5 + lic);

    // Blend: 0 = pure image, 1 = full flow noise
    vec3 result = mix(original, tinted, u_strength);

    gl_FragColor = vec4(result, 1.0);
}
