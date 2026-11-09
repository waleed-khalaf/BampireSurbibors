class_name WeaponSnapshot
extends RefCounted
## A copy of the run's weapon state, inside a RunSnapshot. Changing it never
## changes the Run.

## The weapon's id, e.g. &"zills".
var id: StringName = &""

## How many attacks it has made this run (for Zills, throws).
var attacks: int = 0

## Every stat's current value, with buffs and abilities applied.
var stats: Dictionary[StringName, float] = {}

## Each buff track's rank, by track id. 0 until a buff card ranks it up.
var buffs: Dictionary[StringName, int] = {}

## The ids of the abilities the weapon has gained, in the order gained.
var abilities: Array[StringName] = []


## Plain-data form, for comparing snapshots and for debug dumps.
func to_dict() -> Dictionary[String, Variant]:
	return {"id": id, "attacks": attacks, "stats": stats, "buffs": buffs, "abilities": abilities}
