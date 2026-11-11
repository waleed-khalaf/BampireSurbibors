class_name LevelingData
extends Resource
## The leveling curve (design §5): how much cash each level-up takes. The real
## values live in res://content/leveling.tres: open it in the Godot inspector
## to change them. The design's curve is 5 + 3·(n−1) cash to go from level n
## to n+1, aiming at about 20 level-ups in a 5-minute run.

## Cash to go from level 1 to level 2.
@export var cash_for_first_level_up: int = 5

## How much more each level-up costs than the one before it.
@export var extra_cash_each_level: int = 3


## The cash it takes to go from [param level] to the next one.
func cash_to_level_up_from(level: int) -> int:
	return cash_for_first_level_up + extra_cash_each_level * (level - 1)
