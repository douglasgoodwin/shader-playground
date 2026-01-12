// Thue-Morse Curve - fractal curve without recursion
// Uses the Thue-Morse sequence for turn directions

precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

#define PI 3.14159265359

// Count number of 1-bits in an integer (popcount)
// Thue-Morse(n) = popcount(n) mod 2
int popcount(int n) {
    int count = 0;
    for (int i = 0; i < 16; i++) {
        if (n == 0) break;
        count += n - (n / 2) * 2; // n mod 2
        n = n / 2;
    }
    return count;
}

// Thue-Morse sequence value at position n
int thueMorse(int n) {
    return popcount(n) - (popcount(n) / 2) * 2; // mod 2
}

// Distance from point to line segment
float segmentDist(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    uv *= 2.0 / u_scale;

    float t = u_time * u_speed * 0.3;

    // Turtle graphics state
    vec2 pos = vec2(-0.8, 0.0);
    float angle = 0.0;
    float stepSize = 0.02 * u_scale;

    // Turn angle - 90 degrees gives interesting patterns
    // 60 degrees gives more Koch-like results
    float turnAngle = PI * 0.5 * u_intensity; // adjustable

    // Animate which part of the sequence we're drawing
    int maxSteps = int(256.0 + 256.0 * sin(t * 0.2));

    float minDist = 1000.0;
    vec3 closestColor = vec3(1.0);

    // Draw the Thue-Morse curve
    for (int i = 0; i < 512; i++) {
        if (i >= maxSteps) break;

        // Get Thue-Morse value for this step
        int tm = thueMorse(i);

        // Turn based on Thue-Morse: 0 = left, 1 = right
        if (tm == 0) {
            angle += turnAngle;
        } else {
            angle -= turnAngle;
        }

        // Calculate next position
        vec2 nextPos = pos + vec2(cos(angle), sin(angle)) * stepSize;

        // Distance to this line segment
        float d = segmentDist(uv, pos, nextPos);

        if (d < minDist) {
            minDist = d;
            // Color based on position in sequence
            float hue = float(i) / float(maxSteps);
            closestColor = vec3(
                0.5 + 0.5 * sin(hue * 6.28 + 0.0),
                0.5 + 0.5 * sin(hue * 6.28 + 2.1),
                0.5 + 0.5 * sin(hue * 6.28 + 4.2)
            );
        }

        pos = nextPos;
    }

    // Render with glow
    float glow = 0.003 / (minDist + 0.003);
    float line = smoothstep(0.008, 0.002, minDist);

    vec3 color = glow * closestColor * 0.4 + line * closestColor;

    // Mouse glow
    vec2 mouse = (u_mouse - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    mouse *= 2.0 / u_scale;
    float mouseDist = length(uv - mouse);
    color += 0.02 / (mouseDist + 0.1) * vec3(0.5, 0.7, 1.0);

    // Ripples
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

    // Background
    vec3 bg = vec3(0.02, 0.02, 0.03);
    color = max(color, bg);

    gl_FragColor = vec4(color, 1.0);
}
