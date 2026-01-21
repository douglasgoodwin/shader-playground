precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_speed;
uniform float u_intensity;
uniform float u_scale;
uniform sampler2D u_fontAtlas;
uniform float u_numChars;

#define MAX_STEPS 80
#define MAX_DIST 40.0
#define SURF_DIST 0.002

// ============================================================
// 6D SHAPE VECTORS - Must match JavaScript font atlas order
// Characters: ' .'-|/\_iczu1UBMW@#' (19 chars)
// ============================================================

// Sample character from font atlas
float sampleChar(int charIdx, vec2 uv) {
    float col = float(charIdx);
    // Flip Y because WebGL textures have Y=0 at bottom, Canvas has Y=0 at top
    vec2 charUV = vec2((col + uv.x) / u_numChars, 1.0 - uv.y);
    return texture2D(u_fontAtlas, charUV).r;
}

// ============================================================
// 3D GEOMETRY
// ============================================================

mat2 rot2D(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

// Scene: Single rotating cube for clear face demonstration
vec3 cubePos;
mat2 cubeRotXZ;
mat2 cubeRotXY;

float map(vec3 p) {
    float t = u_time * u_speed * 0.3;

    // Store transformations for UV calculation
    cubeRotXZ = rot2D(t);
    cubeRotXY = rot2D(t * 0.7);

    // Transform point into cube's local space
    vec3 localP = p;
    localP.xz *= cubeRotXZ;
    localP.xy *= cubeRotXY;

    float cubeSize = 1.5 * u_scale;
    return sdBox(localP, vec3(cubeSize));
}

vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

float rayMarch(vec3 ro, vec3 rd) {
    float d = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d;
        float ds = map(p);
        d += ds;
        if (d > MAX_DIST || ds < SURF_DIST) break;
    }
    return d;
}

// Inverse rotation (transpose of rotation matrix)
mat2 inv2D(mat2 m) {
    return mat2(m[0][0], m[1][0], m[0][1], m[1][1]);
}

// Get UV coordinates on the face - SCREEN ALIGNED (characters stay upright)
vec2 getFaceUV(vec3 p, vec3 n, vec3 ro, vec3 right, vec3 up) {
    float cubeSize = 1.5 * u_scale;

    // Transform to local space to find which face
    vec3 localN = n;
    localN.xz *= cubeRotXZ;
    localN.xy *= cubeRotXY;

    // Find face center in local space
    vec3 absN = abs(localN);
    vec3 faceCenter;

    if (absN.x > absN.y && absN.x > absN.z) {
        faceCenter = vec3(sign(localN.x) * cubeSize, 0.0, 0.0);
    } else if (absN.y > absN.z) {
        faceCenter = vec3(0.0, sign(localN.y) * cubeSize, 0.0);
    } else {
        faceCenter = vec3(0.0, 0.0, sign(localN.z) * cubeSize);
    }

    // Transform face center back to world space (inverse rotations)
    faceCenter.xy *= inv2D(cubeRotXY);
    faceCenter.xz *= inv2D(cubeRotXZ);

    // Calculate offset from face center in world space
    vec3 offset = p - faceCenter;

    // Project offset onto screen-aligned axes (right and up vectors)
    float u = dot(offset, right) / cubeSize;
    float v = dot(offset, up) / cubeSize;

    // Map to 0-1 range
    vec2 uv = vec2(u, v) * 0.5 + 0.5;

    return uv;
}

// Get a character index based on the face
// Using indices that match the font atlas: ' .'-|/\_iczu1UBMW@#'
int getFaceChar(vec3 n) {
    // Transform normal to local space
    vec3 localN = n;
    localN.xz *= cubeRotXZ;
    localN.xy *= cubeRotXY;

    vec3 absN = abs(localN);

    // Assign different characters to each face
    // Index 15=M, 16=W, 14=B, 13=U, 17=@, 18=#
    if (absN.x > absN.y && absN.x > absN.z) {
        return localN.x > 0.0 ? 15 : 16; // M or W
    } else if (absN.y > absN.z) {
        return localN.y > 0.0 ? 17 : 18; // @ or #
    } else {
        return localN.z > 0.0 ? 13 : 14; // U or B
    }
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;

    vec2 mouse = u_mouse / u_resolution - 0.5;
    float t = u_time * u_speed;

    // Camera
    vec3 ro = vec3(0.0, 0.0, -5.0);
    ro.xz *= rot2D(mouse.x * 3.14159);
    ro.y += mouse.y * 3.0;

    vec3 lookAt = vec3(0.0);
    vec3 forward = normalize(lookAt - ro);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = cross(forward, right);

    vec3 rd = normalize(uv.x * right + uv.y * up + 1.5 * forward);

    // Raymarch
    float d = rayMarch(ro, rd);

    vec3 color = vec3(0.02, 0.02, 0.04); // Background

    if (d < MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = calcNormal(p);

        // Get face UV (screen-aligned so characters stay upright)
        vec2 faceUV = getFaceUV(p, n, ro, right, up);

        // Get character for this face
        int charIdx = getFaceChar(n);

        // Render the character from font atlas
        float pixel = sampleChar(charIdx, faceUV);

        // Lighting
        vec3 lightDir = normalize(vec3(1.0, 1.0, -1.0));
        float diff = max(dot(n, lightDir), 0.0);
        float ambient = 0.2;

        // Rim lighting
        vec3 viewDir = normalize(ro - p);
        float rim = 1.0 - max(dot(viewDir, n), 0.0);
        rim = pow(rim, 3.0) * 0.3;

        // Face color based on normal (for variety)
        vec3 faceColor = vec3(0.2, 0.9, 0.5); // Base green

        vec3 localN = n;
        localN.xz *= cubeRotXZ;
        localN.xy *= cubeRotXY;
        vec3 absN = abs(localN);

        if (absN.x > absN.y && absN.x > absN.z) {
            faceColor = vec3(0.9, 0.3, 0.4); // Red-ish for X faces
        } else if (absN.y > absN.z) {
            faceColor = vec3(0.3, 0.8, 0.9); // Cyan for Y faces
        } else {
            faceColor = vec3(0.9, 0.8, 0.3); // Yellow for Z faces
        }

        float lighting = (ambient + diff * 0.8 + rim) * u_intensity;
        color = pixel * faceColor * lighting;

        // Edge highlight
        float edge = 1.0 - smoothstep(0.0, 0.05, min(min(faceUV.x, faceUV.y), min(1.0 - faceUV.x, 1.0 - faceUV.y)));
        color += edge * faceColor * 0.3;
    }

    // Subtle vignette
    float vignette = 1.0 - length(uv) * 0.3;
    color *= vignette;

    gl_FragColor = vec4(color, 1.0);
}
