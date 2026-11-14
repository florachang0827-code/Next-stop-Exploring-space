extends RefCounted
# Build editable transform tracks against the imported rig's actual rest frames.
static func install(avatar:Node3D) -> AnimationPlayer:
	var skeleton:Skeleton3D=avatar.find_children("*","Skeleton3D",true,false)[0]
	var player=AnimationPlayer.new()
	avatar.add_child(player)
	var library=AnimationLibrary.new()
	for mode in ["Idle","Walk","Run"]:
		var clip=Animation.new()
		clip.length={"Idle":2.4,"Walk":0.86,"Run":0.60}[mode]
		clip.loop_mode=Animation.LOOP_LINEAR
		var names=["pelvis","spine_02","head"]
		for side in [".L",".R"]:
			for limb in ["thigh","shin","foot","upper_arm","forearm"]:names.append(limb+side)
		for bone in names:
			var idx=skeleton.find_bone(bone)
			if idx<0:continue
			var local=skeleton.get_bone_rest(idx).basis.get_rotation_quaternion()
			var basis_q=skeleton.get_bone_global_rest(idx).basis.get_rotation_quaternion()
			var track=clip.add_track(Animation.TYPE_ROTATION_3D)
			clip.track_set_path(track,NodePath(str(avatar.get_path_to(skeleton))+":"+bone))
			for k in 25:
				var phase=TAU*k/24.0
				if bone.ends_with(".R"):phase+=PI
				var swing=sin(phase)
				var active=mode!="Idle"
				var fast=mode=="Run"
				var pitch=0.0
				var yaw=0.0
				if bone.begins_with("thigh"):pitch=(0.78 if fast else 0.53)*swing if active else 0.0
				elif bone.begins_with("shin"):pitch=-(1.04 if fast else .62)*maxf(0,cos(phase)) if active else 0.0
				elif bone.begins_with("foot"):pitch=-.27*swing if active else 0.0
				elif bone=="spine_02":pitch=(-.12 if fast else .015)*(.9+.1*cos(2*phase));yaw=.07*swing if active else 0.0
				elif bone=="pelvis":yaw=-.09*swing if active else .012*swing
				elif bone=="head":pitch=.035*cos(2*phase)
				var delta=Quaternion(Vector3.UP,yaw)*Quaternion(Vector3.RIGHT,pitch)
				if bone.begins_with("upper_arm") or bone.begins_with("forearm"):
					var side=bone.right(2)
					var upper=skeleton.find_bone("upper_arm"+side)
					var elbow=skeleton.find_bone("forearm"+side)
					var wrist=skeleton.find_bone("hand"+side)
					var upper_rest=skeleton.get_bone_global_rest(elbow).origin-skeleton.get_bone_global_rest(upper).origin
					var fore_rest=skeleton.get_bone_global_rest(wrist).origin-skeleton.get_bone_global_rest(elbow).origin
					var inv=skeleton.global_transform.basis.inverse()
					var outward=.13 if side==".L" else -.13
					var stride=(.42 if fast else .23)*swing if active else 0.0
					var upper_pose=Quaternion(upper_rest.normalized(),(inv*Vector3(outward,-1,stride)).normalized())
					delta=upper_pose
					if bone.begins_with("forearm"):
						var fore_target=(inv*Vector3(outward,-1,stride+.17)).normalized()
						delta=Quaternion(fore_rest.normalized(),upper_pose.inverse()*fore_target)
				clip.rotation_track_insert_key(track,clip.length*k/24.0,local*basis_q.inverse()*delta*basis_q)
		library.add_animation(mode,clip)
	player.add_animation_library("",library)
	return player
