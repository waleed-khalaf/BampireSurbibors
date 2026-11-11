class_name LevelingData
extends Resource
## The leveling rules (design §5): how much cash each level-up takes, which
## levels offer abilities, and what the fallback cards give once every buff
## is maxed. The real values live in res://content/leveling.tres: open it in
## the Godot inspector to change them. The design's curve is 5 + 3·(n−1)
## cash to go from level n to n+1, aiming at about 20 level-ups in a
## 5-minute run.

## Cash to go from level 1 to level 2.
@export var cash_for_first_level_up: int = 5

## How much more each level-up costs than the one before it.
@export var extra_cash_each_level: int = 3

## The levels whose cards are abilities instead of buffs. The design's are
## 5, 10 and 15: three of the weapon's five abilities a run.
@export var ability_levels: PackedInt32Array = PackedInt32Array([5, 10, 15])

## The cash the Big tip card pays, once every buff is maxed. It fills the
## level bar like any other cash.
@export var big_tip_cash: int = 10

## The Patience the Sip of tea card restores, once every buff is maxed,
## never past Shireen's maximum.
@export var sip_of_tea_patience: float = 30.0


## The cash it takes to go from [param level] to the next one.
func cash_to_level_up_from(level: int) -> int:
	return cash_for_first_level_up + extra_cash_each_level * (level - 1)


## Whether reaching [param level] offers abilities rather than buffs.
func is_ability_level(level: int) -> bool:
	return ability_levels.has(level)
