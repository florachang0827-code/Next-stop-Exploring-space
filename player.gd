extends CharacterBody3D
@export var visual: PackedScene
@export var camera_target=Vector3(0,0.9,0)
@export var idle_animation="Idle"
@export var walk_animation="Walk"
@export var run_animation="Run"
@export var interact_animation=""
var locked=false
var pivot=Node3D.new()
var arm=SpringArm3D.new()
var avatar
var animator
var first_person=false
@export var jump_speed=4.2
var jump_requested=false
var eye=Camera3D.new()
func toggle_view():
	first_person=not first_person
	avatar.visible=not first_person
	if first_person:eye.make_current()
	else:arm.get_child(0).make_current()
var touches={}
func zoom(amount):
	if not locked:
		if first_person:eye.fov=clampf(eye.fov*amount,45,90)
		else:arm.spring_length=clampf(arm.spring_length*amount,.48,6.5)
func orbit(delta):
	pivot.rotation.y-=delta.x*.006
	arm.rotation.x=clampf(arm.rotation.x-delta.y*.005,-1.18,.68)
	eye.rotation.x=arm.rotation.x
func _ready():
	collision_layer=2
	var capsule=CollisionShape3D.new()
	capsule.shape=CapsuleShape3D.new()
	capsule.shape.radius=.19
	capsule.shape.height=1.26
	capsule.position.y=.63
	add_child(capsule)
	avatar=visual.instantiate()
	avatar.scale=Vector3.ONE*.21
	add_child(avatar)
	for surface in avatar.find_children("*","MeshInstance3D",true,false):
		if "transparent visor" in surface.name.to_lower():
			var visor=StandardMaterial3D.new()
			visor.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
			visor.albedo_color=Color(.72,.9,1,.15)
			visor.roughness=.12
			surface.material_override=visor
	animator=preload("res://gait.gd").install(avatar)
	floor_snap_length=.3
	add_child(pivot)
	pivot.position=camera_target
	pivot.add_child(arm)
	arm.spring_length=1.65
	arm.margin=.12
	arm.rotation.x=-.12
	arm.add_excluded_object(get_rid())
	var camera=Camera3D.new()
	camera.near=.035
	arm.add_child(camera)
	camera.current=true
	pivot.add_child(eye)
	eye.position.y=.13
	eye.near=.025
func animate(n):
	if animator and n!="" and animator.has_animation(n) and animator.current_animation!=n:animator.play(n)
func _unhandled_input(e):
	if locked:
		touches.clear()
		return
	if e is InputEventKey and e.pressed and not e.echo and e.keycode==KEY_V:toggle_view()
	if e is InputEventKey and e.pressed and not e.echo and e.keycode==KEY_SPACE and is_on_floor():
		jump_requested=true
	if e is InputEventScreenTouch:
		if e.pressed:touches[e.index]=e.position
		else:touches.erase(e.index)
	if e is InputEventScreenDrag and touches.has(e.index):
		if touches.size()==1:orbit(e.relative)
		elif touches.size()==2:
			var other=touches.keys()[0] if touches.keys()[1]==e.index else touches.keys()[1]
			var old_gap=touches[e.index].distance_to(touches[other])
			var new_gap=e.position.distance_to(touches[other])
			if old_gap>4 and new_gap>4:zoom(old_gap/new_gap)
		touches[e.index]=e.position
	if e is InputEventMagnifyGesture:zoom(1.0/e.factor)
	if e is InputEventMouseMotion and (e.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT)):orbit(e.relative)
	if e is InputEventMouseButton and e.pressed:
		if e.button_index==MOUSE_BUTTON_WHEEL_UP:zoom(.84)
		if e.button_index==MOUSE_BUTTON_WHEEL_DOWN:zoom(1.0/.84)
func _physics_process(dt):
	var v=Vector3.ZERO
	if not locked:
		v.x=float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
		v.z=float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))-float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	v=pivot.basis*v.normalized()
	var running=Input.is_key_pressed(KEY_SHIFT)
	velocity.x=v.x*(2.8 if running else 1.5)
	velocity.z=v.z*(2.8 if running else 1.5)
	velocity.y-=12*dt
	if jump_requested and not locked and is_on_floor():velocity.y=jump_speed
	jump_requested=false
	var stride=Vector3(velocity.x,0,velocity.z)*dt
	if is_on_floor() and stride.length_squared()>0 and test_move(global_transform,stride):
		var raised=global_transform.translated(Vector3.UP*.23)
		if not test_move(global_transform,Vector3.UP*.23) and not test_move(raised,stride):global_position.y+=.23
	move_and_slide()
	if v.length()>.1:avatar.rotation.y=atan2(v.x,v.z)
	animate((run_animation if running else walk_animation) if v.length()>.1 else idle_animation)
