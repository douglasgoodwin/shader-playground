precision mediump float;

uniform sampler2D u_texture;
uniform float u_time;
uniform float u_twistSpeed;
uniform float u_twistAmount;
uniform vec2 u_resolution;
uniform int u_hasTexture;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    // Flip Y so top of screen = top of video
    uv.y = 1.0 - uv.y;

    if (u_hasTexture == 0) {
        // Show a placeholder grid pattern when no video/image loaded
        vec2 grid = fract(uv * 20.0);
        float lines = step(0.95, grid.x) + step(0.95, grid.y);
        vec3 color = mix(vec3(0.1, 0.1, 0.15), vec3(0.3, 0.3, 0.4), lines);
        gl_FragColor = vec4(color, 1.0);
        return;
    }

    float y = uv.y;

    // Map row to a local phase offset: bottom = 0, top = twistAmount cycles
    float rowPhase = u_twistAmount * y * 6.2831853;

    // Time angle for this row
    float localAngle = u_twistSpeed * u_time + rowPhase;

    // Convert angle to a horizontal offset in UV space
    float xOffset = localAngle / 6.2831853;
    xOffset = fract(xOffset);

    // Shift X coordinate
    float shiftedX = uv.x - xOffset;

    // Wrap horizontally
    shiftedX = fract(shiftedX);

    vec2 twistedUV = vec2(shiftedX, y);

    gl_FragColor = texture2D(u_texture, twistedUV);
}
