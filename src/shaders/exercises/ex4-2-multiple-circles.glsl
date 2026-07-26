precision mediump float;

uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float radius = 0.04;
    float result = 0.0;

    for (float x = 0.05; x < 1.0; x += 0.1) {
        for (float y = 0.05; y < 1.0; y += 0.1) {
            vec2 center = vec2(x, y);

            float circle = 1.0 - step(radius, length(uv - center));

            result = max(result, circle);
        }
    }

    gl_FragColor = vec4(vec3(result), 1.0);
}
