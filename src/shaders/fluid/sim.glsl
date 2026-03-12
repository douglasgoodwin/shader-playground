// Navier-Stokes fluid simulation
// Based on transport + interaction approach
// Stores: velocity.xy, density.z, 0.0
precision highp float;

uniform sampler2D u_state;
uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_mouseDown;
uniform int u_frame;
uniform float u_viscosity;
uniform float u_speed;

#define DT 0.5
#define C 3.5

#define IN0(x, y) texture2D(u_state, (gl_FragCoord.xy + vec2(x, y)) / u_resolution)
#define IN(x, y) texture2D(u_state, (gl_FragCoord.xy - v * DT + vec2(x, y)) / u_resolution)

// Obstacle shape for collisions
float shape(vec2 pos) {
    vec2 center = u_resolution * 0.5;
    vec2 pos0 = center + vec2(-90.0, 0.0);
    float r0 = 30.0 + 10.0 * sin(float(u_frame) * 0.02);
    vec2 pos1 = center + vec2(90.0, 0.0);
    float r1 = 50.0;
    float s0 = length(pos - pos0) - r0;
    float s1 = length(pos - pos1) - r1;
    return clamp(-min(s0, s1), 0.0, 1.0);
}

void main() {
    if (u_frame == 0) {
        // Initialize: small random velocity from position, uniform density
        vec2 uv = gl_FragCoord.xy / u_resolution;
        vec2 vel = (uv - 0.5) * 2.0;
        gl_FragColor = vec4(vel, 1.0, 0.0);
        return;
    }

    float eta = u_viscosity;
    float zeta = eta * 0.4;

    vec2 accel = vec2(0.0);
    if (u_mouseDown > 0.5) {
        vec2 dx = u_mouse - gl_FragCoord.xy;
        float d = length(dx);
        // Swirl + push force
        accel = u_speed * normalize(vec2(dx.y, -dx.x) + dx) * exp(-d * d / 1000.0);
    }

    // RK-inspired semi-Lagrangian advection
    vec4 b = IN0(0, 0);
    vec2 k1 = b.xy + accel * DT * 0.5;
    vec2 v = k1 / 2.0;

    b = IN(0, 0);
    v = b.xy + accel * DT;

    b = IN(0, 0);
    float sp = 1.5;
    vec4 dbdx = (IN(sp, 0.0) - IN(-sp, 0.0)) / (2.0 * sp);
    vec4 dbdy = (IN(0.0, sp) - IN(0.0, -sp)) / (2.0 * sp);

    vec4 laplace_b = (IN(sp, 0.0) + IN(-sp, 0.0) + IN(0.0, sp) + IN(0.0, -sp) - 4.0 * b) / (2.0 * sp * sp);

    // grad(div v) — mixed partial derivatives
    float sp2 = 4.0 * sp * sp;
    vec2 grad_div_v = vec2(
        (-IN(-sp, sp).y - IN(0.0, sp).x + IN(sp, sp).y
         + IN(-sp, 0.0).x + IN(sp, 0.0).x
         + IN(-sp, -sp).y - IN(0.0, -sp).x - IN(sp, -sp).y) / sp2 + 0.5 * laplace_b.x,
        (-IN(-sp, sp).x + IN(0.0, sp).y + IN(sp, sp).x
         - IN(-sp, 0.0).y - IN(sp, 0.0).y
         + IN(-sp, -sp).x + IN(0.0, -sp).y - IN(sp, -sp).x) / sp2 + 0.5 * laplace_b.y
    );

    // Continuity: Drho/Dt = -rho * div(v)
    float div_v = dbdx.x + dbdy.y;
    float drho_dt_div_rho = -div_v;

    // Equation of state: pressure gradient / rho
    vec2 grad_p_div_rho = C * vec2(dbdx.z, dbdy.z) / b.z;

    // Navier-Stokes: Dv/Dt = accel - grad(p)/rho + viscous terms
    vec2 Dv_Dt = accel - grad_p_div_rho + (eta * laplace_b.xy + (zeta + eta / 3.0) * grad_div_v) / b.z;

    // Correction for large accelerations
    vec2 corr = (b.xy + Dv_Dt * DT - v) * 1.0;
    float vlen = length(v);
    if (length(corr) > vlen * 0.05) {
        corr = normalize(corr) * vlen * 0.05;
    }

    b = IN(corr.x, corr.y);

    v = b.xy + Dv_Dt * DT;
    // Stability limit
    float max_v = DT * 100.0 * min(b.z, 5.0);
    if (length(v) > max_v) {
        v = normalize(v) * max_v;
    }

    // Prevent fluid entering obstacles
    if (shape(gl_FragCoord.xy + 2.0 * v * DT) > 0.5) {
        v *= 0.5;
        if (shape(gl_FragCoord.xy + 2.0 * v * DT) > 0.5) {
            v *= 0.5;
        }
    }

    // Density update with diffusion damping
    float rho = (b.z + laplace_b.z * 2.0 * sp * sp / 8.0) * exp(min(drho_dt_div_rho * DT, 1.0));
    rho = mix(clamp(rho, 0.0, 100.0), 1.0, 0.01);
    if (shape(gl_FragCoord.xy) > 0.5) {
        rho = mix(b.z + laplace_b.z * 2.0 * sp * sp / 8.0, 1.0, 0.01);
    }

    // No-slip boundary
    v *= 1.0 - shape(gl_FragCoord.xy);

    gl_FragColor = vec4(v, rho, 0.0);
}
