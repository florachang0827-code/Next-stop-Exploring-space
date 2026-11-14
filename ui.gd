extends CanvasLayer
var world
var m
var hud=Label.new()
var hint=Label.new()
var guide=Label.new()
var last_position=Vector3.ZERO
var wandered=0.0
var panel=PanelContainer.new()
var content=VBoxContainer.new()
var footer=VBoxContainer.new()
var heading=Label.new()
var bay
var deck
var page=-1
var checklist=PanelContainer.new()
var step_buttons:Array[Button]=[]
var nav_station=-1
const STATIONS=[0,1,1,2,2,3,3]
const PAGES=[0,1,7,2,8,3,6]
var nav_step=-1
func navigate_step(i):
	nav_step=i
	nav_station=STATIONS[i]
	open(-1)
	if world.occupied==nav_station:world.occupied=-1
var next_step=Button.new()
func task_index():
	if m.stage==0:return 0
	if m.stage==1:return clampi(int(m.s.get("design_step",3 if m.s.get("prepared",false) else 1)),1,4)
	if m.stage==2:return 4
	return 5 if m.stage==3 else 6
func follow_task():
	open(5 if m.stage==2 else PAGES[task_index()])
func visit_station(i):
	var step=nav_step
	if step<0 and STATIONS[task_index()]==i:step=task_index()
	if step==4 and m.stage==2:open(5)
	elif step==6 and m.stage!=4:open(3)
	elif step>=0 and STATIONS[step]==i:open(PAGES[step])
	else:open(i)
func update_steps():
	checklist.visible=m.stage>0 and page<0
	if not checklist.visible:return
	var idx=task_index()
	var sent=float(m.s.get("sent",0))
	var names=["Set the science goal","Build the spacecraft and fit instruments","Adjust the spacecraft","Choose a rocket and orbit","Pass the launch checks","Operate and return science  %d / %d"%[floori(sent),m.goal()[1]],"Review the mission"]
	for i in names.size():
		var done=i<idx or (i==6 and m.stage==4)
		if i==5:done=sent>=m.goal()[1]
		step_buttons[i].visible=i not in [2,4] or idx==i
		step_buttons[i].text=("[x]  " if done else (">    " if i==idx else "[ ]  "))+names[i]
	next_step.text="Continue: "+names[idx]
func commit_step(step):
	if task_index()<step:
		follow_task()
		return
	m.s["design_step"]=step+1
	follow_task()
func invalidate(step):
	m.s.erase("approval")
	m.s["design_step"]=mini(task_index(),step)
func recommended():
	m.c.tools=[m.c.goal==1,m.c.goal==0,m.c.goal==2,false]
	invalidate(1)
	world.refresh()
	open(1)
var tutorial=true
var sound=true
var elapsed=0.0
var status=""
var tone=AudioStreamPlayer.new()
const SAVE="user://flight.json"
func label(parent,t):
	var l=Label.new()
	l.text=t
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l
func assessment_bar(parent,value,maximum,color):
	var bar=ProgressBar.new()
	bar.max_value=maximum
	bar.value=value
	bar.show_percentage=false
	bar.custom_minimum_size.y=9
	for key in ["background","fill"]:
		var skin=StyleBoxFlat.new()
		skin.bg_color=color if key=="fill" else Color("#293e4d")
		skin.set_corner_radius_all(4)
		bar.add_theme_stylebox_override(key,skin)
	parent.add_child(bar)
func design_metrics():
	for row in Review.rows(m):
		var level=int(row[1])
		var tint=[Color("#82d9b4"),Color("#f4c16c"),Color("#fa9188")][level]
		label(content,"%s   /   %s     %s"%[row[0],["Ready","Caution","Conflict"][level],row[2]])
		assessment_bar(content,[100,70,20][level],100,tint)
func btn(parent,t,fn,major=false):
	var b=Button.new()
	b.text=t
	b.custom_minimum_size.y=34
	for state in ["normal","hover","pressed","disabled"]:
		var skin=StyleBoxFlat.new()
		skin.bg_color={"normal":Color("#a6cfc2") if major else Color("#244452"),"hover":Color("#396275"),"pressed":Color("#395a60"),"disabled":Color("#28343f")}[state]
		skin.set_corner_radius_all(8)
		skin.content_margin_left=8
		skin.content_margin_right=8
		b.add_theme_stylebox_override(state,skin)
	if major:b.add_theme_color_override("font_color",Color("#132930"))
	b.pressed.connect(func(): beep();fn.call())
	if major:b.modulate=Color("#ffbf80")
	parent.add_child(b)
	return b
func beep():
	if sound:tone.play()
