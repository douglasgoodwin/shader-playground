// Soap-bubble / oil-slick thin-film iridescence
uniform float u_time;
varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vViewDir;

void main() {
    vec3 n = normalize(vNormal);
    vec3 v = normalize(vViewDir);
    vec3 l = normalize(vec3(0.4, 1.0, 0.6));

    float fresnel = 1.0 - max(dot(v, n), 0.0);
    float thin = fresnel * 6.0 + dot(vPosition, n) * 2.0 + u_time * 0.3;

    // Thin-film interference — three shifted cosines for RGB
    vec3 film;
    film.r = 0.5 + 0.5 * cos(thin * 6.2832);
    film.g = 0.5 + 0.5 * cos(thin * 6.2832 + 2.094);
    film.b = 0.5 + 0.5 * cos(thin * 6.2832 + 4.189);

    // Stronger at glancing angles
    film = mix(vec3(0.95), film, smoothstep(0.0, 0.6, fresnel));

    // Lighting
    float diff = max(dot(n, l), 0.0);
    float spec = pow(max(dot(reflect(-l, n), v), 0.0), 120.0);

    vec3 color = film * (0.35 + diff * 0.5);
    color += vec3(1.0) * spec * 0.7;
    color += film * pow(fresnel, 3.0) * 0.3;

    gl_FragColor = vec4(color, 1.0);
}
