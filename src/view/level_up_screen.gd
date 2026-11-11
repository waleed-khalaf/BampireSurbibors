class_name LevelUpScreen
extends Control
## The level-up card screen, shown over the paused run (design §5). It holds
## no rules: RunView hands it the Run's snapshot with the cards up, the
## player moves between them with the arrow keys and picks one with Enter,
## and it reports the pick back through [signal card_chosen]. Its layout is
## in level_up_screen.tscn; each card is a level_up_card.tscn.

## The player pressed Enter on the card at this index.
signal card_chosen(index: int)

const CARD_SCENE: PackedScene = preload("res://src/view/level_up_card.tscn")

@onready var _title: Label = %Title
@onready var _waiting: Label = %Waiting
@onready var _cards_row: HBoxContainer = %Cards

var _cards: Array[LevelUpCard] = []
var _selected: int = 0


func _ready() -> void:
	# Hidden until a level-up. The scene file leaves it visible so it can be
	# seen and edited in the editor.
	visible = false


## Shows the cards in [param snapshot], which must have some up, with the
## first one selected. [param weapon_name] is the weapon's display name.
func show_cards(snapshot: RunSnapshot, weapon_name: String) -> void:
	_title.text = "%s Lv %d" % [weapon_name, snapshot.cards_level]
	# Several level-ups at once are chosen one after another.
	_waiting.text = "%d more level-up%s waiting" % [snapshot.pending_level_ups, "" if snapshot.pending_level_ups == 1 else "s"]
	_waiting.visible = snapshot.pending_level_ups > 0
	# Out of the row at once (queue_free alone would leave them in the
	# layout until the end of the frame, beside the new cards).
	for card: LevelUpCard in _cards:
		_cards_row.remove_child(card)
		card.queue_free()
	_cards.clear()
	for card: Card in snapshot.cards:
		var shown: LevelUpCard = CARD_SCENE.instantiate()
		_cards_row.add_child(shown)
		shown.show_card(card)
		_cards.append(shown)
	_select(0)
	visible = true


## Takes the screen down once the pick has been made.
func hide_cards() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _cards.is_empty():
		return
	# The actions are the movement keys (arrows or WASD) and Enter (Project
	# Settings > Input Map). A key held down doesn't count as a new press,
	# so holding Enter can't pick through several level-ups at once.
	if event.is_action_pressed("move_left") or event.is_action_pressed("move_up"):
		_select(posmod(_selected - 1, _cards.size()))
	elif event.is_action_pressed("move_right") or event.is_action_pressed("move_down"):
		_select(posmod(_selected + 1, _cards.size()))
	elif event.is_action_pressed("accept"):
		card_chosen.emit(_selected)
	else:
		return
	get_viewport().set_input_as_handled()


func _select(index: int) -> void:
	_selected = index
	for i: int in _cards.size():
		_cards[i].set_selected(i == index)
