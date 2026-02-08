// Velocity update pass for boids simulation
precision highp float;

uniform sampler2D u_positionTex;
uniform sampler2D u_velocityTex;
uniform vec2 u_resolution;
uniform float u_simResolution;
uniform float u_deltaTime;
uniform vec2 u_mouse;
uniform float u_mouseInfluence;

// Boids parameters
uniform float u_separation;
uniform float u_alignment;
uniform float u_cohesion;
uniform float u_maxSpeed;
uniform float u_perceptionRadius;
uniform float u_time;

varying vec2 v_uv;

// Hash function for per-bird pseudo-randomness
float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 decodePosition(vec4 texel) {
    return (texel.rgb - 0.5) * 4.0;
}

vec3 decodeVelocity(vec4 texel) {
    return (texel.rgb - 0.5) * 2.0;
}

vec3 encodeVelocity(vec3 vel) {
    return clamp(vel / 2.0 + 0.5, 0.0, 1.0);
}

void main() {
    float texelSize = 1.0 / u_simResolution;

    vec3 pos = decodePosition(texture2D(u_positionTex, v_uv));
    vec4 velTexel = texture2D(u_velocityTex, v_uv);
    vec3 vel = decodeVelocity(velTexel);

    // Leadership timer: stored in alpha channel (0-1 maps to 0-2 seconds)
    float leaderTimer = velTexel.a * 2.0;
    leaderTimer = max(leaderTimer - u_deltaTime, 0.0);

    // Random chance to become a leader when timer has expired
    float rand = hash(v_uv + fract(u_time * 0.1));
    if (leaderTimer <= 0.0 && rand < 0.02) {
        leaderTimer = 1.0 + hash(v_uv + fract(u_time * 0.37)) * 1.0; // 1-2 seconds
    }
    bool isLeader = leaderTimer > 0.0;

    vec3 separation = vec3(0.0);
    vec3 alignment = vec3(0.0);
    vec3 cohesion = vec3(0.0);
    float separationCount = 0.0;
    float neighborCount = 0.0;

    float samples = min(u_simResolution, 32.0);
    float step = u_simResolution / samples;

    for (float i = 0.0; i < 32.0; i++) {
        if (i >= samples) break;
        for (float j = 0.0; j < 32.0; j++) {
            if (j >= samples) break;

            vec2 sampleUV = vec2(i * step + 0.5, j * step + 0.5) * texelSize;
            if (distance(sampleUV, v_uv) < 0.001) continue;

            vec3 otherPos = decodePosition(texture2D(u_positionTex, sampleUV));
            vec3 otherVel = decodeVelocity(texture2D(u_velocityTex, sampleUV));

            vec3 diff = pos - otherPos;
            float dist = length(diff);

            if (dist < u_perceptionRadius && dist > 0.001) {
                // Separation: inverse-square falloff, wider zone
                if (dist < u_perceptionRadius * 0.6) {
                    separation += diff / (dist * dist + 0.001);
                    separationCount += 1.0;
                }

                alignment += otherVel;
                cohesion += otherPos;
                neighborCount += 1.0;
            }
        }
    }

    vec3 steer = vec3(0.0);

    if (separationCount > 0.0) {
        separation /= separationCount;
        steer += separation * u_separation;
    }

    // Leaders suppress flocking forces and steer independently
    float alignWeight = isLeader ? 0.3 : 1.0;
    float cohesionWeight = isLeader ? 0.1 : 1.0;

    if (neighborCount > 0.0) {
        alignment /= neighborCount;
        if (length(alignment) > 0.001) {
            steer += normalize(alignment) * u_alignment * alignWeight;
        }

        cohesion /= neighborCount;
        cohesion = cohesion - pos;
        if (length(cohesion) > 0.001) {
            steer += normalize(cohesion) * u_cohesion * cohesionWeight;
        }
    }

    // Leader escape direction: persistent random heading derived from bird identity
    if (isLeader) {
        float h1 = hash(v_uv * 7.13 + floor(u_time * 0.5));
        float h2 = hash(v_uv * 3.71 + floor(u_time * 0.5) + 0.5);
        vec3 escapeDir = normalize(vec3(
            h1 * 2.0 - 1.0,
            h2 * 2.0 - 1.0,
            (hash(v_uv * 11.3 + floor(u_time * 0.5)) - 0.5) * 0.5
        ));
        steer += escapeDir * 0.6;
    }

    // Mouse influence
    vec3 mousePos = vec3((u_mouse / u_resolution - 0.5) * 2.0, 0.0);
    vec3 toMouse = mousePos - pos;
    float mouseDist = length(toMouse);
    if (mouseDist > 0.05 && mouseDist < 1.5) {
        steer += normalize(toMouse) * u_mouseInfluence / (mouseDist + 0.1);
    }

    // Boundary avoidance
    float boundary = 1.8;
    float margin = 0.3;
    if (pos.x > boundary) steer.x -= (pos.x - boundary) / margin * 2.0;
    if (pos.x < -boundary) steer.x -= (pos.x + boundary) / margin * 2.0;
    if (pos.y > boundary) steer.y -= (pos.y - boundary) / margin * 2.0;
    if (pos.y < -boundary) steer.y -= (pos.y + boundary) / margin * 2.0;
    if (pos.z > boundary * 0.5) steer.z -= (pos.z - boundary * 0.5) / margin * 2.0;
    if (pos.z < -boundary * 0.5) steer.z -= (pos.z + boundary * 0.5) / margin * 2.0;

    // Wandering - varied per-bird for symmetry breaking
    float phase = v_uv.x * 123.4 + v_uv.y * 567.8;
    float t = u_deltaTime * 10.0 + phase;
    steer += vec3(
        sin(t * 3.7 + phase * 2.1),
        cos(t * 2.9 + phase * 1.7),
        sin(t * 1.3 + phase * 3.3)
    ) * 0.08;

    // Update velocity
    vel += steer * u_deltaTime * 5.0;

    // Speed limits (leaders get a speed boost)
    float speedLimit = isLeader ? u_maxSpeed * 1.2 : u_maxSpeed;
    float speed = length(vel);
    if (speed > speedLimit) {
        vel = normalize(vel) * speedLimit;
    }
    if (speed < u_maxSpeed * 0.25) {
        vel = normalize(vel + vec3(0.001)) * u_maxSpeed * 0.25;
    }

    gl_FragColor = vec4(encodeVelocity(vel), clamp(leaderTimer / 2.0, 0.0, 1.0));
}
