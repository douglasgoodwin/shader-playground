precision mediump float;

varying vec3  v_color;
varying float v_depth;

uniform float u_colorBoost;
uniform float u_depthShade;

void main() {
    // Soft round splat — discard outside unit disk, fade at edge.
    vec2 c = gl_PointCoord - 0.5;
    float r2 = dot(c, c);
    if (r2 > 0.25) discard;
    float alpha = smoothstep(0.25, 0.14, r2);

    // Optional depth shading: dim far points slightly.
    float shade = mix(1.0, v_depth + 0.3, u_depthShade);
    vec3 rgb = v_color * shade * (1.0 + u_colorBoost);

    gl_FragColor = vec4(rgb, alpha);
}
