// Fractal kaleidoscope — recursive angular folds with position offset
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform sampler2D u_texture;
uniform vec2 u_textureSize;
uniform int u_hasTexture;
uniform float u_segments;
uniform float u_zoom;
uniform float u_speed;

#define PI 3.14159265359
#define TAU 6.28318530718

vec2 coverUV(vec2 uv, vec2 texSize, vec2 screenSize) {
    float screenAspect = screenSize.x / screenSize.y;
    float texAspect = texSize.x / texSize.y;
    vec2 scale = vec2(1.0);
    if (texAspect > screenAspect) scale.x = screenAspect / texAspect;
    else scale.y = texAspect / screenAspect;
    return (uv - 0.5) * scale + 0.5;
}

vec3 sampleTexture(vec2 uv) {
    uv = clamp(uv, 0.0, 1.0);
    if (u_hasTexture == 1) return texture2D(u_texture, coverUV(uv, u_textureSize, u_resolution)).rgb;
    float t = u_time * 0.3;
    vec3 c;
    c.r = 0.5 + 0.5 * sin(uv.x * 12.0 + t);
    c.g = 0.5 + 0.5 * sin(uv.y * 10.0 + t * 1.3 + 2.0);
    c.b = 0.5 + 0.5 * sin((uv.x + uv.y) * 8.0 + t * 0.7 + 4.0);
    return c;
}

// Fold point across a line defined by angle
vec2 foldAngle(vec2 p, float angle) {
    vec2 n = vec2(cos(angle), sin(angle));
    return p - 2.0 * min(dot(p, n), 0.0) * n;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    float aspect = u_resolution.x / u_resolution.y;

    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);

    // Slow drift
    float t = u_time * u_speed * 0.1;
    p += vec2(sin(t * 0.7) * 0.1, cos(t * 0.5) * 0.1);

    // Multiple fold iterations — each fold doubles the symmetry
    float segAngle = PI / u_segments;
    for (int i = 0; i < 6; i++) {
        // Rotate slowly
        float rot = t * 0.2 * float(i + 1) * 0.3;
        float c = cos(rot), s = sin(rot);
        p = vec2(c * p.x - s * p.y, s * p.x + c * p.y);

        // Fold across segment boundary
        float a = atan(p.y, p.x);
        a = mod(a + PI, segAngle * 2.0) - segAngle;
        p = length(p) * vec2(cos(a), abs(sin(a)));

        // Translate to create fractal offset
        p -= vec2(0.5, 0.0) * u_zoom * 0.3;
    }

    // Map folded position to texture UV
    vec2 texUV = p / u_zoom + 0.5;

    vec3 color = sampleTexture(texUV);

    gl_FragColor = vec4(color, 1.0);
}
