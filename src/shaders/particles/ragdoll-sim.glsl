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

// Number of bone constraints
#define NUM_CONSTRAINTS 15

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

        // Constraint table: (particleA, particleB, restLength)
        vec3 constraints[NUM_CONSTRAINTS];
        // Spine
        constraints[0]  = vec3(0, 1, 0.04);    // head-neck
        constraints[1]  = vec3(1, 2, 0.05);    // neck-chest
        constraints[2]  = vec3(2, 3, 0.06);    // chest-hips
        // Left arm
        constraints[3]  = vec3(2, 4, 0.04);    // chest-shoulderL
        constraints[4]  = vec3(4, 5, 0.05);    // shoulderL-elbowL
        constraints[5]  = vec3(5, 6, 0.045);   // elbowL-handL
        // Right arm
        constraints[6]  = vec3(2, 7, 0.04);    // chest-shoulderR
        constraints[7]  = vec3(7, 8, 0.05);    // shoulderR-elbowR
        constraints[8]  = vec3(8, 9, 0.045);   // elbowR-handR
        // Left leg
        constraints[9]  = vec3(3, 10, 0.03);   // hips-hipL
        constraints[10] = vec3(10, 11, 0.06);  // hipL-kneeL
        constraints[11] = vec3(11, 12, 0.055); // kneeL-footL
        // Right leg
        constraints[12] = vec3(3, 13, 0.03);   // hips-hipR
        constraints[13] = vec3(13, 14, 0.06);  // hipR-kneeR
        constraints[14] = vec3(14, 15, 0.055); // kneeR-footR

        for (int i = 0; i < NUM_CONSTRAINTS; i++) {
            float a = constraints[i].x;
            float b = constraints[i].y;
            float len = constraints[i].z;
            if (idx == int(a))
                correction += solveConstraint(pos, getParticle(ragdollY, b).xy, len, 1.0);
            else if (idx == int(b))
                correction += solveConstraint(pos, getParticle(ragdollY, a).xy, len, 1.0);
        }

        pos += correction;

        // Floor collision after constraints
        if (pos.y < -0.95) pos.y = -0.95;

        gl_FragColor = vec4(encode(pos), encode(prevPos));
    }
}