func setup(w):
	world=w
	bay=preload("res://ship_bay.gd").new()
	add_child(bay)
	bay.hide()
	deck=preload("res://flight_deck.gd").new()
	add_child(deck)
	deck.hide()
	var arrow=preload("res://brief_arrow.gd").new()
	arrow.station_world=w
	add_child(arrow)
	last_position=w.get_node("Commander").position
	add_child(guide)
	guide.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	guide.offset_top=-53
	guide.offset_bottom=-19
	guide.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	guide.mouse_filter=Control.MOUSE_FILTER_IGNORE
	guide.add_theme_font_size_override("font_size",17)
	guide.add_theme_constant_override("outline_size",5)
	guide.add_theme_color_override("font_outline_color",Color("#172331"))
	guide.hide()
	m=w.mission
	var wave=AudioStreamWAV.new()
	wave.format=AudioStreamWAV.FORMAT_8_BITS
	wave.mix_rate=22050
	var bytes=PackedByteArray()
	for i in 1100:bytes.append(int(128+24*sin(i*.16)*(1.0-i/1100.0)))
	wave.data=bytes
	tone.stream=wave
	add_child(tone)
	var top=PanelContainer.new()
	var hud_style=StyleBoxFlat.new()
	hud_style.bg_color=Color("#142c40ee")
	hud_style.set_corner_radius_all(12)
	hud_style.content_margin_left=12
	hud_style.content_margin_right=12
	hud_style.content_margin_top=8
	hud_style.content_margin_bottom=8
	top.add_theme_stylebox_override("panel",hud_style)
	add_child(top)
	top.position=Vector2(18,16)
	var bar=VBoxContainer.new()
	top.add_child(bar)
	bar.add_child(hud)
	var row=HBoxContainer.new()
	bar.add_child(row)
	for i in 4:btn(row,w.labels[i],visit_station.bind(i))
	btn(row,"Help",open.bind(4))
	btn(row,"Save",save_game)
	btn(row,"Load",load_game)
	btn(row, "Switch mission", ask_switch_mission)
	btn(row,"Zoom +",func():open(-1);world.get_node("Commander").zoom(.8))
	btn(row,"Zoom -",func():open(-1);world.get_node("Commander").zoom(1.25))
	btn(row,"View [V]",func():open(-1);world.get_node("Commander").toggle_view())
	add_child(hint)
	hint.position=Vector2(22,116)
	add_child(panel)
	panel.anchor_left=1
	panel.anchor_right=1
	panel.anchor_bottom=1
	panel.offset_left=-522
	panel.offset_right=-16
	panel.offset_top=120
	panel.offset_bottom=-14
	var style=StyleBoxFlat.new()
	style.bg_color=Color("#142c40")
	style.set_corner_radius_all(14)
	style.content_margin_left=18
	style.content_margin_right=18
	style.content_margin_top=14
	style.content_margin_bottom=12
	panel.add_theme_stylebox_override("panel",style)
	var body=VBoxContainer.new()
	panel.add_child(body)
	heading.add_theme_font_size_override("font_size",24)
	heading.modulate=Color("#a4e4dd")
	body.add_child(heading)
	var scroll=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	body.add_child(footer)
	add_child(checklist)
	checklist.position=Vector2(18,159)
	checklist.add_theme_stylebox_override("panel",hud_style)
	var list=VBoxContainer.new()
	checklist.add_child(list)
	label(list,"MISSION CHECKLIST")
	for i in 7:
		var row_button=btn(list,"",navigate_step.bind(i))
		row_button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		step_buttons.append(row_button)
	list.add_child(next_step)
	next_step.pressed.connect(follow_task)
	move_child(arrow,-1)
	open(0)
func clear(box):
	for n in box.get_children():
		box.remove_child(n)
		n.queue_free()
func open(i):
	if i>=0:
		nav_station=-1
		nav_step=-1
	page=i
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deck.visible=(i==5 and m.stage==2) or (i==3 and m.stage==3)
	if deck.visible:
		move_child(deck,-1)
		deck.display(self,i==3)
	bay.visible=i in [1,7] and m.stage==1
	if bay.visible:
		move_child(bay,-1)
		bay.display(self)
	panel.visible=i>=0 and not bay.visible and not deck.visible
	hud.get_parent().get_parent().visible=i<0
	hint.visible=i<0
	world.get_node("Commander").locked=i>=0
	if i<0 or bay.visible or deck.visible:return
	clear(content)
	clear(footer)
	heading.text=["Mission brief","Spacecraft assembly","Launch control","Orbital tracking","Flight handbook","Transfer to lunar orbit","Mission review","Design the spacecraft","Preflight checks","3. Design Review"][i]
	if i==0:brief()
	if i==1:assembly()
	if i==2:launchpad()
	if i==3:tracking()
	if i==4:help()
	if i==5:
		diagram(true)
		label(content,"Ascent  /  Coast  /  Lunar insertion")
		btn(footer,"Skip transfer",finish_flight,true)
	if i==6:review()
	if i==7:spacecraft()
	if i==8:preflight()
	if i==9:design_board()
	if i!=5:btn(footer,"Return to hall   [Esc]",open.bind(-1))
