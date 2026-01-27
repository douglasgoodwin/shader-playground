precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // TODO: Create a variable called 'red' and set it to uv.x
    // float red = ???;

    // TODO: Create a variable called 'green' and set it to uv.y
    // float green = ???;

    // TODO: Create a variable called 'blue' and set it to 0.5
    // float blue = ???;

    // TODO: Uncomment this line after creating the variables above
    // gl_FragColor = vec4(red, green, blue, 1.0);

    gl_FragColor = vec4(0.0);  // Delete this line when done
}
