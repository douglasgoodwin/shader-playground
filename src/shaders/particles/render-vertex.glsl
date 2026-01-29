// Render vertex shader - positions particles from texture data
attribute vec2 a_texCoord;

uniform sampler2D u_positionTex;
uniform sampler2D u_velocityTex;
uniform vec2 u_resolution;
uniform float u_pointSize;

varying vec3 v_velocity;
varying vec2 v_velocity2D;
varying float v_depth;

vec3 decodePosition(vec4 texel) {
    return (texel.rgb - 0.5) * 4.0;
}

vec3 decodeVelocity(vec4 texel) {
    return (texel.rgb - 0.5) * 2.0;
}

void main() {
    vec4 posTex = texture2D(u_positionTex, a_texCoord);
    vec4 velTex = texture2D(u_velocityTex, a_texCoord);

    vec3 pos = decodePosition(posTex);
    v_velocity = decodeVelocity(velTex);

    // Simple perspective projection
    float fov = 2.0;
    float z = pos.z + 3.0; // Camera distance
    vec2 projected = pos.xy / (z / fov);

    // Aspect ratio correction
    float aspect = u_resolution.x / u_resolution.y;
    projected.x /= aspect;

    v_depth = z;

    // Compute 2D velocity direction for triangle orientation
    vec2 vel2D = v_velocity.xy;
    vel2D.x /= aspect; // Match aspect correction
    v_velocity2D = length(vel2D) > 0.001 ? normalize(vel2D) : vec2(0.0, 1.0);

    gl_Position = vec4(projected, 0.0, 1.0);

    // Size based on depth and velocity
    float speed = length(v_velocity);
    float baseSize = u_pointSize * (3.0 / z);
    gl_PointSize = baseSize * (0.8 + speed * 0.5);
}
