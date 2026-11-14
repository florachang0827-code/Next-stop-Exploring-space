extends RefCounted

static func rows(m):
	var a=m.totals()
	var capacity=m.part("rocket")[2]
	var power=m.generation(true)
	var cost=a[0]/m.d.budget
	var heat=m.heat()/m.d.engineering.heat_limit
	var comm_red=m.blocked_link() or not m.contract()[2]
	var load=(a[2]-power)*m.d.hours/m.part("battery")[3]
	return [
		["Mass",2 if a[1]>capacity or m.span()>m.d.engineering.fairing[m.c.rocket] else (1 if a[1]>capacity*.93 else 0),"%d / %d kg; stowed width %.2f m."%[a[1],capacity,m.span()]],
		["Power",2 if load>.25 else (1 if power<a[2]*1.10 else 0),"Sunlit output %.0f W; observation draw %.0f W."%[power,a[2]]],
		["Communications",2 if comm_red else (1 if a[3]>m.link_rate() else 0),"%.2f GB per observation; %.2f GB per contact."%[a[3],m.link_rate()]],
		["Thermal",2 if heat>1 else (1 if heat>.85 else 0),"%.0f%% of the teaching heat limit."%(heat*100)],
		["Cost",2 if cost>1 else (1 if cost>.94 else 0),"%d / %d M, including launch."%[a[0],m.d.budget]],
		["Redundancy",0 if m.extra("backup") or m.extra("relay") else 1,"Secondary communication path installed." if m.extra("backup") or m.extra("relay") else "Single communication path; engineering deduction applies."]
	]
static func greens(m):
	var count=0
	for row in rows(m):
		if row[1]==0:count+=1
	return count
static func signature(m):
	return JSON.stringify([m.c,m.hardware])
static func passed(m):
	return greens(m)>=4 and m.checks().is_empty() and m.s.get("trust",90)>=60
static func approved(m):
	return passed(m) and m.s.get("approval","")==signature(m)
