extends Control

var station_world
var pointer=Vector2.RIGHT
var caption="Accept a mission"

func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	size=Vector2(218,46)

func _process(_dt):
	if not station_world:return
	var ui=station_world.get_node("Interface")
	var station=int(ui.nav_station)
	if station<0 and station_world.mission.stage==0:station=0
	visible=station>=0 and ui.page<0
	if not visible:return
	var camera=get_viewport().get_camera_3d()
	if not camera:return
	caption=station_world.labels[station].capitalize()
	var target=station_world.pad(station)+Vector3.UP*.25
	var bounds=get_viewport_rect().size
	var center=bounds*.5
	var dest:Vector2
	if camera.is_position_behind(target):
		var local=camera.to_local(target)
		dest=center+Vector2(local.x,-local.y).normalized()*bounds.length()
		if absf(local.x)<.01:dest=center+Vector2.DOWN*bounds.y
	else:
		dest=camera.unproject_position(target)
	var direction=center.direction_to(dest)
	var anchor=dest-direction*128.0
	var half=size*.5
	anchor=anchor.clamp(half+Vector2(14,142),bounds-half-Vector2(14,60))
	position=anchor-half
	pointer=anchor.direction_to(dest)
	queue_redraw()

func _draw():
	draw_rect(Rect2(Vector2.ZERO,size),Color("#172c3df2"))
	var origin=Vector2(22,23)
	var side=pointer.orthogonal()
	draw_colored_polygon(PackedVector2Array([origin+pointer*14,origin-pointer*10+side*9,origin-pointer*5,origin-pointer*10-side*9]),Color("#ffbe73"))
	draw_string(ThemeDB.fallback_font,Vector2(43,18),"DESTINATION",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#a4e4dd"))
	draw_string(ThemeDB.fallback_font,Vector2(43,37),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)
