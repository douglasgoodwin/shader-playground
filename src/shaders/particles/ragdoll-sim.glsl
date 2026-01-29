// Ragdoll Verlet integration simulation
// Each ragdoll is 16 particles in a row of the texture
// Particle indices: 0=head, 1=neck, 2=chest, 3=hips,
//   4=shoulderL, 5=elbowL, 6=handL, 7=shoulderR, 8=elbowR, 9=handR,
//   10=hipL, 11=kneeL, 12=footL, 13=hipR, 14=kneeR, 15=footR

precision highp float;

uniform sampler2D u_positionTex;    // xy = current pos, zw = previous pos
uniform vec2 u_resolution;
uniform float u_simResolution;
uniform float u_deltaTime;
uniform vec2 u_mouse;
uniform float u_gravity;
uniform float u_damping;
uniform int u_pass;  // 0 = verlet integrate, 1+ = constraint passes

varying vec2 v_uv;

#define PARTICLES_PER_RAGDOLL 16.0

// Constraint definitions: pairs of particle indices and rest lengths
// Spine
#define C_HEAD_NECK vec3(0.0, 1.0, 0.08)
#define C_NECK_CHEST vec3(1.0, 2.0, 0.1)
#define C_CHEST_HIPS vec3(2.0, 3.0, 0.12)

// Left arm
#define C_CHEST_SHOULDERL vec3(2.0, 4.0, 0.08)
#define C_SHOULDERL_ELBOWL vec3(4.0, 5.0, 0.1)
#define C_ELBOWL_HANDL vec3(5.0, 6.0, 0.09)

// Right arm
#define C_CHEST_SHOULDERR vec3(2.0, 7.0, 0.08)
#define C_SHOULDERR_ELBOWR vec3(7.0, 8.0, 0.1)
#define C_ELBOWR_HANDR vec3(8.0, 9.0, 0.09)

// Left leg
#define C_HIPS_HIPL vec3(3.0, 10.0, 0.06)
#define C_HIPL_KNEEL vec3(10.0, 11.0, 0.12)
#define C_KNEEL_FOOTL vec3(11.0, 12.0, 0.11)

// Right leg
#define C_HIPS_HIPR vec3(3.0, 13.0, 0.06)
#define C_HIPR_KNEER vec3(13.0, 14.0, 0.12)
#define C_KNEER_FOOTR vec3(14.0, 15.0, 0.11)

// Decode position from texture (0-1) to world coords (-1 to 1)
vec2 decode(vec2 encoded) {
    return (encoded - 0.5) * 2.0;
}

// Encode position from world coords to texture (0-1) with clamping
vec2 encode(vec2 world) {
    return clamp(world * 0.5 + 0.5, 0.0, 1.0);
}

// Get position of particle within same ragdoll (returns world coords)
vec4 getParticle(float ragdollY, float particleIndex) {
    vec2 uv = vec2((particleIndex + 0.5) / u_simResolution, ragdollY);
    vec4 raw = texture2D(u_positionTex, uv);
    return vec4(decode(raw.xy), decode(raw.zw));
}

// Apply single distance constraint, return correction for this particle
vec2 solveConstraint(vec2 pos, vec2 otherPos, float restLength, float weight) {
    vec2 delta = otherPos - pos;
    float dist = length(delta);
    if (dist < 0.0001) return vec2(0.0);

    float diff = (dist - restLength) / dist;
    return delta * diff * weight * 0.5;
}

