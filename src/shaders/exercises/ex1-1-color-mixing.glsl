precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // This creates a color. RGB values go from 0.0 to 1.0
    // TODO: Change these numbers to make the screen:
    //   a) Pure blue
    //   b) Yellow (hint: red + green = yellow)
    //   c) Your favorite color
    vec3 color = vec3(1.0, 0.5, 0.0);  // Currently red

    gl_FragColor = vec4(color, 1.0);
}
