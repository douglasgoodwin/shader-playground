precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // sin() takes a number and returns a wave between -1 and 1
    // We convert it to 0-1 range with: (sin(x) + 1.0) / 2.0

    // TODO: Change the 10.0 to other numbers (try 1, 5, 20, 50)
    //       What does this number control?
    float wave = sin(uv.x * 10.0);

    // Convert from -1,1 to 0,1
    wave = (wave + 1.0) / 2.0;

    // TODO: Add u_time to make it animate:
    //       sin(uv.x * 10.0 + u_time)

    gl_FragColor = vec4(vec3(wave), 1.0);
}