void main() {
    float texelSize = 1.0 / u_simResolution;

    // Determine which particle this is
    float particleIndex = floor(v_uv.x * u_simResolution);
    float ragdollIndex = floor(v_uv.y * u_simResolution);
    float ragdollY = v_uv.y;

    // Skip unused particles (we only use 16 per row)
    if (particleIndex >= PARTICLES_PER_RAGDOLL) {
        gl_FragColor = vec4(0.5, 0.5, 0.5, 0.5);
        return;
    }

    vec4 data = texture2D(u_positionTex, v_uv);
    vec2 pos = decode(data.xy);
    vec2 prevPos = decode(data.zw);

    if (u_pass == 0) {
        // Verlet integration pass
        vec2 velocity = (pos - prevPos) * u_damping;

        // Gravity
        vec2 acceleration = vec2(0.0, -u_gravity);

        // Mouse repulsion
        vec2 mousePos = (u_mouse / u_resolution) * 2.0 - 1.0;
        mousePos.x *= u_resolution.x / u_resolution.y;
        vec2 toMouse = pos - mousePos;
        float mouseDist = length(toMouse);
        if (mouseDist < 0.4 && mouseDist > 0.01) {
            acceleration += normalize(toMouse) * 2.0 / (mouseDist * mouseDist);
        }

        // Verlet step
        vec2 newPos = pos + velocity + acceleration * u_deltaTime * u_deltaTime;

        // Floor collision
        if (newPos.y < -0.95) {
            newPos.y = -0.95;
            // Friction
            newPos.x = mix(newPos.x, pos.x, 0.3);
        }

        // Wall collisions - clamp to valid range
        float aspect = min(u_resolution.x / u_resolution.y, 1.8);
        newPos.x = clamp(newPos.x, -aspect, aspect);
        newPos.y = clamp(newPos.y, -0.98, 0.98);

        // Safety: if position is way out of bounds, dampen heavily
        if (abs(newPos.x) > 3.0 || abs(newPos.y) > 3.0) {
            newPos = pos * 0.5;
        }

        gl_FragColor = vec4(encode(newPos), encode(pos));
    } else {
        // Constraint solving pass
        vec2 correction = vec2(0.0);
        int idx = int(particleIndex);

        // Each particle checks constraints it's part of
        // This is verbose but necessary for GLSL ES 1.0

        if (idx == 0) { // head
            vec2 other = getParticle(ragdollY, 1.0).xy;
            correction += solveConstraint(pos, other, C_HEAD_NECK.z, 1.0);
        }
        else if (idx == 1) { // neck
            correction += solveConstraint(pos, getParticle(ragdollY, 0.0).xy, C_HEAD_NECK.z, 1.0);
            correction += solveConstraint(pos, getParticle(ragdollY, 2.0).xy, C_NECK_CHEST.z, 1.0);
        }
        else if (idx == 2) { // chest
            correction += solveConstraint(pos, getParticle(ragdollY, 1.0).xy, C_NECK_CHEST.z, 1.0);
            correction += solveConstraint(pos, getParticle(ragdollY, 3.0).xy, C_CHEST_HIPS.z, 1.0);
            correction += solveConstraint(pos, getParticle(ragdollY, 4.0).xy, C_CHEST_SHOULDERL.z, 1.0);
            correction += solveConstraint(pos, getParticle(ragdollY, 7.0).xy, C_CHEST_SHOULDERR.z, 1.0);
        }
        else if (idx == 3) { // hips
            correction += solveConstraint(pos, getParticle(ragdollY, 2.0).xy, C_CHEST_HIPS.z, 1.0);
            correction += solveConstraint(pos, getParticle(ragdollY, 10.0).xy, C_HIPS_HIPL.z, 1.0);
            correction += solveConstraint(pos, getParticle(ragdollY, 13.0).xy, C_HIPS_HIPR.z, 1.0);
        }
        else if (idx == 4) { // shoulderL
            correction += solveConstraint(pos, getParticle(ragdollY, 2.0).xy, C_CHEST_SHOULDERL.z, 1.0);
            correction += solveConstraint(pos, getParticle(ragdollY, 5.0).xy, C_SHOULDERL_ELBOWL.z, 1.0);
        }
        else if (idx == 5) { // elbowL
            correction += solveConstraint(pos, getParticle(ragdollY, 4.0).xy, C_SHOULDERL_ELBOWL.z, 1.0);
            correction += solveConstraint(pos, getParticle(ragdollY, 6.0).xy, C_ELBOWL_HANDL.z, 1.0);
        }
        else if (idx == 6) { // handL
            correction += solveConstraint(pos, getParticle(ragdollY, 5.0).xy, C_ELBOWL_HANDL.z, 1.0);
        }
        else if (idx == 7) { // shoulderR
            correction += solveConstraint(pos, getParticle(ragdollY, 2.0).xy, C_CHEST_SHOULDERR.z, 1.0);
            correction += solveConstraint(pos, getParticle(ragdollY, 8.0).xy, C_SHOULDERR_ELBOWR.z, 1.0);
        }
        else if (idx == 8) { // elbowR
            correction += solveConstraint(pos, getParticle(ragdollY, 7.0).xy, C_SHOULDERR_ELBOWR.z, 1.0);
            correction += solveConstraint(pos, getParticle(ragdollY, 9.0).xy, C_ELBOWR_HANDR.z, 1.0);
        }
        else if (idx == 9) { // handR
            correction += solveConstraint(pos, getParticle(ragdollY, 8.0).xy, C_ELBOWR_HANDR.z, 1.0);
        }
        else if (idx == 10) { // hipL
            correction += solveConstraint(pos, getParticle(ragdollY, 3.0).xy, C_HIPS_HIPL.z, 1.0);
            correction += solveConstraint(pos, getParticle(ragdollY, 11.0).xy, C_HIPL_KNEEL.z, 1.0);
        }
        else if (idx == 11) { // kneeL
            correction += solveConstraint(pos, getParticle(ragdollY, 10.0).xy, C_HIPL_KNEEL.z, 1.0);
            correction += solveConstraint(pos, getParticle(ragdollY, 12.0).xy, C_KNEEL_FOOTL.z, 1.0);
        }
        else if (idx == 12) { // footL
            correction += solveConstraint(pos, getParticle(ragdollY, 11.0).xy, C_KNEEL_FOOTL.z, 1.0);
        }
        else if (idx == 13) { // hipR
            correction += solveConstraint(pos, getParticle(ragdollY, 3.0).xy, C_HIPS_HIPR.z, 1.0);
            correction += solveConstraint(pos, getParticle(ragdollY, 14.0).xy, C_HIPR_KNEER.z, 1.0);
        }
        else if (idx == 14) { // kneeR
            correction += solveConstraint(pos, getParticle(ragdollY, 13.0).xy, C_HIPR_KNEER.z, 1.0);
            correction += solveConstraint(pos, getParticle(ragdollY, 15.0).xy, C_KNEER_FOOTR.z, 1.0);
        }
        else if (idx == 15) { // footR
            correction += solveConstraint(pos, getParticle(ragdollY, 14.0).xy, C_KNEER_FOOTR.z, 1.0);
        }

        pos += correction;

        // Floor collision after constraints
        if (pos.y < -0.95) pos.y = -0.95;

        gl_FragColor = vec4(encode(pos), encode(prevPos));
    }
}
