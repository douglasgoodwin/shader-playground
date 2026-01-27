precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    vec3 color;

    // TODO: Complete the if statement
    //       If uv.x < 0.5, make color red
    //       Otherwise, make color blue
    if (uv.x < 0.5) {
        color = vec3(0.0);  // TODO: Set to red
    } else {
        color = vec3(0.0);  // TODO: Set to blue
    }

    gl_FragColor = vec4(color, 1.0);
}
