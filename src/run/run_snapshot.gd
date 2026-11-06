class_name RunSnapshot
extends RefCounted
## A copy of a Run's state at one moment. The view draws from it and tests
## assert on it. Its fields can be written, but that only changes the copy,
## never the Run.
##
## Later tickets add admirers, Patience, cash and so on.

## Seconds of run time simulated so far (ticks × the fixed timestep).
var time: float = 0.0

## Number of fixed steps simulated so far.
var tick: int = 0

## Shireen's position in world pixels. The run starts with her at (0, 0).
var shireen_position: Vector2 = Vector2.ZERO

## The way Shireen last moved, as a length-1 vector in any of the 8
## directions. It keeps its value while she stands still, so facing-based
## weapons (the Assaya Cane) stay predictable. She starts facing right.
var shireen_facing: Vector2 = Vector2.RIGHT

## Whether she walked during the last step. The view picks her walk or idle
## animation from it.
var shireen_moving: bool = false


## Plain-data form, handy for comparing two snapshots and for debug dumps.
func to_dict() -> Dictionary[String, Variant]:
	return {
		"time": time,
		"tick": tick,
		"shireen_position": shireen_position,
		"shireen_facing": shireen_facing,
		"shireen_moving": shireen_moving,
	}
