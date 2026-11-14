extends Control
var bay
var clock=0.0
func _process(dt):
	if is_visible_in_tree() and bay.ui and bay.overlay=="Mass" and abs(bay.ui.m.balance())>.105:
		clock+=dt
		queue_redraw()
func origin():return Vector2(size.x*.5,size.y*.46)
func scale_u():return minf(size.x/540,size.y/390)
func socket(side):return origin()+Vector2(side*142,35)*scale_u()
func hit(pos):
	for side in [-1,1]:
		if socket(side).distance_to(pos)<43*scale_u():return side
	return 0
func _can_drop_data(pos,data):return data is Dictionary and data.has("part") and hit(pos)!=0
func _drop_data(pos,data):
	if _can_drop_data(pos,data):bay.fit(data,hit(pos))
func _gui_input(e):
	if e is InputEventMouseButton and e.button_index==MOUSE_BUTTON_LEFT and e.pressed and hit(e.position)!=0 and not bay.selected.is_empty():
		bay.fit(bay.selected,hit(e.position))
func words(p,t,color=Color.WHITE,sz=16):draw_string(ThemeDB.fallback_font,p,t,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,color)
func _draw():
	if not bay or not bay.ui or size.x<1 or size.y<1:return
	var m=bay.ui.m
	var o=origin()
	var u=scale_u()
	var mint=Color("#80dccf")
	var gold=Color("#f7bf73")
	var red=Color("#ff786c")
	draw_rect(Rect2(Vector2.ZERO,size),Color("#102939"))
	for x in range(0,int(size.x),28):draw_line(Vector2(x,0),Vector2(x,size.y),Color("#1c3947"))
	for y in range(0,int(size.y),28):draw_line(Vector2(0,y),Vector2(size.x,y),Color("#1c3947"))
	words(Vector2(16,28),"ORBITER   /   ENGINEERING SCHEMATIC",mint)
	draw_set_transform(o,0,Vector2.ONE*u)
	var hull=PackedVector2Array([Vector2(-51,-92),Vector2(34,-92),Vector2(56,-68),Vector2(56,67),Vector2(29,88),Vector2(-45,88),Vector2(-59,63),Vector2(-59,-65)])
	draw_colored_polygon(hull,Color("#c5b59a"))
	draw_rect(Rect2(-43,-68,83,130),Color("#394e61"))
	draw_rect(Rect2(-37,-62,72,116),Color("#91aab1"))
	var wing_side=m.side("solar")
	var width=(115 if m.c.solar==1 else 81)*maxf(.25,cos(deg_to_rad(m.hardware.panel_angle)))
	draw_line(Vector2(0,-32),Vector2(wing_side*76,-32),gold,6)
	var wing=Rect2(68 if wing_side==1 else -68-width,-60,width,54)
	draw_rect(wing,Color("#305982"))
	draw_rect(wing,mint,false,2)
	for j in range(1,5):draw_line(wing.position+Vector2(width*j/5,0),wing.position+Vector2(width*j/5,54),Color("#86a8c9"),1)
	var ant=Vector2(m.side("antenna")*41,-94)
	var aim=Vector2.UP.rotated(deg_to_rad(m.hardware.antenna_angle)*m.side("antenna"))
	draw_line(ant,ant+aim*22,gold,4)
	draw_arc(ant+aim*31,20 if m.c.antenna==1 else 12,aim.angle()+.35,aim.angle()+PI*2-.35,24,mint,3)
	var nozzle=Vector2(m.side("drive")*13,87)
	draw_colored_polygon(PackedVector2Array([nozzle+Vector2(-9,0),nozzle+Vector2(9,0),nozzle+Vector2(18,22),nozzle+Vector2(-18,22)]),[Color("#c6855b"),mint,Color("#82a0c2")][m.c.drive])
	draw_rect(Rect2(m.side("battery")*24-11,26,22,16+8*m.c.battery),gold)
	for i in m.c.tools.size():
		if m.c.tools[i]:
			var pt=Vector2(m.side("tool"+str(i))*59,-48+i*25)
			draw_circle(pt,10,[Color("#84d3ef"),Color("#b69ce4"),gold,mint][i])
			draw_circle(pt,4,Color("#203144"))
	var extras=m.d.extras.keys()
	for i in extras.size():
		var k=extras[i]
		if m.extra(k):
			var pt=Vector2(m.side(k)*(23+(i%2)*12),-49+floori(i/2.0)*24)
			draw_rect(Rect2(pt,Vector2(13,17)),[mint,gold,Color("#d987a7")][i%3])
	for side in [-1,1]:
		var pt=(socket(side)-o)/u
		draw_line(Vector2(side*60,35),pt,Color("#55848a"),2)
		draw_circle(pt,23,Color("#1b4658"))
		draw_arc(pt,22,0,TAU,32,gold if bay.selected.size() else mint,2)
		words(pt+Vector2(-6,6),"+")
		words(pt+Vector2(-40,43),"PORT" if side<0 else "STARBOARD",mint,13)
	var info=""
	match bay.overlay:
		"Mass":
			var shift=m.balance()
			var col=gold if abs(shift)>.105 and sin(clock*5)>0 else mint
			draw_line(Vector2(0,-110),Vector2(0,125),mint,1)
			draw_circle(Vector2(shift*145,0),8,col)
			info="Center of mass: %+.2f m. "%shift+("Off-axis thrust: 7% efficiency loss." if abs(shift)>.105 else "Thrust line aligned.")
		"Power":
			var pts=PackedVector2Array()
			for j in 16:
				pts.append(Vector2(-120+j*16,134-m.generation(m.condition(j,3))*.19))
			draw_polyline(pts,gold,3)
			info="Sunlight %.0f W   /   Eclipse %.0f W   /   Observe %.0f W"%[m.generation(true),m.generation(false),m.totals()[2]]
		"Heat":
			for i in m.c.tools.size():
				if m.c.tools[i]:draw_circle(Vector2(m.side("tool"+str(i))*59,-48+i*25),12+m.d.tools[i][3]*.18,Color(1,.18,.08,.34))
			info="Combined heat load: %.1f / %.0f classroom units. Radiators remove heat."%[m.heat(),m.d.engineering.heat_limit]
		"Comms":
			var tip=ant+aim*23
			draw_colored_polygon(PackedVector2Array([tip,tip+aim.rotated(-.28)*90,tip+aim.rotated(.28)*90]),Color(1,.2,.18,.8) if m.blocked_link() else Color(.32,.9,.8,.55))
			info="Beam blocked by solar wing. Change mount or angle." if m.blocked_link() else "Clear beam • %.2f GB per contact"%m.link_rate()
		"Envelope":
			var lim=m.d.engineering.fairing[m.c.rocket]
			draw_rect(Rect2(-lim*60,-142,lim*120,270),red if m.span()>lim else mint,false,3)
			draw_line(Vector2(-m.span()*60,118),Vector2(m.span()*60,118),gold,4)
			info="Stowed width %.2f m   /   Fairing %.2f m"%[m.span(),lim]
		"Cost":
			info="Installed equipment prices (M)"
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	words(Vector2(14,size.y-18),info,gold,15)
	if bay.overlay=="Cost":
		var y=53
		for g in bay.GROUPS:
			for k in bay.GROUPS[g]:
				var items=bay.options(k)
				for i in items.size():
					if bay.installed(k,i):
						words(Vector2(12,y),"%s   %d M"%[items[i][0],items[i][1]],mint,13)
						y+=17

