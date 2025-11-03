shader_type spatial;
render_mode unshaded;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_nearest;

void fragment() {
    float d = texture(DEPTH_TEXTURE, SCREEN_UV).r;
    ALBEDO = vec3(d, d, d);
}
