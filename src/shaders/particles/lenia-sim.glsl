// Particle Lenia simulation shader
// N-body forces with Gaussian kernels: short-range repulsion + growth/attraction
precision highp float;

varying vec2 v_uv;

uniform sampler2D u_positionTex;
uniform float u_dt;
uniform float u_mu_k;
uniform float u_sigma_k;
uniform float u_w_k;
uniform float u_mu_g;
uniform float u_sigma_g;
uniform float u_c_rep;
uniform float u_simResolution;
uniform float u_particleCount;

// Gaussian peak function: returns (value, derivative)
vec2 peak_f(float x, float mu, float sigma) {
    float t = (x - mu) / sigma;
    float g = exp(-0.5 * t * t);
    return vec2(g, -t / sigma * g);
}

// Decode position from texture (0-1 range to world space ~[-7, 7])
vec2 decodePos(vec2 encoded) {
    return (encoded - 0.5) * 14.0;
}

// Encode position to texture (world space to 0-1 range)
vec2 encodePos(vec2 pos) {
    return pos / 14.0 + 0.5;
}

void main() {
    // Current particle index
    float simRes = u_simResolution;
    float idx = floor(v_uv.x * simRes) + floor(v_uv.y * simRes) * simRes;

    // Skip inactive particles
    if (idx >= u_particleCount) {
        gl_FragColor = vec4(0.5, 0.5, 0.5, 0.5);
        return;
    }

    vec4 self = texture2D(u_positionTex, v_uv);
    vec2 pos = decodePos(self.xy);

    // Accumulate forces
    vec2 R_grad = vec2(0.0); // Repulsion gradient
    vec2 U_grad = vec2(0.0); // Growth potential gradient
    float U = peak_f(0.0, u_mu_k, u_sigma_k).x * u_w_k; // Self-contribution
    float E = 1.0; // Energy

    for (float j = 0.0; j < 256.0; j += 1.0) {
        if (j >= u_particleCount) break;
        if (j == idx) continue;

        // Get other particle's texcoord
        float jx = mod(j, simRes);
        float jy = floor(j / simRes);
        vec2 jUV = (vec2(jx, jy) + 0.5) / simRes;

        vec4 other = texture2D(u_positionTex, jUV);
        vec2 pos_j = decodePos(other.xy);

        vec2 dp = pos - pos_j;
        float r = length(dp);

        if (r < 0.001) continue; // Skip overlapping

        vec2 dir = dp / r;

        // Short-range repulsion (r < 1)
        if (r < 1.0) {
            R_grad -= dir * (1.0 - r);
            E += 0.5 * (1.0 - r) * (1.0 - r);
        }

        // Gaussian kernel interaction
        vec2 K = peak_f(r, u_mu_k * u_sigma_k, u_sigma_k);
        float Kval = K.x * u_w_k;
        float Kderiv = K.y * u_w_k;

        U += Kval;
        U_grad += Kderiv * dir;
    }

    // Growth function
    vec2 G = peak_f(U, u_mu_g, u_sigma_g);

    // Update position
    pos -= u_dt * (R_grad * u_c_rep - G.y * U_grad);

    // Clamp to world bounds
    pos = clamp(pos, -6.5, 6.5);

    // Encode back
    float energy = clamp(E * u_c_rep - G.x, 0.0, 1.0);
    gl_FragColor = vec4(encodePos(pos), 0.5, energy * 0.5 + 0.25);
}
