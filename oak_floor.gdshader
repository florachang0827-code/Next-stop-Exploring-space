shader_type spatial;
render_mode cull_disabled;
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
float hash(vec2 p){return fract(sin(dot(p,vec2(41.7,289.1)))*43758.54);}
float noise2(vec2 p){
	vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.),f.x),f.y);
}
void fragment(){
	vec2 p=world_pos.xz;
	float row=floor(p.y/.27);
	float offset=hash(vec2(row,4.))*1.75;
	vec2 board=vec2((p.x+offset)/1.85,p.y/.27);
	float id=hash(floor(board));
	float drift=noise2(vec2(p.x*.76,p.y*2.8)+id*9.);
	float grain=noise2(vec2(p.x*1.35,p.y*30.+drift*4.6));
	float pores=noise2(vec2(p.x*2.1,p.y*76.+drift*9.));
	float lod=1.-smoothstep(.06,.33,fwidth(p.y)*30.);
	float tone=clamp(.22+id*.30+.46*grain+.12*(pores-.5)*lod,0.,1.);
	vec3 timber=mix(vec3(.38,.205,.105),vec3(.81,.58,.35),tone);
	vec2 edge=min(fract(board),1.-fract(board))*vec2(1.85,.27);
	float seam=min(edge.x,edge.y);
	float width=max(.0025,fwidth(seam));
	ALBEDO=timber*mix(.71,1.,smoothstep(0.,width+.002,seam));
	ROUGHNESS=.83;
}
