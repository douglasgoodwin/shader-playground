precision mediump float;

uniform sampler2D u_texture;     // mode 0: video texture; mode 1: atlas texture
uniform vec2 u_resolution;
uniform int u_hasTexture;
uniform int u_mode;              // 0 = capture (render video to tile), 1 = display

// Display uniforms
uniform float u_writePtr;        // current write position in ring buffer
uniform float u_tileCount;       // total tiles in atlas
uniform float u_gridSize;        // atlas grid dimension (e.g. 8 for 8x8)
uniform float u_depth;           // how many tiles of delay to spread across Y

vec4 sampleTile(float tileIdx, vec2 localUV) {
    float col = mod(tileIdx, u_gridSize);
    float row = floor(tileIdx / u_gridSize);
    vec2 atlasUV = (vec2(col, row) + localUV) / u_gridSize;
    return texture2D(u_texture, atlasUV);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // Capture mode: render video into tile FBO (flip Y for GL convention)
    if (u_mode == 0) {
        gl_FragColor = texture2D(u_texture, vec2(uv.x, 1.0 - uv.y));
        return;
    }

    // Display mode
    if (u_hasTexture == 0) {
        vec2 grid = fract(uv * 20.0);
        float lines = step(0.95, grid.x) + step(0.95, grid.y);
        vec3 color = mix(vec3(0.1, 0.1, 0.15), vec3(0.3, 0.3, 0.4), lines);
        gl_FragColor = vec4(color, 1.0);
        return;
    }

    // Map Y position to time delay
    // Bottom of screen (uv.y=0) = newest frame, top (uv.y=1) = oldest
    float maxDelay = min(u_depth, u_tileCount - 1.0);
    float delayF = (1.0 - uv.y) * maxDelay;
    float d0 = floor(delayF);
    float d1 = min(d0 + 1.0, u_tileCount - 1.0);
    float blend = fract(delayF);

    // Ring buffer: writePtr is newest, writePtr-1 is one frame old, etc.
    float tile0 = mod(u_writePtr - d0 + u_tileCount, u_tileCount);
    float tile1 = mod(u_writePtr - d1 + u_tileCount, u_tileCount);

    // Sample same spatial position from different temporal tiles
    // Flip uv.y within tile to undo the capture flip
    vec2 sampleUV = vec2(uv.x, 1.0 - uv.y);
    vec4 c0 = sampleTile(tile0, sampleUV);
    vec4 c1 = sampleTile(tile1, sampleUV);

    gl_FragColor = mix(c0, c1, blend);
}
