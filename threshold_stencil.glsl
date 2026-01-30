// Stencil version of threshold shader - outputs opaque white for stencil writing
extern float threshold;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    float value = Texel(tex, tc).r;

    // Anti-aliased edge for smoother stencil
    float edgeWidth = 0.04;
    float alpha = smoothstep(threshold - edgeWidth, threshold + edgeWidth, value);

    if (alpha > 0.5) {
        return vec4(1.0, 1.0, 1.0, 1.0);  // Opaque white for stencil
    }
    discard;
}
