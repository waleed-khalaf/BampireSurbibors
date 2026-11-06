class_name AdmirerRenderer
extends Node2D
## Draws every admirer in the Run's snapshot from a pool of sprites.
##
## The Run keeps admirers as plain data (ADR-0001), so the view needs some
## way to draw hundreds of them. This keeps a pool of Sprite2D nodes and
## reuses them every frame: sprite 0 shows the first admirer in the snapshot,
## sprite 1 the second and so on. It only creates sprites when the crowd
## grows past the pool, and hides spares when it shrinks, so nothing is
## created or freed while the crowd stays the same size. Sprites that share a
## texture are drawn by Godot in one batch.
##
## The node has y-sorting on and sits next to Shireen under the World node,
## so an Uncle standing lower on screen is drawn in front of her, and one
## higher up behind her.

## Each admirer type's sheet: one row of 32×32 frames, 2-frame walk, facing
## right. Feet at (16, 30), like Shireen (see art/README.md).
const SHEETS: Dictionary[StringName, Texture2D] = {
	&"dowry_uncle": preload("res://art/admirers/dowry_uncle.png"),
}
const WALK_FRAMES: int = 2
const WALK_FPS: float = 4.0
## Where the feet are in each frame. The sprite's position is the admirer's
## position, so this is the offset that puts the feet there.
const FEET: Vector2 = Vector2(16, 30)
## How far left or right an admirer has to be walking before his sprite
## flips. Walking almost straight up or down keeps the old flip, so he
## doesn't flicker when he's right above or below Shireen.
const FLIP_THRESHOLD: float = 0.2

var _pool: Array[Sprite2D] = []
## Real time, which only drives the walk animation speed.
var _anim_time: float = 0.0


func _ready() -> void:
	y_sort_enabled = true


## Draws [param snapshot]'s admirers. [param previous] is the snapshot one
## step earlier and [param blend] (0 to 1) how far we are between the two,
## so admirers glide smoothly on screens faster than 60 Hz, just like
## Shireen. [param delta] is the real frame time.
func show_admirers(snapshot: RunSnapshot, previous: RunSnapshot, blend: float, delta: float) -> void:
	_anim_time += delta
	var previous_positions: Dictionary[int, Vector2] = {}
	for admirer: AdmirerSnapshot in previous.admirers:
		previous_positions[admirer.id] = admirer.position

	var count: int = snapshot.admirers.size()
	while _pool.size() < count:
		_pool.append(_new_sprite())

	for i: int in count:
		var admirer: AdmirerSnapshot = snapshot.admirers[i]
		var sprite: Sprite2D = _pool[i]
		sprite.visible = true
		var texture: Texture2D = SHEETS.get(admirer.type_id)
		if sprite.texture != texture:
			sprite.texture = texture
		# A new admirer has no previous position: show him where he is.
		var from: Vector2 = previous_positions.get(admirer.id, admirer.position)
		sprite.position = from.lerp(admirer.position, blend).round()
		# Each admirer starts his walk cycle at a different moment (picked
		# from his id), so a crowd doesn't step in lockstep.
		sprite.frame = floori(_anim_time * WALK_FPS + admirer.id * 0.37) % WALK_FRAMES
		if admirer.facing.x < -FLIP_THRESHOLD:
			sprite.flip_h = true
		elif admirer.facing.x > FLIP_THRESHOLD:
			sprite.flip_h = false

	for i: int in range(count, _pool.size()):
		_pool[i].visible = false


func _new_sprite() -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.offset = -FEET
	sprite.hframes = WALK_FRAMES
	add_child(sprite)
	return sprite
