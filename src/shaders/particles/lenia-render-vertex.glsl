// Lenia render vertex shader - positions particles as point sprites
attribute vec2 a_texCoord;

uniform sampler2D u_positionTex;
uniform vec2 u_resolution;
uniform float u_pointSize;
uniform float u_viewR;

varying float v_energy;

vec2 decodePos(vec2 encoded) {
    return (encoded - 0.5) * 14.0;
}

void main() {
    vec4 posTex = texture2D(u_positionTex, a_texCoord);
    vec2 pos = decodePos(posTex.xy);
    v_energy = posTex.w;

    // Project to screen with zoom
    vec2 projected = pos / u_viewR;

    // Aspect ratio correction
    float aspect = u_resolution.x / u_resolution.y;
    projected.x /= aspect;

    gl_Position = vec4(projected, 0.0, 1.0);
    gl_PointSize = u_pointSize;
}