func brief():
	label(content,"Space Mission Design Lab")
	label(content,"Choose a science question below, then click Start designing. Your goal is to collect measurements and send them back to Earth.")
	for i in 3:
		var g=m.d.missions[i]
		var b=btn(content,("%s  •  %d points"%[g[0],g[1]]),choose_goal.bind(i))
		b.disabled=m.stage>=2
		if m.c.goal==i:b.modulate=Color("#94e0ce")
	var g=m.goal()
	var names=[]
	for k in g[2]:names.append(m.d.tools[int(k)][0])
	label(content,"Required: %s\nRecommended orbit: %s\nScience multipliers • Camera %.1f / Spectrometer %.1f / Radar %.1f"%[" or ".join(names),g[5],g[3][0],g[3][1],g[3][2]])
	if m.stage<2:btn(footer,"Start designing",accept,true)
func choose_goal(i):
	m.c.goal=i
	m.s.erase("prepared")
	m.s["design_step"]=1
	open(0)
func accept():
	m.stage=1
	open(1)
func assembly():
	if m.stage!=1:
		label(content,"Accept a mission first." if m.stage==0 else "The flight configuration is locked.")
		return
	label(content,"Science instruments • Price, weight and power use")
	if tutorial:label(content,"Click an instrument to install it. A camera maps the surface, a spectrometer measures light to look for signs of ice, and radar sends radio waves to probe below the surface.")
	btn(content,"Select recommended instrument",recommended,true)
	for i in m.d.tools.size():
		var a=m.d.tools[i]
		btn(content,("%s %s   /   %d M   %d kg   %d W   %.2f GB"%["[on]" if m.c.tools[i] else "[off]",a[0],a[1],a[2],a[3],a[4]]),toggle.bind(i))
	var ready=false
	for instrument in m.goal()[2]:
		if m.c.tools[int(instrument)]:ready=true
	if not ready:label(content,"Install an instrument suited to your science goal.").modulate=Color("#ffaaaa")
	btn(footer,"Confirm instruments",commit_step.bind(1),true).disabled=not ready
func spacecraft():
	if m.stage!=1 or task_index()<2:
		label(content,"Confirm the science instruments first.")
		return
	label(content,"Solar panels generate power in sunlight. Batteries supply it in shadow. A larger antenna sends more data per contact. Propulsion provides the reserve needed to enter orbit.")
	for k in ["solar","battery","antenna","drive"]:picker(k)
	label(content,"Transfer duration is fixed for teaching. Propulsion reserve is an abstract maneuver unit.")
	summary()
	btn(footer,"Confirm design and continue",commit_step.bind(2),true)
func toggle(i):
	invalidate(1)
	m.c.tools[i]=not m.c.tools[i]
	world.refresh()
	open(1)
func picker(k):
	var o=OptionButton.new()
	for a in m.d[k]:
		var t=""
		match k:
			"rocket":t="%s  /  %d M  /  %d kg capacity"%[a[0],a[1],a[2]]
			"orbit":t="%s  /  %d reserve  /  %.2fx resolution"%[a[0],a[1],a[2]]
			_:t="%s  /  %d M  /  %d kg  /  %s %s"%[a[0],a[1],a[2],a[3],{"solar":"W","battery":"Wh","antenna":"GB/contact","drive":"reserve"}[k]]
		o.add_item(t)
	label(content,k.capitalize())
	content.add_child(o)
	o.select(m.c[k])
	o.item_selected.connect(func(i):invalidate(3 if k in ["rocket","orbit"] else 2);m.c[k]=i;open(page))
func summary():
	var a=m.totals()
	label(content,"Cost %d / 140 M   •   Mass %d / %d kg\nObservation %d W   •   %.2f GB per observation"%[a[0],a[1],m.part("rocket")[2],a[2],a[3]])
	var fixes=launch_fixes()
	for i in fixes.size():
		if page==8 and i==0:continue
		label(content,"Must fix: "+fixes[i]).modulate=Color("#ffaaaa")
	var tips={
		"Observation draws more than sunlight supplies.":"Your instruments use power faster than your panels make it. The battery covers the difference.",
		"Limited battery margin through eclipse.":"In the Moon's shadow your panels stop making electricity. Save battery power before an eclipse.",
		"Data production exceeds one contact's capacity.":"One observation makes more data than your antenna can send in one contact. Plan extra downlinks.",
		"Low target coverage.":"This path spends little time over the target, so each observation earns less science.",
		"Little maneuver reserve after insertion.":"Entering orbit uses most of your maneuver reserve. Less will be available to protect the spacecraft during solar activity."}
	for r in m.risks():label(content,"Caution (launch allowed): "+tips.get(r,r)).modulate=Color("#ffd08a")
