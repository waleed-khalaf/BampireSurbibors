class_name WeaponHit
extends RefCounted
## One hit a weapon is about to land on an admirer. Abilities get it in
## their on-hit hook before the damage is dealt, and may change
## [member damage].

## Who is hit.
var admirer: Admirer

## How much dazzle power lands on him.
var damage: float = 0.0

## Where the hit happens in world pixels (where the zill is, not his feet).
var position: Vector2 = Vector2.ZERO


func _init(p_admirer: Admirer, p_damage: float, p_position: Vector2) -> void:
	admirer = p_admirer
	damage = p_damage
	position = p_position
