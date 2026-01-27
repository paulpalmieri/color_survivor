extern float threshold;
extern vec3 blobColor;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    float value = Texel(tex, tc).r;
    if (value > threshold) {
        // slight edge darkening for definition
        float edge = smoothstep(threshold, threshold + 0.1, value);
        vec3 finalColor = blobColor * (0.8 + 0.2 * edge);
        return vec4(finalColor, 1.0);
    }
    return vec4(0.0);
}
