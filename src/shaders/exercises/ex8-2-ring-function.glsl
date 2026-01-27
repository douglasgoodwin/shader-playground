precision mediump float;
uniform vec2 u_resolution;

// A ring is the area between two circles (outer minus inner)
float drawRing(vec2 uv, vec2 center, float innerRadius, float outerRadius) {
    // TODO: Draw a circle with outerRadius
    // TODO: Draw a circle with innerRadius
    // TODO: Subtract inner from outer to get a ring
    return 0.0;  // Replace this
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float ring = drawRing(uv, vec2(0.5, 0.5), 0.2, 0.3);

    gl_FragColor = vec4(vec3(ring), 1.0);
}
