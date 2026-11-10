class_name PickupRenderer
extends Node2D
## Draws every pickup in the Run's snapshot (the cash on the sand and in
## flight, and the cups of karkadeh tea) from a pool of sprites, the same way
## AdmirerRenderer draws admirers: sprites are reused every frame, and only
## created when there are more pickups than ever before.
##
## The sheets are res://art/pickups/cash.png (three 16×16 frames, a bill, a
## stack and a wad) and res://art/pickups/karkadeh_tea.png (one 16×16 frame);
## see art/README.md.
##
## The node has y-sorting on and sits under the World node with Shireen and
## the admirers, so a bill lying lower on screen than an Uncle is drawn in
## front of him, and one higher up behind him.

const CASH_SHEET: Texture2D = preload("res://art/pickups/cash.png")
const TEA_SHEET: Texture2D = preload("res://art/pickups/karkadeh_tea.png")
const CASH_FRAMES: int = 3
## A bill worth at least this much is drawn as a stack, and at least
## [constant WAD_FROM] as a wad (design §7: Uncles drop 2, Falconers 4).
const STACK_FROM: int = 2
const WAD_FROM: int = 4
const BILL_FRAME: int = 0
const STACK_FRAME: int = 1
const WAD_FRAME: int = 2
## The Run keeps a pickup's position on the ground, like an admirer's feet.
## The sprite's centre is drawn this many pixels higher, so the bill lies at
## his feet rather than under them.
const LIFT: float = 6.0

var _pool: Array[Sprite2D] = []


func _ready() -> void:
	y_sort_enabled = true


## Draws [param snapshot]'s pickups. [param previous] is the snapshot one
## step earlier and [param blend] (0 to 1) how far we are between the two, so
## flying cash glides smoothly on screens faster than 60 Hz.
func show_pickups(snapshot: RunSnapshot, previous: RunSnapshot, blend: float) -> void:
	var previous_positions: Dictionary[int, Vector2] = {}
	for pickup: PickupSnapshot in previous.pickups:
		# Only flying cash moves, so only it needs a position to blend from.
		if pickup.state == Pickup.State.FLYING:
			previous_positions[pickup.id] = pickup.position

	var count: int = snapshot.pickups.size()
	while _pool.size() < count:
		var sprite := Sprite2D.new()
		sprite.offset = Vector2(0.0, -LIFT)
		add_child(sprite)
		_pool.append(sprite)

	for i: int in count:
		var pickup: PickupSnapshot = snapshot.pickups[i]
		var sprite: Sprite2D = _pool[i]
		sprite.visible = true
		if pickup.kind == Pickup.Kind.TEA:
			if sprite.texture != TEA_SHEET:
				sprite.texture = TEA_SHEET
				sprite.hframes = 1
			sprite.frame = 0
		else:
			if sprite.texture != CASH_SHEET:
				sprite.texture = CASH_SHEET
				sprite.hframes = CASH_FRAMES
			sprite.frame = frame_for_cash(pickup.value)
		# A pickup that just dropped or lies still has no previous position
		# to blend from: show it where it is.
		var from: Vector2 = previous_positions.get(pickup.id, pickup.position)
		sprite.position = from.lerp(pickup.position, blend).round()

	for i: int in range(count, _pool.size()):
		_pool[i].visible = false


## Which of the three cash frames shows a bill worth [param value].
static func frame_for_cash(value: int) -> int:
	if value >= WAD_FROM:
		return WAD_FRAME
	if value >= STACK_FROM:
		return STACK_FRAME
	return BILL_FRAME
