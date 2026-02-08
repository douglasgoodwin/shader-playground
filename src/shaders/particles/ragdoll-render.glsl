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
    float thickness = 0.006;
    float jointRadius = 0.0075;

    float c = 0.0;

    // Bone table: (particleA, particleB) - matches constraint topology
    vec2 bones[15];
    bones[0]  = vec2(0, 1);    // head-neck
    bones[1]  = vec2(1, 2);    // neck-chest
    bones[2]  = vec2(2, 3);    // chest-hips
    bones[3]  = vec2(2, 4);    // chest-shoulderL
    bones[4]  = vec2(4, 5);    // shoulderL-elbowL
    bones[5]  = vec2(5, 6);    // elbowL-handL
    bones[6]  = vec2(2, 7);    // chest-shoulderR
    bones[7]  = vec2(7, 8);    // shoulderR-elbowR
    bones[8]  = vec2(8, 9);    // elbowR-handR
    bones[9]  = vec2(3, 10);   // hips-hipL
    bones[10] = vec2(10, 11);  // hipL-kneeL
    bones[11] = vec2(11, 12);  // kneeL-footL
    bones[12] = vec2(3, 13);   // hips-hipR
    bones[13] = vec2(13, 14);  // hipR-kneeR
    bones[14] = vec2(14, 15);  // kneeR-footR

    for (int i = 0; i < 15; i++) {
        c = max(c, bone(p, ragdoll, bones[i].x, bones[i].y, thickness));
    }

    // Head (larger circle)
    c = max(c, joint(p, ragdoll, 0.0, 0.0125));

    // Joint table: (particleIndex, radiusScale)
    vec2 joints[6];
    joints[0] = vec2(2, 1.0);    // chest
    joints[1] = vec2(3, 1.0);    // hips
    joints[2] = vec2(5, 0.7);    // elbowL
    joints[3] = vec2(8, 0.7);    // elbowR
    joints[4] = vec2(11, 0.7);   // kneeL
    joints[5] = vec2(14, 0.7);   // kneeR

    for (int i = 0; i < 6; i++) {
        c = max(c, joint(p, ragdoll, joints[i].x, jointRadius * joints[i].y));
    }

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
