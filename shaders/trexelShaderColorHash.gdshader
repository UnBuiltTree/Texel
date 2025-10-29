shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D TEX : filter_nearest, source_color;
uniform bool TRIPLANAR = true;

uniform float TREXEL_SIZE : hint_range(0.001, 10.0) = 0.1;
uniform float BIAS_STRENGTH : hint_range(0.0, 0.01) = 0.0005;

uniform float hashColorIntensity : hint_range(0.0, 1.0) = 0.5;

varying vec3 local_pos_v;
varying vec3 normal_v;

vec3 hash3(vec3 p) {
    p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
    p += dot(p, p.yzx + 19.19);
    return fract(vec3(p.x * p.y, p.y * p.z, p.z * p.x));
}

vec3 sample_triplanar_texel(vec3 p, vec3 normal) {
    vec2 ts = vec2(textureSize(TEX, 0));

    vec2 uvx = (floor(p.zy * ts) + 0.5) / ts;
    vec2 uvy = (floor(p.xz * ts) + 0.5) / ts;
    vec2 uvz = (floor(p.xy * ts) + 0.5) / ts;

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

    vec3 trexel_index = floor(biased_pos / TREXEL_SIZE);
    vec3 trexel_center_local = (trexel_index + 0.5) * TREXEL_SIZE;

    vec3 world_center = (MODEL_MATRIX * vec4(trexel_center_local, 1.0)).xyz;
    vec3 view_center  = (VIEW_MATRIX * vec4(world_center, 1.0)).xyz;

    LIGHT_VERTEX = view_center;

    vec3 tex_color;
    if (TRIPLANAR) {
        tex_color = sample_triplanar_texel(trexel_center_local, normal_v);
    } else {
        vec2 ts = vec2(textureSize(TEX, 0));
        vec2 snap_uv = (floor(UV * ts) + 0.5) / ts;
        tex_color = texture(TEX, snap_uv).rgb;
    }

    vec3 voxel_color = hash3(trexel_index);

    vec3 final_color = mix(tex_color, voxel_color, hashColorIntensity);

    ALBEDO = final_color;
}
