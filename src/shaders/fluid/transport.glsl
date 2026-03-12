// Transport UV coordinates through the velocity field
precision highp float;

uniform sampler2D u_state;     // fluid sim (velocity in xy)
uniform sampler2D u_transport; // previous UV coordinates
uniform vec2 u_resolution;
uniform int u_frame;

#define DT 0.5

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    if (u_frame == 0) {
        gl_FragColor = vec4(uv, 0.0, 0.0);
        return;
    }

    vec2 v = texture2D(u_state, uv).xy * DT;
    vec2 srcUV = (gl_FragCoord.xy - v) / u_resolution;
    gl_FragColor = texture2D(u_transport, srcUV);
}
