extends VBoxContainer
const SLOT=4.0
const COLORS=["#5eceb4","#edbc72","#7ebbf2","#cd9de4"]
const NAMES=["◎  Observe","☀  Charge","↑  Downlink","❄  Safe"]
var deck
var m
var stage
var timeline=[]
var actions=[]
var meters=[]
var values=[]
var banner
var advice
var scan_progress
var reward
var pause_button
var storm_buttons=[]
var action_time=0.0
var effect=-1
var feedback=""
func strip():
	var h=HBoxContainer.new()
	add_child(h)
	return h
func setup(parent_deck):
	deck=parent_deck
	m=deck.m
	size_flags_vertical=SIZE_EXPAND_FILL
	var line=strip()
	for i in int(m.d.turns):
		var cell=Label.new()
		cell.text=str(i+1)
		cell.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		cell.size_flags_horizontal=SIZE_EXPAND_FILL
		line.add_child(cell)
		timeline.append(cell)
	stage=preload("res://orbit_stage.gd").new()
	stage.size_flags_vertical=SIZE_EXPAND_FILL
	add_child(stage)
	stage.build_scene(m)
	banner=deck.text_line(stage,"",19)
	banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	banner.grow_horizontal=Control.GROW_DIRECTION_BEGIN
	reward=deck.text_line(stage,"",23)
	reward.position=Vector2(20,16)
	reward.autowrap_mode=TextServer.AUTOWRAP_OFF
	banner.autowrap_mode=TextServer.AUTOWRAP_OFF
	scan_progress=ProgressBar.new()
	scan_progress.show_percentage=false
	scan_progress.custom_minimum_size.y=7
	add_child(scan_progress)
	var gauges=strip()
	for title in ["Science delivered","Onboard data","Battery","Heat"]:
		var column=deck.box(gauges)
		values.append(deck.text_line(column,title,16))
		var bar=ProgressBar.new()
		bar.custom_minimum_size.y=12
		bar.show_percentage=false
		column.add_child(bar)
		meters.append(bar)
	advice=deck.text_line(self,"",20)
	var row=strip()
	for i in 4:
		var b=deck.button(row,NAMES[i],send.bind(i))
		b.custom_minimum_size.y=62
		b.size_flags_horizontal=SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size",20)
		var skin=StyleBoxFlat.new()
		skin.bg_color=Color(COLORS[i]).darkened(.54)
		skin.set_corner_radius_all(10)
		b.add_theme_stylebox_override("normal",skin)
		actions.append(b)
	var tools=strip()
	pause_button=deck.button(tools,"Pause [P]",deck.toggle_pause)
	deck.button(tools,"Save flight",deck.ui.save_game)
	if m.event_due():
		for b in actions:b.hide()
		for i in 2:
			var protect=i==0
			var can_shield=m.s.energy>=18 and m.s.reserve>=8
			var caption="Shield array • Keep full solar power\nSpend 18 Wh + 8 reserve" if protect else "Sample storm • Store particle data\nGain up to 4 science; lose 25% solar power"
			if protect and not can_shield:caption="Shield unavailable\nRequires 18 Wh and 8 reserve"
			var choice=deck.button(row,caption,storm.bind(protect))
			choice.custom_minimum_size.y=62
			choice.size_flags_horizontal=SIZE_EXPAND_FILL
			choice.modulate=Color("#99edcc") if protect==can_shield else Color.WHITE
			storm_buttons.append(choice)
	refresh()
func storm(protect):
	if m.s.get("paused",false):return
	m.anomaly(protect)
	deck.display(deck.ui,true)
func guided():
	return deck.ui.tutorial and m.s.turn==0 and not m.s.get("played",false)
func preferred():
	if guided():return 0
	if deck.ui.tutorial and m.s.turn==1 and m.s.data>0 and m.condition(m.s.turn,4):return 2
	if m.s.data>0 and m.condition(m.s.turn,4):return 2
	if m.s.pending+m.s.sent>=m.goal()[1]:return 1
	if m.s.get("flight_heat",0)>=85:return 3
	if m.s.data>=m.d.storage-.001:return 1
	if m.s.energy<m.part("battery")[3]*.22:return 1
	return 0
