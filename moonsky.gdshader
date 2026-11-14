shader_type sky;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void sky() {
	float h = max(EYEDIR.y,0.0);
	vec3 sky_color = mix(vec3(.41,.64,.73),vec3(.08,.17,.39),smoothstep(.0,.70,h));
	vec2 grid = SKY_COORDS * vec2(780.,390.);
	float seed = hash(floor(grid));
	float star = smoothstep(.21,.02,length(fract(grid)-.5))*step(.974,seed);
	COLOR = sky_color + vec3(.75,.85,1.)*star*smoothstep(.01,.17,h);
}