func science_fix():
	var draft=preload("res://mission.gd").new()
	draft.c=m.c.duplicate(true)
	draft.hardware=m.hardware.duplicate(true)
	draft.s=m.s.duplicate(true)
	var goal_text="Earth needs %d science points. "%m.goal()[1]
	for i in draft.c.tools.size():
		if not draft.c.tools[i]:continue
		draft.c.tools[i]=false
		if draft.checks().is_empty():
			return goal_text+"Open Science and click Remove %s. It uses up space in each radio transmission."%m.d.tools[i][0]
		draft.c.tools[i]=true
	for orbit in m.d.orbit.size():
		draft.c.orbit=orbit
		if draft.checks().is_empty():
			return goal_text+"In the rocket and orbit settings, choose %s under Orbit. This path can return enough measurements."%m.d.orbit[orbit][0]
	draft.c.orbit=m.c.orbit
	draft.c.antenna=1
	draft.hardware.mounts["antenna"]=-m.side("solar")
	if draft.checks().is_empty():
		return goal_text+"Open Communications, click %s antenna, then click the %s + mount. It sends more data each time."%[m.d.antenna[1][0],"PORT" if draft.side("antenna")<0 else "STARBOARD"]
	return goal_text+"Click Use starter design to replace the current parts and orbit with a setup that can meet the goal."
func starter_design():
	var starter=preload("res://mission.gd").new()
	starter.c.goal=m.c.goal
	starter.c.tools[[1,0,2][m.c.goal]]=true
	if not starter.checks().is_empty():return
	m.c=starter.c
	m.hardware=starter.hardware
	m.s={}
	invalidate(1)
	world.refresh()
	open(1)
func launch_fixes():
	var required=[]
	for i in m.goal()[2]:required.append(m.d.tools[int(i)][0])
	var fit=["A spectrometer measures light to look for ice; radar can probe beneath the surface.","A camera records images used to map the terrain.","Radar sends radio waves below the surface to reveal layers."][m.c.goal]
	var fixes=[]
	var errors=m.checks()
	for e in errors:
		match e:
			"Too little science can reach Earth in 16 turns.":fixes.append(science_fix())
			"Install a science instrument.":fixes.append("No science instrument is installed. At the assembly bench, select %s. %s"%[" or ".join(required),fit])
			"Required science instrument missing.":
				if true in m.c.tools:fixes.append("Open Science and install %s. %s"%[" or ".join(required),fit])
			"Budget exceeded.":fixes.append("Your design costs %d M over budget. Remove optional equipment or choose a cheaper rocket."%(m.totals()[0]-m.d.budget))
			"Payload exceeds launcher capacity.":fixes.append("Your spacecraft is %d kg too heavy for this rocket. Choose a rocket with a higher payload limit or remove equipment."%(m.totals()[1]-m.part("rocket")[2]))
			"Insufficient insertion reserve.":fixes.append("The spacecraft cannot make the maneuver needed to enter this orbit. Choose a lower-cost orbit or upgrade propulsion.")
			"Orbit never covers this target.":fixes.append("This orbit never passes over the target. Choose a polar orbit to fly over the Moon's poles.")
			_:fixes.append(e)
	return fixes
func launchpad():
	if m.stage!=1:
		label(content,"Accept a mission before launch." if m.stage==0 else "Launch configuration committed.")
		if m.stage>=2:btn(content,"Continue flight",open.bind(6 if m.stage==4 else (5 if m.stage==2 else 3)))
		return
	label(content,"Choose a rocket that can lift your spacecraft and an orbit that crosses your target. Click Design review for expert feedback, or Test this design in flight for a quick flight.")
	picker("rocket")
	picker("orbit")
	design_metrics()
	label(content,"Target coverage %.0f%%. High polar offers three contacts per four turns."%(100*m.coverage()))
	if task_index()<3:label(content,"Confirm your instruments and spacecraft design before continuing.")
	var a=m.totals()
	var limit_error=a[0]>m.d.budget or a[1]>m.part("rocket")[2]
	if limit_error:
		label(footer,"REVIEW BLOCKED: cut optional parts to reduce cost or mass, or select a rocket within both limits.").modulate=Color("#ffaaaa")
		btn(footer,"Rework spacecraft",open.bind(7))
	var issues=launch_fixes()
	if issues.is_empty() and not m.contract()[2]:
		issues.append("Too little science can reach Earth. Change the instruments, antenna or orbit.")
	if not issues.is_empty():
		label(footer,"Fix before flight: "+str(issues[0])).modulate=Color("#ffaaaa")
		if str(issues[0]).contains("Click Use starter design"):btn(footer,"Use starter design",starter_design)
	btn(footer,"Design review • Meet the three reviewers",enter_design_review,true).disabled=task_index()<3 or limit_error
	btn(footer,"Test this design in flight",test_design).disabled=task_index()<3 or not issues.is_empty()
	btn(content,"Edit spacecraft",open.bind(1))
