shader_type canvas_item;
render_mode unshaded;
uniform sampler2D world_image : hint_screen_texture, repeat_disable, filter_nearest;

const vec3 INK = vec3(0.12, 0.13, 0.22);
const vec3 COLORS[32] = {
	vec3(.075,.09,.15), vec3(.14,.16,.25), vec3(.22,.22,.34), vec3(.32,.31,.43),
	vec3(.39,.38,.52), vec3(.52,.50,.62), vec3(.68,.65,.73), vec3(.84,.80,.82),
	vec3(.12,.20,.26), vec3(.16,.30,.36), vec3(.23,.41,.47), vec3(.33,.53,.56),
	vec3(.47,.65,.65), vec3(.62,.76,.75), vec3(.76,.84,.81), vec3(.88,.91,.85),
	vec3(.20,.15,.20), vec3(.32,.21,.23), vec3(.46,.29,.26), vec3(.60,.37,.29),
	vec3(.74,.46,.31), vec3(.86,.59,.37), vec3(.93,.73,.49), vec3(1.,.87,.64),
	vec3(.32,.38,.32), vec3(.45,.53,.40), vec3(.60,.66,.49), vec3(.73,.76,.61),
	vec3(.63,.53,.48), vec3(.76,.65,.56), vec3(.88,.78,.65), vec3(.98,.91,.77)
};
float lum(vec3 c){return dot(c,vec3(.299,.587,.114));}
void fragment(){
	vec2 cell=SCREEN_PIXEL_SIZE*max(2.,floor(1./(SCREEN_PIXEL_SIZE.y*150.)+.5));
	vec2 grid=floor(SCREEN_UV/cell);
	vec2 uv=(grid+.5)*cell;
	float lod=0.;
	vec3 c=textureLod(world_image,uv,lod).rgb;
	float y=lum(c);
	float neighbor=max(lum(textureLod(world_image,uv+vec2(cell.x,0.),lod).rgb),lum(textureLod(world_image,uv+vec2(0.,cell.y),lod).rgb));
	c=clamp((c-.52)*1.14+.49,0.,1.);
	float best=100.;
	vec3 paint=INK;
	for(int i=0;i<32;i++){
		vec3 diff=c-COLORS[i];
		float dist=dot(diff*diff,vec3(.32,.48,.20));
		if(dist<best){best=dist;paint=COLORS[i];}
	}
	if(neighbor-y>.14){paint=mix(paint,INK,.55);}
	vec2 within=fract(SCREEN_UV/cell);

	float gridline=1.-step(min(SCREEN_PIXEL_SIZE.x/cell.x,0.22),min(within.x,within.y));
	COLOR=vec4(paint*(1.-0.10*gridline),1.);
}


