extends Control
var phase=0.0
var flight=false
func _draw():
	var center=Vector2(size.x*.65,48)
	draw_circle(center,22,Color("#b9cdcf"))
	draw_circle(center+Vector2(-7,4),5,Color("#90a5ad"))
	draw_arc(center,36,0,TAU,80,Color("#528eaa"),1.5,true)
	var p=center+Vector2.from_angle(phase*TAU)*36
	if flight:p=Vector2(24,76).lerp(center+Vector2(-30,-19),clampf(phase,0,1))
	draw_colored_polygon(PackedVector2Array([p+Vector2(8,-4),p+Vector2(-5,5),p+Vector2(-6,-3)]),Color("#ffaf70"))
	draw_string(ThemeDB.fallback_font,Vector2(4,16),"ORBIT SCHEMATIC",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#a8dbdd"))
