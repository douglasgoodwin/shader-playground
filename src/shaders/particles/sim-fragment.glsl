// Boids simulation - updates particle positions and velocities
// Uses ping-pong textures: reads from one, writes to framebuffer
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

varying vec2 v_uv;

// Decode position from texture (stored in RGB, normalized to 0-1)
vec3 decodePosition(vec4 texel) {
    return (texel.rgb - 0.5) * 4.0; // Map 0-1 to -2 to 2
}

// Decode velocity from texture
vec3 decodeVelocity(vec4 texel) {
    return (texel.rgb - 0.5) * 2.0; // Map 0-1 to -1 to 1
}

// Encode position back to texture
vec3 encodePosition(vec3 pos) {
    return clamp(pos / 4.0 + 0.5, 0.0, 1.0);
}

// Encode velocity back to texture
vec3 encodeVelocity(vec3 vel) {
    return clamp(vel / 2.0 + 0.5, 0.0, 1.0);
}

void main() {
    float texelSize = 1.0 / u_simResolution;

    // Get current particle state
    vec4 posTex = texture2D(u_positionTex, v_uv);
    vec4 velTex = texture2D(u_velocityTex, v_uv);

    vec3 pos = decodePosition(posTex);
    vec3 vel = decodeVelocity(velTex);

    // Boids forces
    vec3 separation = vec3(0.0);
    vec3 alignment = vec3(0.0);
    vec3 cohesion = vec3(0.0);
    float separationCount = 0.0;
    float neighborCount = 0.0;

    // Sample neighbors (limited for performance)
    float samples = min(u_simResolution, 32.0);
    float step = u_simResolution / samples;

    for (float i = 0.0; i < 32.0; i++) {
        if (i >= samples) break;
        for (float j = 0.0; j < 32.0; j++) {
            if (j >= samples) break;

            vec2 sampleUV = vec2(i * step + 0.5, j * step + 0.5) * texelSize;
            if (distance(sampleUV, v_uv) < 0.001) continue; // Skip self

            vec3 otherPos = decodePosition(texture2D(u_positionTex, sampleUV));
            vec3 otherVel = decodeVelocity(texture2D(u_velocityTex, sampleUV));

            vec3 diff = pos - otherPos;
            float dist = length(diff);

            if (dist < u_perceptionRadius && dist > 0.001) {
                // Separation - steer away from nearby boids
                if (dist < u_perceptionRadius * 0.5) {
                    separation += normalize(diff) / dist;
                    separationCount += 1.0;
                }

                // Alignment - match velocity of nearby boids
                alignment += otherVel;

                // Cohesion - steer towards center of nearby boids
                cohesion += otherPos;

                neighborCount += 1.0;
            }
        }
    }

    // Average the forces
    vec3 steer = vec3(0.0);

    if (separationCount > 0.0) {
        separation /= separationCount;
        steer += normalize(separation) * u_separation;
    }

    if (neighborCount > 0.0) {
        alignment /= neighborCount;
        steer += normalize(alignment) * u_alignment;

        cohesion /= neighborCount;
        cohesion = cohesion - pos; // Direction to center
        steer += normalize(cohesion) * u_cohesion;
    }

    // Mouse attraction/repulsion
    vec3 mousePos = vec3((u_mouse / u_resolution - 0.5) * 2.0, 0.0);
    vec3 toMouse = mousePos - pos;
    float mouseDist = length(toMouse);
    if (mouseDist > 0.1 && mouseDist < 1.5) {
        steer += normalize(toMouse) * u_mouseInfluence / mouseDist;
    }

    // Boundary avoidance - soft walls
    float boundary = 1.8;
    float margin = 0.3;
    if (pos.x > boundary) steer.x -= (pos.x - boundary) / margin;
    if (pos.x < -boundary) steer.x -= (pos.x + boundary) / margin;
    if (pos.y > boundary) steer.y -= (pos.y - boundary) / margin;
    if (pos.y < -boundary) steer.y -= (pos.y + boundary) / margin;
    if (pos.z > boundary * 0.5) steer.z -= (pos.z - boundary * 0.5) / margin;
    if (pos.z < -boundary * 0.5) steer.z -= (pos.z + boundary * 0.5) / margin;

    // Add slight random wandering
    float t = u_deltaTime * 10.0 + v_uv.x * 100.0 + v_uv.y * 100.0;
    steer += vec3(sin(t), cos(t * 1.3), sin(t * 0.7)) * 0.02;

    // Update velocity
    vel += steer * u_deltaTime * 5.0;

    // Limit speed
    float speed = length(vel);
    if (speed > u_maxSpeed) {
        vel = normalize(vel) * u_maxSpeed;
    }
    // Minimum speed - birds don't stop
    if (speed < u_maxSpeed * 0.3) {
        vel = normalize(vel + vec3(0.001, 0.001, 0.0)) * u_maxSpeed * 0.3;
    }

    // Update position
    pos += vel * u_deltaTime;

    // Output depends on which buffer we're writing to
    // We'll use gl_FragCoord to determine: left half = position, right half = velocity
    // Actually, we need separate passes. This shader outputs position.
    // We'll run it twice with different outputs.

    gl_FragColor = vec4(encodePosition(pos), 1.0);
}
