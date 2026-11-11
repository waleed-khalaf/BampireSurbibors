class_name HudBar
extends Control
## A HUD bar that shows an amount out of a maximum: Shireen's Patience, the
## level bar. It holds no rules: RunView hands it the numbers from the Run's
## snapshot every frame.
##
## The bar is drawn from three plain rectangles rather than a ProgressBar
## node, so it stays crisp pixel art at the 640×360 base resolution. Its size,
## place on screen and fill colour are the node's own, set in run_view.tscn.

## Colours from the shared palette (art/palette.gpl).
const BORDER_COLOR: Color = Color("2b1d1a")  # ink
const EMPTY_COLOR: Color = Color("4a3236")  # hair_light
const BORDER: int = 1

## The colour of the filled part. Rose for Patience, gold for the level bar.
@export var fill_color: Color = Color("c2414b")  # rose

## How many pixels of the bar are filled. Kept so the bar only redraws when
## the picture would actually change.
var _fill_width: int = -1


## Shows [param amount] out of [param maximum].
func show_amount(amount: float, maximum: float) -> void:
	var inside: float = size.x - 2.0 * BORDER
	var share: float = clampf(amount / maximum, 0.0, 1.0) if maximum > 0.0 else 0.0
	# Rounded up, so the last sliver of Patience (or the first cash toward
	# a level) still shows as one pixel, and only a real 0 shows an empty bar.
	var fill_width: int = ceili(inside * share)
	if fill_width != _fill_width:
		_fill_width = fill_width
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BORDER_COLOR)
	var inside := Rect2(Vector2(BORDER, BORDER), size - Vector2(2 * BORDER, 2 * BORDER))
	draw_rect(inside, EMPTY_COLOR)
	if _fill_width > 0:
		draw_rect(Rect2(inside.position, Vector2(_fill_width, inside.size.y)), fill_color)
