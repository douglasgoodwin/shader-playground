precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    vec3 color;

    // TODO: Use nested if statements to color four quadrants:
    //       Top-left: red
    //       Top-right: green
    //       Bottom-left: blue
    //       Bottom-right: yellow (1,1,0)
    //
    // Hint: First check if uv.x < 0.5 (left vs right)
    //       Then inside each branch, check uv.y < 0.5 (bottom vs top)

    color = vec3(uv.x, uv.y, 0.0);  // Replace with your quadrant logic

    gl_FragColor = vec4(color, 1.0);
}
