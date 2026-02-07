// Sand Terrain - Adapted from Shane's "Desert Sand" (Shadertoy)
// Slow circular pan over procedural sand dunes with wavy ripple texture

precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;
uniform float u_camHeight;

#define FAR 80.

mat2 rot2(float a) { float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

float hash(vec3 p) { return fract(sin(dot(p, vec3(21.71, 157.97, 113.43))) * 45758.5453); }

// 2D noise
float n2D(vec2 p) {
    vec2 i = floor(p); p -= i;
    p *= p * (3. - p * 2.);
    return dot(mat2(fract(sin(mod(vec4(0, 1, 113, 114) + dot(i, vec2(1, 113)), 6.2831853)) *
               43758.5453)) * vec2(1. - p.y, p.y), vec2(1. - p.x, p.x));
}

// Hash for gradient noise
vec2 hash22(vec2 p) {
    float n = sin(dot(p, vec2(113, 1)));
    return fract(vec2(2097152, 262144) * n) * 2. - 1.;
}

// Gradient noise
float gradN2D(vec2 f) {
    const vec2 e = vec2(0, 1);
    vec2 p = floor(f);
    f -= p;
    vec2 w = f * f * (3. - 2. * f);
    float c = mix(mix(dot(hash22(p + e.xx), f - e.xx), dot(hash22(p + e.yx), f - e.yx), w.x),
                  mix(dot(hash22(p + e.xy), f - e.xy), dot(hash22(p + e.yy), f - e.yy), w.x), w.y);
    return c * .5 + .5;
}

// 3D noise
float n3D(vec3 p) {
    const vec3 s = vec3(113, 157, 1);
    vec3 ip = floor(p); p -= ip;
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p * p * (3. - 2. * p);
    h = mix(fract(sin(h) * 43758.5453), fract(sin(h + s.x) * 43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z);
}

float fBm3(vec3 p) { return n3D(p) * .57 + n3D(p * 2.) * .28 + n3D(p * 4.) * .15; }

// Repeat gradient lines for sand ripples
float grad(float x, float offs) {
    x = abs(fract(x / 6.283 + offs - .25) - .5) * 2.;
    float x2 = clamp(x * x * (-1. + 2. * x), 0., 1.);
    x = smoothstep(0., 1., x);
    return mix(x, x2, .15);
}

// One sand ripple layer
float sandL(vec2 p) {
    vec2 q = rot2(3.14159 / 18.) * p;
    q.y += (gradN2D(q * 18.) - .5) * .05;
    float grad1 = grad(q.y * 80., 0.);

    q = rot2(-3.14159 / 20.) * p;
    q.y += (gradN2D(q * 12.) - .5) * .05;
    float grad2 = grad(q.y * 80., .5);

    q = rot2(3.14159 / 4.) * p;
    float a2 = dot(sin(q * 12. - cos(q.yx * 12.)), vec2(.25)) + .5;
    float a1 = 1. - a2;
    return 1. - (1. - grad1 * a1) * (1. - grad2 * a2);
}

float gT; // global distance for Moire suppression

float sand(vec2 p) {
    p = vec2(p.y - p.x, p.x + p.y) * .7071 / 4.;
    float c1 = sandL(p);
    vec2 q = rot2(3.14159 / 12.) * p;
    float c2 = sandL(q * 1.25);
    c1 = mix(c1, c2, smoothstep(.1, .9, gradN2D(p * vec2(4))));
    return c1 / (1. + gT * gT * .015);
}

// Dune height function
float surfFunc(vec3 p) {
    p /= 2.5;
    float layer1 = n2D(p.xz * .2) * 2. - .5;
    layer1 = smoothstep(0., 1.05, layer1);
    float layer2 = n2D(p.xz * .275);
    layer2 = 1. - abs(layer2 - .5) * 2.;
    layer2 = smoothstep(.2, 1., layer2 * layer2);
    float layer3 = n2D(p.xz * 1.5);
    return layer1 * .7 + layer2 * .25 + layer3 * .05;
}

float camSurfFunc(vec3 p) {
    p /= 2.5;
    float layer1 = n2D(p.xz * .2) * 2. - .5;
    layer1 = smoothstep(0., 1.05, layer1);
    float layer2 = n2D(p.xz * .275);
    layer2 = 1. - abs(layer2 - .5) * 2.;
    layer2 = smoothstep(.2, 1., layer2 * layer2);
    return (layer1 * .7 + layer2 * .25) / .95;
}

float map(vec3 p) {
    float sf = surfFunc(p);
    return p.y + (.5 - sf) * 2. * u_scale;
}

float trace(vec3 ro, vec3 rd) {
    float t = 0., h;
    for (int i = 0; i < 96; i++) {
        h = map(ro + rd * t);
        if (abs(h) < .001 * (t * .125 + 1.) || t > FAR) break;
        t += h;
    }
    return min(t, FAR);
}

vec3 normal(vec3 p) {
    vec2 e = vec2(.001, 0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

// Sand bump mapping
float bumpSurf3D(vec3 p) {
    float n = surfFunc(p);
    float nx = surfFunc(p + vec3(.001, 0, 0));
    float nz = surfFunc(p + vec3(0, 0, .001));
    return sand(p.xz + vec2(n - nx, n - nz) / .001);
}

vec3 doBumpMap(vec3 p, vec3 nor, float bf) {
    const vec2 e = vec2(0.001, 0);
    float ref = bumpSurf3D(p);
    vec3 g = (vec3(bumpSurf3D(p - e.xyy),
                   bumpSurf3D(p - e.yxy),
                   bumpSurf3D(p - e.yyx)) - ref) / e.x;
    g -= nor * dot(nor, g);
    return normalize(nor + g * bf);
}

float softShadow(vec3 ro, vec3 lp, float k, float t) {
    vec3 rd = lp - ro;
    float shade = 1.;
    float dist = 0.002;
    float end = max(length(rd), .0001);
    rd /= end;
    for (int i = 0; i < 24; i++) {
        float h = map(ro + rd * dist);
        shade = min(shade, k * h / dist);
        h = clamp(h, .1, .5);
        dist += h;
        if (shade < .001 || dist > end) break;
    }
    return min(max(shade, 0.) + .05, 1.);
}

float calcAO(vec3 p, vec3 n) {
    float ao = 0.;
    for (float i = 1.; i < 6.; i++) {
        float l = i * .5 / 5. * 4.;
        ao += (l - map(p + n * l));
    }
    return clamp(1. - ao / 5., 0., 1.);
}

vec3 getSky(vec3 ro, vec3 rd, vec3 ld) {
    vec3 col = vec3(.8, .7, .5), col2 = vec3(.4, .6, .9);
    vec3 sky = mix(col, col2, pow(max(rd.y + .15, 0.), .5));
    sky *= vec3(.84, 1, 1.17);
    float sun = clamp(dot(ld, rd), 0., 1.);
    sky += vec3(1, .7, .4) * pow(sun, 16.) * .2;
    sun = pow(sun, 32.);
    sky += vec3(1, .9, .6) * pow(sun, 32.) * .35;
    return sky;
}

void main() {
    vec2 u = (gl_FragCoord.xy - u_resolution.xy * .5) / u_resolution.y;

    float t_anim = u_time * u_speed * 0.4;

    // Circular panning camera
    float orbitRadius = 12.;
    float cx = sin(t_anim) * orbitRadius;
    float cz = cos(t_anim) * orbitRadius;

    vec3 ro = vec3(cx, 1.2 + u_camHeight, cz);

    // Look toward center offset by a lead angle for smooth panning feel
    float lookAhead = t_anim + 0.6;
    vec3 lookAt = vec3(sin(lookAhead) * orbitRadius * 0.5, 0.8 + u_camHeight * 0.5, cos(lookAhead) * orbitRadius * 0.5);

    // Raise camera with terrain
    float sfH = camSurfFunc(ro);
    ro.y += sfH;
    lookAt.y += camSurfFunc(lookAt);

    // Camera
    float FOV = 3.14159265 / 2.5;
    vec3 forward = normalize(lookAt - ro);
    vec3 right = normalize(vec3(forward.z, 0, -forward.x));
    vec3 up = cross(forward, right);
    vec3 rd = normalize(forward + FOV * u.x * right + FOV * u.y * up);

    // Sun
    vec3 lp = vec3(FAR * .25, FAR * .25, FAR) + vec3(0, 0, ro.z);

    // Raymarch
    float t = trace(ro, rd);
    gT = t;

    vec3 col = vec3(0);
    vec3 sp = ro + t * rd;

    if (t < FAR) {
        vec3 sn = normal(sp);
        vec3 ld = lp - sp;
        float lDist = max(length(ld), .001);
        ld /= lDist;
        lDist /= FAR;
        float atten = 1. / (1. + lDist * lDist * .025);

        sn = doBumpMap(sp, sn, .07);

        float sh = softShadow(sp + sn * .002, lp, 6., t);
        float ao = calcAO(sp, sn);
        sh = min(sh + ao * .25, 1.);

        float dif = max(dot(ld, sn), 0.);
        float spe = pow(max(dot(reflect(-ld, sn), -rd), 0.), 5.);
        float fre = clamp(1. + dot(rd, sn), 0., 1.);
        float Schlick = pow(1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
        float fre2 = mix(.2, 1., Schlick);
        float amb = ao * .35;

        // Sand color with subtle variation
        col = mix(vec3(1, .95, .7), vec3(.9, .6, .4), fBm3(vec3(sp.xz * 16., 0.)));
        col = mix(col * 1.4, col * .6, fBm3(vec3(sp.xz * 32. - .5, 0.)));

        // Crevice darkening from sand ripples
        float bSurf = bumpSurf3D(sp);
        col *= bSurf * .75 + .5;

        // Sand sparkle
        col = mix(col * .7 + (hash(floor(sp * 96.)) * .7 + hash(floor(sp * 192.)) * .3) * .3, col, min(t * t / FAR, 1.));
        col *= vec3(1.2, 1, .9);

        col = col * (dif + amb + vec3(1, .97, .92) * fre2 * spe * 2.) * atten;

        // Sky reflection
        vec3 gLD = normalize(lp - vec3(0, 0, ro.z));
        vec3 refSky = getSky(sp, reflect(rd, sn), gLD);
        col += col * refSky * .05 + refSky * fre * fre2 * atten * .15;

        col *= sh * ao;
    }

    // Fog blend to sky
    vec3 gLD = normalize(lp - vec3(0, 0, ro.z));
    vec3 sky = getSky(ro, rd, gLD);
    col = mix(col, sky, smoothstep(0., .95, t / FAR));

    // Sun scatter
    col += vec3(1., .6, .2) * pow(max(dot(rd, gLD), 0.), 16.) * .45 * u_intensity;

    // Dusty haze
    vec3 mistCol = vec3(1, .95, .9);
    float dust = max(n3D(sp * .1) * .3, 0.);
    col = col * .75 + (col + .25 * vec3(1.2, 1, .9)) * mistCol * dust * 1.5;

    // Vignette
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    col = min(col, 1.) * pow(16. * uv.x * uv.y * (1. - uv.x) * (1. - uv.y), .0625);

    // Gamma
    gl_FragColor = vec4(sqrt(clamp(col, 0., 1.)), 1);
}
