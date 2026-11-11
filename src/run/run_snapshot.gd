class_name RunSnapshot
extends RefCounted
## A copy of a Run's state at one moment. The view draws from it and tests
## assert on it. Its fields can be written, but that only changes the copy,
## never the Run.

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

## Whether the run is being played, paused on level-up cards, or over.
var phase: Run.Phase = Run.Phase.PLAYING

## How the run ended, or NONE while it is still being played.
var outcome: Run.Outcome = Run.Outcome.NONE

## The type id of the admirer who touched her most recently, e.g.
## &"dowry_uncle", or empty if nobody has yet. After a defeat it's the one
## who took the last of her Patience: who she said yes to.
var last_touching_type: StringName = &""

## How much cash Shireen has collected so far in the run, shown on the end
## screen. Spent cash counts too: it never goes down.
var cash_collected: int = 0

## Her weapon's level, from 1. Collecting cash raises it (see
## [member level_cash]), and each level-up pauses the run on [member cards].
var level: int = 1

## The cash collected toward the next level so far, from 0 up to just under
## [member level_cash_needed]. The HUD level bar is level_cash out of
## level_cash_needed.
var level_cash: int = 0

## The cash the next level-up takes, from the leveling data.
var level_cash_needed: int = 0

## The level-up cards up right now, in the order the player sees them, or
## empty unless [member phase] is LEVEL_UP. Pick one with Run.choose_card and
## its index here.
var cards: Array[Card] = []

## The level [member cards] are for, or 0 with none up. Below [member level]
## when more level-ups wait behind this one.
var cards_level: int = 0

## How many more level-ups wait for their own cards once these are chosen.
## A big bill can be worth several levels at once (design §5).
var pending_level_ups: int = 0

## Every cash bill and cup of tea on the field, oldest first.
var pickups: Array[PickupSnapshot] = []

## Every admirer on the field: first the ones chasing Shireen, in spawn
## order (oldest first), then the dazzled ones swooning or walking off, in
## the order they were dazzled. See [member AdmirerSnapshot.state].
var admirers: Array[AdmirerSnapshot] = []

## How many admirers are still chasing Shireen. Dazzled ones on their way
## out don't count. The debug capture's state dump reports it (ticket 03).
var admirer_count: int = 0

## How many admirers Shireen has dazzled this run. The end screens show it.
var admirers_dazzled: int = 0

## The run's weapon: its stats, buffs and abilities. Null when the run has
## no weapon (some tests).
var weapon: WeaponSnapshot

## Everything the weapon has in flight, oldest first.
var projectiles: Array[ProjectileSnapshot] = []


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
		"level": level,
		"level_cash": level_cash,
		"level_cash_needed": level_cash_needed,
		"cards": cards.map(func(card: Card) -> Dictionary: return card.to_dict()),
		"cards_level": cards_level,
		"pending_level_ups": pending_level_ups,
		"pickups": pickups.map(func(pickup: PickupSnapshot) -> Dictionary: return pickup.to_dict()),
		"admirer_count": admirer_count,
		"admirers": admirers.map(func(admirer: AdmirerSnapshot) -> Dictionary: return admirer.to_dict()),
		"weapon": weapon.to_dict() if weapon != null else {},
		"projectiles": projectiles.map(func(projectile: ProjectileSnapshot) -> Dictionary: return projectile.to_dict()),
	}
