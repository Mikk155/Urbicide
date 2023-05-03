
@SolidClass base(Trigger, TriggerCond, Angles, MoveWith) = trigger_bounce : "Bouncey area"
[
	frags(string) : "Factor (0=stop, 1=perfect bounce)" : "0.9"
	armorvalue(string) : "Minimum Speed" : "100"
	spawnflags(flags) =
	[
		16: "Truncate Speed" : 0
	]
]