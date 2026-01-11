precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

#define PI 3.14159265358979323846

vec2 rotate2D(vec2 _st, float _angle) {
    _st -= 0.5;
    _st = mat2(cos(_angle), -sin(_angle),
               sin(_angle), cos(_angle)) * _st;
    _st += 0.5;
    return _st;
}

vec2 tile(vec2 _st, float _zoom) {
    _st *= _zoom;
    return fract(_st);
}

vec2 rotateTilePattern(vec2 _st) {
    // Scale the coordinate system by 2x2
    _st *= 2.0;

    // Give each cell an index number according to its position
    float index = 0.0;
    index += step(1., mod(_st.x, 2.0));
    index += step(1., mod(_st.y, 2.0)) * 2.0;

    //      |
    //  2   |   3
    //      |
    //--------------
    //      |
    //  0   |   1
    //      |

    // Make each cell between 0.0 - 1.0
    _st = fract(_st);

    // Rotate each cell according to the index
    if (index == 1.0) {
        _st = rotate2D(_st, PI * 0.5);
    } else if (index == 2.0) {
        _st = rotate2D(_st, PI * -0.5);
    } else if (index == 3.0) {
        _st = rotate2D(_st, PI);
    }

    return _st;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec2 mouse = u_mouse / u_resolution;
    float t = u_time * u_speed;

    // Mouse influence on rotation
    float mouseDist = distance(uv, mouse);
    float mouseInfluence = 0.5 / (mouseDist + 0.5);

    // Tile the pattern
    vec2 st = tile(uv, 6.0 * u_scale);
    st = rotateTilePattern(st);

    // Animated rotation
    st = rotate2D(st, PI * t * 0.25 + mouseInfluence * 0.5);

    // Triangle pattern
    float f = step(st.x, st.y);

    // Animated colors with intensity control
    vec3 color = vec3(
        f * 0.5 * u_intensity,
        f * cos(t) * u_intensity,
        f * sin(t) * u_intensity
    );

    // Add some color variation based on position
    color += (1.0 - f) * vec3(0.05, 0.05, 0.1) * u_intensity;

    // Mouse glow
    color += mouseInfluence * 0.2 * vec3(0.5, 0.3, 1.0) * u_intensity;

    // Ripple effect
    for (int i = 0; i < 10; i++) {
        vec2 ripplePos = u_ripples[i].xy / u_resolution;
        float rippleTime = u_ripples[i].z;

        if (rippleTime > 0.0) {
            float age = u_time - rippleTime;
            float rippleDist = distance(uv, ripplePos);
            float radius = age * 0.5 * u_speed;
            float ring = abs(rippleDist - radius);
            float ripple = smoothstep(0.05, 0.0, ring) * exp(-age * 2.0 / u_intensity);
            color += ripple * u_rippleColors[i] * u_intensity;
        }
    }

    // Gamma correction
    float gamma = 2.2;
    color = pow(color, vec3(1.0 / gamma));

    gl_FragColor = vec4(color, 1.0);
}
