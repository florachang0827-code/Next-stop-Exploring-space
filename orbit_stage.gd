extends "res://probe_view.gd"
var earth=Vector3(-3.8,-.08,0)
var moon=Vector3(1.65,0,0)
var scan
var glow
var vapors=[]
var panels=[]
var payloads=[]
var dish_mat
var hull
var space_env
var camera
func planet(center,r,earthlike):
	var ball=piece(viewport3,SphereMesh.new(),center,Vector3.ONE*r*2,"ffffff")
	var shader=Shader.new()
	shader.code="""shader_type spatial;
	uniform bool ocean;
	float noise3(vec3 p){return sin(p.x*4.+sin(p.z*6.))+sin(p.y*6.+p.z*4.)+.45*sin(p.x*13.+p.y*17.);}
	void fragment(){vec3 p=NORMAL; float n=noise3(p);
	vec3 c=mix(vec3(.18,.24,.31),vec3(.55,.61,.63),smoothstep(-1.4,1.4,n));
	if(ocean){c=mix(vec3(.025,.24,.42),vec3(.18,.56,.43),smoothstep(.05,.23,n));c=mix(c,vec3(.8,.91,.92),smoothstep(.92,1.,sin(p.y*26.+n*2.))*.62);}
	ALBEDO=c; ROUGHNESS=1.;}"""
	var mat=ShaderMaterial.new()
	mat.shader=shader
	mat.set_shader_parameter("ocean",earthlike)
	ball.material_override=mat
func build_scene(m):
	build(m)
	hull=vehicle.get_child(0).material_override
	for wing in vehicle.get_child(1).get_children():panels.append(wing.material_override)
	dish_mat=vehicle.get_child(3).material_override
	for i in range(4,vehicle.get_child_count()):payloads.append(vehicle.get_child(i).material_override)
	space_env=viewport3.get_child(2).environment
	camera=viewport3.get_camera_3d()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect=Camera3D.KEEP_WIDTH
	camera.size=12
	camera.position=Vector3(0,0,10)
	camera.rotation=Vector3.ZERO
	planet(earth,.82,true)
	planet(moon,.78,false)
	vehicle.scale=Vector3.ONE*.57
	var orbit=ImmediateMesh.new()
	var ink=StandardMaterial3D.new()
	ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.albedo_color=Color("#528392")
	orbit.surface_begin(Mesh.PRIMITIVE_LINE_STRIP,ink)
	for i in 121:orbit.surface_add_vertex(path(TAU*i/120))
	orbit.surface_end()
	var wire=MeshInstance3D.new()
	wire.mesh=orbit
	viewport3.add_child(wire)
	scan=piece(viewport3,CylinderMesh.new(),moon,Vector3.ONE,"6bffdf")
	light_up(scan.material_override,Color("#60ffce"),true)
	glow=piece(vehicle,SphereMesh.new(),Vector3(.1,.05,.45),Vector3.ONE*.2,"fff4bb")
	for i in 6:vapors.append(piece(viewport3,SphereMesh.new(),moon,Vector3.ONE*.09,"ffad86"))
func light_up(mat,c,on):
	mat.emission_enabled=on
	mat.emission=c
func path(a):
	return moon+Vector3(2.10*cos(a),.88*sin(a),-.9*cos(a))
func animate(a,clock,action,phase,contact,low,hot):
	vehicle.position=path(a)
	vehicle.rotation=Vector3(.27,.55+sin(a)*.6,.13*sin(a))
	camera.size=lerpf(camera.size,11.3 if contact else 12.1,.045)
	space_env.background_color=Color("#102b40") if contact else Color("#091321")
	var src=vehicle.position
	var dest=moon+(src-moon).normalized()*.77
	var offset=dest-src
	scan.visible=action==0
	if scan.visible:
		scan.position=(src+dest)*.5
		scan.quaternion=Quaternion(Vector3.UP,offset.normalized())
		scan.scale=Vector3(.032+.012*sin(clock*22),offset.length()/2,.032)
	packet.visible=action==2
	packet.position=src.lerp(earth,phase)
	packet.scale=Vector3.ONE*.24
	light_up(dish_mat,Color("#71caff"),action==2)
	for mat in payloads:light_up(mat,Color("#77ffd2"),action==0)
	glow.visible=low or action==1
	light_up(glow.material_override,Color.ORANGE_RED if low else Color.GOLD,true)
	light_up(hull,Color("#bd362c"),low)
	for mat in panels:mat.albedo_color=Color("#263953") if low else Color("#5094b4")
	for i in vapors.size():
		var drift=fposmod(clock*1.1+i*.18,1)
		vapors[i].visible=hot or action==3
		vapors[i].position=src+Vector3(.24*sin(i+drift*4),.24+drift*.65,.4)

