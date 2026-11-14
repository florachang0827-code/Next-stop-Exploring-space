extends RefCounted
var d = JSON.parse_string(FileAccess.get_file_as_string("res://classroom.json"))
var c = {"goal":0,"tools":[false,false,false,false],"solar":0,"battery":0,"antenna":0,"drive":0,"rocket":0,"orbit":0}
var stage = 0
var s = {}
var note = ""
var hardware={"extras":[],"mounts":{},"panel_angle":0,"antenna_angle":0}
func extra(k):return k in hardware.extras
func side(k):return int(hardware.mounts.get(k,1))
func generation(sunlit):
	return (d.extras.rtg[3] if extra("rtg") else 0.0)+(part("solar")[3]*cos(deg_to_rad(hardware.panel_angle))*s.get("power",1) if sunlit else 0.0)
func blocked_link():
	return side("antenna")==side("solar") and abs(hardware.antenna_angle-hardware.panel_angle)<18 and hardware.panel_angle>=30
func link_rate():
	return part("antenna")[3]*maxf(.2,cos(deg_to_rad(hardware.antenna_angle))) * (.2 if blocked_link() else 1.0)+(d.extras.backup[3] if extra("backup") else 0.0)
func heat():
	return totals()[2]*.48+(22 if extra("rtg") else 0)-(25 if extra("radiator") else 0)-(18 if extra("pump") else 0)-(10 if extra("insulation") else 0)
func balance():
	var moment=0.0
	for k in ["solar","antenna","battery","drive"]:
		moment+=part(k)[2]*side(k)*{"solar":.52,"antenna":.32,"battery":-.45,"drive":-.24}[k]
	for i in c.tools.size():
		if c.tools[i]:moment+=d.tools[i][2]*side("tool"+str(i))*.52
	for k in hardware.extras:moment+=d.extras[k][2]*side(k)*.52
	return moment/totals()[1]
func span():
	return 1.80+(.25 if c.solar==1 else 0.0)+(.32 if c.tools[2] else 0.0)+(.15 if extra("rtg") else 0.0)+(.20 if extra("adapter") else 0.0)
func insertion():
	return part("orbit")[1]/(.93 if abs(balance())>d.engineering.balance_limit else 1.0)
func goal(): return d.missions[c.goal]
func part(k): return d[k][c[k]]
func totals():
	var a = [d.base[0]+part("rocket")[1],d.base[1],d.base[2],0.0,0.0]
	for k in ["solar","battery","antenna","drive"]:
		a[0]+=part(k)[1]
		a[1]+=part(k)[2]
	for k in hardware.extras:
		a[0]+=d.extras[k][1]
		a[1]+=d.extras[k][2]
	a[2]+=6 if extra("pump") else 0
	for i in c.tools.size():
		if c.tools[i]:
			for j in 4: a[j]+=d.tools[i][j+1]
			a[4]+=d.tools[i][5]*goal()[3][i]
	return a
func coverage(): return goal()[4][c.orbit]
func contract():
	var fit=false
	for i in goal()[2]:
		if c.tools[int(i)]:fit=true
	var a=totals()
	var contacts=0
	var opportunities=0
	for t in int(d.turns):
		if condition(t,4):contacts+=1
		else:opportunities+=1
	# Upper bound across possible observation/downlink allocations.
	var maximum=0.0
	if a[3]>0:
		for observations in range(1,int(d.turns)):
			var downlinks=mini(contacts,int(d.turns)-observations)
			maximum=maxf(maximum,minf(observations,downlinks*link_rate()/a[3])*a[4]*coverage()*part("orbit")[2])
	return [fit,coverage()>0,maximum>=goal()[1]]
func checks():
	var a=totals()
	var e=[]
	if a[0]>d.budget:e.append("Budget exceeded.")
	if a[1]>part("rocket")[2]:e.append("Payload exceeds launcher capacity.")
	if part("drive")[3]<insertion():e.append("Insufficient insertion reserve.")
	if not true in c.tools:e.append("Install a science instrument.")
	var match_goal=false
	for i in goal()[2]:
		if c.tools[int(i)]:match_goal=true
	if not match_goal:e.append("Required science instrument missing.")
	if coverage()==0:e.append("Orbit never covers this target.")
	if heat()>d.engineering.heat_limit:e.append("Heat limit exceeded. Fit a radiator or remove a hot instrument.")
	if span()>d.engineering.fairing[c.rocket]:e.append("Outside the fairing. Choose a larger rocket or remove wide equipment.")
	if blocked_link():e.append("Solar wing blocks the antenna. Turn the antenna or move it to the opposite mount.")
	if (a[2]-generation(true))*d.hours>part("battery")[3]*.25:e.append("Power margin too low: a sunlit observation uses over a quarter of the battery. Rotate panels, increase supply or reduce load.")
	if contract()[0] and coverage()>0 and not contract()[2]:e.append("Too little science can reach Earth in 16 turns.")
	return e