func enter_design_review():
	if m.stage!=1 or task_index()<3:return
	m.s["design_step"]=4
	open(9)
func test_design():
	if m.stage!=1 or task_index()<3 or not launch_fixes().is_empty() or not m.contract()[2]:return
	m.s["design_step"]=4
	begin_transfer()
func preflight():
	if m.stage!=1 or task_index()!=4:
		label(content,"Confirm the spacecraft, rocket and orbit first.")
		return
	label(content,"Check the budget, rocket weight limit and fuel for reaching orbit. Red items must be fixed. Amber cautions are risks you may accept.")
	var passed=m.contract()
	for i in 3:
		label(content,("%s  "%("PASS" if passed[i] else "FAIL"))+["Contract: required science instrument","Contract: orbit reaches the target","Contract: sufficient theoretical science return in 16 turns"][i])
	if not m.extra("backup") and not m.extra("relay"):
		label(content,"Advisory: no redundant communication path. Engineering score deduction: up to 2 points. Launch is allowed.").modulate=Color("#ffd08a")
	btn(content,"Edit rocket and orbit",open.bind(2))

	summary()
	var fixes=launch_fixes()
	if not fixes.is_empty():
		label(footer,"LAUNCH BLOCKED  •  "+fixes[0]).modulate=Color("#ffaaaa")
		btn(footer,"Open assembly bench",open.bind(1))
	if Review.approved(m):
		btn(footer,"Enter launch window",start_flight,true)
	else:
		var a=m.totals()
		btn(footer,"Enter design review",open.bind(9),true).disabled=a[0]>m.d.budget or a[1]>m.part("rocket")[2]
const Review=preload("res://design_review.gd")
func design_board():
	if m.stage!=1 or task_index()!=4:return
	var rows=Review.rows(m)
	var a=m.totals()
	var trust=int(m.s.get("trust",90))
	var roles=["Systems engineer","Science lead","Project manager"]
	var margin=100*(m.generation(true)-a[2])/maxf(a[2],1)
	var questions=["Sunlight power margin is %+.0f%%. How will the battery cover an eclipse?"%margin,
		"Your instruments record %.2f GB per observation. Can a %.2f GB contact clear it?"%[a[3],m.link_rate()],
		"You have %.0f M left. What would you cut to fund a backup link?"%(m.d.budget-a[0])]
	for i in 3:
		var group_rows=[[0,1,3],[2],[4,5]][i]
		var marks=0.0
		for idx in group_rows:marks+=[100,70,20][rows[idx][1]]
		var row=HBoxContainer.new()
		content.add_child(row)
		var portrait=preload("res://reviewer_avatar.gd").new()
		portrait.role=i
		portrait.custom_minimum_size=Vector2(46,48)
		row.add_child(portrait)
		var q=label(row,"%s   •   %.0f/100\n%s"%[roles[i],marks/group_rows.size(),questions[i]])
		q.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	design_metrics()
	var fatal=m.checks()
	if fatal.size():label(content,"FATAL — "+str(fatal[0])).modulate=Color("#ff9990")
	label(footer,"Green checks: %d / 6 (need 4)     Trust: %d (need 60)"%[Review.greens(m),trust])
	if trust<60:label(content,"Trust is too low. Start a new mission design from Mission Brief.").modulate=Color("#ff9990")
	var cards=m.s.get("risk_cards",[])
	for pair in [["Mass","Keep the current set of instruments."],["Thermal","Space out hot observations."],["Cost","Reserve the remaining budget for operations."],["Power","Schedule battery charging before eclipse."],["Communications","Reserve contact turns to clear the buffer."],["Redundancy","Accept single-link operation and monitor every contact."]]:
		for r in rows:
			if r[0]==pair[0] and r[1]==1:
				if pair[0] in cards:label(content,"Defense recorded: "+pair[1])
				else:btn(content,"Risk card: "+pair[1]+"  (-8 trust)",defend.bind(pair[0]))
	btn(footer,"Return to assembly",open.bind(7))
	btn(footer,"Accept remaining risks and approve",approve_design,true).disabled=not Review.passed(m)
	if trust<60:btn(footer,"Restart design review cycle",reset)
func defend(topic):
	var cards=m.s.get("risk_cards",[])
	if topic not in cards:
		cards.append(topic)
		m.s["risk_cards"]=cards
		m.s["trust"]=maxi(0,int(m.s.get("trust",90))-8)
	open(9)
func approve_design():
	if not Review.passed(m):return
	m.s["approval"]=Review.signature(m)
	open(8)
func start_flight():
	if task_index()!=4 or not Review.approved(m):return
	begin_transfer()
func begin_transfer():
	m.stage=2
	m.s["launch_t"]=0.0
	m.s.erase("timing")
	elapsed=0
	open(5)
