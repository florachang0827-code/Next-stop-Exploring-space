extends Control
signal finished
var m
var elapsed=0.0
var exposure=0.0
var aim=Vector2(.5,.5)
var tracking=false
var transfer=-1.0
var framed=Vector2.ZERO
var photo
var last_frame=Rect2()
var result=false
var send_button
func setup(model):
	m=model
	size_flags_vertical=SIZE_EXPAND_FILL
	mouse_filter=MOUSE_FILTER_STOP
	send_button=Button.new()
	send_button.text="Transmit photo"
	add_child(send_button)
	send_button.pressed.connect(send_photo)
func target():
	return Vector2(.12+.76*elapsed/20,.48+.13*sin(elapsed*.43))
func seconds_to_send():
	return 2.0+2.0/maxf(.25,m.link_rate())+.16*exposure
func send_photo():
	if m.s.get("paused",false):return
	if result:
		finished.emit()
		return
	if exposure<=0 or transfer>=0:return
	tracking=false
	capture_photo()
	transfer=seconds_to_send()
func _gui_input(event):
	if result or transfer>=0 or m.s.get("paused",false):return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		tracking=event.pressed
		aim=event.position/size
	if event is InputEventMouseMotion:
		tracking=(event.button_mask&MOUSE_BUTTON_MASK_LEFT)!=0
		if tracking:aim=event.position/size
func capture_photo():
	if photo or last_frame.size.x<=0 or DisplayServer.get_name()=="headless":return
	var image=get_viewport().get_texture().get_image()
	if not image:return
	var region=Rect2i(last_frame).intersection(Rect2i(Vector2i.ZERO,image.get_size()))
	if region.has_area():
		var crop=image.get_region(region)
		crop.resize(320,240)
		photo=ImageTexture.create_from_image(crop)
		m.s["flyby_photo"]=Marshalls.raw_to_base64(crop.save_png_to_buffer())
func finish(delivered):
	capture_photo()
	result=true
	tracking=false
	var points=snappedf(minf(14,2+exposure*1.8),.1) if delivered else 0.0
	m.s.sent+=points
	m.s["flyby_done"]=true
	m.s["flyby_points"]=points
	m.s["flyby_frame"]=[framed.x,framed.y]
	m.note="Crater photo delivered: %.1f science."%points if delivered else "Earth set before the photo arrived. Observe and downlink at the next contact."
	send_button.text="Continue operations"
	send_button.disabled=false
func _process(dt):
	if not is_visible_in_tree():return
	send_button.position=Vector2(15,size.y-46)
	if result or m.s.get("paused",false):
		tracking=false
		queue_redraw()
		return
	var step=minf(dt,20-elapsed)
	elapsed+=step
	if transfer>=0:
		transfer-=step
		if transfer<=.0001:finish(true)
	elif tracking and (aim*size).distance_to(target()*size)<38 and m.s.get("flight_heat",0)<95:
		exposure+=step
		framed=aim-target()
		last_frame= get_global_transform_with_canvas()*Rect2(aim*size-Vector2(80,60),Vector2(160,120))
		m.s["flight_heat"]=minf(100,m.s.get("flight_heat",m.heat()*.58)+step*4)
	if not result and elapsed>=20:finish(false)
	send_button.disabled=not result and (exposure<=0 or transfer>=0)
	queue_redraw()
func words(p,t,sz=19):
	draw_string(ThemeDB.fallback_font,p,t,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,Color.WHITE)
func _draw():
	if not m:return
	draw_rect(Rect2(Vector2.ZERO,size),Color("#26394a"))
	var center=size*(target() if not result else Vector2(.5,.5)-framed)
	for i in 54:
		var p=Vector2(fposmod(i*117.6-elapsed*12,size.x),fposmod(i*i*37.2,size.y))
		var r=4+i%13
		draw_circle(p,r,Color("#415568"))
		draw_circle(p+Vector2(1,-2),r*.83,Color("#344655"))
	draw_circle(center,34,Color("#e5c18f"))
	draw_circle(center+Vector2(3,-5),29,Color("#777b81"))
	draw_circle(center+Vector2(8,-7),20,Color("#505669"))
	if not result:
		draw_arc(aim*size,38,0,TAU,48,Color("#83ebd2"),2,true)
		words(Vector2(15,27),"SUNLIT CRATER   /   Earth sets in %.1f s"%maxf(0,20-elapsed))
		words(Vector2(15,54),"Hold and drag over the gold crater. Then click Transmit photo before Earth sets.")
		words(Vector2(15,81),"Exposure %.1f s    |    Heat %.0f%%    |    Transmission %.1f s"%[exposure,m.s.get("flight_heat",m.heat()*.58),seconds_to_send()])
		if transfer>=0:words(Vector2(15,108),"Sending to Earth ... %.1f s"%transfer)
	else:
		if photo:draw_texture_rect(photo,Rect2(size*.15,size*.7),false)
		words(Vector2(15,34),"FLYOVER RESULT   /   "+m.note)
		words(Vector2(15,62),"Click Continue operations to finish the survey.")


