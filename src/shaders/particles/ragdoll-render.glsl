// Ragdoll rendering - draws stick figures by sampling position texture
precision highp float;

uniform sampler2D u_positionTex;
uniform vec2 u_resolution;
uniform float u_simResolution;
uniform float u_time;

#define PARTICLES_PER_RAGDOLL 16.0
#define NUM_RAGDOLLS 64.0

// Get particle position (decode from 0-1 texture to -1 to 1 world coords)
vec2 getPos(float ragdoll, float particle) {
    vec2 uv = vec2(
        (particle + 0.5) / u_simResolution,
        (ragdoll + 0.5) / u_simResolution
    );
    vec2 encoded = texture2D(u_positionTex, uv).xy;
    return (encoded - 0.5) * 2.0;  // Decode: 0-1 -> -1 to 1
}

// Distance from point to line segment
float distToSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * t);
}

// Draw a bone (line segment)
float bone(vec2 p, float ragdoll, float p1, float p2, float thickness) {
    vec2 a = getPos(ragdoll, p1);
    vec2 b = getPos(ragdoll, p2);
    float d = distToSegment(p, a, b);
    return smoothstep(thickness, thickness * 0.5, d);
}

// Draw a joint (circle)
float joint(vec2 p, float ragdoll, float particle, float radius) {
    vec2 pos = getPos(ragdoll, particle);
    float d = length(p - pos);
    return smoothstep(radius, radius * 0.5, d);
}

// Draw complete ragdoll
float drawRagdoll(vec2 p, float ragdoll) {
    float thickness = 0.012;
    float jointRadius = 0.015;

    float c = 0.0;

    // Spine
    c = max(c, bone(p, ragdoll, 0.0, 1.0, thickness));   // head-neck
    c = max(c, bone(p, ragdoll, 1.0, 2.0, thickness));   // neck-chest
    c = max(c, bone(p, ragdoll, 2.0, 3.0, thickness));   // chest-hips

    // Left arm
    c = max(c, bone(p, ragdoll, 2.0, 4.0, thickness));   // chest-shoulderL
    c = max(c, bone(p, ragdoll, 4.0, 5.0, thickness));   // shoulderL-elbowL
    c = max(c, bone(p, ragdoll, 5.0, 6.0, thickness));   // elbowL-handL

    // Right arm
    c = max(c, bone(p, ragdoll, 2.0, 7.0, thickness));   // chest-shoulderR
    c = max(c, bone(p, ragdoll, 7.0, 8.0, thickness));   // shoulderR-elbowR
    c = max(c, bone(p, ragdoll, 8.0, 9.0, thickness));   // elbowR-handR

    // Left leg
    c = max(c, bone(p, ragdoll, 3.0, 10.0, thickness));  // hips-hipL
    c = max(c, bone(p, ragdoll, 10.0, 11.0, thickness)); // hipL-kneeL
    c = max(c, bone(p, ragdoll, 11.0, 12.0, thickness)); // kneeL-footL

    // Right leg
    c = max(c, bone(p, ragdoll, 3.0, 13.0, thickness));  // hips-hipR
    c = max(c, bone(p, ragdoll, 13.0, 14.0, thickness)); // hipR-kneeR
    c = max(c, bone(p, ragdoll, 14.0, 15.0, thickness)); // kneeR-footR

    // Head (larger circle)
    c = max(c, joint(p, ragdoll, 0.0, 0.025));

    // Joints
    c = max(c, joint(p, ragdoll, 2.0, jointRadius));  // chest
    c = max(c, joint(p, ragdoll, 3.0, jointRadius));  // hips
    c = max(c, joint(p, ragdoll, 5.0, jointRadius * 0.7));  // elbowL
    c = max(c, joint(p, ragdoll, 8.0, jointRadius * 0.7));  // elbowR
    c = max(c, joint(p, ragdoll, 11.0, jointRadius * 0.7)); // kneeL
    c = max(c, joint(p, ragdoll, 14.0, jointRadius * 0.7)); // kneeR

    return c;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec2 p = uv * 2.0 - 1.0;
    p.x *= u_resolution.x / u_resolution.y;

    // Background gradient
    vec3 bgTop = vec3(0.15, 0.18, 0.25);
    vec3 bgBottom = vec3(0.08, 0.08, 0.12);
    vec3 color = mix(bgBottom, bgTop, uv.y);

    // Floor
    if (p.y < -0.93) {
        color = mix(color, vec3(0.2, 0.18, 0.22), smoothstep(-0.93, -0.95, p.y));
    }

    // Draw all ragdolls
    float ragdollMask = 0.0;
    for (float i = 0.0; i < NUM_RAGDOLLS; i++) {
        ragdollMask = max(ragdollMask, drawRagdoll(p, i));
    }

    // Ragdoll color
    vec3 ragdollColor = vec3(0.9, 0.85, 0.8);
    color = mix(color, ragdollColor, ragdollMask);

    // Vignette
    float vignette = 1.0 - length(uv - 0.5) * 0.6;
    color *= vignette;

    gl_FragColor = vec4(color, 1.0);
}
