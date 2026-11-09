class_name RunSnapshot
extends RefCounted
## A copy of a Run's state at one moment. The view draws from it and tests
## assert on it. Its fields can be written, but that only changes the copy,
## never the Run.
##
## Later tickets add Patience, cash, pickups and so on.

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

## Every admirer on the field: first the ones chasing Shireen, in spawn
## order (oldest first), then the dazzled ones swooning or walking off, in
## the order they were dazzled. See [member AdmirerSnapshot.state].
var admirers: Array[AdmirerSnapshot] = []

## How many admirers are still chasing Shireen. Dazzled ones on their way
## out don't count. The debug capture's state dump reports it (ticket 03).
var admirer_count: int = 0

## How many admirers Shireen has dazzled this run. The end screens show it.
var admirers_dazzled: int = 0


## Patience Shireen is losing per second right now: the summed drain of
## every admirer touching her. Dazzled admirers drain nothing. (Patience
## itself arrives with ticket 05.)
var drain_per_second: float = 0.0

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
		"admirer_count": admirer_count,
		"admirers_dazzled": admirers_dazzled,
		"drain_per_second": drain_per_second,
		"admirers": admirers.map(func(admirer: AdmirerSnapshot) -> Dictionary: return admirer.to_dict()),
		"weapon": weapon.to_dict() if weapon != null else {},
		"projectiles": projectiles.map(func(projectile: ProjectileSnapshot) -> Dictionary: return projectile.to_dict()),
	}
