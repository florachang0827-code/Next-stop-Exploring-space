extends SubViewportContainer
var vehicle=Node3D.new()
var packet
var viewport3=SubViewport.new()
func piece(parent,mesh,pos,sz,color):
	var n=MeshInstance3D.new()
	n.mesh=mesh
	n.position=pos
	n.scale=sz
	var mat=StandardMaterial3D.new()
	mat.albedo_color=Color(color)
	n.material_override=mat
	parent.add_child(n)
	return n
func build(m):
	stretch=true
	viewport3.own_world_3d=true
	add_child(viewport3)
	viewport3.add_child(vehicle)
	var cam=Camera3D.new()
	viewport3.add_child(cam)
	cam.position=Vector3(2.5,1.8,4.7)
	cam.look_at(Vector3.ZERO)
	cam.current=true
	var env=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("#102638")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color.WHITE
	env.environment.ambient_light_energy=.7
	viewport3.add_child(env)
	var light=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-40,-25,0)
	viewport3.add_child(light)
	piece(vehicle,BoxMesh.new(),Vector3.ZERO,Vector3(.8,1,.68),"e9c994")
	var span=1.3 if m.c.solar else .86
	var wing=Node3D.new()
	vehicle.add_child(wing)
	wing.position=Vector3(m.side("solar")*.38,.12,0)
	wing.rotation.z=deg_to_rad(m.hardware.panel_angle)
	for i in 5:
		piece(wing,BoxMesh.new(),Vector3(m.side("solar")*(i+.6)*span/5,0,0),Vector3(span*.19,.06,.64),"5094b4")
	piece(vehicle,CylinderMesh.new(),Vector3(0,-.61,0),Vector3(.32,.20,.32),"c88f72")
	var dish=piece(vehicle,SphereMesh.new(),Vector3(m.side("antenna")*.28,.65,0),Vector3(.48,.11,.48),"c3dedb")
	dish.rotation.z=deg_to_rad(30+m.hardware.antenna_angle)
	for i in m.c.tools.size():
		if m.c.tools[i]:piece(vehicle,CylinderMesh.new(),Vector3(m.side("tool"+str(i))*.29,.29-i*.17,.38),Vector3(.18,.13,.18),["64c2e4","bba5e2","e8bb67","80d6bd"][i])
	packet=piece(viewport3,SphereMesh.new(),Vector3.ZERO,Vector3.ONE*.12,"ffb149")
	packet.material_override.emission_enabled=true
	packet.material_override.emission=Color("#ffbb60")
	packet.visible=false
func show_state(t,progress):
	vehicle.rotation.y=.28*sin(t*.34)
	packet.visible=progress>=0
	packet.position=Vector3(-1.9+1.9*progress,.8*(1-progress),1.2*(1-progress))
