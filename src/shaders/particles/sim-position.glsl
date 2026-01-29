// Position update pass - simply integrates velocity
precision highp float;

uniform sampler2D u_positionTex;
uniform sampler2D u_velocityTex;
uniform float u_deltaTime;

varying vec2 v_uv;

vec3 decodePosition(vec4 texel) {
    return (texel.rgb - 0.5) * 4.0;
}

vec3 decodeVelocity(vec4 texel) {
    return (texel.rgb - 0.5) * 2.0;
}

vec3 encodePosition(vec3 pos) {
    return clamp(pos / 4.0 + 0.5, 0.0, 1.0);
}

void main() {
    vec3 pos = decodePosition(texture2D(u_positionTex, v_uv));
    vec3 vel = decodeVelocity(texture2D(u_velocityTex, v_uv));

    pos += vel * u_deltaTime;

    gl_FragColor = vec4(encodePosition(pos), 1.0);
}
