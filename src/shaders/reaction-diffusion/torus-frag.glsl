// Torus fragment shader - outputs color from vertex shader
precision highp float;

varying vec3 v_color;

void main() {
    gl_FragColor = vec4(v_color, 1.0);
}