func finish_flight():
	if m.stage!=2 or not m.s.has("timing"):return
	var saved=m.insertion()*.2*clampf(m.s.timing,0,1)
	m.launch()
	m.s.reserve+=saved
	m.note="Orbit acquired. Ignition timing saved %.1f maneuver units."%saved
	open(3)
func diagram(flight):
	var v=preload("res://diagram.gd").new()
	v.flight=flight
	v.phase=elapsed/12 if flight else m.s.turn/16.0
	v.custom_minimum_size.y=98
	content.add_child(v)
func tracking():
	if m.stage!=3:
		label(content,"Tracking begins after lunar insertion.")
		if m.stage==4:btn(content,"View mission review",open.bind(6))
		if m.stage==2:btn(content,"View transfer",open.bind(5))
		return
	diagram(false)
	var s=m.s
	label(content,"Turn %d / 16   •   15 minutes per action\n%s"%[s.turn+1,m.note])
	for v in [["Battery",s.energy,m.part("battery")[3],"Wh"],["Storage",s.data,m.d.storage,"GB"],["Delivered science",s.sent,m.goal()[1],"pts"]]:
		label(content,"%s   %.2f / %.0f %s"%v)
		var bar=ProgressBar.new()
		bar.max_value=v[2]
		bar.value=v[1]
		bar.show_percentage=false
		bar.custom_minimum_size.y=8
		content.add_child(bar)
	label(content,"Pending %.1f pts  •  Health %.0f  •  Reserve %.0f\nGeneration %.0f W  •  Last draw %.0f W"%[s.pending,s.health,s.reserve,m.generation(m.condition(s.turn,3)),s.draw])
	for t in range(int(s.turn),mini(int(s.turn)+4,16)):
		label(content,"T%02d     %s     /     %s"%[t+1,"Sunlight" if m.condition(t,3) else "Eclipse","Earth contact" if m.condition(t,4) else "No contact"])
	if m.event_due():
		label(footer,"Next: choose how to handle the solar storm. This choice unlocks the turn.").modulate=Color("#ffcf89")
		label(content,"Solar activity surge. Resolve before continuing.")
		var b=btn(footer,"Protect array  /  18 Wh + 8 reserve",resolve.bind(true))
		b.disabled=s.energy<18 or s.reserve<8
		if b.disabled:label(content,"Shielding requires 18 Wh and 8 maneuver units.")
		btn(footer,"Collect 0.65 GB + 4 pts  /  lose 25% generation",resolve.bind(false))
	else:
		var advice=orbit_advice()
		label(footer,"Next: "+advice[1]).modulate=Color("#ffcf89")
		var row=HBoxContainer.new()
		footer.add_child(row)
		for i in 4:
			var caption=["Observe","Charge","Downlink","Safe"][i]
			btn(row,("› "+caption) if i==advice[0] else caption,action.bind(i),i==advice[0])
		if s.sent>=m.goal()[1]:btn(footer,"Complete mission",end_mission,true)
func orbit_advice():
	var s=m.s
	var gen=m.generation(m.condition(s.turn,3))
	var contact=m.condition(s.turn,4)
	var energy_for_link=s.energy+(gen-m.d.transmit)*m.d.hours
	if contact and s.data>0.001 and energy_for_link>=0:
		return [2,"Click Downlink. Earth is in range. Send stored data to score science points."]
	var a=m.totals()
	var room=m.d.storage-s.data
	if room>0.01 and s.energy+(gen-a[2])*m.d.hours>=0:
		var task=["scan for ice","map the surface","probe below the surface"][m.c.goal]
		return [0,"Click Observe to "+task+". "+("Storage is empty. Collect data first, then send it during Earth contact." if s.data<0.001 else "Store more data for a later downlink.")]
	if gen>m.d.base[2] and s.energy<m.part("battery")[3]:
		return [1,"Click Charge. Available power can refill the battery while you wait."]
	return [3,"Click Safe. Use minimum power while waiting for "+("Earth contact." if room<=0.01 else "a better power window.")]
func resolve(b):
	m.anomaly(b)
	open(3)
func action(i):
	m.act(i)
	if m.stage==4 or m.s.sent>=m.goal()[1]:
		end_mission()
	else:open(3)
func end_mission():
	m.stage=4
	open(6)
	var won=m.s.sent>=m.goal()[1]
	var result=AcceptDialog.new()
	result.title="Mission successful" if won else "Mission unsuccessful"
	result.dialog_text=outcome_text()
	result.dialog_autowrap=true
	result.ok_button_text="View flight review"
	result.exclusive=true
	result.confirmed.connect(result.queue_free)
	result.canceled.connect(result.queue_free)
	add_child(result)
	result.get_label().add_theme_font_size_override("font_size",18)
	result.get_label().modulate=Color("#b7efdb") if won else Color("#ffb4ad")
	result.popup_centered(Vector2i(510,260))
