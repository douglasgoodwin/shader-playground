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

varying vec2 v_uv;

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
    vec3 vel = decodeVelocity(texture2D(u_velocityTex, v_uv));

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
                if (dist < u_perceptionRadius * 0.4) {
                    separation += normalize(diff) / (dist + 0.01);
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
        steer += normalize(separation) * u_separation;
    }

    if (neighborCount > 0.0) {
        alignment /= neighborCount;
        if (length(alignment) > 0.001) {
            steer += normalize(alignment) * u_alignment;
        }

        cohesion /= neighborCount;
        cohesion = cohesion - pos;
        if (length(cohesion) > 0.001) {
            steer += normalize(cohesion) * u_cohesion;
        }
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

    // Wandering
    float t = u_deltaTime * 10.0 + v_uv.x * 123.4 + v_uv.y * 567.8;
    steer += vec3(sin(t * 3.7), cos(t * 2.9), sin(t * 1.3)) * 0.03;

    // Update velocity
    vel += steer * u_deltaTime * 5.0;

    // Speed limits
    float speed = length(vel);
    if (speed > u_maxSpeed) {
        vel = normalize(vel) * u_maxSpeed;
    }
    if (speed < u_maxSpeed * 0.25) {
        vel = normalize(vel + vec3(0.001)) * u_maxSpeed * 0.25;
    }

    gl_FragColor = vec4(encodeVelocity(vel), 1.0);
}