func eligible(i):
	var s=m.s
	if s.get("paused",false) or s.get("played",false) or m.event_due():return false
	if guided() and i!=0:return false
	if deck.ui.tutorial and s.turn==1 and s.data>0 and m.condition(s.turn,4) and i!=2:return false
	if i==0:return s.get("flight_heat",0)<90 and s.data<m.d.storage-.001
	if i==2:return m.condition(s.turn,4) and s.data>.001
	return true
func send(i):
	if not eligible(i):return
	var s=m.s
	var old=[s.sent,s.data,s.energy,s.get("flight_heat",m.heat()*.58)]
	m.act(i,false)
	var actual=3 if m.note.begins_with("Insufficient energy") else i
	s["flight_heat"]=clampf(old[3]+([maxf(12,m.heat()*.34),-5.,-3.,-34.][actual]),0,100)
	s["played"]=true
	s["slot_time"]=minf(s.get("slot_time",0),SLOT-.85)
	if s.turn==0 and deck.ui.tutorial:s.slot_time=1
	action_time=0
	effect=actual
	match actual:
		0:feedback="+%.2f GB scanned"%[s.data-old[1]]
		1:feedback="%+.0f Wh battery"%[s.energy-old[2]]
		2:feedback="+%.1f science delivered"%[s.sent-old[0]]
		3:feedback="Cooling   %.0f → %.0f"%[old[3],s.flight_heat]
	refresh()
func update_meter(i,title,n,cap,unit,color):
	values[i].text=title+"   %.1f / %.0f%s"%[n,cap,unit]
	meters[i].max_value=cap
	meters[i].value=n
	meters[i].modulate=Color(color)
