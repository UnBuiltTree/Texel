shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D TEX : filter_nearest, source_color;

uniform bool TRIPLANAR = true;
uniform bool PIXEL_SCALE_TEXELS = false;

uniform float TEXTURE_BIAS : hint_range(-0.1, 0) = 0.0;
uniform float LIGHT_BIAS   : hint_range(-0.1, 0) = -0.061;

uniform float TEXEL_SIZE : hint_range(0.001, 10.0) = 0.0625;
uniform float TEXTURE_SCALE : hint_range(0.01, 10.0) = 0.25;

varying vec3 local_pos_v;
varying vec3 normal_v;

vec3 sample_face_aligned(vec3 p, vec3 normal) {
    vec2 ts = vec2(textureSize(TEX, 0));
    vec3 scaled = p * TEXTURE_SCALE;

    vec2 uvx = (floor(scaled.zy * ts) + 0.5) / ts;
    vec2 uvy = (floor(scaled.xz * ts) + 0.5) / ts;
    vec2 uvz = (floor(scaled.xy * ts) + 0.5) / ts;

    if (normal.x < 0.0) uvx.x = 1.0 - uvx.x;
    if (normal.y < 0.0) uvy.x = 1.0 - uvy.x;
    if (normal.z < 0.0) uvz.x = 1.0 - uvz.x;

    vec3 an = abs(normal);

    if (an.x >= an.y && an.x >= an.z)
        return texture(TEX, uvx).rgb;
    else if (an.y >= an.z)
        return texture(TEX, uvy).rgb;
    else
        return texture(TEX, uvz).rgb;
}

void vertex() {
    local_pos_v = VERTEX;
    normal_v = NORMAL;
}

void fragment() {
    vec2 ts = vec2(textureSize(TEX, 0));
    float pixel_world = 1.0 / float(max(ts.x, ts.y) * TEXTURE_SCALE);
    float final_texel = PIXEL_SCALE_TEXELS ? pixel_world : TEXEL_SIZE;

    vec3 biased_texel_pos = local_pos_v - normal_v * TEXTURE_BIAS;

    vec3 texel_index = floor(biased_texel_pos / final_texel);
    vec3 texel_center_local = (texel_index + 0.5) * final_texel;

    vec3 biased_light_pos = local_pos_v - normal_v * LIGHT_BIAS;

    vec3 light_index = floor(biased_light_pos / final_texel);
    vec3 light_center_local = (light_index + 0.5) * final_texel;

    vec3 world_light = (MODEL_MATRIX * vec4(light_center_local, 1.0)).xyz;
    vec3 view_light  = (VIEW_MATRIX * vec4(world_light, 1.0)).xyz;

    LIGHT_VERTEX = view_light;

    vec3 world_normal = normalize((MODEL_MATRIX * vec4(normal_v, 0.0)).xyz);
    vec3 view_normal  = normalize((VIEW_MATRIX * vec4(world_normal, 0.0)).xyz);
    NORMAL = view_normal;

    vec3 texel_color;

    if (TRIPLANAR) {
        texel_color = sample_face_aligned(texel_center_local, world_normal);
    } else {
        vec2 scaled_uv = UV * TEXTURE_SCALE;
        vec2 snap_uv = (floor(scaled_uv * ts) + 0.5) / ts;
        texel_color = texture(TEX, snap_uv).rgb;
    }

    ALBEDO = texel_color;
}
