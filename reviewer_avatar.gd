extends Control
var role=0
func _draw():
	var p=Vector2(22,23)
	var palette=[Color("#79c6cb"),Color("#ad94d8"),Color("#e6ae75")]
	draw_circle(p,21,Color("#233e4d"))
	draw_circle(p+Vector2(0,13),9,palette[role])
	draw_circle(p+Vector2(0,-3),9,[Color("#c68662"),Color("#e7bf95"),Color("#a76e57")][role])
	draw_arc(p+Vector2(0,-3),9,PI,TAU,12,Color("#403348"),4)
	for x in [-3,3]:draw_circle(p+Vector2(x,-3),1,Color("#243443"))
	if role==0:draw_line(p+Vector2(-7,-3),p+Vector2(7,-3),Color("#273e53"),1)
