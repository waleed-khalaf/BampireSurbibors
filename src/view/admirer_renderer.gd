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
## Each admirer type's sheet is res://art/admirers/<type id>.png, so a new
## type needs a PNG there and no change here (see art/README.md).
##
## The node has y-sorting on and sits next to Shireen under the World node,
## so an Uncle standing lower on screen is drawn in front of her, and one
## higher up behind her.

## Where the sheets live, one per admirer type, named after the type's id.
const SHEETS_DIR: String = "res://art/admirers"
## Every sheet has the same layout: one row of 32×32 frames, a 2-frame walk
## cycle, facing right (see art/README.md).
const WALK_FRAMES: int = 2
const WALK_FPS: float = 4.0
## Where the feet are in each frame, like Shireen's. The sprite's position is
## the admirer's position, so this is the offset that puts the feet there.
const FEET: Vector2 = Vector2(16, 30)
## How far left or right an admirer has to be walking before his sprite
## flips. Walking almost straight up or down keeps the old flip, so he
## doesn't flicker when he's right above or below Shireen.
const FLIP_THRESHOLD: float = 0.2

var _pool: Array[PooledSprite] = []
## Type id -> its sheet, loaded the first time that type is drawn. A type
## whose sheet is missing is stored as null, so it's warned about only once.
var _sheets: Dictionary[StringName, Texture2D] = {}
## Real time, which only drives the walk animation speed.
var _anim_time: float = 0.0


## A pooled sprite remembers which admirer it showed last frame. Sprites are
## handed out by position in the snapshot, so when an admirer leaves the run
## everyone after him moves down one sprite. The id tells us when that
## happens, so the new admirer's look is set from his own state instead of
## inheriting the last one's.
class PooledSprite extends Sprite2D:
	## Admirer ids start at 1, so a sprite that has never shown anyone holds
	## NO_ADMIRER and gets set up from the first admirer it's given.
	const NO_ADMIRER: int = -1
	var admirer_id: int = NO_ADMIRER


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
		var sprite: PooledSprite = _pool[i]
		sprite.visible = true
		var texture: Texture2D = _sheet_for(admirer.type_id)
		if sprite.texture != texture:
			sprite.texture = texture
		# A new admirer has no previous position: show him where he is.
		var from: Vector2 = previous_positions.get(admirer.id, admirer.position)
		sprite.position = from.lerp(admirer.position, blend).round()
		# Each admirer starts his walk cycle at a different moment (picked
		# from his id), so a crowd doesn't step in lockstep.
		sprite.frame = floori(_anim_time * WALK_FPS + admirer.id * 0.37) % WALK_FRAMES
		if sprite.admirer_id != admirer.id:
			# The sprite changed hands: start from this admirer's own facing,
			# however slight its left/right part, so he never shows the flip
			# of whoever used the sprite before him. Walking exactly straight
			# up or down (facing.x of 0) faces right, like a fresh spawn.
			sprite.admirer_id = admirer.id
			sprite.flip_h = admirer.facing.x < 0.0
		elif admirer.facing.x < -FLIP_THRESHOLD:
			sprite.flip_h = true
		elif admirer.facing.x > FLIP_THRESHOLD:
			sprite.flip_h = false

	for i: int in range(count, _pool.size()):
		_pool[i].visible = false


func _new_sprite() -> PooledSprite:
	var sprite := PooledSprite.new()
	sprite.centered = false
	sprite.offset = -FEET
	sprite.hframes = WALK_FRAMES
	add_child(sprite)
	return sprite


## The sheet for one admirer type, loaded on first use and cached. Returns
## null (and warns once) if the PNG is missing, so a type whose art hasn't
## been drawn yet is reported instead of just not showing up.
func _sheet_for(type_id: StringName) -> Texture2D:
	if _sheets.has(type_id):
		return _sheets[type_id]
	var path: String = SHEETS_DIR.path_join("%s.png" % type_id)
	var texture: Texture2D = null
	# load() goes through Godot's import system, so this also works in an
	# exported game, where the PNG itself is no longer on disk. The exists
	# check first keeps a missing sheet to our one warning, instead of
	# load()'s own error on top of it.
	if ResourceLoader.exists(path):
		texture = load(path)
	if texture == null:
		push_warning("No sprite sheet for admirer type \"%s\": expected %s (see art/README.md)." % [type_id, path])
	_sheets[type_id] = texture
	return texture
