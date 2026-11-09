class_name HeartPopRenderer
extends Node2D
## Draws the heart that pops over an admirer the moment he is dazzled, and
## floats up while he swoons. It comes from a pool of sprites, like the
## admirers themselves (see AdmirerRenderer).
##
## The sheet is res://art/effects/heart.png: two 16×16 frames, a small heart
## and then the full one (see art/README.md).

const HEART_SHEET: Texture2D = preload("res://art/effects/heart.png")
const SMALL_FRAME: int = 0
const FULL_FRAME: int = 1
## The heart shows small for this long, then at full size: the "pop".
const POP_SECONDS: float = 0.08
## Where it appears, measured up from the admirer's feet: just above the
## head of a 32 px sprite.
const START_HEIGHT: float = 32.0
## How fast it floats up, in pixels per second.
const RISE_SPEED: float = 14.0

var _pool: Array[Sprite2D] = []


## Draws a heart over every swooning admirer in [param snapshot].
func show_hearts(snapshot: RunSnapshot) -> void:
	var count: int = 0
	for admirer: AdmirerSnapshot in snapshot.admirers:
		if admirer.state != Admirer.State.SWOONING:
			continue
		if count == _pool.size():
			var sprite := Sprite2D.new()
			sprite.texture = HEART_SHEET
			sprite.hframes = 2
			add_child(sprite)
			_pool.append(sprite)
		var heart: Sprite2D = _pool[count]
		count += 1
		heart.visible = true
		heart.frame = SMALL_FRAME if admirer.state_time < POP_SECONDS else FULL_FRAME
		heart.position = (admirer.position - Vector2(0.0, START_HEIGHT + RISE_SPEED * admirer.state_time)).round()

	for i: int in range(count, _pool.size()):
		_pool[i].visible = false
