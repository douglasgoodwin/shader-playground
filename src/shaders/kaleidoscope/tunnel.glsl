// Kaleidoscope tunnel — segments with radial repetition and zoom pulse
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
uniform float u_invert;

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

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    float aspect = u_resolution.x / u_resolution.y;

    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);

    float r = length(p);
    float a = atan(p.y, p.x);

    // Kaleidoscope fold
    float segAngle = TAU / u_segments;
    float rawA = a;
    a = mod(a, segAngle);
    if (mod(floor((rawA + PI) / segAngle), 2.0) > 0.5) {
        a = segAngle - a;
    }

    // Tunnel: use log of radius for repeating depth + time scroll
    float depth = log(max(r, 0.001)) + u_time * u_speed * 0.3;
    float ring = fract(depth * 0.5);

    // Map angle and depth ring to texture UV
    vec2 texUV = vec2(a / segAngle, ring);
    texUV = texUV * u_zoom;
    texUV = fract(texUV);

    vec3 color = sampleTexture(texUV);

    color = mix(color, 1.0 - color, u_invert);

    // Darken the center slightly for depth
    color *= smoothstep(0.0, 0.15, r);

    gl_FragColor = vec4(color, 1.0);
}
