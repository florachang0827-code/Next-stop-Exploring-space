extends PanelContainer
const SLOT=9.0
const Plot=preload("res://flight_plot.gd")
const OPEN=Plot.OPEN
const CLOSE=Plot.CLOSE
const CENTER=Plot.CENTER
const ACTIONS=["Observe","Charge","Downlink","Safe"]
var ui
var m
var body
var plot
var probe
var live
var battery
var thermal
var link
var packet_label
var instruction
var key_button
var controls=[]
var pause_button
var flyby
var game
var ops=false
func text_line(parent,t="",font=18):
	var l=Label.new()
	l.text=t
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size",font)
	parent.add_child(l)
	return l
func box(parent):
	var v=VBoxContainer.new()
	v.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(v)
	return v
func button(parent,t,cb):
	var b=Button.new()
	b.text=t
	b.custom_minimum_size.y=42
	b.pressed.connect(cb)
	parent.add_child(b)
	return b
func display(interface,operations):
	ui=interface
	m=ui.m
	ops=operations
	for n in get_children():
		remove_child(n)
		n.queue_free()
	game=null
	controls.clear()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg=StyleBoxFlat.new()
	bg.bg_color=Color("#112737")
	bg.content_margin_left=28
	bg.content_margin_right=28
	bg.content_margin_top=22
	bg.content_margin_bottom=20
	add_theme_stylebox_override("panel",bg)
	body=box(self)
	var header=HBoxContainer.new()
	body.add_child(header)
	var title=text_line(header,"Orbital Operations" if ops else "Launch Window",32)
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(header,"Return to hall  [Esc]",ui.open.bind(-1))
	text_line(body,m.goal()[0]+"    /    SELENE FLIGHT CONTROL",17).modulate=Color("#9bdacb")
	plot=preload("res://flight_plot.gd").new()
	plot.launch=not ops
	plot.size_flags_vertical=Control.SIZE_EXPAND_FILL
	if not ops:
		body.add_child(plot)
		live=text_line(body,"",24)
		instruction=text_line(body,"Press Enter or click Ignite as the arrow crosses green. Missed it? Wait for the return pass.")
		key_button=button(body,"Ignite  [Enter]",ignite)

		refresh_launch()
		return
	if m.c.goal==1 and not m.s.get("flyby_done",false) and m.condition(m.s.turn,4) and not m.event_due():
		plot.free()
		flyby=preload("res://lunar_flyby.gd").new()
		body.add_child(flyby)
		flyby.setup(m)
		pause_button=button(body,"Pause  [P]",toggle_pause)
		flyby.finished.connect(display.bind(ui,true))
		return
	flyby=null
	plot.free()
	game=preload("res://orbit_game.gd").new()
	body.add_child(game)
	game.setup(self)
func ignite():
	if ops or m.stage!=2:return
	var t=pingpong(float(m.s.get("launch_t",0)),Plot.SWEEP)
	if m.s.has("timing"):return
	if t<OPEN or t>CLOSE:
		m.note="Missed the band. Try the next pass."
	else:
		m.s["timing"]=clampf(1-absf(t-CENTER)/(CENTER-OPEN),0,1)
		m.s["capture_time"]=0.0
		chime()
	refresh_launch()
func chime():
	if not ui.sound:return
	var player=AudioStreamPlayer.new()
	var wave=AudioStreamWAV.new()
	wave.format=AudioStreamWAV.FORMAT_8_BITS
	wave.mix_rate=22050
	var data=PackedByteArray()
	for i in 11025:
		var n=mini(2,int(i/2600))
		data.append(int(128+35*sin(TAU*[440,554,660][n]*i/22050.0)*exp(-float(i%2600)/1900)))
	wave.data=data
	player.stream=wave
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
func refresh_launch():
	var t=pingpong(float(m.s.get("launch_t",0)),Plot.SWEEP)
	plot.time=float(m.s.get("launch_t",0))
	plot.captured=m.s.has("timing")
	plot.queue_redraw()
	if plot.captured:
		live.text="ORBIT ACQUIRED   •   %.1f maneuver units saved"%(m.insertion()*.2*m.s.timing)
		live.modulate=Color("#83efab")
		key_button.disabled=true
	else:
		key_button.text="Ignite  [Enter]"
		live.text="GREEN WINDOW   •   Ignite now!" if t>=OPEN and t<=CLOSE else ("Missed. Try the next pass." if m.note.begins_with("Missed") else "Aim for the green band on either pass.")
func toggle_pause():
	if not ops:return
	m.s["paused"]=not m.s.get("paused",false)
	if is_instance_valid(game):game.refresh()
	elif is_instance_valid(flyby):pause_button.text="Resume  [P]" if m.s.paused else "Pause  [P]"
func _process(dt):
	if not visible or not m:return
	if not ops and m.stage==2:
		if m.s.has("timing"):
			m.s["capture_time"]=m.s.get("capture_time",0)+dt
			if m.s.capture_time>=1.7:ui.finish_flight()
		else:m.s["launch_t"]=m.s.get("launch_t",0)+dt
		if visible and not ops:refresh_launch()


