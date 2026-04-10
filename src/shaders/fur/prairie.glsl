// Grassy prairie with wind waves propagating across the field
// Uses raymarching with shell layers over a ground plane
// Wind is a 2D vector field that creates visible traveling waves
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_wind;
uniform float u_gravity;
uniform float u_density;
uniform float u_furLength;

#define MAX_STEPS 80
#define NUM_SHELLS 48
#define GRASS_HEIGHT 0.25

// Hashes
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

// Smooth noise
float snoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Multi-scale wind field: large gusts + small turbulence
vec2 windVec(vec2 p, float t) {
    // Dominant wind direction with time-varying angle
    float angle = 0.3 + 0.2 * sin(t * 0.15);
    vec2 dominant = vec2(cos(angle), sin(angle));

    // Large gusts — slow-moving pressure waves
    float gust = snoise(p * 0.3 + dominant * t * 0.8) * 2.0 - 1.0;
    gust += snoise(p * 0.7 - dominant * t * 0.4) * 0.5;

    // Turbulence — faster, smaller eddies
    float turb = snoise(p * 3.0 + vec2(t * 2.0, -t * 1.3));

    vec2 w = dominant * (1.0 + gust * 0.8);
    w += vec2(-dominant.y, dominant.x) * turb * 0.4; // cross-wind eddies

    return w;
}

// Terrain height
float terrain(vec2 p) {
    return snoise(p * 0.5) * 0.1 + snoise(p * 1.5) * 0.02;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    float aspect = u_resolution.x / u_resolution.y;

    // Camera setup — looking across the prairie
    vec3 ro = vec3(0.0, 0.6, -1.5); // camera position
    vec3 lookAt = vec3(0.0, 0.15, 2.0);
    vec3 fwd = normalize(lookAt - ro);
    vec3 right = normalize(cross(fwd, vec3(0.0, 1.0, 0.0)));
    vec3 up = cross(right, fwd);

    vec2 screen = (uv - 0.5) * vec2(aspect, 1.0);
    vec3 rd = normalize(fwd * 1.5 + right * screen.x + up * screen.y);

    // Sky gradient
    float skyGrad = max(rd.y, 0.0);
    vec3 skyColor = mix(vec3(0.55, 0.65, 0.75), vec3(0.25, 0.45, 0.75), skyGrad);
    skyColor = mix(skyColor, vec3(0.9, 0.85, 0.7), pow(max(1.0 - skyGrad, 0.0), 4.0)); // horizon haze

    vec3 color = skyColor;

    // Intersect ground plane (y = 0)
    if (rd.y < -0.001) {
        float t = -ro.y / rd.y;
        vec3 hit = ro + rd * t;

        // Ground position
        vec2 gp = hit.xz;
        float terrainH = terrain(gp);

        // Grass parameters
        float grassH = GRASS_HEIGHT * u_furLength;
        float gridScale = 30.0 * u_density;

        // Wind at this ground position
        vec2 wind = windVec(gp, u_time) * u_wind;

        // Base ground color
        vec3 groundColor = mix(vec3(0.12, 0.08, 0.04), vec3(0.15, 0.10, 0.05), hash(floor(gp * 10.0)));

        vec3 grassColor = groundColor;
        float grassAlpha = 0.0;

        // Shell layers
        for (int i = 0; i < NUM_SHELLS; i++) {
            float shell = float(i) / float(NUM_SHELLS);
            float heightFactor = shell * shell;

            // Wind displacement — quadratic increase with height
            vec2 windOffset = wind * heightFactor * 0.15;

            // Gravity droop
            float grav = u_gravity * heightFactor * 0.06;

            // Displaced grass lookup
            vec2 displaced = gp + windOffset;
            vec2 cell = floor(displaced * gridScale);
            vec2 cellF = fract(displaced * gridScale);

            vec2 h = hash2(cell);
            vec2 center = vec2(0.25 + h.x * 0.5, 0.25 + h.y * 0.5);
            float bladeH = 0.3 + h.x * 0.7;

            float dist = length(cellF - center);

            // Blade radius thins with height
            float radius = (0.22 - shell * 0.18);

            if (shell < bladeH && dist < radius) {
                // Color: green with variation, yellower at tips
                vec3 baseGreen = mix(
                    vec3(0.15, 0.35, 0.08),
                    vec3(0.25, 0.45, 0.10),
                    h.y
                );
                vec3 tipColor = mix(
                    vec3(0.45, 0.50, 0.15),
                    vec3(0.55, 0.55, 0.20),
                    h.x
                );
                vec3 bladeColor = mix(baseGreen, tipColor, shell);

                // Wind-reactive: bent grass catches light differently
                float windStr = length(wind);
                float catchLight = windStr * heightFactor * 0.3;
                bladeColor += vec3(catchLight * 0.15, catchLight * 0.1, 0.0);

                // Ambient occlusion: darker at base
                bladeColor *= 0.5 + 0.5 * shell;

                float a = smoothstep(radius, radius * 0.2, dist);
                a *= 1.0 - shell * 0.4;

                grassColor = mix(grassColor, bladeColor, a);
                grassAlpha = max(grassAlpha, a);
            }
        }

        // Distance fog
        float fogDist = length(hit - ro);
        float fog = 1.0 - exp(-fogDist * 0.08);

        color = mix(grassColor, skyColor, fog);
    }

    // Sun
    vec3 sunDir = normalize(vec3(0.5, 0.3, 0.8));
    float sun = pow(max(dot(rd, sunDir), 0.0), 128.0);
    color += vec3(1.0, 0.9, 0.7) * sun * 0.4;

    // Tone mapping
    color = color / (color + 0.8);

    gl_FragColor = vec4(color, 1.0);
}
