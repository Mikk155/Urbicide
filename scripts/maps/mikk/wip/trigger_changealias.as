
@PointClass base(Targetname) iconsprite("sprites/trigger.spr") = trigger_changealias : "Trigger Change Alias"
[
	target(string)  : "Alias to affect"
	netname(string) : "String to Set"
	spawnflags(flags) =
	[
		1 : "Resolve references" : 0
		2 : "Debug Mode" : 0
	]
]