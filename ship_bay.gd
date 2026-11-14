extends PanelContainer

const GROUPS={"Structure":["adapter"],"Power":["solar","battery","rtg"],"Communications":["antenna","relay"],"Science":["tool0","tool1","tool2","tool3"],"Propulsion":["drive"],"Thermal":["radiator","pump","insulation"],"Redundancy":["computer","backup"]}
var ui
var group="Science"
var overlay="Mass"
var selected={}
var feedback=""
var canvas
var catalog=VBoxContainer.new()
var report=Label.new()
var resource_title=Label.new()
var readings=HBoxContainer.new()
var last_values=[]
var confirm=Button.new()
var title=Label.new()
var last_stage=-1

class PartButton extends Button:
	var payload
	signal preview_part(payload)
	func _get_drag_data(_pos):
		preview_part.emit(payload)
		var preview=TextureRect.new()
		preview.texture=icon
		set_drag_preview(preview)
		return payload

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style=StyleBoxFlat.new()
	style.bg_color=Color("#102333")
	style.content_margin_left=26
	style.content_margin_top=18
	style.content_margin_right=26
	style.content_margin_bottom=16
	add_theme_stylebox_override("panel",style)
	var col=VBoxContainer.new()
	add_child(col)
	var top=HBoxContainer.new()
	col.add_child(top)
	title.add_theme_font_size_override("font_size",26)
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	top.add_child(title)
	button(top,"Return to hall [Esc]",func():ui.open(-1))
	var tabs=HBoxContainer.new()
	col.add_child(tabs)
	for category in GROUPS:button(tabs,category,choose_group.bind(category))
	var main=HBoxContainer.new()
	main.size_flags_vertical=Control.SIZE_EXPAND_FILL
	col.add_child(main)
	canvas=preload("res://ship_canvas.gd").new()
	canvas.bay=self
	canvas.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	main.add_child(canvas)
	var scroll=ScrollContainer.new()
	scroll.custom_minimum_size.x=390
	main.add_child(scroll)
	catalog.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(catalog)
	var layers=HBoxContainer.new()
	col.add_child(layers)
	var prefix=Label.new()
	prefix.text="LAYERS   "
	layers.add_child(prefix)
	for layer in ["Mass","Power","Heat","Comms","Envelope","Cost"]:button(layers,layer,set_layer.bind(layer))
	col.add_child(resource_title)
	col.add_child(readings)
	report.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	report.custom_minimum_size.y=50
	col.add_child(report)
	col.add_child(confirm)
	confirm.pressed.connect(advance)
func button(parent,t,fn):
	var b=Button.new()
	parent.add_child(b)
	b.text=t
	b.pressed.connect(fn)
	return b
func display(interface):
	ui=interface
	last_values=[]
	if last_stage!=ui.page:
		group="Science" if ui.page==1 else "Power"
		selected={}
		feedback=""
	last_stage=ui.page
	refresh()
func advance():
	ui.m.s["design_step"]=3
	ui.open(2)
func choose_group(g):
	last_values=[]
	group=g
	selected={}
	refresh()
func set_layer(l):
	overlay=l
	refresh()
func options(k):
	if k.begins_with("tool"):return [ui.m.d.tools[int(k.right(1))]]
	if ui.m.d.extras.has(k):return [ui.m.d.extras[k]]
	return ui.m.d[k]
func installed(k,variant):
	if k.begins_with("tool"):return ui.m.c.tools[int(k.right(1))]
	if ui.m.d.extras.has(k):return ui.m.extra(k)
	return ui.m.c[k]==variant
func choose(k,v):
	selected={"part":k,"variant":v}
	feedback="Choose PORT or STARBOARD on the schematic to mount "+str(options(k)[v][0])+"."
	refresh()
func fit(payload,side,remove=false):
	var k=payload.part
	var v=int(payload.variant)
	var old=ui.m.totals()
	last_values=resource_values(ui.m)
	configure(ui.m,payload,side,remove)
	ui.invalidate(1 if k.begins_with("tool") else 2)
	ui.world.refresh()
	var now=ui.m.totals()
	feedback="%s %s   /   mass %+.0f kg   /   cost %+.0f M   /   observation draw %+.0f W"%["Removed" if remove else "Mounted",options(k)[v][0],now[1]-old[1],now[0]-old[0],now[2]-old[2]]
	if not remove and k.begins_with("tool") and now==old:
		feedback="%s is already installed. Adding it again gives no extra science."%options(k)[v][0]
	selected={}
	refresh()
func configure(model,payload,side,remove):
	var k=payload.part
	var v=int(payload.variant)
	if k.begins_with("tool"):model.c.tools[int(k.right(1))]=not remove
	elif model.d.extras.has(k):
		model.hardware.extras.erase(k)
		if not remove:model.hardware.extras.append(k)
	else:model.c[k]=v
	if remove:model.hardware.mounts.erase(k)
	else:model.hardware.mounts[k]=side
func rotate_part(k):
	ui.m.hardware[k]=(int(ui.m.hardware[k])+15)%105
	ui.invalidate(2)
	feedback="Angle updated. Check Power and Comms for changes."
	refresh()
