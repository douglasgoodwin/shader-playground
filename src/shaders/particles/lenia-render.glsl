// Lenia render fragment shader - gaussian spot rendering
precision highp float;

varying float v_energy;

void main() {
    vec2 xy = gl_PointCoord * 2.0 - 1.0;
    float r2 = dot(xy, xy);

    // Gaussian falloff
    float alpha = exp(-r2 * 4.0);
    if (alpha < 0.01) discard;

    // Warm white color modulated by energy
    float e = clamp(v_energy * 2.0, 0.0, 1.0);
    vec3 color = mix(vec3(0.2, 0.5, 1.0), vec3(1.0, 0.9, 0.7), e);

    gl_FragColor = vec4(color * alpha, alpha);
}
