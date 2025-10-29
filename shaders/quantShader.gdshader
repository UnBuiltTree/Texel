shader_type canvas_item;

// All this shader does is snap all the colors into set values ~UnBuilt
// PostProcess effect

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform float LEVELS_H = 16.0; // hue steps
uniform float LEVELS_V = 16.0; // value steps
const float EPSILON = 0.0001;

vec3 rgb_to_hsv(vec3 c) {
    float maxc = max(max(c.r, c.g), c.b);
    float minc = min(min(c.r, c.g), c.b);
    float delta = maxc - minc;

    float h = 0.0;
    if (delta > EPSILON) {
        if (abs(maxc - c.r) < EPSILON)
            h = mod((c.g - c.b) / delta, 6.0);
        else if (abs(maxc - c.g) < EPSILON)
            h = ((c.b - c.r) / delta) + 2.0;
        else
            h = ((c.r - c.g) / delta) + 4.0;
    }
    h /= 6.0;

    float s = (maxc < EPSILON) ? 0.0 : delta / maxc;
    return vec3(h, s, maxc);
}

vec3 hsv_to_rgb(vec3 hsv) {
    float h = hsv.x;
    float s = hsv.y;
    float v = hsv.z;

    float region = floor(h * 6.0);
    float f = fract(h * 6.0);

    float p = v * (1.0 - s);
    float q = v * (1.0 - f * s);
    float t = v * (1.0 - (1.0 - f) * s);

    if (region < 1.0) return vec3(v, t, p);
    if (region < 2.0) return vec3(q, v, p);
    if (region < 3.0) return vec3(p, v, t);
    if (region < 4.0) return vec3(p, q, v);
    if (region < 5.0) return vec3(t, p, v);
    return vec3(v, p, q);
}

void fragment() {
    vec3 c = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;

    vec3 hsv = rgb_to_hsv(c);

    // quantize
    hsv.x = floor(hsv.x * LEVELS_H) / LEVELS_H;
    hsv.z = floor(hsv.z * LEVELS_V) / LEVELS_V;

    vec3 outc = hsv_to_rgb(hsv);
    COLOR = vec4(outc, 1.0);
}
