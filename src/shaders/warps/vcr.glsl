// VCR Noise - CRT screen distortion with scan lines, static, and tracking errors
// Based on work by Felix Turner (CC BY-NC-SA 4.0)
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform sampler2D u_texture;
uniform vec2 u_textureSize;
uniform float u_deform;
uniform float u_geometry;
uniform float u_speed;
uniform int u_hasTexture;

#include "/lygia/generative/random.glsl"

// Procedural noise (replaces texture-based noise)
float noise(vec2 p) {
    float s = random(vec2(1.0, 2.0 * cos(u_time)) * u_time * 8.0 + p);
    s *= s;
    return s;
}

float onOff(float a, float b, float c) {
    return step(c, sin(u_time + a * cos(u_time * b)));
}

float ramp(float y, float start, float end) {
    float inside = step(start, y) - step(end, y);
    float fact = (y - start) / (end - start) * inside;
    return (1.0 - fact) * inside;
}

float stripes(vec2 uv) {
    float noi = noise(uv * vec2(0.5, 1.0) + vec2(1.0, 3.0));
    return ramp(mod(uv.y * 4.0 + u_time / 2.0 + sin(u_time + sin(u_time * 0.63)), 1.0), 0.5, 0.6) * noi;
}

// Procedural fallback pattern when no image is loaded
vec3 fallbackPattern(vec2 uv) {
    float t = u_time * 0.5;
    // Color bars (classic TV test pattern)
    float bar = floor(uv.x * 7.0) / 7.0;
    vec3 col = vec3(0.0);
    if (bar < 1.0/7.0) col = vec3(1.0, 1.0, 1.0);
    else if (bar < 2.0/7.0) col = vec3(1.0, 1.0, 0.0);
    else if (bar < 3.0/7.0) col = vec3(0.0, 1.0, 1.0);
    else if (bar < 4.0/7.0) col = vec3(0.0, 1.0, 0.0);
    else if (bar < 5.0/7.0) col = vec3(1.0, 0.0, 1.0);
    else if (bar < 6.0/7.0) col = vec3(1.0, 0.0, 0.0);
    else col = vec3(0.0, 0.0, 1.0);
    return col * 0.8;
}

// Cover-fit: scale UVs so texture fills canvas without letterboxing
vec2 coverUV(vec2 uv, vec2 texSize, vec2 screenSize) {
    float screenAspect = screenSize.x / screenSize.y;
    float texAspect = texSize.x / texSize.y;
    vec2 scale = vec2(1.0);
    if (texAspect > screenAspect) {
        scale.x = screenAspect / texAspect;
    } else {
        scale.y = texAspect / screenAspect;
    }
    return (uv - 0.5) * scale + 0.5;
}

vec3 getVideo(vec2 uv) {
    vec2 look = uv;
    float window = 1.0 / (1.0 + 20.0 * (look.y - mod(u_time / 4.0, 1.0)) * (look.y - mod(u_time / 4.0, 1.0)));
    look.x = look.x + sin(look.y * 10.0 + u_time) / 50.0 * onOff(4.0, 4.0, 0.3) * (1.0 + cos(u_time * 80.0)) * window;
    float vShift = 0.4 * onOff(2.0, 3.0, 0.9) * (sin(u_time) * sin(u_time * 20.0) +
                                         (0.5 + 0.1 * sin(u_time * 200.0) * cos(u_time)));
    look.y = mod(look.y + vShift, 1.0);

    if (u_hasTexture == 1) {
        return texture2D(u_texture, coverUV(look, u_textureSize, u_resolution)).rgb;
    }
    return fallbackPattern(look);
}

vec2 screenDistort(vec2 uv) {
    uv -= vec2(0.5);
    float r2 = dot(uv, uv);
    uv *= 1.0 + u_geometry * r2;
    uv += vec2(0.5);
    return uv;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    uv = screenDistort(uv);
    vec3 video = getVideo(uv);

    float vigAmt = 3.0 + 0.3 * sin(u_time + 5.0 * cos(u_time * 5.0));
    float vignette = (1.0 - vigAmt * (uv.y - 0.5) * (uv.y - 0.5)) * (1.0 - vigAmt * (uv.x - 0.5) * (uv.x - 0.5));

    float intensity = u_deform;
    video += stripes(uv) * intensity;
    video += noise(uv * 2.0) / 2.0 * intensity;
    video *= vignette;
    // Scan lines: thin bright lines with dark gaps between
    float scanline = smoothstep(0.4, 0.5, fract(uv.y * u_resolution.y * 0.5));
    video *= 0.7 + 0.3 * scanline;

    gl_FragColor = vec4(video, 1.0);
}
