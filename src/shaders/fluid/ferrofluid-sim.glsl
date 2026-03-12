precision highp float;

uniform sampler2D u_state;
uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_mouseDown;
uniform float u_feed;
uniform float u_kill;

void main() {
    vec2 px = 1.0 / u_resolution;
    vec2 st = gl_FragCoord.xy / u_resolution;

    // Current state: r = chemical A, g = chemical B
    vec4 cur = texture2D(u_state, st);
    float A = cur.r;
    float B = cur.g;

    // 9-point Laplacian (weighted for isotropy)
    float lapA = 0.0;
    float lapB = 0.0;

    // Cardinal neighbors (weight 1.0)
    vec4 n  = texture2D(u_state, st + vec2( 0.0,  px.y));
    vec4 s  = texture2D(u_state, st + vec2( 0.0, -px.y));
    vec4 e  = texture2D(u_state, st + vec2( px.x,  0.0));
    vec4 w  = texture2D(u_state, st + vec2(-px.x,  0.0));
    lapA += n.r + s.r + e.r + w.r;
    lapB += n.g + s.g + e.g + w.g;

    // Diagonal neighbors (weight 0.707)
    vec4 ne = texture2D(u_state, st + vec2( px.x,  px.y));
    vec4 nw = texture2D(u_state, st + vec2(-px.x,  px.y));
    vec4 se = texture2D(u_state, st + vec2( px.x, -px.y));
    vec4 sw = texture2D(u_state, st + vec2(-px.x, -px.y));
    float dw = 0.707106781;
    lapA += (ne.r + nw.r + se.r + sw.r) * dw;
    lapB += (ne.g + nw.g + se.g + sw.g) * dw;

    // Center weight = -(4 + 4*0.707) = -6.828
    lapA -= A * 6.82842712;
    lapB -= B * 6.82842712;

    // Normalize by total weight
    lapA /= 6.82842712;
    lapB /= 6.82842712;

    // Gray-Scott reaction
    float dA = 1.0;   // diffusion rate A
    float dB = 0.5;   // diffusion rate B
    float ABB = A * B * B;

    A += dA * lapA - ABB + u_feed * (1.0 - A);
    B += dB * lapB + ABB - (u_feed + u_kill) * B;

    // Mouse injects chemical B
    float dist = length(gl_FragCoord.xy - u_mouse);
    float inject = u_mouseDown * smoothstep(20.0, 5.0, dist);
    B += inject * 0.3;

    gl_FragColor = vec4(clamp(A, 0.0, 1.0), clamp(B, 0.0, 1.0), 0.0, 1.0);
}
