// Glazed ceramic — smooth specular with subtle color shifts
uniform float u_time;
varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vWorldPosition;
varying vec3 vViewDir;

void main() {
    vec3 n = normalize(vNormal);
    vec3 v = normalize(vViewDir);
    vec3 l1 = normalize(vec3(0.6, 1.0, 0.4));
    vec3 l2 = normalize(vec3(-0.5, 0.3, -0.8));

    // Glaze color — shifts subtly across the surface
    float band = sin(vPosition.y * 3.0 + vPosition.x * 1.5 + u_time * 0.1) * 0.5 + 0.5;
    vec3 warmGlaze = vec3(0.92, 0.88, 0.82);   // cream
    vec3 coolGlaze = vec3(0.78, 0.82, 0.88);   // pale blue-grey
    vec3 baseColor = mix(warmGlaze, coolGlaze, band * 0.4);

    // Pooling — glaze thickens in concavities (approximated by curvature)
    float concavity = 1.0 - max(dot(n, v), 0.0);
    vec3 poolColor = vec3(0.6, 0.7, 0.75);
    baseColor = mix(baseColor, poolColor, smoothstep(0.5, 0.9, concavity) * 0.3);

    // Two-light setup for richer reflections
    float diff1 = max(dot(n, l1), 0.0);
    float diff2 = max(dot(n, l2), 0.0) * 0.3;
    float diff = diff1 + diff2;

    // Sharp glossy specular (ceramic is very smooth)
    float spec1 = pow(max(dot(reflect(-l1, n), v), 0.0), 180.0);
    float spec2 = pow(max(dot(reflect(-l2, n), v), 0.0), 80.0) * 0.4;

    // Subsurface warmth
    float sss = max(dot(-n, l1), 0.0) * 0.08;

    vec3 color = baseColor * (0.25 + diff * 0.55);
    color += vec3(1.0, 0.98, 0.95) * (spec1 + spec2);
    color += vec3(0.95, 0.85, 0.75) * sss;

    // Fresnel — subtle glaze sheen at edges
    float fresnel = pow(1.0 - max(dot(v, n), 0.0), 5.0);
    color += vec3(0.9, 0.92, 0.95) * fresnel * 0.15;

    gl_FragColor = vec4(color, 1.0);
}
