class_name RunSnapshot
extends RefCounted
## A read-only copy of a Run's state at one moment. The view draws from it and
## tests assert on it. Changing a snapshot never changes the Run.
##
## Later tickets add Shireen, admirers, Patience, cash and so on.

## Seconds of run time simulated so far (ticks × the fixed timestep).
var time: float = 0.0

## Number of fixed steps simulated so far.
var tick: int = 0


func _init(p_time: float, p_tick: int) -> void:
	time = p_time
	tick = p_tick


## Plain-data form, handy for comparing two snapshots and for debug dumps.
func to_dict() -> Dictionary:
	return {
		"time": time,
		"tick": tick,
	}
