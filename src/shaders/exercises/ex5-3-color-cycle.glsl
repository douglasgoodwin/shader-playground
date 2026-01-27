precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // TODO: Animate each color channel with different speeds
    //       Use sin() with different multipliers on u_time
    //       Remember to convert from -1,1 to 0,1
    float red = 0.5;    // TODO: (sin(u_time) + 1.0) / 2.0
    float green = 0.5;  // TODO: (sin(u_time * 1.3) + 1.0) / 2.0
    float blue = 0.5;   // TODO: (sin(u_time * 1.7) + 1.0) / 2.0

    gl_FragColor = vec4(red, green, blue, 1.0);
}
