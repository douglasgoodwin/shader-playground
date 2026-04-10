// Shell-method fur on a flat surface with animated wind and gravity
// Each shell layer is a horizontal slice; noise determines strand presence
// Wind and gravity displace strand tips more than roots (height-dependent)
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_wind;
uniform float u_gravity;
uniform float u_density;
uniform float u_furLength;

#define NUM_SHELLS 64
#define FUR_HEIGHT 0.15

// Hash for strand placement
vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

// Value noise for wind field
float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = dot(hash2(i), vec2(1.0));
    float b = dot(hash2(i + vec2(1.0, 0.0)), vec2(1.0));
    float c = dot(hash2(i + vec2(0.0, 1.0)), vec2(1.0));
    float d = dot(hash2(i + vec2(1.0, 1.0)), vec2(1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// FBM wind field — two octaves for gusts
float windField(vec2 p, float t) {
    float w = 0.0;
    w += vnoise(p * 2.0 + vec2(t * 1.2, t * 0.4)) * 0.6;
    w += vnoise(p * 5.0 + vec2(t * 2.5, -t * 0.8)) * 0.3;
    w += vnoise(p * 11.0 + vec2(-t * 0.7, t * 3.1)) * 0.1;
    return w;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    float aspect = u_resolution.x / u_resolution.y;

    // Surface coordinates — tile space for strands
    vec2 surfUV = vec2(uv.x * aspect, uv.y);
    float furH = FUR_HEIGHT * u_furLength;

    // Base color gradient (skin underneath)
    vec3 skinColor = mix(vec3(0.15, 0.08, 0.04), vec3(0.25, 0.13, 0.06), uv.y);

    // Strand grid parameters
    float gridScale = 80.0 * u_density;

    vec3 color = skinColor;
    float alpha = 1.0;

    // March through shells from bottom to top
    for (int i = 0; i < NUM_SHELLS; i++) {
        float t = float(i) / float(NUM_SHELLS);
        float shellHeight = t;

        // Wind displacement increases with height (quadratic)
        float heightFactor = shellHeight * shellHeight;
        vec2 windDir = vec2(1.0, 0.3); // dominant wind direction
        float wf = windField(surfUV * 0.5, u_time) * 2.0 - 1.0;
        vec2 windOffset = windDir * wf * u_wind * heightFactor * 0.08;

        // Gravity pulls tips down (in screen space, -Y)
        float gravityOffset = -u_gravity * heightFactor * 0.04;

        // Displaced UV for this shell
        vec2 shellUV = surfUV + windOffset + vec2(0.0, gravityOffset);

        // Grid cell for strand lookup
        vec2 cell = floor(shellUV * gridScale);
        vec2 cellUV = fract(shellUV * gridScale);

        // Strand center and properties from hash
        vec2 h = hash2(cell);
        vec2 strandCenter = vec2(0.3 + h.x * 0.4, 0.3 + h.y * 0.4);
        float strandHeight = 0.4 + h.x * 0.6; // how tall this strand grows

        // Distance from strand center
        float dist = length(cellUV - strandCenter);

        // Strand radius thins toward tip
        float baseRadius = 0.18;
        float radius = baseRadius * (1.0 - t * 0.85);

        // Only draw if this shell is below strand's max height
        if (t < strandHeight && dist < radius) {
            // Fur color varies per strand, darkens at base
            float shade = 0.4 + 0.6 * t; // lighter at tips
            vec3 furBase = mix(
                vec3(0.35, 0.18, 0.08),
                vec3(0.65, 0.40, 0.20),
                h.y
            );

            // Wind-reactive highlight — strands bent by wind catch more light
            float windHighlight = abs(wf) * heightFactor * 0.4;

            // Subtle color variation with wind
            vec3 strandColor = furBase * shade + vec3(windHighlight * 0.3, windHighlight * 0.15, 0.0);

            // Rim lighting at strand edges
            float rim = smoothstep(radius * 0.3, radius, dist);
            strandColor *= 1.0 - rim * 0.3;

            // Alpha: opaque at base, transparent at tips
            float strandAlpha = smoothstep(radius, radius * 0.3, dist);
            strandAlpha *= 1.0 - t * 0.6;

            // Composite
            color = mix(color, strandColor, strandAlpha);
        }
    }

    // Vignette
    float vig = 1.0 - 0.4 * length(uv - 0.5);
    color *= vig;

    gl_FragColor = vec4(color, 1.0);
}
