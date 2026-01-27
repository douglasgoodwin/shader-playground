precision mediump float;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // A circle is all points within a certain distance from center
    vec2 center = vec2(0.5, 0.5);
    float radius = 0.3;

    // length() measures distance between two points
    float dist = length(uv - center);

    // TODO: We have the distance. Now we need to ask:
    //       "Is this pixel inside the circle (dist < radius)?"
    //       Use step() to create a sharp edge:
    //       float circle = 1.0 - step(radius, dist);
    float circle = 0.0;  // Replace this line

    gl_FragColor = vec4(vec3(circle), 1.0);
}
