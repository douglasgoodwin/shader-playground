// Video kaleidoscope — angular reflections with configurable segments
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
    // Procedural fallback — colorful pattern
    float t = u_time * 0.3;
    vec3 c = vec3(0.0);
    c.r = 0.5 + 0.5 * sin(uv.x * 12.0 + t);
    c.g = 0.5 + 0.5 * sin(uv.y * 10.0 + t * 1.3 + 2.0);
    c.b = 0.5 + 0.5 * sin((uv.x + uv.y) * 8.0 + t * 0.7 + 4.0);
    return c;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    float aspect = u_resolution.x / u_resolution.y;

    // Center and correct aspect ratio
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);

    // Slow rotation
    float rot = u_time * u_speed * 0.15;
    float c = cos(rot), s = sin(rot);
    p = vec2(c * p.x - s * p.y, s * p.x + c * p.y);

    // Convert to polar
    float r = length(p);
    float a = atan(p.y, p.x);

    // Kaleidoscope: fold the angle into one segment
    float segAngle = TAU / u_segments;
    a = mod(a, segAngle);
    // Mirror alternate segments for seamless reflections
    if (mod(floor((atan(p.y, p.x) + PI) / segAngle), 2.0) > 0.5) {
        a = segAngle - a;
    }

    // Convert back to cartesian for texture sampling
    vec2 kp = vec2(cos(a), sin(a)) * r;

    // Map to texture UV with zoom
    vec2 texUV = kp / u_zoom + 0.5;

    vec3 color = sampleTexture(texUV);

    gl_FragColor = vec4(color, 1.0);
}
