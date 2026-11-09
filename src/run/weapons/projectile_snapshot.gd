class_name ProjectileSnapshot
extends RefCounted
## A copy of one projectile's state, inside a RunSnapshot. Changing it never
## changes the Run.

## Unique among the run's projectiles. The same projectile keeps its id from
## one snapshot to the next, so the view can follow it.
var id: int = 0

## What it is, e.g. &"zill". The view picks its sprite by it.
var kind: StringName = &""

## Its centre on the ground, in world pixels, like an admirer's feet. The
## view draws it higher up, at hand height.
var position: Vector2 = Vector2.ZERO

## Pixels per second, with direction.
var velocity: Vector2 = Vector2.ZERO

## Its hit radius in pixels.
var radius: float = 0.0


## Plain-data form, for comparing snapshots and for debug dumps.
func to_dict() -> Dictionary[String, Variant]:
	return {"id": id, "kind": kind, "position": position, "velocity": velocity, "radius": radius}
