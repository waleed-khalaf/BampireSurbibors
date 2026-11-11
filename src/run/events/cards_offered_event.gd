class_name CardsOfferedEvent
extends RunEvent
## The run has paused for a level-up and put its cards up (design §5). The
## view shows the card screen; the Run waits for Run.choose_card. Emitted by
## the step that leveled up, right after its LeveledUpEvent, and by
## Run.choose_card when another level-up is waiting behind the one chosen.

## The level the cards are for.
var level: int = 0

## The cards, in the order the player sees them. Pick one by its index here.
var cards: Array[Card] = []


func _init(p_level: int, p_cards: Array[Card]) -> void:
	level = p_level
	cards = p_cards


func to_dict() -> Dictionary[String, Variant]:
	return {
		"event": "cards_offered",
		"level": level,
		"cards": cards.map(func(card: Card) -> Dictionary: return card.to_dict()),
	}
