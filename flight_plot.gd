extends Control
const SWEEP=2.4
const OPEN=1.05
const CLOSE=1.35
const CENTER=1.2
var time=0.0
var launch=true
var captured=false
var contact=false
func words(p,t,color=Color.WHITE,sz=18):draw_string(ThemeDB.fallback_font,p,t,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,color)
func _draw():
	var w=size.x
	var h=size.y
	var teal=Color("#77e0bc")
	var gold=Color("#ffbf7b")
	draw_rect(Rect2(Vector2.ZERO,size),Color("#0c2031"))
	for i in 95:
		draw_circle(Vector2(fposmod(i*193.71,w),fposmod(i*i*29.8,h)),1 if i%7 else 1.8,Color("#698899"))
	var c=Vector2(w*.46,h*.43)
	var r=minf(w*.29,h*.31)
	var phi=time*.29
	var tilt=.23+.10*sin(time*.75)
	var pts=PackedVector2Array()
	for j in 97:
		var a=TAU*j/96
		pts.append(c+Vector2(cos(a)*r,sin(a)*r*.48).rotated(tilt))
	draw_polyline(pts,teal if captured or (not launch and contact) else Color("#687faf"),3,true)
	draw_circle(c,r*.29,Color("#438da6") if launch else Color("#a1afbc"))
	if launch:
		for j in 6:
			var ang=time*.8+j*1.1
			if cos(ang)>0:draw_circle(c+Vector2(sin(ang)*r*.19,cos(j*1.7)*r*.13),r*.049,Color("#8bd1a7"))
	var moon=c+Vector2(cos(phi)*r,sin(phi)*r*.48).rotated(tilt)
	draw_circle(moon,r*.095 if launch else 5,Color("#d8d7cb") if launch else gold)
	if launch:
		var left=w*.10
		var width=w*.80
		var y=h*.84
		draw_rect(Rect2(left,y,width,12),Color("#354559"))
		draw_rect(Rect2(left+width*OPEN/SWEEP,y,width*(CLOSE-OPEN)/SWEEP,12),Color("#42836e"))
		draw_line(Vector2(left+width*.5,y-11),Vector2(left+width*.5,y+22),teal,3)
		var x=left+width*pingpong(time,SWEEP)/SWEEP
		draw_colored_polygon(PackedVector2Array([Vector2(x-7,y-12),Vector2(x+7,y-12),Vector2(x,y-2)]),gold)
		words(Vector2(left,y+39),"IGNITION TIMING",teal,14)
		words(Vector2(left+width*.5-27,y+39),"CENTER",gold,14)
	else:words(Vector2(12,h-18),"ORBIT SCHEMATIC",teal,14)


