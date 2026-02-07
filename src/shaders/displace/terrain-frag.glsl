precision mediump float;

uniform sampler2D u_texture;
uniform int u_hasTexture;

varying vec2 v_uv;
varying vec3 v_normal;
varying float v_height;

void main() {
    // Light direction (upper-left, slightly behind camera)
    vec3 lightDir = normalize(vec3(0.3, 1.0, 0.5));
    float diffuse = max(dot(v_normal, lightDir), 0.0);
    float ambient = 0.25;
    float lighting = ambient + diffuse * 0.75;

    vec3 color;
    if (u_hasTexture == 1) {
        color = texture2D(u_texture, v_uv).rgb;
    } else {
        // Fallback: gradient based on height and UV
        float h = v_height * 0.5 + 0.5;
        color = mix(
            vec3(0.15, 0.25, 0.45),  // deep blue
            vec3(0.85, 0.75, 0.55),  // sandy
            smoothstep(-0.3, 0.5, h)
        );
        color = mix(color, vec3(0.95, 0.98, 1.0), smoothstep(0.5, 0.8, h)); // snow caps
    }

    color *= lighting;

    gl_FragColor = vec4(color, 1.0);
}
