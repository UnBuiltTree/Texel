shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D TEX : filter_nearest, source_color;
uniform bool TRIPLANAR = true;
uniform float TEXEL_SIZE : hint_range(0.001, 10.0) = 0.1;
uniform float BIAS_STRENGTH : hint_range(0.0, 0.01) = 0.001;
uniform float TEXTURE_SCALE : hint_range(0.01, 10.0) = 1.0;

varying vec3 local_pos_v;
varying vec3 normal_v;

vec3 sample_triplanar_texel(vec3 p, vec3 normal) {
    vec2 ts = vec2(textureSize(TEX, 0));

    // texture scaling
    vec3 scaled = p * TEXTURE_SCALE;

    // Snap each projection to nearest texel
    vec2 uvx = (floor(scaled.zy * ts) + 0.5) / ts;
    vec2 uvy = (floor(scaled.xz * ts) + 0.5) / ts;
    vec2 uvz = (floor(scaled.xy * ts) + 0.5) / ts;

    vec3 cx = texture(TEX, uvx).rgb;
    vec3 cy = texture(TEX, uvy).rgb;
    vec3 cz = texture(TEX, uvz).rgb;

    vec3 n = abs(normal);
    vec3 w = n / (n.x + n.y + n.z);

    return cx * w.x + cy * w.y + cz * w.z;
}

void vertex() {
    local_pos_v = VERTEX;
    normal_v = NORMAL;
}

void fragment() {
    vec3 biased_pos = local_pos_v - normal_v * BIAS_STRENGTH;
    vec3 texel_index = floor(biased_pos / TEXEL_SIZE);
    vec3 texel_center_local = (texel_index + 0.5) * TEXEL_SIZE;

    vec3 world_center = (MODEL_MATRIX * vec4(texel_center_local, 1.0)).xyz;
    vec3 view_center  = (VIEW_MATRIX * vec4(world_center, 1.0)).xyz;
    LIGHT_VERTEX = view_center;

    vec3 texel_color;

    if (TRIPLANAR) {
        texel_color = sample_triplanar_texel(texel_center_local, normal_v);
    } else {
        vec2 ts = vec2(textureSize(TEX, 0));
        
        vec2 scaled_uv = UV * TEXTURE_SCALE;
        vec2 snap_uv = (floor(scaled_uv * ts) + 0.5) / ts;

        texel_color = texture(TEX, snap_uv).rgb;
    }

    ALBEDO = texel_color;
}
