// Lightning Storm Landscape
// Dark terrain illuminated by simplex noise lightning bolts
// Terrain adapted from Nelua red landscape demo

precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;
uniform float u_camHeight;

// --- Hash / Noise for terrain ---

vec3 vec2_xyx(vec2 v) { return vec3(v.x, v.y, v.x); }
vec3 vec3_yzx(vec3 v) { return vec3(v.y, v.z, v.x); }

float hash1(vec2 v) {
    vec3 v3 = fract(vec2_xyx(v) * 0.1031);
    v3 += dot(v3, vec3_yzx(v3) + 33.33);
    return fract((v3.x + v3.y) * v3.z);
}

vec2 hash2(vec2 v) {
    vec3 v3 = vec2_xyx(v) * vec3(0.1031, 0.103, 0.0973);
    v3 += dot(v3, vec3_yzx(v3) + 33.33);
    return fract((vec2(v3.x, v3.x) + vec2(v3.y, v3.z)) * vec2(v3.z, v3.y));
}

float noisemix2(float a, float b, float c, float d, vec2 f) {
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 I = floor(i + 1.0);
    float a = hash1(i);
    float b = hash1(vec2(I.x, i.y));
    float c = hash1(vec2(i.x, I.y));
    float d = hash1(I);
    return noisemix2(a, b, c, d, f);
}

float gradientNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 I = floor(i + 1.0);
    vec2 F = f - 1.0;
    float a = dot(-0.5 + hash2(i), f);
    float b = dot(-0.5 + hash2(vec2(I.x, i.y)), vec2(F.x, f.y));
    float c = dot(-0.5 + hash2(vec2(i.x, I.y)), vec2(f.x, F.y));
    float d = dot(-0.5 + hash2(I), F);
    return 0.5 + noisemix2(a, b, c, d, f);
}

// --- Simplex noise for lightning ---

vec3 random3(vec3 c) {
    float j = 4096.0 * sin(dot(c, vec3(17.0, 59.4, 15.0)));
    vec3 r;
    r.z = fract(512.0 * j);
    j *= 0.125;
    r.x = fract(512.0 * j);
    j *= 0.125;
    r.y = fract(512.0 * j);
    return r - 0.5;
}

const float F3 = 0.3333333;
const float G3 = 0.1666667;

float simplex3d(vec3 p) {
    vec3 s = floor(p + dot(p, vec3(F3)));
    vec3 x = p - s + dot(s, vec3(G3));

    vec3 e = step(vec3(0.0), x - x.yzx);
    vec3 i1 = e * (1.0 - e.zxy);
    vec3 i2 = 1.0 - e.zxy * (1.0 - e);

    vec3 x1 = x - i1 + G3;
    vec3 x2 = x - i2 + 2.0 * G3;
    vec3 x3 = x - 1.0 + 3.0 * G3;

    vec4 w, d;
    w.x = dot(x, x);
    w.y = dot(x1, x1);
    w.z = dot(x2, x2);
    w.w = dot(x3, x3);
    w = max(0.6 - w, 0.0);

    d.x = dot(random3(s), x);
    d.y = dot(random3(s + i1), x1);
    d.z = dot(random3(s + i2), x2);
    d.w = dot(random3(s + 1.0), x3);

    w *= w;
    w *= w;
    d *= w;

    return dot(d, vec4(52.0));
}

float simplexFBM(vec3 m) {
    return 0.5333333 * simplex3d(m)
         + 0.2666667 * simplex3d(2.0 * m)
         + 0.1333333 * simplex3d(4.0 * m)
         + 0.0666667 * simplex3d(8.0 * m);
}

// --- Terrain (two layers) ---

float fbmTerrain(vec2 p) {
    float a = 1.0, t = 0.0;
    for (int i = 0; i < 4; i++) {
        t += a * valueNoise(p);
        a *= 0.5;
        p *= 2.0;
    }
    return t;
}

// Near foreground hills - u_scale controls verticality
float mapNear(vec3 p) {
    float h = fbmTerrain(p.xz) * 0.5 * u_scale;
    float d = p.y + h * 0.75;
    return d * 0.5;
}

// Far background hills - offset noise, taller ridgeline, pushed back
float mapFar(vec3 p) {
    float h = fbmTerrain(p.xz * 0.6 + 50.0) * 0.7;
    float d = p.y + h * 0.75 - 0.05;
    return d * 0.5;
}

