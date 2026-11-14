extends Node3D
@export var building:PackedScene
@export var stations:Array[Vector3]=[Vector3(-3.7,.72,-.9),Vector3(-3.2,.72,.72),Vector3(.8,.72,-.8),Vector3(2.1,.72,.68)]
var labels=["Mission brief","Assembly bench","Launch control","Orbital tracking"]
var mission=preload("res://mission.gd").new()
var previews=[]
@export_range(.24,.55) var station_radius=.40
var occupied=-1
func pad(i):
	return stations[i]+Vector3(0,0,.94 if i==2 else .52)
func _physics_process(_dt):
	var next=-1
	for i in stations.size():
		var delta=$Commander.global_position-pad(i)
		var radius=station_radius+(.10 if i==occupied else 0.0)
		if absf(delta.y)<.45 and Vector2(delta.x,delta.z).length()<radius:
			next=i
			break
	if next==occupied:return
	occupied=next
	if next>=0 and $Interface.page<0 and $Interface.nav_station in [-1,next]:$Interface.visit_station(next)
func block(pos,sz):
	var body=StaticBody3D.new()
	var cs=CollisionShape3D.new()
	cs.shape=BoxShape3D.new()
	cs.shape.size=sz
	body.position=pos
	body.add_child(cs)
	add_child(body)
	return body
func shape(pos,sz,color,type=0):
	var n=MeshInstance3D.new()
	n.mesh=[BoxMesh.new(),SphereMesh.new(),CylinderMesh.new()][type]
	n.scale=sz
	n.position=pos
	var m=StandardMaterial3D.new()
	m.albedo_color=color
	n.material_override=m
	add_child(n)
	return n
