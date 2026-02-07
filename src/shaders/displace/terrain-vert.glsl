attribute vec3 a_position;
attribute vec2 a_uv;

uniform mat4 u_mvp;
uniform float u_time;
uniform float u_displacement;
uniform float u_noiseScale;
uniform float u_speed;

varying vec2 v_uv;
varying vec3 v_normal;
varying float v_height;

// --- Simplex 3D noise ---

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

float fbm(vec3 p) {
    return 0.5333333 * simplex3d(p)
         + 0.2666667 * simplex3d(2.0 * p)
         + 0.1333333 * simplex3d(4.0 * p)
         + 0.0666667 * simplex3d(8.0 * p);
}

float getHeight(vec3 p) {
    return fbm(p) * u_displacement;
}

void main() {
    vec3 pos = a_position;
    float t = u_time * u_speed;

    // Noise sample point
    vec3 noisePos = vec3(pos.x * u_noiseScale, t, pos.z * u_noiseScale);

    // Displace Y
    float h = getHeight(noisePos);
    pos.y = h;

    // Compute normal via finite differences
    float eps = 0.01;
    float hx = getHeight(noisePos + vec3(eps, 0.0, 0.0));
    float hz = getHeight(noisePos + vec3(0.0, 0.0, eps));
    vec3 normal = normalize(vec3(h - hx, eps * u_noiseScale, h - hz));

    v_uv = a_uv;
    v_normal = normal;
    v_height = h;

    gl_Position = u_mvp * vec4(pos, 1.0);
}