func refresh():
	var s=m.s
	var t=float(s.get("slot_time",0))
	var contact=m.condition(s.turn,4)
	var run_start=int(s.turn)
	var run_end=int(s.turn)+1
	while run_start>0 and m.condition(run_start-1,4)==contact:run_start-=1
	while run_end<int(m.d.turns) and m.condition(run_end,4)==contact:run_end+=1
	var fraction=(s.turn-run_start+t/SLOT)/(run_end-run_start)
	var angle=(-PI*.5 if not contact else PI*.5)+PI*fraction
	stage.animate(angle,s.turn*SLOT+t,effect if action_time<.8 else -1,minf(1,action_time/.8),contact,s.energy<m.part("battery")[3]*.22,s.get("flight_heat",0)>=85)
	banner.text=("%s   %.1f s  "%["● CONTACT OPEN" if contact else "× SIGNAL LOST",(run_end-s.turn)*SLOT-t])
	banner.modulate=Color("#85f2ae") if contact else Color("#ffa99f")
	for i in timeline.size():
		var cell=timeline[i]
		var key=str(m.condition(i,4))+str(i==s.turn)
		if cell.get_meta("style","")!=key:
			cell.set_meta("style",key)
			var skin=StyleBoxFlat.new()
			skin.bg_color=Color("#226e58") if m.condition(i,4) else Color("#783f50")
			if i==s.turn:
				skin.set_border_width_all(2)
				skin.border_color=Color.WHITE
			cell.add_theme_stylebox_override("normal",skin)
	update_meter(0,"Science",s.sent,m.goal()[1],"","#79efca")
	update_meter(1,"Storage",s.data,m.d.storage," GB","#99cfff")
	update_meter(2,"Battery",s.energy,m.part("battery")[3]," Wh","#fdcf71")
	var sunlit=m.condition(s.turn,3)
	if s.has("power_delta"):
		var change=float(s.power_delta)
		var change_text="%+.1f Wh"%change
		if is_zero_approx(change):change_text="Full" if is_equal_approx(s.energy,m.part("battery")[3]) else "Balanced"
		values[2].text+="  •  "+change_text
		values[2].tooltip_text="Last action: %.0f W generated, %.0f W used."%[s.power_source_w,s.draw]
	actions[1].tooltip_text="Sunlight: panels can recharge the battery." if sunlit else "In shadow: panels produce no power. A radioisotope generator can still supply power."
	var heat=float(s.get("flight_heat",m.heat()*.58))
	update_meter(3,"Heat",heat,100,"","#ff8876" if heat>=75 else "#eac696")
	var pick=preferred()
	var paused=s.get("paused",false)
	for i in 4:
		actions[i].disabled=not eligible(i)
		actions[i].text=("➜ " if pick==i and eligible(i) else "")+NAMES[i]
		if i==1 and not sunlit and m.generation(false)<m.d.base[2]:actions[i].text=actions[i].text.replace("Charge","Conserve")
		actions[i].modulate=Color.WHITE.lerp(Color(COLORS[i]),.5+.4*sin(Time.get_ticks_msec()*.008)) if pick==i and eligible(i) else Color.WHITE
	pause_button.text="Resume [P]" if paused else "Pause [P]"
	for j in storm_buttons.size():storm_buttons[j].disabled=paused or (j==0 and (s.energy<18 or s.reserve<8))
	scan_progress.value=100*minf(1,action_time/.8) if effect>=0 else 0
	reward.text=feedback if action_time<2.5 else ""
	reward.position.y=24-minf(16,action_time*14)
	if paused:
		advice.text="Paused. Click Resume or press P to continue."
	elif m.event_due():
		banner.text="SOLAR STORM   •   CLOCK STOPPED"
		advice.text="Choose one response below to restart the clock. "+("For a first flight, shield your panels." if not storm_buttons[0].disabled else "Shielding needs more resources. Choose Sample storm.")
	elif s.get("played",false):
		advice.text="Action complete. Next move in %.1f s."%maxf(0,SLOT-t)
		if s.turn==0 and s.data>0:advice.text="Scan stored! In %.1f s, click Downlink to send it to Earth."%maxf(0,SLOT-t)
	elif guided():
		advice.text="Click Observe to scan. The clock waits for your first scan."
	elif deck.ui.tutorial and s.turn==1 and contact and s.data>0:
		advice.text="Click Downlink now. Stored data earns science when it reaches Earth."
	else:
		advice.text=["Click Observe to fill storage. Send it on a green slot.","Click Charge to save battery for the next scan.","Click Downlink while Earth is in range to score.","Click Safe to cool down before scanning again."][pick]
	if pick==1 and not sunlit and m.generation(false)<m.d.base[2] and not paused and not m.event_due() and not s.get("played",false):
		advice.text="In shadow. Click Conserve to idle until sunlight returns."
	if not paused and not m.event_due() and not s.get("played",false) and not contact and s.data>=m.d.storage-.001:
		advice.text="Storage full. Wait for a green slot, then click Downlink."
func _process(dt):
	if not is_visible_in_tree() or not m or m.stage!=3:return
	var s=m.s
	if not s.get("paused",false) and not m.event_due():
		action_time+=dt
		if not guided() and not (deck.ui.tutorial and s.turn==1 and s.data>0 and m.condition(s.turn,4) and not s.get("played",false)):
			s["slot_time"]=s.get("slot_time",0)+dt
		if s.get("slot_time",0)>=SLOT:
			if not s.get("played",false):
				m.act(1,false)
				s["flight_heat"]=maxf(0,s.get("flight_heat",m.heat()*.58)-5)
			m.finish_slot()
			s["slot_time"]=0
			s["played"]=false
			if m.stage==4 or s.sent>=m.goal()[1]:
				deck.ui.end_mission()
				return
			if m.event_due() or (m.c.goal==1 and not s.get("flyby_done",false) and m.condition(s.turn,4)):
				deck.display(deck.ui,true)
				return
	refresh()





