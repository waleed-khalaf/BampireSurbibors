class_name LevelUpCard
extends PanelContainer
## One card on the level-up screen: the track or ability's name, the rank it
## gives and what changes. It holds no rules: LevelUpScreen hands it a Card
## from the Run's snapshot and tells it whether it is the selected one.
## Its size and layout are in level_up_card.tscn.

## Colours from the shared palette (art/palette.gpl).
const PAPER_COLOR: Color = Color("f8e6b8")  # sand_pale
const INK_COLOR: Color = Color("2b1d1a")  # ink
const GOLD_COLOR: Color = Color("e0a92e")  # gold
## The frame's width and the space between it and the text, in pixels.
const BORDER: int = 2
const PADDING: int = 6

@onready var _name_label: Label = %Name
@onready var _rank_label: Label = %Rank
@onready var _description_label: Label = %Description

var _selected: bool = false


func _ready() -> void:
	_show_frame()


## Fills the card in from [param card].
func show_card(card: Card) -> void:
	_name_label.text = card.name
	match card.kind:
		Card.Kind.BUFF:
			_rank_label.text = "Rank %d of %d" % [card.rank, card.max_rank]
		Card.Kind.ABILITY:
			_rank_label.text = "New ability"
		_:
			_rank_label.text = "Every buff is maxed"
	_description_label.text = card.description


## Draws the gold frame of the selected card, or the plain one.
func set_selected(selected: bool) -> void:
	if selected == _selected:
		return
	_selected = selected
	_show_frame()


func _show_frame() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER_COLOR
	style.border_color = GOLD_COLOR if _selected else INK_COLOR
	style.set_border_width_all(BORDER)
	style.set_content_margin_all(PADDING)
	add_theme_stylebox_override("panel", style)
