extends Node3D

# Faceted silhouettes share one mesh per plant or outcrop.
func profile(pos:Vector3,rings:Array,colors:Array,sides:int,angle:float,solid:bool):
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in rings.size()-1:
		for i in sides:
			var verts=[]
			for corner in [[j,i],[j,i+1],[j+1,i+1],[j,i],[j+1,i+1],[j+1,i]]:
				var ring:Vector4=rings[corner[0]]
				var a=TAU*corner[1]/sides+angle
				verts.append(Vector3(ring.z+ring.x*cos(a),ring.y,ring.w+ring.x*sin(a)))
			var color=Color(colors[j]).darkened(.055*posmod(i*7+j,4))
			for v in verts:
				st.set_color(color)
				st.set_smooth_group(-1)
				st.add_vertex(v)
	st.generate_normals()
	var obj=MeshInstance3D.new()
	obj.mesh=st.commit()
	var m=StandardMaterial3D.new()
	m.vertex_color_use_as_albedo=true
	m.vertex_color_is_srgb=true
	m.cull_mode=BaseMaterial3D.CULL_DISABLED
	obj.material_override=m
	obj.position=pos
	add_child(obj)
	if solid:obj.create_trimesh_collision()
func grow():
	var rng=RandomNumberGenerator.new()
	rng.seed=710
	for i in 38:
		var a=TAU*i/38.0+rng.randf_range(-.04,.04)
		var r=rng.randf_range(10,18)
		var p=Vector3(cos(a)*r,-.2,sin(a)*r)
		var h=rng.randf_range(1.8,4.9)
		if i%3==0:
			for j in 3:
				var k=h*rng.randf_range(.44,1.0)
				profile(p+Vector3(j*.65,0,j*.35),[Vector4(.58,0,0,0),Vector4(.48,k*.70,.18,0),Vector4(.025,k,.38,.12)],["#23859b","#65d4d2"],5,a,true)
		else:
			profile(p,[Vector4(.32,0,0,0),Vector4(.16,h*.48,.12,.08),Vector4(.20,h,.26,.02)],["#434573","#8273a7"],7,a,true)
			profile(p,[Vector4(.12,h-.05,.26,.02),Vector4(.32*h,h+.12,.26,.02),Vector4(.36*h,h+.25,.26,.02),Vector4(.20*h,h+.51,.28,.02),Vector4(.012,h+.68,.3,.02)],["#ffd275","#fc9dc6","#8657ab","#64569c"],11,a,true)
			for j in 3:
				var bulb=MeshInstance3D.new()
				var gem=SphereMesh.new()
				gem.radial_segments=6
				gem.rings=3
				bulb.mesh=gem
				bulb.scale=Vector3(.16,.22,.16)
				bulb.position=p+Vector3(.26+cos(j*2)*h*.22,h+.41,.02+sin(j*2)*h*.22)
				var glow=StandardMaterial3D.new()
				glow.albedo_color=Color("#ffe789")
				glow.emission_enabled=true
				glow.emission=Color("#ffc573")
				bulb.material_override=glow
				add_child(bulb)