func risks():
	var a=totals()
	var r=[]
	if a[2]>part("solar")[3]:r.append("Observation draws more than sunlight supplies.")
	if part("battery")[3]<2*a[2]*d.hours+150:r.append("Limited battery margin through eclipse.")
	if a[3]>part("antenna")[3]:r.append("Data production exceeds one contact's capacity.")
	if coverage()<.8:r.append("Low target coverage.")
	if part("drive")[3]-insertion()<=30:r.append("Little maneuver reserve after insertion.")
	return r
func launch():
	if not checks().is_empty():return
	var review_trust=s.get("trust",90)
	var review_cards=s.get("risk_cards",[])
	stage=3
	s={"turn":0,"energy":part("battery")[3],"reserve":part("drive")[3]-insertion(),"power":1.0,"data":0.0,"pending":0.0,"sent":0.0,"health":100.0,"event":false,"loss":0.0,"outages":0,"missed":0,"draw":0.0}
	note="Insertion complete. Solar activity is forecast for turn 5."
	s["trust"]=review_trust
	s["risk_cards"]=review_cards
func condition(t,j):return bool(part("orbit")[j][int(t)%4]) or (j==4 and extra("relay") and int(t)%4==0)
func event_due():return stage==3 and s.turn+1==d.event[0] and not s.event
func deposit(gb,points):
	var kept=minf(gb,d.storage-s.data)
	s.pending+=points*kept/gb
	s.data+=kept
	s.loss+=gb-kept
	if kept<gb:note+=" Storage overflow: %.2f GB lost."%(gb-kept)
func anomaly(protect):
	if not event_due():return
	if protect:
		if s.energy<d.event[1] or s.reserve<d.event[2]:return
		s.energy-=d.event[1]
		s.reserve-=d.event[2]
		note="Shielding preserved array output."
	else:
		s.power=d.event[3]
		note="Particle measurements stored. Array output reduced."
		deposit(d.event[4],d.event[5])
	s.event=true
func act(i,advance_slot=true):
	if stage!=3 or event_due():return
	var a=totals()
	var sunlight=condition(s.turn,3)
	var link=condition(s.turn,4)
	var gen=generation(sunlight)
	var draw=[a[2],d.base[2],d.transmit,d.safe][i]
	note=""
	if s.energy+(gen-draw)*d.hours<0:
		i=3
		draw=d.safe
		s.health=maxf(0,s.health-(5 if extra("computer") else 10))
		s.outages+=1
		note="Insufficient energy. Safe mode; health -%d."%(5 if extra("computer") else 10)
	var previous_energy=s.energy
	s.draw=draw
	s.energy=clampf(s.energy+(gen-draw)*d.hours,0,part("battery")[3])
	s["power_delta"]=s.energy-previous_energy
	s["power_source_w"]=gen
	if link and s.data>0 and i!=2:s.missed+=1
	if i==0:
		note="Observation generated %.2f GB; link capacity %.2f GB per contact."%[a[3],part("antenna")[3]]
		deposit(a[3],a[4]*coverage()*part("orbit")[2])
	elif i==2:
		if link and s.data>0:
			var gb=minf(s.data,link_rate())
			var v=s.pending*gb/s.data
			s.data-=gb
			s.pending-=v
			s.sent+=v
			note="Transmitted %.2f GB and delivered %.1f science."%[gb,v]
		else:note="No contact or empty storage. Turn and energy spent."
	elif note=="":note="Power balance: %+.1f Wh after housekeeping."%((gen-draw)*d.hours)
	if advance_slot:finish_slot()
func finish_slot():
	s.turn+=1
	if s.turn>=d.turns:stage=4
func scores():
	var a=totals()
	return [minf(1,s.sent/goal()[1]),maxf(0,.6*s.health/100+.4*s.energy/part("battery")[3]-(0 if extra("backup") or extra("relay") else .1)),1-a[0]/(2*d.budget),maxf(0,1-(s.missed+s.outages)/float(d.turns))]




