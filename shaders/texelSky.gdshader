shader_type sky;

uniform float SKY_TEXEL_SIZE   = 10.0;
uniform float CLOUD_TEXEL_SIZE = 10.0;

uniform bool ENABLE_CLOUDS = true;

uniform float SKY_FAR = 50000.0;

uniform float CLOUD_LAYER_Y = 100.0;
uniform float LAYER_HEIGHT = 10.0;
uniform int   LAYER_COUNT = 5;
uniform float CLOUD_SCROLL = 0.05;
uniform float CLOUD_FADE_DISTANCE = 2000.0;

uniform float CLOUD_SCALE = 0.02;

uniform float cloud_edge_start = 0.50;
uniform float cloud_edge_end   = 0.6;

uniform vec3 sky_color      = vec3(0.30, 0.45, 0.80); 
uniform vec3 cloud_color    = vec3(1.0, 1.0, 1.0);

uniform vec3  sun_dir   = vec3(0.0, -0.6, -0.8);
uniform float sun_radius = 5000.0;
uniform vec3  sun_color  = vec3(1.0, 0.95, 0.75);

vec2 random(vec2 uv) {
	uv = vec2(dot(uv, vec2(127.1,311.7)), dot(uv, vec2(269.5,183.3)));
	return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}


float noise(vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	vec2 w = smoothstep(vec2(0.0), vec2(1.0), f);
	
	float n00 = dot(random(i + vec2(0,0)), f - vec2(0,0));
	float n10 = dot(random(i + vec2(1,0)), f - vec2(1,0));
	float n01 = dot(random(i + vec2(0,1)), f - vec2(0,1));
	float n11 = dot(random(i + vec2(1,1)), f - vec2(1,1));
	
	float nx0 = mix(n00, n10, w.x);
	float nx1 = mix(n01, n11, w.x);
	return mix(nx0, nx1, w.y) + 0.5;
}

void sky() {
	
	vec3 dir = normalize(EYEDIR);
	
	// sky background
	vec3 sky_hit   = dir * SKY_FAR;
	vec3 sky_pixel = floor(sky_hit / SKY_TEXEL_SIZE) * SKY_TEXEL_SIZE;
	
	vec3 col = sky_color;
	vec3 base_sky = sky_color;
	
	// the sun
	{
		vec3 center_dir = normalize(-sun_dir);
		
		vec3 up = vec3(0.0, 1.0, 0.0);
		vec3 right = normalize(cross(center_dir, up));
		if (length(right) < 0.001) right = vec3(1.0, 0.0, 0.0);
		
		vec3 up2 = normalize(cross(right, center_dir));
		
		float u = dot(dir, right);
		float v = dot(dir, up2);
		
		float sun_ang = sun_radius / SKY_FAR;
		float grid = 1.0 / (SKY_TEXEL_SIZE * 0.001);
		
		float u_snap = (floor(u * grid) + 0.5) / grid;
		float v_snap = (floor(v * grid) + 0.5) / grid;
		
		if (u_snap*u_snap + v_snap*v_snap < sun_ang*sun_ang)
			col = sun_color;
	}
	
	// clouds
	if (ENABLE_CLOUDS && dir.y > 0.0) {
		for (int layer = LAYER_COUNT - 1; layer >= 0; layer--) {
			float layer_y = CLOUD_LAYER_Y + float(layer) * LAYER_HEIGHT;
			float t = layer_y / dir.y;
			
			vec3 hit = dir * t;
			vec3 hit_unscrolled = hit;
			
			float layer_inverse = float(LAYER_COUNT) - float(layer);
			hit.x += TIME * CLOUD_SCROLL * (20.0 + layer_inverse * 10.0);
			hit.z += TIME * CLOUD_SCROLL * (10.0 + layer_inverse * 8.0);
			
			vec3 snapped = floor(hit / CLOUD_TEXEL_SIZE) * CLOUD_TEXEL_SIZE;
			
			float offset = float(layer) * 137.0;
			vec2 uv = snapped.xz * CLOUD_SCALE + offset;
			float raw = noise(uv);
			
			float edge_alpha = clamp((raw - cloud_edge_start) / (cloud_edge_end - cloud_edge_start), 0.0, 1.0 );
			if (edge_alpha <= 0.0) continue;
			
			float dist = length(hit_unscrolled);
			float fade = clamp(1.0 - dist / CLOUD_FADE_DISTANCE, 0.0, 1.0);
			if (fade <= 0.0) continue;
			
			float depth = 1.0 - float(layer) / float(LAYER_COUNT - 1);
			float alpha = depth * fade * edge_alpha;
			
			vec3 layer_col = mix(base_sky, cloud_color, alpha);
			col = mix(col, layer_col, alpha);
			
		}
		
	}
	COLOR = col;
}
