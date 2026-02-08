precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

#define MAX_STEPS 128
#define MAX_DIST 50.0
#define SURF_DIST 0.001

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdCappedCylinder(vec3 p, float h, float r) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdEllipsoid(vec3 p, vec3 r) {
    float k0 = length(p / r);
    float k1 = length(p / (r * r));
    return k0 * (k0 - 1.0) / k1;
}

mat2 rot2D(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// --- Voronoi for faceting ---
vec3 hash3(vec3 p) {
    p = vec3(
        dot(p, vec3(127.1, 311.7, 74.7)),
        dot(p, vec3(269.5, 183.3, 246.1)),
        dot(p, vec3(113.5, 271.9, 124.6))
    );
    return fract(sin(p) * 43758.5453123) - 0.5;
}

vec3 voronoiCell(vec3 p, float cellSize) {
    vec3 sp = p / cellSize;
    vec3 id = floor(sp);
    vec3 bestPos = vec3(0.0);
    float bestDist = 100.0;
    for (int x = -1; x <= 1; x++)
    for (int y = -1; y <= 1; y++)
    for (int z = -1; z <= 1; z++) {
        vec3 neighbor = id + vec3(float(x), float(y), float(z));
        vec3 site = neighbor + 0.5 + hash3(neighbor) * 0.8;
        float d = length(sp - site);
        if (d < bestDist) {
            bestDist = d;
            bestPos = site * cellSize;
        }
    }
    return bestPos;
}

float hash1(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

// Material ID: 1=pear, 2=stem
float materialId;

// Single pear shape in local coords
float pearBody(vec3 q) {
    vec3 pearBase = q - vec3(0.0, 0.55, 0.0);
    float pearBottom = sdEllipsoid(pearBase, vec3(0.5, 0.55, 0.5));
    vec3 pearTop = q - vec3(0.0, 1.25, 0.0);
    float pearTopD = sdEllipsoid(pearTop, vec3(0.32, 0.4, 0.32));
    return smin(pearBottom, pearTopD, 0.25);
}

float pearStem(vec3 q) {
    vec3 stemP = q - vec3(0.02, 1.65, 0.0);
    return sdCappedCylinder(stemP, 0.15, 0.025);
}

float mapScene(vec3 p) {
    float pear = pearBody(p);
    float stem = pearStem(p);

    float d = pear;
    materialId = 1.0;
    if (stem < d) { d = stem; materialId = 2.0; }

    return d;
}

float map(vec3 p) {
    float d = pearBody(p);
    d = min(d, pearStem(p));
    return d;
}

vec3 calcSmoothNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

vec3 calcFacetNormal(vec3 p, float cellSize) {
    vec3 cellCenter = voronoiCell(p, cellSize);
    float d = map(cellCenter);
    vec3 n = calcSmoothNormal(cellCenter);
    vec3 surfaceP = cellCenter - n * d;
    return calcSmoothNormal(surfaceP);
}

float rayMarch(vec3 ro, vec3 rd) {
    float d = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d;
        float ds = mapScene(p);
        d += ds * 0.5;
        if (d > MAX_DIST || ds < SURF_DIST) break;
    }
    return d;
}

float softShadow(vec3 ro, vec3 rd, float mint, float maxt, float k) {
    float res = 1.0;
    float t = mint;
    for (int i = 0; i < 48; i++) {
        float h = map(ro + rd * t);
        res = min(res, k * h / t);
        t += clamp(h, 0.02, 0.1);
        if (h < 0.001 || t > maxt) break;
    }
    return clamp(res, 0.0, 1.0);
}

float calcAO(vec3 p, vec3 n) {
    float occ = 0.0;
    float sca = 1.0;
    for (int i = 0; i < 5; i++) {
        float h = 0.01 + 0.12 * float(i);
        float d = map(p + h * n);
        occ += (h - d) * sca;
        sca *= 0.95;
    }
    return clamp(1.0 - 3.0 * occ, 0.0, 1.0);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;
    vec2 mouse = u_mouse / u_resolution - 0.5;
    float t = u_time * u_speed * 0.15;

    float camAngle = t * 0.3 + mouse.x * 3.14159;
    float camDist = 4.5;
    float camHeight = 1.0 + mouse.y * 2.0;

    vec3 ro = vec3(
        camDist * sin(camAngle),
        camHeight,
        camDist * cos(camAngle)
    );

    vec3 lookAt = vec3(0.0, 0.85, 0.0);
    vec3 forward = normalize(lookAt - ro);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = cross(forward, right);

    vec3 rd = normalize(uv.x * right + uv.y * up + 1.8 * forward);

    float d = rayMarch(ro, rd);

    vec3 color = vec3(0.01, 0.008, 0.005);

    if (d < MAX_DIST) {
        vec3 p = ro + rd * d;

        mapScene(p);
        float mat = materialId;

        vec3 smoothN = calcSmoothNormal(p);

        // Detail slider controls facet count
        float facetScale = mix(0.35, 0.04, clamp((u_intensity - 0.5) / 2.5, 0.0, 1.0));

        float cellSize;
        if (mat > 1.5) {
            cellSize = facetScale * 0.5;
        } else {
            cellSize = facetScale;
        }
        vec3 n = calcFacetNormal(p, cellSize);

        vec3 lightPos = vec3(-3.0, 5.0, -2.0);
        vec3 lightDir = normalize(lightPos - p);
        vec3 lightColor = vec3(1.0, 0.85, 0.6);

        float diff = dot(n, lightDir) * 0.5 + 0.5;
        diff = diff * diff;

        vec3 viewDir = normalize(ro - p);
        vec3 halfDir = normalize(lightDir + viewDir);
        float spec = pow(max(dot(n, halfDir), 0.0), 32.0);

        float ao = calcAO(p, smoothN);

        vec3 cellId = voronoiCell(p, cellSize);
        float h1 = hash1(cellId * 7.31);
        float h2 = hash1(cellId * 13.17);
        float h3 = hash1(cellId * 23.53);

        vec3 matColor;
        float specStrength = 0.3;

        if (mat < 1.5) {
            // Mottled pear: mix yellow, yellow-green, green, olive
            vec3 yellow = vec3(0.78, 0.72, 0.18);
            vec3 yellowGreen = vec3(0.62, 0.7, 0.15);
            vec3 green = vec3(0.35, 0.55, 0.12);
            vec3 olive = vec3(0.5, 0.48, 0.1);
            // Pick between colors per facet
            float pick = h1;
            if (pick < 0.35) {
                matColor = mix(yellow, yellowGreen, h2);
            } else if (pick < 0.6) {
                matColor = mix(yellowGreen, green, h2);
            } else if (pick < 0.8) {
                matColor = mix(yellow, olive, h2);
            } else {
                matColor = mix(green, olive, h2);
            }
            // Extra per-facet brightness variation
            matColor *= 0.85 + h3 * 0.3;
            specStrength = 0.3;
        } else {
            // Stem - warm brown/orange
            float sv = h1 * 0.15 - 0.075;
            matColor = vec3(0.45 + sv, 0.28 + sv * 0.5, 0.08);
            specStrength = 0.1;
        }

        vec3 ambient = 0.03 * matColor;
        vec3 diffuseLight = diff * lightColor * matColor;
        vec3 specLight = spec * specStrength * lightColor;

        color = (ambient + diffuseLight + specLight) * ao;

        vec3 fillDir = normalize(vec3(3.0, 2.0, 2.0) - p);
        float fillDiff = max(dot(n, fillDir), 0.0);
        color += fillDiff * 0.08 * vec3(0.4, 0.45, 0.6) * matColor;

        float rim = pow(1.0 - max(dot(smoothN, viewDir), 0.0), 3.0);
        color += rim * 0.03 * vec3(0.3, 0.35, 0.4);
    }

    color *= vec3(1.05, 0.95, 0.85);

    vec2 vUv = gl_FragCoord.xy / u_resolution;
    float vignette = 1.0 - 0.7 * pow(length(vUv - 0.5) * 1.4, 2.0);
    color *= vignette;

    color = pow(color, vec3(0.4545));

    gl_FragColor = vec4(color, 1.0);
}
