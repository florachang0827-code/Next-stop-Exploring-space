shader_type spatial;
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
float hash(vec2 p){return fract(sin(dot(p,vec2(31.39,73.19)))*43758.5);}
float noise2(vec2 p){
	vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.),f.x),f.y);
}
void fragment(){
	vec2 p=world_pos.xz;
	float bed=.52*noise2(p*.38)+.32*noise2(p*1.3)+.16*noise2(p*4.5);
	float grains=(noise2(p*17.)-.5)*(1.-smoothstep(.03,.14,fwidth(p.x)+fwidth(p.y)));
	vec2 cell=floor(p/1.35);
	vec2 center=.28+.44*vec2(hash(cell),hash(cell+8.1));
	float r=length(fract(p/1.35)-center);
	float radius=.07+.12*hash(cell+9.7);
	float crater=(smoothstep(radius*.75,radius,r)-smoothstep(radius,radius*1.4,r))*.14-(1.-smoothstep(0.,radius,r))*.19;
	ALBEDO=mix(vec3(.075,.19,.34),vec3(.18,.50,.58),clamp(bed+grains*.18+crater,0.,1.));
	ROUGHNESS=.96;
}
