// Furry creature — raymarched sphere with shell-method fur
// Fur strands droop under gravity and sway with animated wind
// The wind field creates parallel strand motion visible across the surface
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_wind;
uniform float u_gravity;
uniform float u_density;
uniform float u_furLength;

#define NUM_SHELLS 40
#define SPHERE_RADIUS 0.8
#define FUR_LENGTH 0.25
#define PI 3.14159265

// Hashes
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

vec3 hash3(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yxx) * p3.zyx);
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Wind field in world space — traveling waves
vec3 windForce(vec3 worldPos, float t) {
    // Dominant wind direction
    vec3 windDir = normalize(vec3(1.0, 0.0, 0.3));

    // Gust waves traveling along wind direction
    float phase = dot(worldPos.xz, windDir.xz) * 3.0 - t * 2.5;
    float gust = sin(phase) * 0.5 + 0.5;
    gust += sin(phase * 2.7 + 1.3) * 0.25;

    // Turbulence
    float turb = vnoise(worldPos.xz * 4.0 + vec2(t * 1.5, -t * 0.8)) * 2.0 - 1.0;

    vec3 w = windDir * gust;
    w += vec3(-windDir.z, 0.0, windDir.x) * turb * 0.3;

    return w;
}

// Sphere intersection
vec2 intersectSphere(vec3 ro, vec3 rd, float r) {
    float b = dot(ro, rd);
    float c = dot(ro, ro) - r * r;
    float disc = b * b - c;
    if (disc < 0.0) return vec2(-1.0);
    disc = sqrt(disc);
    return vec2(-b - disc, -b + disc);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution.y;

    // Mouse-driven rotation
    vec2 mouseNorm = u_mouse / u_resolution;
    float rotY = (mouseNorm.x - 0.5) * PI * 0.5;
    float rotX = (mouseNorm.y - 0.5) * PI * 0.3;

    // Camera
    vec3 ro = vec3(0.0, 0.0, 2.5);
    vec3 rd = normalize(vec3(uv, -1.2));

    // Background — soft radial gradient
    float bgGrad = length(uv) * 0.7;
    vec3 bgColor = mix(vec3(0.12, 0.10, 0.15), vec3(0.04, 0.03, 0.05), bgGrad);

    vec3 color = bgColor;

    float furLen = FUR_LENGTH * u_furLength;

    // Test outer shell (sphere + fur) first
    vec2 tOuter = intersectSphere(ro, rd, SPHERE_RADIUS + furLen);
    if (tOuter.x > 0.0) {
        // Also get inner sphere hit
        vec2 tInner = intersectSphere(ro, rd, SPHERE_RADIUS);

        // March entry/exit along the ray through the fur volume
        float tStart = tOuter.x;
        float tEnd = tInner.x > 0.0 ? tInner.x : tOuter.y;

        // Skin color at the surface
        vec3 skinHit = tInner.x > 0.0 ? ro + rd * tInner.x : ro + rd * tOuter.y;
        vec3 skinNormal = normalize(skinHit);

        // Simple diffuse lighting on skin
        vec3 lightDir = normalize(vec3(0.5, 0.8, 0.6));
        float diff = max(dot(skinNormal, lightDir), 0.0) * 0.6 + 0.4;
        vec3 skinColor = vec3(0.18, 0.10, 0.07) * diff;

        color = skinColor;

        // UV on sphere surface for strand grid
        float theta = atan(skinNormal.z, skinNormal.x); // longitude
        float phi = acos(clamp(skinNormal.y, -1.0, 1.0)); // latitude

        // Strand grid in spherical UV
        float gridScale = 40.0 * u_density;
        vec2 sphereUV = vec2(theta / PI * 0.5 + 0.5, phi / PI);

        // Process shells from skin outward
        for (int i = 0; i < NUM_SHELLS; i++) {
            float shell = float(i) / float(NUM_SHELLS);
            float shellR = SPHERE_RADIUS + shell * furLen;

            // Find where this shell sphere intersects the ray
            vec2 tShell = intersectSphere(ro, rd, shellR);
            if (tShell.x < 0.0) continue;

            vec3 shellPos = ro + rd * tShell.x;
            vec3 shellNorm = normalize(shellPos);

            // Height factor for wind/gravity (quadratic for realistic droop)
            float heightFactor = shell * shell;

            // Wind force at this world position
            vec3 wind = windForce(shellPos, u_time) * u_wind;

            // Project wind onto tangent plane of sphere
            vec3 tangentWind = wind - shellNorm * dot(wind, shellNorm);

            // Gravity: always pulls down, project onto tangent plane
            vec3 gravDir = vec3(0.0, -1.0, 0.0);
            vec3 tangentGrav = gravDir - shellNorm * dot(gravDir, shellNorm);
            tangentGrav *= u_gravity;

            // Total displacement in tangent space
            vec3 displacement = (tangentWind * 0.12 + tangentGrav * 0.08) * heightFactor;

            // Displace the lookup point along the sphere surface
            vec3 displacedNorm = normalize(shellNorm + displacement);

            // Convert displaced normal to UV
            float dTheta = atan(displacedNorm.z, displacedNorm.x);
            float dPhi = acos(clamp(displacedNorm.y, -1.0, 1.0));
            vec2 dUV = vec2(dTheta / PI * 0.5 + 0.5, dPhi / PI);

            // Strand lookup in grid
            vec2 cell = floor(dUV * gridScale);
            vec2 cellF = fract(dUV * gridScale);

            vec2 h = hash2(cell);
            vec2 center = vec2(0.25 + h.x * 0.5, 0.25 + h.y * 0.5);
            float strandH = 0.3 + h.x * 0.7;

            float dist = length(cellF - center);
            float radius = 0.22 * (1.0 - shell * 0.8);

            if (shell < strandH && dist < radius) {
                // Fur color: warm brown/orange with variation
                vec3 h3 = hash3(cell);
                vec3 furBase = mix(
                    vec3(0.40, 0.22, 0.10),
                    vec3(0.70, 0.45, 0.20),
                    h3.x
                );
                // Tips are lighter
                vec3 furTip = furBase * 1.3 + vec3(0.1, 0.05, 0.0);
                vec3 furColor = mix(furBase, furTip, shell);

                // Lighting on fur
                float furDiff = max(dot(shellNorm, lightDir), 0.0) * 0.5 + 0.5;
                furColor *= furDiff;

                // Wind highlight: strands bent into light catch more
                float windCatch = max(dot(normalize(tangentWind + vec3(0.001)), lightDir), 0.0);
                furColor += vec3(0.15, 0.08, 0.02) * windCatch * heightFactor * length(wind);

                // Rim light
                float fresnel = 1.0 - abs(dot(shellNorm, -rd));
                furColor += vec3(0.2, 0.15, 0.10) * pow(fresnel, 3.0) * 0.5;

                // Alpha
                float a = smoothstep(radius, radius * 0.15, dist);
                a *= 1.0 - shell * 0.5;

                // AO: darker near the base
                furColor *= 0.5 + 0.5 * shell;

                color = mix(color, furColor, a);
            }
        }
    }

    // Subtle vignette
    float vig = 1.0 - 0.3 * length(uv);
    color *= vig;

    gl_FragColor = vec4(color, 1.0);
}