func refresh():
	if not ui:return
	var m=ui.m
	title.text="Spacecraft Assembly   /   "+m.goal()[0]
	for n in catalog.get_children():
		catalog.remove_child(n)
		n.queue_free()
	ui.label(catalog,group+" components")
	ui.label(catalog,"Click a component to preview its cost. Click a + mount to install it.")
	if group=="Science":button(catalog,"Use recommended instrument only",ui.recommended)
	for k in GROUPS[group]:
		var items=options(k)
		for i in items.size():
			var a=items[i]
			var b=PartButton.new()
			b.payload={"part":k,"variant":i}
			b.icon=load("res://assets/components/%s_%d.svg"%[k,i])
			var purpose={"adapter":"Connect the spacecraft","solar":"Collect sunlight","battery":"Store electricity","rtg":"Power in darkness","antenna":"Send data to Earth","relay":"Add radio contacts","tool0":"Map the surface","tool1":"Look for ice","tool2":"Probe below ground","tool3":"Measure magnetic fields","drive":"Change orbit","radiator":"Release heat","pump":"Move coolant","insulation":"Reduce heat load","computer":"Protect flight control","backup":"Backup radio link"}[k]
			var name_text=str(a[0])
			if k in ["solar","battery","antenna"]:name_text+=" "+{"solar":"panel","battery":"battery","antenna":"antenna"}[k]
			b.text="%s%s   •   %d M / %d kg\n%s"%["✓ " if installed(k,i) else "",name_text,a[1],a[2],purpose]
			b.alignment=HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_constant_override("h_separation",12)
			b.custom_minimum_size.y=68
			b.preview_part.connect(preview_drag)
			b.pressed.connect(choose.bind(k,i))
			catalog.add_child(b)
			if installed(k,i) and (k.begins_with("tool") or m.d.extras.has(k)):button(catalog,"Remove "+str(a[0]),fit.bind(b.payload,1,true))
	if group=="Power":button(catalog,"Rotate solar wing   %d°   +15°"%m.hardware.panel_angle,rotate_part.bind("panel_angle"))
	if group=="Communications":button(catalog,"Aim antenna   %d°   +15°"%m.hardware.antenna_angle,rotate_part.bind("antenna_angle"))
	update_resources()
	var errors=ui.launch_fixes()
	report.text=feedback+"\n"+(str(errors[0]) if errors.size() else ("Review deduction: no backup communication path." if not m.extra("relay") and not m.extra("backup") else "Design checks clear."))
	report.modulate=Color("#ffac99") if errors.size() else Color("#beddd6")
	var science_ok=false
	for idx in m.goal()[2]:
		if m.c.tools[int(idx)]:science_ok=true
	confirm.text="Choose rocket and orbit"
	if selected.is_empty() and feedback=="" and (errors.is_empty() or not science_ok):
		var required=PackedStringArray()
		for idx in m.goal()[2]:required.append(m.d.tools[int(idx)][0])
		report.text=("Next: click Choose rocket and orbit, or try another component." if science_ok else "Next: open Science and fit "+ " or ".join(required)+". For quick setup, click Use recommended instrument only.")
	if not errors.is_empty() and str(errors[0]).contains("Click Use starter design"):
		button(catalog,"Use starter design",ui.starter_design)
	confirm.disabled=not science_ok
	canvas.queue_redraw()



func preview_drag(payload):
	selected=payload
	update_resources()
	canvas.queue_redraw()
func resource_values(model):
	var totals=model.totals()
	return [totals[0],totals[1],model.part("battery")[3],totals[2]]
func update_resources():
	resource_title.text="Installed spacecraft" if selected.is_empty() else "Preview • "+str(options(selected.part)[selected.variant][0])
	ui.clear(readings)
	var model=ui.m
	var before=resource_values(model) if last_values.is_empty() else last_values
	if not selected.is_empty():
		before=resource_values(model)
		var draft=preload("res://mission.gd").new()
		draft.c=model.c.duplicate(true)
		draft.hardware=model.hardware.duplicate(true)
		draft.s=model.s.duplicate(true)
		configure(draft,selected,1,false)
		model=draft
	var after=resource_values(model)
	var max_battery=0.0
	for pack in model.d.battery:max_battery=maxf(max_battery,pack[3])
	var limits=[model.d.budget,model.part("rocket")[2],max_battery,model.generation(true)]
	var names=["Cost / budget","Mass / rocket limit","Battery capacity","Draw / sunlit power"]
	var units=["M","kg","Wh","W"]
	for i in 4:
		var col=VBoxContainer.new()
		col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		readings.add_child(col)
		ui.label(col,names[i])
		var delta=after[i]-before[i]
		var detail="%.0f / %.0f %s"%[after[i],limits[i],units[i]]
		if delta!=0:detail+="  (%+.0f)"%delta
		ui.label(col,detail)
		var tint=Color("#73cfbb")
		if i!=2 and after[i]>limits[i]:tint=Color("#f5b568") if i==3 else Color("#ff918a")
		ui.assessment_bar(col,after[i],maxf(1,limits[i]),tint)
	if not selected.is_empty():readings.tooltip_text="Preview with the selected component mounted."
	else:readings.tooltip_text="Installed spacecraft totals."



