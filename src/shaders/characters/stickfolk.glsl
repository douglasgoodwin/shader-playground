precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

#include "/lygia/math/const.glsl"
#include "/lygia/generative/random.glsl"

// SDF for a line segment
float sdSegment(vec2 p, vec2 a, vec2 b, float thick) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - thick;
}

// SDF for a circle
float sdCircle(vec2 p, vec2 center, float r) {
    return length(p - center) - r;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;
    vec2 mouse = (u_mouse - 0.5 * u_resolution.xy) / u_resolution.y;
    float t = u_time * u_speed;

    // Number of characters across
    float count = floor(5.0 * u_scale + 0.5);
    float spacing = 0.8 / count;

    vec3 bg = vec3(0.08, 0.07, 0.12);
    vec3 color = bg;

    for (float i = 0.0; i < 12.0; i++) {
        if (i >= count) break;

        // Character center x position
        float cx = (i - (count - 1.0) * 0.5) * spacing;
        float phase = random(i) * PI * 2.0 + t;
        float charRand = random(i + 100.0);

        // Pick an action: walk, wave, jump (cycle through)
        float action = mod(floor(phase * 0.3), 3.0);

        // Base body position
        float groundY = -0.25;
        float jumpOffset = 0.0;
        if (action > 1.5) {
            // Jump
            jumpOffset = abs(sin(phase * 1.5)) * 0.08 * u_intensity;
        }
        float baseY = groundY + jumpOffset;

        // Body proportions
        float headR = 0.022 * u_intensity;
        float bodyLen = 0.07 * u_intensity;
        float limbLen = 0.04 * u_intensity;
        float thick = 0.005;

        // Key points
        vec2 hip = vec2(cx, baseY);
        vec2 neck = hip + vec2(0.0, bodyLen);
        vec2 head = neck + vec2(0.0, headR * 1.3);

        // Arm animation
        float armAngleL, armAngleR;
        if (action < 0.5) {
            // Walk: arms swing
            armAngleL = sin(phase * 2.0) * 0.6;
            armAngleR = -sin(phase * 2.0) * 0.6;
        } else if (action < 1.5) {
            // Wave: one arm up
            armAngleL = sin(phase * 3.0) * 0.3;
            armAngleR = -1.2 + sin(phase * 4.0) * 0.4;
        } else {
            // Jump: arms up
            float jumpPhase = sin(phase * 1.5);
            armAngleL = -1.0 - jumpPhase * 0.5;
            armAngleR = -1.0 - jumpPhase * 0.5;
        }

        vec2 shoulderL = neck + vec2(-0.01, -0.005);
        vec2 shoulderR = neck + vec2(0.01, -0.005);
        vec2 handL = shoulderL + vec2(cos(armAngleL + PI * 0.5), sin(armAngleL + PI * 0.5)) * limbLen;
        vec2 handR = shoulderR + vec2(cos(-armAngleR - PI * 0.5), sin(-armAngleR - PI * 0.5)) * limbLen;

        // Leg animation
        float legAngleL, legAngleR;
        if (action < 0.5) {
            // Walk: legs stride
            legAngleL = sin(phase * 2.0) * 0.4 + PI;
            legAngleR = -sin(phase * 2.0) * 0.4 + PI;
        } else if (action > 1.5) {
            // Jump: legs tucked
            float jumpPhase = sin(phase * 1.5);
            legAngleL = PI + 0.3 + jumpPhase * 0.3;
            legAngleR = PI - 0.3 - jumpPhase * 0.3;
        } else {
            // Standing
            legAngleL = PI + 0.15;
            legAngleR = PI - 0.15;
        }

        vec2 footL = hip + vec2(cos(legAngleL), sin(legAngleL)) * limbLen;
        vec2 footR = hip + vec2(cos(legAngleR), sin(legAngleR)) * limbLen;

        // Head looks toward mouse
        vec2 toMouse = mouse - head;
        float lookAngle = atan(toMouse.y, toMouse.x);
        float lookStrength = min(1.0, 1.0 / (length(toMouse) * 5.0 + 0.5));
        vec2 eyeOffset = vec2(cos(lookAngle), sin(lookAngle)) * headR * 0.3 * lookStrength;

        // Composite SDF
        float d = sdCircle(uv, head, headR);
        d = min(d, sdSegment(uv, neck, hip, thick));       // body
        d = min(d, sdSegment(uv, shoulderL, handL, thick)); // left arm
        d = min(d, sdSegment(uv, shoulderR, handR, thick)); // right arm
        d = min(d, sdSegment(uv, hip, footL, thick));       // left leg
        d = min(d, sdSegment(uv, hip, footR, thick));       // right leg

        // Per-character color
        vec3 charColor = vec3(
            0.5 + 0.5 * sin(charRand * 6.28),
            0.5 + 0.5 * sin(charRand * 6.28 + 2.09),
            0.5 + 0.5 * sin(charRand * 6.28 + 4.19)
        ) * u_intensity;

        // Render
        float body = smoothstep(0.004, 0.0, d);
        color = mix(color, charColor, body);

        // Eyes
        vec2 eyeCenter = head + eyeOffset;
        float eyeD = length(uv - eyeCenter);
        float eye = smoothstep(headR * 0.25, headR * 0.15, eyeD);
        color = mix(color, vec3(0.0), eye * body);
    }

    // Ground line
    float groundLine = smoothstep(0.003, 0.0, abs(uv.y + 0.25));
    color = mix(color, vec3(0.2, 0.2, 0.3), groundLine * 0.5);

    // Mouse glow
    float mouseDist = distance(uv, mouse);
    color += 0.05 / (mouseDist + 0.1) * vec3(0.4, 0.3, 0.6) * u_intensity;

    // Ripple effect
    vec2 uvNorm = gl_FragCoord.xy / u_resolution;
    for (int i = 0; i < 10; i++) {
        vec2 ripplePos = u_ripples[i].xy / u_resolution;
        float rippleTime = u_ripples[i].z;
        if (rippleTime > 0.0) {
            float age = u_time - rippleTime;
            float rippleDist = distance(uvNorm, ripplePos);
            float radius = age * 0.5 * u_speed;
            float ring = abs(rippleDist - radius);
            float ripple = smoothstep(0.05, 0.0, ring) * exp(-age * 2.0 / u_intensity);
            color += ripple * u_rippleColors[i] * u_intensity;
        }
    }

    gl_FragColor = vec4(color, 1.0);
}
