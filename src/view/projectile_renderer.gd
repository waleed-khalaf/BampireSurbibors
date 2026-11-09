class_name ProjectileRenderer
extends Node2D
## Draws everything the weapon has in flight (the zills) from a pool of
## sprites, the same way AdmirerRenderer draws admirers: sprites are reused
## every frame, and only created when there are more projectiles than ever
## before.
##
## Each kind's sheet is res://art/projectiles/<kind>.png, so a new kind of
## projectile needs a PNG there and no change here (see art/README.md).

## Where the sheets live, one per projectile kind, named after the kind.
const SHEETS_DIR: String = "res://art/projectiles"
## Every sheet is one row of square 16×16 frames that play in a loop.
const FRAME_SIZE: int = 16
const SPIN_FPS: float = 12.0
## The Run keeps a projectile's position on the ground, like an admirer's
## feet. It is drawn this many pixels higher, where Shireen's hands and an
## admirer's chest are.
const HAND_HEIGHT: float = 14.0
## The sheets are drawn for a projectile of this radius. A bigger one (a
## size buff) is drawn scaled up to match.
const DRAWN_RADIUS: float = 4.0

var _pool: Array[Sprite2D] = []
## Kind -> its sheet, loaded the first time that kind is drawn. A kind whose
## sheet is missing is stored as null, so it's warned about only once.
var _sheets: Dictionary[StringName, Texture2D] = {}
## Real time, which only drives the spin animation.
var _anim_time: float = 0.0


## Draws [param snapshot]'s projectiles. [param previous] is the snapshot one
## step earlier and [param blend] (0 to 1) how far we are between the two, so
## they glide smoothly on screens faster than 60 Hz. [param delta] is the
## real frame time.
func show_projectiles(snapshot: RunSnapshot, previous: RunSnapshot, blend: float, delta: float) -> void:
	_anim_time += delta
	var previous_positions: Dictionary[int, Vector2] = {}
	for projectile: ProjectileSnapshot in previous.projectiles:
		previous_positions[projectile.id] = projectile.position

	var count: int = snapshot.projectiles.size()
	while _pool.size() < count:
		var sprite := Sprite2D.new()
		add_child(sprite)
		_pool.append(sprite)

	for i: int in count:
		var projectile: ProjectileSnapshot = snapshot.projectiles[i]
		var sprite: Sprite2D = _pool[i]
		sprite.visible = true
		var texture: Texture2D = _sheet_for(projectile.kind)
		if sprite.texture != texture:
			sprite.texture = texture
			@warning_ignore("integer_division")
			sprite.hframes = maxi(texture.get_width() / FRAME_SIZE, 1) if texture != null else 1
		# A projectile thrown this step has no previous position: show it
		# where it is.
		var from: Vector2 = previous_positions.get(projectile.id, projectile.position)
		sprite.position = (from.lerp(projectile.position, blend) - Vector2(0.0, HAND_HEIGHT)).round()
		# Each one starts its spin at a different moment (picked from its
		# id), so a volley doesn't spin in lockstep.
		sprite.frame = floori(_anim_time * SPIN_FPS + projectile.id * 0.37) % sprite.hframes
		sprite.scale = Vector2.ONE * (projectile.radius / DRAWN_RADIUS)

	for i: int in range(count, _pool.size()):
		_pool[i].visible = false


## The sheet for one projectile kind, loaded on first use and cached. Returns
## null (and warns once) if the PNG is missing.
func _sheet_for(kind: StringName) -> Texture2D:
	if _sheets.has(kind):
		return _sheets[kind]
	var path: String = SHEETS_DIR.path_join("%s.png" % kind)
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path)
	if texture == null:
		push_warning("No sprite sheet for projectile kind \"%s\": expected %s (see art/README.md)." % [kind, path])
	_sheets[kind] = texture
	return texture
