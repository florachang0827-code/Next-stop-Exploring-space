extends Node3D
const HONEY=Color("#ffd696")
const OAK=Color("#bf8255")
const CREAM=Color("#ffedcf")
const SAGE=Color("#81ac96")
const SLATE=Color("#294957")
func finish(node,color,glow=false):
	var m=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=.72
	if glow:
		m.emission_enabled=true
		m.emission=color
		m.emission_energy_multiplier=1.25
	node.material_override=m
	add_child(node)
	return node
func orb(pos,sz,color,glow=false):
	var n=MeshInstance3D.new()
	n.mesh=SphereMesh.new()
	n.mesh.radial_segments=20
	n.mesh.rings=10
	n.position=pos
	n.scale=sz
	return finish(n,color,glow)
func rounded(pos,sz,r,color):
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring=[]
	r=minf(r,minf(sz.x,sz.z)*.48)
	for corner in 4:
		var cx=[1,-1,-1,1][corner]*(sz.x/2-r)
		var cz=[1,1,-1,-1][corner]*(sz.z/2-r)
		for j in 7:
			var a=(corner+j/6.0)*PI/2
			ring.append(Vector3(cx+r*cos(a),0,cz+r*sin(a)))
	for i in ring.size():
		var a=ring[i]
		var b=ring[(i+1)%ring.size()]
		var h=Vector3.UP*sz.y*.5
		for v in [h,a+h,b+h,-h,b-h,a-h,a-h,b+h,a+h,a-h,b-h,b+h]:st.add_vertex(v)
	st.generate_normals()
	var n=MeshInstance3D.new()
	n.mesh=st.commit()
	n.position=pos
	finish(n,color)
	n.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
	return n
func light_at(pos,energy,radius):
	var l=OmniLight3D.new()
	l.position=pos
	l.light_color=Color("#ffd29a")
	l.light_energy=energy
	l.omni_range=radius
	add_child(l)
func caption(pos,t,size):
	var n=Label3D.new()
	n.text=t
	n.position=pos
	n.pixel_size=size
	n.font_size=40
	n.modulate=CREAM
	add_child(n)
func furnish(stations):
	for i in [0,2,3]:
		var p=stations[i]+Vector3(0,0,-.25)
		rounded(p+Vector3.UP*.29,Vector3(.48,.58,.32),.15,SAGE)
		rounded(p+Vector3.UP*.60,Vector3(.84,.09,.49),.17,OAK)
		var display=rounded(p+Vector3(0,.77,-.08),Vector3(.57,.28,.08),.038,SLATE)
		display.rotation.x=-.12
		caption(p+Vector3(0,.79,-.028),["SELENE  /  01","","FLIGHT  /  03","ORBIT  /  04"][i],.00068)
		for j in 4:orb(p+Vector3(-.18+j*.10,.664,.12),Vector3(.052,.019,.052),HONEY if j==0 else SAGE,j==0)
	# Curved upholstered banquette cushions and reading lamp in the lounge.
	for j in 3:
		var n=orb(Vector3(.93+j*.49,1.35,-.66),Vector3(.48,.16,.49),[SAGE,CREAM,OAK][j])
		n.rotation.z=.09*(j-1)
	orb(Vector3(2.55,1.09,-1.34),Vector3(.13,.85,.13),OAK)
	orb(Vector3(2.55,1.60,-1.34),Vector3(.43,.38,.43),HONEY,true)
	light_at(Vector3(2.49,1.62,-1.30),.82,2.9)
	rounded(Vector3(-.83,.705,.60),Vector3(1.76,.012,1.23),.34,SAGE)
	for j in 5:rounded(Vector3(-1.42+j*.08,.715,.6),Vector3(.026,.006,1.02),.012,CREAM)
	for x in [-3.65,-.60,1.55]:
		orb(Vector3(x,2.40,-.13),Vector3(.53,.115,.53),OAK)
		orb(Vector3(x,2.35,-.13),Vector3(.46,.085,.46),HONEY,true)
		light_at(Vector3(x,2.26,-.13),.68,3.25)
	# Wall-mounted orbital artwork with brass rings and raised ceramic moons.
	rounded(Vector3(-1.19,1.66,-1.87),Vector3(1.72,.82,.09),.04,SLATE)
	for j in 3:
		var n=MeshInstance3D.new()
		var torus=TorusMesh.new()
		torus.inner_radius=.135+j*.066
		torus.outer_radius=torus.inner_radius+.009
		n.mesh=torus
		n.rotation.x=PI/2
		n.scale.x=1.64
		n.position=Vector3(-1.22,1.67,-1.80)
		finish(n,HONEY)
	orb(Vector3(-1.22,1.67,-1.785),Vector3(.18,.18,.06),CREAM)
	caption(Vector3(-1.18,1.34,-1.805),"LUNAR ARCHIVE",.0011)
