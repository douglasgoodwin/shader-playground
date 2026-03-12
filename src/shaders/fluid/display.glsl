// Display: combine fluid state with transported texture
precision highp float;

uniform sampler2D u_state;
uniform sampler2D u_transport;
uniform sampler2D u_image;
uniform vec2 u_resolution;
uniform int u_hasImage;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec4 data = texture2D(u_state, uv);
    float rho = data.z;

    // Transported UV coordinates
    vec2 tUV = texture2D(u_transport, uv).xy;

    if (u_hasImage == 1) {
        // Show warped image
        vec3 col = texture2D(u_image, tUV).rgb;
        col *= rho; // density modulates brightness
        gl_FragColor = vec4(col, 1.0);
    } else {
        // Velocity visualization: map velocity to color
        vec3 velCol = vec3(data.xy * 4.0 + 0.5, 0.0);
        // Use transported UVs for procedural color
        vec3 procCol = vec3(
            0.5 + 0.5 * sin(tUV.x * 6.28 + 0.0),
            0.5 + 0.5 * sin(tUV.y * 6.28 + 2.09),
            0.5 + 0.5 * sin((tUV.x + tUV.y) * 6.28 + 4.19)
        );
        procCol = pow(procCol + 0.15, vec3(1.5));
        gl_FragColor = vec4(procCol * rho, 1.0);
    }
}