vec3 calcNormalNear(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        mapNear(p + e.xyy) - mapNear(p - e.xyy),
        mapNear(p + e.yxy) - mapNear(p - e.yxy),
        mapNear(p + e.yyx) - mapNear(p - e.yyx)
    ));
}

float rayMarchNear(vec3 ro, vec3 rd, float maxT) {
    float t = 0.0;
    for (int i = 0; i < 200; i++) {
        vec3 p = ro + t * rd;
        float d = mapNear(p);
        if (d < 0.003 * t || t >= maxT) break;
        t += d;
    }
    return t;
}

float rayMarchFar(vec3 ro, vec3 rd) {
    float t = 8.0; // start further out to skip near region
    for (int i = 0; i < 128; i++) {
        vec3 p = ro + t * rd;
        float d = mapFar(p);
        if (d < 0.003 * t || t >= 25.0) break;
        t += d;
    }
    return t;
}

// --- Camera ---

vec3 cameraPerspective(vec3 lookfrom, vec3 lookat, float vfov, vec2 uv) {
    vec3 w = normalize(lookat - lookfrom);
    vec3 u = normalize(cross(w, vec3(0.0, 1.0, 0.0)));
    vec3 v = cross(u, w);
    float wf = 1.0 / tan(vfov * 0.00872664626);
    return normalize(uv.x * u + uv.y * v + wf * w);
}

// --- Lightning bolt (simplex noise based, vertical) ---

// Returns bolt brightness for a given screen coord, with time-varying seed offset
float lightningBolt(vec2 coord, vec2 res, float timeOffset) {
    // Swap x/y so the bolt runs vertically (top to bottom)
    vec2 p = (coord.yx + vec2(0.5 * res.y, 0.0)) / res.y;
    vec3 p3 = vec3(p, timeOffset * 0.4);

    float intensity = simplexFBM(vec3(p3 * 12.0 + 12.0));

    // Bolt shape: narrow horizontally, runs full height
    vec2 uv = coord / res;
    uv = uv * 2.0 - 1.0;
    // Parabolic mask on y (was x), displaces x (was y)
    // Tighter mask (0.25/0.08) for a narrower, more concentrated bolt
    float t = clamp(uv.y * -uv.y * 0.25 + 0.08, 0.0, 1.0);
    float d = abs(intensity * -t + uv.x);

    // Higher exponent = sharper bolt with less diffuse glow
    float g = pow(d, 0.6);

    vec3 boltCol = vec3(1.70, 1.48, 1.78);
    boltCol = boltCol * -g + boltCol;
    boltCol = boltCol * boltCol;
    boltCol = boltCol * boltCol;

    return (boltCol.x + boltCol.y + boltCol.z) / 3.0;
}

// --- Lightning flash timing ---

// Returns: x = flash intensity, y = time seed for bolt, z = bolt x offset in screen
vec3 lightningFlash(float time) {
    float flash = 0.0;
    float seed = 0.0;
    float xpos = 0.0;

    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float period = 2.5 + fi * 1.7;
        float phase = fi * 0.8;
        float t = mod(time + phase, period);

        float strikeTime = period * 0.5;
        float dt = t - strikeTime;

        if (dt > 0.0 && dt < 0.4) {
            float f = exp(-dt * 12.0);
            f += 0.3 * exp(-abs(dt - 0.15) * 20.0);

            float strikeSeed = floor((time + phase) / period);
            float sx = (hash1(vec2(strikeSeed, fi * 7.0)) - 0.5) * 1.2;

            if (f > flash) {
                flash = f;
                seed = strikeSeed * 3.7 + fi * 13.0;
                xpos = sx;
            }
        }
    }

    return vec3(flash, seed, xpos);
}

// --- Color grading ---

vec3 tonemapACES(vec3 col) {
    return clamp((col * (2.51 * col + 0.03)) / (col * (2.43 * col + 0.59) + 0.14), 0.0, 1.0);
}

