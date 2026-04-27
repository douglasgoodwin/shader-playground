// Point cloud — samples a texture, smooths it into a depth field,
// and displaces each point along Z by that depth.

uniform sampler2D u_image;
uniform vec2  u_imageSize;
uniform float u_depth;
uniform float u_pointSize;
uniform float u_invert;
uniform float u_pixelRatio;
uniform float u_blurRadius;
uniform float u_time;
uniform float u_level;   // overall audio energy, 0..1
uniform float u_bass;    // low-band energy, 0..1
uniform float u_treble;  // high-band energy, 0..1

varying vec3  v_color;
varying float v_depth;

float lum(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void main() {
    // position.xy holds our UV in [0,1]
    vec2 puv = position.xy;

    vec3 centerColor = texture2D(u_image, puv).rgb;
    v_color = centerColor;

    // 9-tap box smoothing → coherent depth instead of per-pixel noise.
    vec2 texelSize = 1.0 / u_imageSize;
    float r = u_blurRadius;
    float d = 0.0;
    d += lum(centerColor);
    d += lum(texture2D(u_image, puv + vec2( r, 0.0) * texelSize).rgb);
    d += lum(texture2D(u_image, puv + vec2(-r, 0.0) * texelSize).rgb);
    d += lum(texture2D(u_image, puv + vec2( 0.0,  r) * texelSize).rgb);
    d += lum(texture2D(u_image, puv + vec2( 0.0, -r) * texelSize).rgb);
    d += lum(texture2D(u_image, puv + vec2( r,  r) * texelSize).rgb);
    d += lum(texture2D(u_image, puv + vec2(-r,  r) * texelSize).rgb);
    d += lum(texture2D(u_image, puv + vec2( r, -r) * texelSize).rgb);
    d += lum(texture2D(u_image, puv + vec2(-r, -r) * texelSize).rgb);
    d /= 9.0;

    d = mix(d, 1.0 - d, u_invert);
    v_depth = d;

    // Fit image aspect inside a 2x2 box on the xy plane.
    float aspect = u_imageSize.x / max(1.0, u_imageSize.y);
    vec2 xy = (puv - 0.5) * 2.0;
    if (aspect > 1.0) xy.y /= aspect;
    else              xy.x *= aspect;

    // Recenter depth around 0 so rotation pivots through the middle of the cloud.
    float z = (d - 0.5) * u_depth;

    // Audio: level breathes the whole cloud along Z, bass sends a radial
    // ripple outward from the image center, treble stays for point-size jitter below.
    z *= 1.0 + u_level * 0.9;
    float rad = length(xy);
    z += sin(rad * 10.0 - u_time * 6.0) * u_bass * 0.35;

    vec4 mv = modelViewMatrix * vec4(xy, z, 1.0);
    gl_Position = projectionMatrix * mv;

    // Perspective-scaled point size, with treble shimmer.
    float size = u_pointSize + u_treble * 4.0;
    gl_PointSize = size * u_pixelRatio / max(0.1, -mv.z);
}
