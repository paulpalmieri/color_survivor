extern float threshold;
extern vec3 blobColor;
extern float noiseScale;
extern float noiseAmount;
extern float noiseTime;
extern float noiseEnabled;  // 1.0 = apply noise, 0.0 = clean edges

// Simplex 2D noise - Ashima (public domain)
vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439,
                        -0.577350269189626, 0.024390243902439);
    vec2 i  = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod(i, 289.0);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0))
                   + i.x + vec3(0.0, i1.x, 1.0));
    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
                            dot(x12.zw,x12.zw)), 0.0);
    m = m*m; m = m*m;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0*a0 + h*h);
    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    float value = Texel(tex, tc).r;

    // Convert texture coords to centered polar coordinates
    vec2 centered = tc - 0.5;
    float angle = atan(centered.y, centered.x);
    float dist = length(centered);

    // Use screen position as seed for per-entity variation
    float seed = sc.x * noiseScale + sc.y * noiseScale * 1.7;

    // Angular noise - sample based on angle to create star/amoeba shapes
    // Higher frequency (angle * 3.0) = more "spikes", seed gives per-entity uniqueness
    float angularNoise = snoise(vec2(angle * 3.0 + seed, seed + noiseTime * 0.2));

    // Second layer of angular noise at different frequency for more organic feel
    float angularNoise2 = snoise(vec2(angle * 5.0 - seed * 0.5, noiseTime * 0.15)) * 0.5;

    // Combine angular noises - this creates the irregular shape
    float shapeNoise = (angularNoise + angularNoise2) * noiseAmount * noiseEnabled;

    // Apply more distortion near the edges where it matters
    shapeNoise *= (0.3 + dist * 1.4);

    // Distort threshold with noise for organic edges
    float noisyThreshold = threshold + shapeNoise;

    // Anti-aliased edge using smoothstep
    float edgeWidth = 0.04;
    float alpha = smoothstep(noisyThreshold - edgeWidth, noisyThreshold + edgeWidth, value);

    if (alpha > 0.0) {
        // Slight edge darkening for definition
        float edge = smoothstep(noisyThreshold, noisyThreshold + 0.15, value);
        vec3 finalColor = blobColor * (0.85 + 0.15 * edge);
        return vec4(finalColor, alpha);
    }
    return vec4(0.0);
}
