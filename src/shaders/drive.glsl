// Rainy Night Drive - adapted from Shadertoy by BigWIngs
// Bokeh city lights through a rain-covered windshield

precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform vec3 u_ripples[10];
uniform vec3 u_rippleColors[10];
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;

#define S(x, y, z) smoothstep(x, y, z)
#define B(a, b, edge, t) S(a-edge, a+edge, t)*S(b+edge, b-edge, t)
#define sat(x) clamp(x, 0., 1.)

#define streetLightCol vec3(1., .7, .3)
#define headLightCol vec3(.8, .8, 1.)
#define tailLightCol vec3(1., .1, .1)

#define CAM_SHAKE 1.
#define LANE_BIAS .5

vec3 ro, rd;

float N(float t) {
    return fract(sin(t * 10234.324) * 123423.23512);
}

vec3 N31(float p) {
    vec3 p3 = fract(vec3(p) * vec3(.1031, .11369, .13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract(vec3((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x));
}

float DistLine(vec3 ro, vec3 rd, vec3 p) {
    return length(cross(p - ro, rd));
}

vec3 ClosestPoint(vec3 ro, vec3 rd, vec3 p) {
    return ro + max(0., dot(p - ro, rd)) * rd;
}

float Remap(float a, float b, float c, float d, float t) {
    return ((t - a) / (b - a)) * (d - c) + c;
}

float BokehMask(vec3 ro, vec3 rd, vec3 p, float size, float blur) {
    float d = DistLine(ro, rd, p);
    float m = S(size, size * (1. - blur), d);
    m *= mix(.7, 1., S(.8 * size, size, d));
    return m;
}

float SawTooth(float t) {
    return cos(t + cos(t)) + sin(2. * t) * .2 + sin(4. * t) * .02;
}

float DeltaSawTooth(float t) {
    return 0.4 * cos(2. * t) + 0.08 * cos(4. * t) - (1. - sin(t)) * sin(t + cos(t));
}

vec2 GetDrops(vec2 uv, float seed, float m, float t) {
    t = t + m * 30.;
    vec2 o = vec2(0.);

    uv.y += t * .05;
    uv *= vec2(10., 2.5) * 2. * u_scale;

    vec2 id = floor(uv);
    vec3 n = N31(id.x + (id.y + seed) * 546.3524);
    vec2 bd = fract(uv);

    bd -= .5;
    bd.y *= 4.;
    bd.x += (n.x - .5) * .6;

    float tt = t + n.z * 6.28;
    float slide = SawTooth(tt);

    float ts = 1.5;
    vec2 trailPos = vec2(bd.x * ts, (fract(bd.y * ts * 2. - t * 2.) - .5) * .5);

    bd.y += slide * 2.;

    float dropShape = bd.x * bd.x;
    dropShape *= DeltaSawTooth(tt);
    bd.y += dropShape;

    float d = length(bd);

    float trailMask = S(-.2, .2, bd.y);
    trailMask *= bd.y;
    float td = length(trailPos * max(.5, trailMask));

    float mainDrop = S(.2, .1, d);
    float dropTrail = S(.1, .02, td);

    dropTrail *= trailMask;
    o = mix(bd * mainDrop, trailPos, dropTrail);

    return o;
}

void CameraSetup(vec2 uv, vec3 pos, vec3 lookat, float zoom, float m, float t) {
    ro = pos;
    vec3 f = normalize(lookat - ro);
    vec3 r = cross(vec3(0., 1., 0.), f);
    vec3 u = cross(f, r);

    vec2 offs = vec2(0.);

    // Rain drops
    vec2 dropUv = uv;
    float x = (sin(t * .1) * .5 + .5) * .5;
    x = -x * x;
    float s = sin(x);
    float c = cos(x);
    mat2 rot = mat2(c, -s, s, c);

    dropUv = uv * rot;
    dropUv.x += -sin(t * .1) * .5;

    offs = GetDrops(dropUv, 1., m, t);
    offs += GetDrops(dropUv * 1.4, 10., m, t);
    offs += GetDrops(dropUv * 2.4, 25., m, t);

    // Ripple effect
    float ripple = sin(t + uv.y * 3.1415 * 30. + uv.x * 124.) * .5 + .5;
    ripple *= .005 * u_intensity;
    offs += vec2(ripple * ripple, ripple);

    vec3 center = ro + f * zoom;
    vec3 i = center + (uv.x - offs.x) * r + (uv.y - offs.y) * u;

    rd = normalize(i - ro);
}

vec3 HeadLights(float i, float t) {
    float z = fract(-t * 2. + i);
    vec3 p = vec3(-.3, .1, z * 40.);
    float d = length(p - ro);

    float size = mix(.03, .05, S(.02, .07, z)) * d;
    float m = 0.;
    float blur = .1;
    m += BokehMask(ro, rd, p - vec3(.08, 0., 0.), size, blur);
    m += BokehMask(ro, rd, p + vec3(.08, 0., 0.), size, blur);
    m += BokehMask(ro, rd, p + vec3(.1, 0., 0.), size, blur);
    m += BokehMask(ro, rd, p - vec3(.1, 0., 0.), size, blur);

    float distFade = max(.01, pow(1. - z, 9.));

    blur = .8;
    size *= 2.5;
    float r = 0.;
    r += BokehMask(ro, rd, p + vec3(-.09, -.2, 0.), size, blur);
    r += BokehMask(ro, rd, p + vec3(.09, -.2, 0.), size, blur);
    r *= distFade * distFade;

    return headLightCol * (m + r) * distFade * u_intensity;
}

vec3 TailLights(float i, float t) {
    t = t * 1.5 + i;

    float id = floor(t) + i;
    vec3 n = N31(id);

    float laneId = S(LANE_BIAS, LANE_BIAS + .01, n.y);
    float ft = fract(t);
    float z = 3. - ft * 3.;

    laneId *= S(.2, 1.5, z);
    float lane = mix(.6, .3, laneId);
    vec3 p = vec3(lane, .1, z);
    float d = length(p - ro);

    float size = .05 * d;
    float blur = .1;
    float m = BokehMask(ro, rd, p - vec3(.08, 0., 0.), size, blur) +
              BokehMask(ro, rd, p + vec3(.08, 0., 0.), size, blur);

    float bs = n.z * 3.;
    float brake = S(bs, bs + .01, z);
    brake *= S(bs + .01, bs, z - .5 * n.y);

    m += (BokehMask(ro, rd, p + vec3(.1, 0., 0.), size, blur) +
          BokehMask(ro, rd, p - vec3(.1, 0., 0.), size, blur)) * brake;

    float refSize = size * 2.5;
    m += BokehMask(ro, rd, p + vec3(-.09, -.2, 0.), refSize, .8);
    m += BokehMask(ro, rd, p + vec3(.09, -.2, 0.), refSize, .8);
    vec3 col = tailLightCol * m * ft;

    float b = BokehMask(ro, rd, p + vec3(.12, 0., 0.), size, blur);
    b += BokehMask(ro, rd, p + vec3(.12, -.2, 0.), refSize, .8) * .2;

    vec3 blinker = vec3(1., .7, .2);
    blinker *= S(1.5, 1.4, z) * S(.2, .3, z);
    blinker *= sat(sin(t * 200.) * 100.);
    blinker *= laneId;
    col += blinker * b;

    return col * u_intensity;
}

vec3 StreetLights(float i, float t) {
    float side = sign(rd.x);
    float offset = max(side, 0.) * (1. / 16.);
    float z = fract(i - t + offset);
    vec3 p = vec3(2. * side, 2., z * 60.);
    float d = length(p - ro);
    float blur = .1;
    float distFade = Remap(1., .7, .1, 1.5, 1. - pow(1. - z, 6.));
    distFade *= (1. - z);
    float m = BokehMask(ro, rd, p, .05 * d, blur) * distFade;

    return m * streetLightCol * u_intensity;
}

vec3 EnvironmentLights(float i, float t) {
    float n = N(i + floor(t));

    float side = sign(rd.x);
    float offset = max(side, 0.) * (1. / 16.);
    float z = fract(i - t + offset + fract(n * 234.));
    float n2 = fract(n * 100.);
    vec3 p = vec3((3. + n) * side, n2 * n2 * n2 * 1., z * 60.);
    float d = length(p - ro);
    float blur = .1;
    float distFade = Remap(1., .7, .1, 1.5, 1. - pow(1. - z, 6.));
    float m = BokehMask(ro, rd, p, .05 * d, blur);
    m *= distFade * distFade * .5;

    m *= 1. - pow(sin(z * 6.28 * 20. * n) * .5 + .5, 20.);
    vec3 randomCol = vec3(fract(n * -34.5), fract(n * 4572.), fract(n * 1264.));
    vec3 col = mix(tailLightCol, streetLightCol, fract(n * -65.42));
    col = mix(col, randomCol, n);
    return m * col * .2 * u_intensity;
}

void main() {
    float t = u_time * u_speed;
    vec3 col = vec3(0.);
    vec2 uv = gl_FragCoord.xy / u_resolution;

    uv -= .5;
    uv.x *= u_resolution.x / u_resolution.y;

    vec2 mouse = u_mouse / u_resolution;

    vec3 pos = vec3(.3, .15, 0.);

    float bt = t * 5.;
    float h1 = N(floor(bt));
    float h2 = N(floor(bt + 1.));
    float bumps = mix(h1, h2, fract(bt)) * .1;
    bumps = bumps * bumps * bumps * CAM_SHAKE;

    pos.y += bumps;
    float lookatY = pos.y + bumps;
    vec3 lookat = vec3(0.3, lookatY, 1.);
    vec3 lookat2 = vec3(0., lookatY, .7);
    lookat = mix(lookat, lookat2, sin(t * .1) * .5 + .5);

    uv.y += bumps * 4.;
    CameraSetup(uv, pos, lookat, 2., mouse.x, t);

    float tt = t * .03;
    tt += mouse.x;

    // Street lights
    for (float i = 0.; i < 1.; i += 0.125) {
        col += StreetLights(i, tt);
    }

    // Headlights
    for (float i = 0.; i < 1.; i += 0.125) {
        float n = N(i + floor(tt));
        col += HeadLights(i + n * 0.125 * .7, tt);
    }

    // Environment lights
    for (float i = 0.; i < 1.; i += 0.0625) {
        col += EnvironmentLights(i, tt);
    }

    // Tail lights
    col += TailLights(0., tt);
    col += TailLights(.5, tt);

    // Sky gradient
    col += sat(rd.y) * vec3(.6, .5, .9) * 0.5;

    gl_FragColor = vec4(col, 1.);
}
