class_name LeveledUpEvent
extends RunEvent
## Shireen's weapon went up a level: the cash she collected filled the level
## bar (design §5). One event per level, so a big bill worth two levels gives
## two events in the same step. The card choice follows as its own event
## (CardsOfferedEvent), once the step is done.

## The level she has just reached, from 2 up.
var level: int = 0


func _init(p_level: int) -> void:
	level = p_level


func to_dict() -> Dictionary[String, Variant]:
	return {"event": "leveled_up", "level": level}
