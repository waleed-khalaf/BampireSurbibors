class_name WeaponAttack
extends RefCounted
## One attack a weapon is about to make. Abilities get it in their on-fire
## and every-Nth hooks before the weapon acts on it, and change it there:
## an ability that makes every 4th throw a giant one triples
## [member damage_scale] and doubles [member area_scale].

## Which attack of the run this is, counting from 1.
var number: int = 0

## Multiplies the weapon's damage stat for this attack only.
var damage_scale: float = 1.0

## Multiplies the weapon's area stat for this attack only.
var area_scale: float = 1.0


func _init(p_number: int) -> void:
	number = p_number
