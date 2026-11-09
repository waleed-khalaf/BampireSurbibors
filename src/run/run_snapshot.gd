class_name RunSnapshot
extends RefCounted
## A copy of a Run's state at one moment. The view draws from it and tests
## assert on it. Its fields can be written, but that only changes the copy,
## never the Run.
##
## Later tickets add the weapon, pickups and so on.

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

## Shireen's Patience right now, from [member max_patience] down to 0.
var patience: float = 0.0

## The Patience she started the run with, from her data. The HUD bar is full
## at this value.
var max_patience: float = 0.0

## Whether the run is still being played or is over.
var phase: Run.Phase = Run.Phase.PLAYING

## How the run ended, or NONE while it is still being played.
var outcome: Run.Outcome = Run.Outcome.NONE

## The type id of the admirer who touched her most recently, e.g.
## &"dowry_uncle", or empty if nobody has yet. After a defeat it's the one
## who took the last of her Patience: who she said yes to.
var last_touching_type: StringName = &""

## The run's stats so far, shown on the end screen. Nothing dazzles admirers
## or drops cash yet, so both stay at 0 until tickets 06 and 07.
var admirers_dazzled: int = 0
var cash_collected: int = 0

## Every admirer in the run, in spawn order (oldest first).
var admirers: Array[AdmirerSnapshot] = []

## How many admirers are in the run. The debug capture's state dump reports
## it (ticket 03).
var admirer_count: int:
	get:
		return admirers.size()


## Plain-data form, handy for comparing two snapshots and for debug dumps.
func to_dict() -> Dictionary[String, Variant]:
	return {
		"time": time,
		"tick": tick,
		"shireen_position": shireen_position,
		"shireen_facing": shireen_facing,
		"shireen_moving": shireen_moving,
		"patience": patience,
		"max_patience": max_patience,
		"phase": Run.phase_name(phase),
		"outcome": Run.outcome_name(outcome),
		"last_touching_type": last_touching_type,
		"admirers_dazzled": admirers_dazzled,
		"cash_collected": cash_collected,
		"admirer_count": admirer_count,
		"admirers": admirers.map(func(admirer: AdmirerSnapshot) -> Dictionary: return admirer.to_dict()),
	}
