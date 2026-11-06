class_name PropScatter
extends Node2D
## Scatters decorative props (palm trees, Lada taxis) over the endless sand.
##
## The world is cut into square chunks. Each chunk's props come from a hash of
## its coordinates, so walking away and coming back shows the same props in
## the same places. Only chunks near the camera have nodes; the rest are freed.
##
## Props are pure decoration: they live only in the view, and the Run never
## knows about them, so they can never block Shireen.

const CHUNK_SIZE: float = 192.0

## Each prop: its texture and where its base sits on the sand, measured from
## the texture's top-left corner (see art/README.md). The base is where the
## sprite's position goes, so y-sorting puts Shireen in front of a palm when
## she is lower on screen and behind it when she is higher.
const PROPS: Array[Dictionary] = [
	{"texture": preload("res://art/props/palm_tree.png"), "base": Vector2(16, 46), "weight": 7},
	{"texture": preload("res://art/props/lada_taxi.png"), "base": Vector2(24, 29), "weight": 2},
]

## Size of the visible area in pixels. RunView sets it from the project
## settings before the first frame.
var view_size: Vector2 = RunConfig.DEFAULT_PLAY_AREA

## Chunk coordinates -> the prop nodes in that chunk.
var _chunks: Dictionary[Vector2i, Array] = {}


func _ready() -> void:
	y_sort_enabled = true


## Makes sure every chunk on or near the screen has its props, and frees
## chunks that are far away.
func follow(camera_position: Vector2) -> void:
	var half: Vector2 = view_size / 2.0 + Vector2(CHUNK_SIZE, CHUNK_SIZE)
	var first := Vector2i(((camera_position - half) / CHUNK_SIZE).floor())
	var last := Vector2i(((camera_position + half) / CHUNK_SIZE).floor())

	for cy: int in range(first.y, last.y + 1):
		for cx: int in range(first.x, last.x + 1):
			var chunk := Vector2i(cx, cy)
			if not _chunks.has(chunk):
				_chunks[chunk] = _spawn_chunk(chunk)

	for chunk: Vector2i in _chunks.keys():
		if chunk.x < first.x - 1 or chunk.x > last.x + 1 or chunk.y < first.y - 1 or chunk.y > last.y + 1:
			for node: Node in _chunks[chunk]:
				node.queue_free()
			_chunks.erase(chunk)


func _spawn_chunk(chunk: Vector2i) -> Array[Node]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(chunk)
	var nodes: Array[Node] = []
	# Mostly 0 or 1 prop per chunk, sometimes 2: busy enough to show movement,
	# sparse enough to keep the swarm readable.
	var roll: float = rng.randf()
	var count: int = 0 if roll < 0.35 else (1 if roll < 0.85 else 2)
	for i: int in count:
		var prop: Dictionary = _pick_prop(rng)
		var sprite := Sprite2D.new()
		sprite.texture = prop.texture
		sprite.centered = false
		sprite.offset = -prop.base
		sprite.flip_h = rng.randf() < 0.5
		if sprite.flip_h:
			# Mirroring flips around the texture's left edge; shift it back so
			# the base stays on the same spot.
			sprite.offset.x = prop.base.x - prop.texture.get_width()
		sprite.position = (Vector2(chunk) + Vector2(rng.randf(), rng.randf())) * CHUNK_SIZE
		sprite.position = sprite.position.round()
		add_child(sprite)
		nodes.append(sprite)
	return nodes


func _pick_prop(rng: RandomNumberGenerator) -> Dictionary:
	var total: int = 0
	for prop: Dictionary in PROPS:
		total += prop.weight
	var pick: int = rng.randi_range(1, total)
	for prop: Dictionary in PROPS:
		pick -= prop.weight
		if pick <= 0:
			return prop
	return PROPS[0]