func outcome_text():
	var s=m.s
	var target=m.goal()[1]
	if s.sent>=target:
		return "Your design met its science goal!\n\nYou completed %s. Earth received %.1f science points, reaching the target of %d."%[m.goal()[0],s.sent,target]
	var lines=PackedStringArray(["Flight test complete.","","Earth received %.1f of %d science points. You needed %.1f more."%[s.sent,target,target-s.sent]])
	if s.pending>0.001:lines.append("%.1f points were still aboard the spacecraft. Only data sent to Earth counts. Choose Downlink during Earth contact."%s.pending)
	elif s.sent==0 and s.loss==0:lines.append("No science was collected. Choose Observe to gather measurements, then Downlink during Earth contact.")
	else:lines.append("Your observations delivered too little science before the final turn. Schedule more observations with the instrument best suited to your target.")
	if s.loss>0.001:lines.append("Full storage caused %.2f GB of data loss."%s.loss)
	if s.outages>0:lines.append("Low battery interrupted %d planned actions."%s.outages)
	if s.missed>0:lines.append("You had data aboard during %d unused contact windows."%s.missed)
	return "\n".join(lines)
func review():
	var s=m.s
	if s.has("flyby_points"):
		label(content,"Lunar flyover  /  %.1f science delivered"%s.flyby_points)
		if s.has("flyby_photo"):
			var image=Image.new()
			if image.load_png_from_buffer(Marshalls.base64_to_raw(s.flyby_photo))==OK:
				var picture=TextureRect.new()
				picture.texture=ImageTexture.create_from_image(image)
				picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				content.add_child(picture)
	var design=m.totals()
	label(content,"Your design in flight")
	label(content,"Read the four scores below. To improve a score, choose Revise this design and test again, change one part, then compare the result.")
	label(content,"%s carried %d of %d kg. The complete design used %d of %d M."%[m.part("rocket")[0],design[1],m.part("rocket")[2],design[0],m.d.budget])
	label(content,"%s gave %.0f%% target coverage. Your instruments produced %.2f GB per observation; your antenna could send %.2f GB per contact."%[m.part("orbit")[0],100*m.coverage(),design[3],m.link_rate()])
	var scores=m.scores()
	var total=0.0
	label(content,"Objective achieved" if s.sent>=m.goal()[1] else "Partial science return")
	for i in 4:
		total+=scores[i]*m.d.weights[i]
		label(content,"%s   %.1f / %d"%[["Science","Engineering margin","Budget efficiency","Scheduling"][i],scores[i]*m.d.weights[i],m.d.weights[i]])
		assessment_bar(content,scores[i]*m.d.weights[i],m.d.weights[i],Color("#82d9b4") if scores[i]>=.8 else (Color("#f4c16c") if scores[i]>=.5 else Color("#fa9188")))
	label(content,"Total %.0f / 100\nReturned %.1f / %.0f pts. Still onboard %.1f pts.\nBattery outages %d. Overflow %.2f GB. Unused contacts with data %d. Orbit coverage %.0f%%."%[total,s.sent,m.goal()[1],s.pending,s.outages,s.loss,s.missed,m.coverage()*100])
	if s.pending>1:label(content,"Pending science remained onboard. "+("High-gain antenna costs 8 M extra." if m.c.antenna==0 else "Schedule more contacts for downlink."))
	if s.outages>0:label(content,"Power shortages interrupted operations. A larger battery costs 6 M extra.")
	if s.missed>0:label(content,"Reserve contact turns for downlink when storage is occupied.")
	if s.sent>=m.goal()[1]:label(content,"Your instruments and orbit delivered the required observations.")
	btn(footer,"Save flight result",save_game)
	btn(footer,"Revise this design and test again",revise_design,true)
	btn(footer,"Choose another science question",reset)
func revise_design():
	m.s={}
	m.note=""
	m.stage=1
	world.refresh()
	open(1)
func reset():
	m=preload("res://mission.gd").new()
	world.mission=m
	world.refresh()
	open(0)
func help():
	label(content,"WASD or arrows • Move\nShift • Run\nSpace • Jump\nRight mouse drag • Orbit camera\nWheel • Zoom\nE • Use nearby station\nEsc • Close panel\nF1 • Help\n\nUse the four station shortcuts at any time. All performance figures are classroom approximations.")
	btn(content,"Guidance: "+("On" if tutorial else "Off"),func():tutorial=not tutorial;open(4))
	btn(content,"Interface sound: "+("On" if sound else "Off"),func():sound=not sound;open(4))
func save_game():
	var f=FileAccess.open(SAVE,FileAccess.WRITE)
	if not f:f=FileAccess.open("res://flight.local.json",FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"version":1,"hardware":m.hardware,"c":m.c,"s":m.s,"stage":m.stage,"note":m.note}))
		status="Flight saved locally."
	else:status="Could not write the save file."