func _ready():
	get_viewport().msaa_3d=Viewport.MSAA_2X
	var model=building.instantiate()
	add_child(model)
	for n in model.find_children("*","MeshInstance3D",true,false):
		var nm=n.name.to_lower()
		if nm in ["round birch coffee table","coffee table pedestal"]:
			n.queue_free()
			continue
		for prefix in ["lounge sofa","sofa cream arm","cream ceramic plant pot","conservatory blue plinth","vaulted clear conservatory","greenhouse glazed end","entry blue pillar"]:
			if nm.begins_with(prefix):
				n.create_trimesh_collision()
				break
		if "interior sand floor" in nm:
			var floor_finish=ShaderMaterial.new()
			floor_finish.shader=preload("res://oak_floor.gdshader")
			n.material_override=floor_finish
		if "glass airlock doors glass" in nm or "airlock metal door handle" in nm or "glass airlock doors mullion" in nm:n.hide()
		if "glass" in nm or "glazing" in nm or "glazed end" in nm:
			var glass=StandardMaterial3D.new()
			glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
			glass.albedo_color=Color(.65,.84,.92,.12)
			n.material_override=glass
	var yard=preload("res://assets/yard.glb").instantiate()
	add_child(yard)
	for n in yard.find_children("*","MeshInstance3D",true,false):
		var nm=n.name.to_lower()
		if nm.begins_with("sculpted cratered lunar terrain"):
			var dust=ShaderMaterial.new()
			dust.shader=preload("res://moondust.gdshader")
			n.material_override=dust
		if nm.begins_with("cream flower planter") or nm.begins_with("scattered lunar rock") or nm.begins_with("bollard slate pedestal"):
			n.create_convex_collision()
	block(Vector3(0,-.23,0),Vector3(46,.16,46))
	block(Vector3(.8,-.03,0),Vector3(13.2,.16,7.8))
	block(Vector3(-1,.55,0),Vector3(8.45,.28,4.5))
	var ramp=StaticBody3D.new()
	var ramp_collision=CollisionShape3D.new()
	var wedge=ConvexPolygonShape3D.new()
	var points=PackedVector3Array()
	for x in [-.97,2.27]:
		for yz in [Vector2(-.18,2.17),Vector2(.69,2.17),Vector2(.69,2.31),Vector2(.04,4.15),Vector2(-.18,4.15)]:
			points.append(Vector3(x,yz.x,yz.y))
	wedge.points=points
	ramp_collision.shape=wedge
	ramp.add_child(ramp_collision)
	add_child(ramp)
	var approach=block(Vector3(.65,-.076,4.34),Vector3(3.5,.09,1.45))
	approach.rotation.x=.20
	for p in [Vector3(-23,1,0),Vector3(23,1,0)]:block(p,Vector3(.4,3,46))
	for p in [Vector3(0,1,-23),Vector3(0,1,23)]:block(p,Vector3(46,3,.4))
	for n in model.find_children("*","MeshInstance3D",true,false):
		if "cream front sill" in n.name.to_lower() and n.global_position.y<1:
			n.hide()
		if n.name.to_lower().begins_with("glass airlock doors"):n.hide()
	block(Vector3(-1,2.8,-2.03),Vector3(8.25,4.4,.22))
	block(Vector3(-5.0,2.8,0),Vector3(.22,4.4,4.1))
	block(Vector3(3.0,2.8,0),Vector3(.22,4.4,4.1))
	block(Vector3(-2.8,1.63,2.1),Vector3(4.4,2.0,.18))
	block(Vector3(2.5,1.63,2.1),Vector3(1.0,2.0,.18))
	block(Vector3(-1,2.69,0),Vector3(8.45,.28,4.5))
	var workbench=block(Vector3(-3.25,1,.35),Vector3(1.85,.7,.73))
	workbench.add_to_group("assembly_surface")
	for i in 4:
		if i!=1:block(stations[i]+Vector3(0,.37,-.25),Vector3(.84,.74,.49))
		var l=Label3D.new()
		l.text=labels[i].to_upper()
		l.position=stations[i]+Vector3(0,1.17,0)
		l.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		l.pixel_size=.0017
		l.font_size=42
		l.modulate=Color("#ffdcaa")
		add_child(l)
		var ring=MeshInstance3D.new()
		var rim=TorusMesh.new()
		rim.inner_radius=station_radius-.035
		rim.outer_radius=station_radius
		ring.mesh=rim
		ring.scale.y=.22
		ring.position=pad(i)
		var ink=StandardMaterial3D.new()
		ink.albedo_color=Color("#ffd59b")
		ink.emission_enabled=true
		ink.emission=Color("#ffbe73")
		ring.material_override=ink
		add_child(ring)
	var decor=preload("res://decor.gd").new()
	add_child(decor)
	decor.furnish(stations)
	for i in 3:previews.append(shape(Vector3(-3.8+i*.46,1.57,.35),Vector3(.22,.25,.22),[Color.ORANGE,Color.AQUAMARINE,Color.SKY_BLUE][i],i))
	refresh()
	var env=WorldEnvironment.new()
	env.environment=Environment.new()
	var sky=Sky.new()
	var sky_material=ShaderMaterial.new()
	sky_material.shader=preload("res://moonsky.gdshader")
	sky.sky_material=sky_material
	env.environment.sky=sky
	env.environment.background_mode=Environment.BG_SKY
	env.environment.reflected_light_source=Environment.REFLECTION_SOURCE_DISABLED
	env.environment.background_color=Color("#233348")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("#ffe7c9")
	env.environment.ambient_light_energy=.57
	add_child(env)
	var sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-55,-30,0)
	sun.light_energy=.78
	add_child(sun)
	$Interface.setup(self)
	var biome=preload("res://biome.gd").new()
	add_child(biome)
	biome.grow()
	$Interface.layer=2
func refresh():
	for i in previews.size():previews[i].visible=mission.c.tools[i]
var bench_press=Vector2.ZERO
func _unhandled_input(e):
	if not e is InputEventMouseButton or e.button_index!=MOUSE_BUTTON_LEFT or $Interface.page>=0:return
	if e.pressed:
		bench_press=e.position
		return
	if bench_press.distance_to(e.position)>6:return
	var camera=get_viewport().get_camera_3d()
	if not camera:return
	var ray=camera.project_ray_origin(e.position)
	var query=PhysicsRayQueryParameters3D.create(ray,ray+camera.project_ray_normal(e.position)*5,1)
	var hit=get_world_3d().direct_space_state.intersect_ray(query)
	if hit and hit.collider.is_in_group("assembly_surface"):$Interface.visit_station(1)
func nearest():
	var best=-1
	var dist=1.65
	for i in 4:
		var r=$Commander.global_position.distance_to(stations[i])
		if r<dist:
			best=i
			dist=r
	return best


