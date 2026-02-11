// Gray-Scott reaction-diffusion simulation
precision highp float;

uniform sampler2D u_state;
uniform float u_simRes;
uniform float u_feed;
uniform float u_kill;

varying vec2 v_uv;

#define S(x,y) texture2D(u_state, v_uv + ds * vec2(x, y)).xy

void main() {
    vec2 v = texture2D(u_state, v_uv).xy;

    // Diagonal blur at half-texel offsets (relies on LINEAR filtering)
    vec2 ds = vec2(1.0 / u_simRes) * 0.5;
    vec2 blur = (S(-1.0, -1.0) + S(1.0, -1.0) + S(-1.0, 1.0) + S(1.0, 1.0)) / 4.0;

    // Chemical A diffuses fully, B diffuses slower
    v = mix(v, blur, vec2(1.0, 0.5));

    // Gray-Scott reaction
    float r = v.x * v.y * v.y;
    v += vec2(-r + u_feed * (1.0 - v.x), r - (u_feed + u_kill) * v.y);

    gl_FragColor = vec4(v, 0.0, 1.0);
}