func load_game():
	var path=SAVE if FileAccess.file_exists(SAVE) else "res://flight.local.json"
	var v=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if v is Dictionary and v.get("c") is Dictionary and v.c.get("tools") is Array and v.c.tools.size()==3:v.c.tools.append(false)
	if not valid(v) or not valid_hardware(v.get("hardware",{})):

		status="No valid saved flight."
		return
	m.hardware=v.get("hardware",preload("res://mission.gd").new().hardware)
	m.c=v.c
	for k in m.c:
		if k!="tools":m.c[k]=int(m.c[k])
	m.stage=int(v.stage)
	m.s=v.s
	if m.s.has("turn"):m.s.turn=int(m.s.turn)
	m.note=v.get("note","Flight restored.")
	world.refresh()
	open([0,1,5,3,6][m.stage])
	status="Flight restored."
func valid_hardware(h):
	if not h is Dictionary:return false
	if h.is_empty():return true
	if not h.get("extras") is Array or not h.get("mounts") is Dictionary:return false
	for k in h.extras:
		if not m.d.extras.has(k) or h.extras.count(k)!=1:return false
	for v in h.mounts.values():
		if not valid_integer(v,-1,1) or int(v)==0:return false
	for k in ["panel_angle","antenna_angle"]:
		if not valid_integer(h.get(k),0,90) or int(h[k])%15!=0:return false
	return true
func valid_integer(value,low,high):
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and value==floor(value) and value>=low and value<=high
func valid(v):
	if not v is Dictionary or v.get("version")!=1 or not v.get("c") is Dictionary or not v.get("s") is Dictionary:return false
	if not valid_integer(v.get("stage"),0,4):return false
	for k in m.c:
		if not v.c.has(k):return false
		if k=="tools":
			if not v.c[k] is Array or v.c[k].size()!=4:return false
			for b in v.c[k]:
				if not b is bool:return false
		else:
			var n=v.c[k]
			if typeof(n) not in [TYPE_INT,TYPE_FLOAT] or n!=floor(n) or n<0 or n>=m.d["missions" if k=="goal" else k].size():return false
	if v.stage>=3:
		for k in ["turn","energy","reserve","power","data","pending","sent","health","loss","outages","missed","draw"]:
			if typeof(v.s.get(k)) not in [TYPE_INT,TYPE_FLOAT] or v.s[k]<0:return false
		if not v.s.get("event") is bool or v.s.turn>16 or v.s.data>8:return false
	return typeof(v.get("note",""))==TYPE_STRING
func _process(dt):
	if not world:return
	update_steps()
	var pos=world.get_node("Commander").position
	if page<0:wandered+=Vector2(pos.x-last_position.x,pos.z-last_position.z).length()
	else:wandered=0.0
	last_position=pos
	guide.visible=tutorial and page<0 and wandered>=3.5
	if guide.visible:
		var step=task_index()
		var target=world.labels[STATIONS[step]].capitalize()
		var instruction=["choose a science objective","choose instruments","configure power, communications and propulsion","choose a rocket and orbit","check your launch plan","operate the spacecraft and return science","review your flight"][step]
		var outdoors=pos.z>2.45 or pos.z< -2.1 or pos.x>3.1 or pos.x< -5.1
		guide.text=("Head inside to " if outdoors else "Visit ")+target+" to "+instruction+"."
	hud.text="DESIGN LAB   /   %s     •     %s     •     %d M     %d kg"%[m.goal()[0],["Briefing","Design","Transfer","Operations","Review"][m.stage],m.totals()[0],m.totals()[1]]
	var i=world.nearest()
	hint.text=("E   /   "+world.labels[i] if i>=0 and page<0 else status)
func _unhandled_key_input(e):
	if not e.pressed or e.echo:return
	if deck.visible:
		if e.keycode==KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			open(-1)
			return
		if deck.ops and e.keycode==KEY_P:deck.toggle_pause()
		if not deck.ops and e.keycode==KEY_ENTER:deck.ignite()
		return
	if e.keycode==KEY_ESCAPE:open(-1)
	if e.keycode==KEY_F1:open(4)
	if e.keycode==KEY_E and page<0 and world.nearest()>=0:
		world.get_node("Commander").animate(world.get_node("Commander").interact_animation)
		visit_station(world.nearest())


func ask_switch_mission():
	if m.stage == 0:
		open(0)
		return

	var dialog = ConfirmationDialog.new()
	dialog.title = "Switch mission?"
	dialog.dialog_text = "Leave this mission and choose another? Unsaved progress will be lost."
	dialog.ok_button_text = "Choose another mission"
	dialog.cancel_button_text = "Keep playing"
	add_child(dialog)

	dialog.confirmed.connect(reset)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(480, 180))










