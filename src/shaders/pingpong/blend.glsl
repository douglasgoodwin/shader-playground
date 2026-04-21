// Generic feedback blend: mix fresh frame with previous (decayed)
precision highp float;

varying vec2 v_uv;

uniform sampler2D u_fresh;
uniform sampler2D u_prev;
uniform float u_decay;

void main() {
    vec3 fresh = texture2D(u_fresh, v_uv).rgb;
    vec3 prev  = texture2D(u_prev,  v_uv).rgb;
    // max preserves fresh at full brightness; the trail fades exponentially.
    // mix() would drag fresh toward prev each frame, dimming bright features.
    gl_FragColor = vec4(max(fresh, prev * u_decay), 1.0);
}