float smootherstep(float edge0, float edge1, float x) {
    float t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

void main() {
    float speed = u_speed;
    vec2 res = u_resolution;
    vec2 uv = gl_FragCoord.xy / res;
    vec2 coord = (2.0 * (gl_FragCoord.xy - res * 0.5)) / res.y;

    // Fixed camera with adjustable height
    vec3 ro = vec3(0.0, u_camHeight, -2.0);
    vec3 lookat = vec3(0.0, u_camHeight, 0.0);
    vec3 rd = cameraPerspective(ro, lookat, 45.0, coord);

    // Lightning state
    vec3 flashInfo = lightningFlash(u_time * speed);
    float flashIntensity = flashInfo.x * u_intensity * 1.5;
    float boltSeed = flashInfo.y;
    float boltX = flashInfo.z;

    // Dark storm sky
    vec3 stormSky = vec3(0.02, 0.02, 0.04);
    vec3 cloudLight = vec3(0.3, 0.3, 0.45);

    // Sky with lightning illumination
    vec3 skyCol = stormSky;
    float cloudBrightness = smootherstep(0.0, 0.25, rd.y) * flashIntensity;
    skyCol = mix(skyCol, cloudLight, cloudBrightness * 0.5);

    // Ambient horizon glow (very subtle, cool)
    skyCol += vec3(0.01, 0.01, 0.03) * max(0.1 - rd.y, 0.0) * 3.0;

    // Bolt glow for compositing
    vec2 boltCoord = gl_FragCoord.xy;
    boltCoord.x -= boltX * res.x * 0.5;
    float boltGlow = lightningBolt(boltCoord, res, boltSeed) * flashIntensity;
    vec3 boltColor = vec3(0.7, 0.7, 1.0);

    // --- Layer 1: Sky + clouds + lightning bolt ---
    vec3 backCol = skyCol;

    // Lightning bolt in the sky
    backCol += boltGlow * boltColor * 0.15;

    // Clouds
    float cloudsAlt = 1000.0;
    float cloudsDist = (1.0 - ro.y / cloudsAlt) / rd.y;
    if (cloudsDist > 0.0) {
        vec2 cloudsPos = ro.xz + rd.xz * cloudsDist;
        float cloudsVal = max(gradientNoise(cloudsPos) - 0.3, 0.0);
        float cloudsDecay = smootherstep(0.0, 0.3, rd.y);
        vec3 cloudCol = cloudLight * flashIntensity * 1.5;
        backCol = mix(backCol, cloudCol, cloudsVal * cloudsDecay);
    }

    // --- Layer 2: Far hills (dark silhouette, backlit by bolt) ---
    float tFar = rayMarchFar(ro, rd);
    vec3 col = backCol;

    if (tFar < 25.0) {
        // Dark silhouette with subtle backlight from the flash
        vec3 farColor = vec3(0.01, 0.01, 0.02);
        // Slight edge glow from lightning behind
        farColor += flashIntensity * vec3(0.02, 0.02, 0.04);

        // Fog softens distant hills into the sky
        float farDecay = 1.0 - exp(-0.15 * (tFar - 8.0));
        col = mix(farColor, backCol, farDecay);
    }

    // --- Layer 3: Near foreground hills (lit by lightning) ---
    float tNear = rayMarchNear(ro, rd, 12.0);

    if (tNear < 12.0) {
        vec3 p = ro + rd * tNear;
        vec3 n = calcNormalNear(p);

        // Lightning as light source from bolt position
        vec3 lightDir = normalize(vec3(boltX, 1.5, p.z + 2.0) - p);

        // Terrain base color - dark rock/earth
        vec3 terrainColor = vec3(0.08, 0.06, 0.05);

        // Diffuse lighting from lightning
        float diff = max(dot(n, lightDir), 0.0);
        // Rim lighting
        float rim = pow(1.0 - max(dot(n, -rd), 0.0), 3.0);

        // Illuminate terrain with lightning flash
        vec3 lightColor = vec3(0.7, 0.7, 1.0);
        vec3 lit = terrainColor * 0.02; // very dim ambient
        lit += terrainColor * diff * flashIntensity * lightColor * 0.6;
        lit += rim * flashIntensity * lightColor * 0.1;

        // Near fog blends toward the mid-layer (far hills + bolt)
        float nearDecay = 1.0 - exp(-0.2 * tNear);
        col = mix(lit, col, nearDecay);
    }

    // Letterbox
    if (abs(coord.y) > 0.75) {
        col = vec3(0.0);
    }

    // Tone mapping and grading
    col = tonemapACES(col);
    col = 1.12661 * sqrt(col) - 0.12661 * col;
    // Cool blue tint for stormy mood
    col = pow(col, vec3(1.1, 0.95, 0.8));
    col = ((vec3(0.9, 0.95, 1.2) - vec3(0.01, 0.01, 0.03)) * col) + vec3(0.01, 0.01, 0.03);
    // Vignette
    col *= (0.3 + 0.7 * pow(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.25));
    // Dither
    col = clamp(col + hash1(gl_FragCoord.xy) * 0.01, 0.0, 1.0);

    gl_FragColor = vec4(col, 1.0);
}
