// Torus vertex shader - computes 3D position from UV + reaction-diffusion state
attribute vec2 a_uv;

uniform mat4 u_mvp;
uniform sampler2D u_state;
uniform float u_twist;
uniform float u_time;

varying vec3 v_color;

#define TAU 6.283185307

void main() {
    // Read chemical B concentration from RD simulation
    float chemB = texture2D(u_state, a_uv).y;

    // Color: mix dark bg with warm gold based on concentration
    vec3 bg = vec3(0.05, 0.1, 0.2);
    v_color = mix(bg, vec3(1.0, 0.75, 0.1), sqrt(chemB) * 1.8);

    // Tube radius varies with concentration
    float r = mix(0.1, 0.6, chemB);

    // Tube angle with twist and slow rotation
    float a = (a_uv.x + a_uv.y * u_twist + u_time * 0.02) * TAU;

    // Cross-section position in xz plane (0.6 = major radius)
    float cx = cos(a) * r + 0.6;
    float cz = -sin(a) * r;

    // Rotate around Y axis to form torus ring
    float b = a_uv.y * TAU;
    vec3 pos;
    pos.x = cx * cos(b);
    pos.y = -cx * sin(b);
    pos.z = cz;

    gl_Position = u_mvp * vec4(pos, 1.0);
}
