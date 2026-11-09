class_name AbilityBehavior
extends RefCounted
## Base class for ability behaviors: the small class that gives an ability
## its logic (see the glossary). An ability's data names its behavior by ID,
## and ContentRegistry.ABILITY_BEHAVIORS maps that ID to a class.
##
## An ability changes its weapon only through the hooks below, which the
## weapon calls at the right moments (see WeaponBehavior). It never reaches
## into the weapon's internals. The hooks are:
##
## - Stat modifiers: no code, just the modifiers list in the ability's data.
## - On-fire: [method on_fire], before every attack.
## - Every-Nth: [method every_nth] and [method on_nth_attack].
## - On-hit: [method on_hit], before every hit lands.
## - Periodic: [method period] and [method on_period].
##
## Each hook is handed the weapon. Through it an ability can read
## weapon.stats, weapon.shireen_position and weapon.crowd (to find admirers
## and damage them directly, which does not call on_hit again).
##
## To add one: extend this class, override the hooks it needs, and add its ID
## to ContentRegistry.ABILITY_BEHAVIORS. No abilities exist yet; the Zills
## abilities arrive with ticket 12.
##
## One instance belongs to one Run's weapon, so it may keep state. Never use
## randomness or time from outside the Run, or runs stop being reproducible.

## The ability's data. The weapon sets it when the ability is gained.
var data: AbilityData


## Called before every attack. Change [param attack] to change the attack.
func on_fire(_weapon: WeaponBehavior, _attack: WeaponAttack) -> void:
	pass


## Return N to have [method on_nth_attack] called on every Nth attack (the
## Nth, the 2×Nth and so on). 0, the default, means never.
func every_nth() -> int:
	return 0


## Called before every Nth attack, after the on-fire hooks.
func on_nth_attack(_weapon: WeaponBehavior, _attack: WeaponAttack) -> void:
	pass


## Called before every hit lands. Change [member WeaponHit.damage] to change
## the hit.
func on_hit(_weapon: WeaponBehavior, _hit: WeaponHit) -> void:
	pass


## Return a number of seconds to have [method on_period] called that often.
## 0, the default, means never.
func period() -> float:
	return 0.0


## Called every [method period] seconds of run time.
func on_period(_weapon: WeaponBehavior) -> void:
	pass
