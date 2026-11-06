extends SceneTree
## Draws the draft sprites from code and saves them as PNG sheets in art/.
##
## Run it with generate_sprites.cmd (see art/README.md). It only writes files
## that don't exist yet, so your LibreSprite edits are safe. Pass --force to
## redraw everything from scratch.
##
## Every pixel is drawn with a named colour from PALETTE, so all sheets share
## one palette. The palette is also saved as art/palette.gpl for LibreSprite.
##
## The drawings are plain shapes (rectangles, ellipses, lines) plus an
## automatic dark outline. They are drafts: good enough to play with and a
## starting point for hand refinement (ticket 26).

## The shared palette: name, hex colour. Keep it under 32 colours.
const PALETTE: Array[Array] = [
	["ink", "2b1d1a"],
	["skin_shadow", "a0624a"],
	["skin", "c98a64"],
	["skin_light", "e3b08a"],
	["hair", "1e1416"],
	["hair_light", "4a3236"],
	["dress_dark", "12605e"],
	["dress", "1f8f86"],
	["dress_light", "4fc2b0"],
	["gold_dark", "a86e1c"],
	["gold", "e0a92e"],
	["gold_light", "ffe17a"],
	["rose", "c2414b"],
	["sand_dark", "c9965a"],
	["sand", "e2b673"],
	["sand_light", "efcb8e"],
	["sand_pale", "f8e6b8"],
	["leaf_dark", "2f6b2c"],
	["leaf", "4f9a3a"],
	["leaf_light", "8cc64a"],
	["trunk_dark", "6b4426"],
	["trunk", "93633a"],
	["car_black", "24242c"],
	["car_gray", "6f7480"],
	["chrome", "b9c0c8"],
	["car_white", "e8e6df"],
	["glass", "7fb6d6"],
]

## Shireen's sheet: one row of 32×32 frames, in this order.
## Keep art/README.md in sync if this changes.
const FRAME_SIZE: Vector2i = Vector2i(32, 32)
const SHIREEN_FRAMES: Array[Dictionary] = [
	# Idle: a 2-frame hip shimmy. The hips and skirt sway, the coins glint.
	{"bob": 0, "hip": -1, "step": 0, "glint": 0},
	{"bob": 0, "hip": 1, "step": 0, "glint": 1},
	# Walk: 4 frames. Left foot forward, pass, right foot forward, pass.
	{"bob": 0, "hip": 0, "step": 1, "glint": 0},
	{"bob": -1, "hip": 0, "step": 0, "glint": 1},
	{"bob": 0, "hip": 0, "step": 2, "glint": 0},
	{"bob": -1, "hip": 0, "step": 0, "glint": 1},
]

var _colors: Dictionary[String, Color] = {}
var _force: bool = false
## Set when anything goes wrong, so the script exits with code 1 and
## generate_sprites.cmd reports the failure.
var _failed: bool = false


func _init() -> void:
	for entry: Array in PALETTE:
		_colors[entry[0]] = Color.html(entry[1])
	_force = "--force" in OS.get_cmdline_user_args()

	_save_image(_draw_palette(), "res://art/palette.png")
	_save_text(_palette_gpl(), "res://art/palette.gpl")
	_save_image(_draw_shireen_sheet(), "res://art/shireen/shireen.png")
	_save_image(_draw_sand_tile(), "res://art/world/sand.png")
	_save_image(_draw_palm_tree(), "res://art/props/palm_tree.png")
	_save_image(_draw_lada_taxi(), "res://art/props/lada_taxi.png")
	quit(1 if _failed else 0)


func c(name: String) -> Color:
	if not _colors.has(name):
		_fail("'%s' is not in the palette" % name)
		return Color.MAGENTA
	return _colors[name]


func _fail(message: String) -> void:
	push_error("generate_sprites: " + message)
	_failed = true


# --- Saving -----------------------------------------------------------------

func _should_write(path: String) -> bool:
	if FileAccess.file_exists(path) and not _force:
		print("  kept     %s (already exists; --force redraws it)" % path)
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	print("  wrote    %s" % path)
	return true


func _save_image(image: Image, path: String) -> void:
	if _should_write(path):
		var error: Error = image.save_png(path)
		if error != OK:
			_fail("could not save %s (%s)" % [path, error_string(error)])


func _save_text(text: String, path: String) -> void:
	if _should_write(path):
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			_fail("could not save %s (%s)" % [path, error_string(FileAccess.get_open_error())])
			return
		file.store_string(text)


# --- Palette ----------------------------------------------------------------

## One pixel per colour, in palette order.
func _draw_palette() -> Image:
	var image := Image.create_empty(PALETTE.size(), 1, false, Image.FORMAT_RGBA8)
	for i: int in PALETTE.size():
		image.set_pixel(i, 0, c(PALETTE[i][0]))
	return image


## GIMP palette format, which LibreSprite loads (Palette > Load Palette).
func _palette_gpl() -> String:
	var lines: PackedStringArray = ["GIMP Palette", "Name: Habibi, Get Closer", "Columns: 8", "#"]
	for entry: Array in PALETTE:
		var color: Color = c(entry[0])
		lines.append("%3d %3d %3d\t%s" % [color.r8, color.g8, color.b8, entry[0]])
	return "\n".join(lines) + "\n"


# --- Shireen ----------------------------------------------------------------

func _draw_shireen_sheet() -> Image:
	var image := Image.create_empty(FRAME_SIZE.x * SHIREEN_FRAMES.size(), FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	for i: int in SHIREEN_FRAMES.size():
		var canvas := Canvas.new(image, Vector2i(FRAME_SIZE.x * i, 0), FRAME_SIZE)
		var frame: Dictionary = SHIREEN_FRAMES[i]
		_draw_shireen(canvas, frame.bob, frame.hip, frame.step, frame.glint)
	return image


## Shireen facing right (the game mirrors her to face left). Feet at y = 29.
## [param bob] lifts her upper body, [param hip] sways her hips and skirt,
## [param step] picks the feet (0 together, 1 left forward, 2 right forward)
## and [param glint] which coins on her hip scarf catch the light.
func _draw_shireen(canvas: Canvas, bob: int, hip: int, step: int, glint: int) -> void:
	# Long hair falling behind her back.
	canvas.ellipse(15.5, 9.5 + bob, 6.5, 6.5, c("hair"))
	canvas.rect(9, 10 + bob, 6, 9, c("hair"))
	canvas.rect(10, 12 + bob, 1, 5, c("hair_light"))

	# Long beledi dress skirt, widening towards the hem.
	for i: int in 8:
		var y: int = 21 + i
		var half: int = 4 + roundi(i * 0.45)
		var sway: int = hip + (1 if step == 1 and i > 4 else 0) - (1 if step == 2 and i > 4 else 0)
		var left: int = 16 + sway - half
		canvas.hline(left, 16 + sway + half, y, c("dress"))
		canvas.hline(left, left + 1, y, c("dress_dark"))
		canvas.px(16 + sway + 2, y, c("dress_light"))
	canvas.hline(16 + hip - 7, 16 + hip + 7, 28, c("gold"))

	# Sandaled feet peeking out under the hem.
	var back_foot: int = 13 if step != 2 else 14
	var front_foot: int = 18 if step != 1 else 20
	canvas.rect(back_foot, 29, 2, 1, c("skin_shadow"))
	canvas.rect(front_foot, 29, 2, 1, c("skin"))

	# Bodice and neck.
	canvas.rect(15, 12 + bob, 3, 2, c("skin_shadow"))
	canvas.rect(12, 14 + bob, 9, 6, c("dress"))
	canvas.rect(12, 14 + bob, 2, 6, c("dress_dark"))
	canvas.hline(14, 19, 14 + bob, c("gold"))

	# Coin hip scarf: a gold band with a row of coins hanging below it.
	canvas.rect(11 + hip, 19, 11, 2, c("gold"))
	canvas.hline(11 + hip, 21 + hip, 20, c("gold_dark"))
	for x: int in range(11, 22, 2):
		var bright: bool = (x + 2 * glint) % 4 == 1
		canvas.px(x + hip, 21, c("gold_light") if bright else c("gold"))

	# Back arm down, front arm raised in a dance pose, with gold bangles.
	canvas.rect(10, 15 + bob, 2, 4, c("dress_dark"))
	canvas.px(10, 19 + bob, c("skin_shadow"))
	canvas.rect(21, 13 + bob, 2, 4, c("dress"))
	canvas.px(21, 12 + bob, c("gold"))
	canvas.rect(22, 10 + bob, 2, 2, c("skin"))

	# Face, turned to the right.
	canvas.ellipse(17.5, 10 + bob, 4, 4.5, c("skin"))
	canvas.vline(14, 8 + bob, 12 + bob, c("skin_shadow"))
	canvas.px(18, 11 + bob, c("skin_light"))
	canvas.px(19, 9 + bob, c("ink"))  # Eye with a kohl wing.
	canvas.px(20, 8 + bob, c("ink"))
	canvas.px(20, 12 + bob, c("rose"))
	canvas.px(15, 12 + bob, c("gold_light"))  # Earring.

	# Fringe and a gold headpiece.
	canvas.ellipse(16.5, 7 + bob, 5.5, 3.5, c("hair"), 7 + bob)
	canvas.hline(14, 19, 5 + bob, c("gold"))
	canvas.px(17, 5 + bob, c("gold_light"))

	canvas.outline(c("ink"))
	canvas.ellipse(16, 30, 7, 1.6, c("sand_dark"), 999, true)


# --- World ------------------------------------------------------------------

## A 64×64 sand tile. Every feature wraps around the edges, so the tile
## repeats without visible seams.
func _draw_sand_tile() -> Image:
	const SIZE: int = 64
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	image.fill(c("sand"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7  # Fixed, so --force redraws the same tile.

	# Wind ripples: a light crest with a darker trough just below it.
	for i: int in 9:
		var x: int = rng.randi_range(0, SIZE - 1)
		var y: int = rng.randi_range(0, SIZE - 1)
		var length: int = rng.randi_range(4, 8)
		for dx: int in length:
			image.set_pixel((x + dx) % SIZE, y, c("sand_light"))
			image.set_pixel((x + dx + 1) % SIZE, (y + 1) % SIZE, c("sand_dark"))

	# Grains.
	for grain: Array in [["sand_light", 110], ["sand_dark", 70], ["sand_pale", 20]]:
		for i: int in grain[1]:
			image.set_pixel(rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1), c(grain[0]))
	return image


## A date palm, 32×48. Its base (where it meets the sand) is at (16, 46).
func _draw_palm_tree() -> Image:
	var image := Image.create_empty(32, 48, false, Image.FORMAT_RGBA8)
	var canvas := Canvas.new(image, Vector2i.ZERO, Vector2i(32, 48))

	# Trunk, leaning slightly right, with ring marks.
	for y: int in range(16, 47):
		var cx: int = 15 + roundi((46 - y) * 0.12)
		canvas.hline(cx - 1, cx + 1, y, c("trunk_dark") if y % 3 == 0 else c("trunk"))
		canvas.px(cx - 1, y, c("trunk_dark"))

	# Fronds: arcs from the crown that droop towards their tips.
	var crown := Vector2(19, 15)
	for frond: Array in [[-175.0, 15, 0.06], [-150.0, 14, 0.08], [-120.0, 10, 0.12],
			[-85.0, 8, 0.15], [-60.0, 12, 0.09], [-30.0, 14, 0.07], [-5.0, 15, 0.06],
			[150.0, 11, 0.03], [30.0, 11, 0.03]]:
		var angle: float = deg_to_rad(frond[0])
		var length: int = frond[1]
		var droop: float = frond[2]
		for t: int in length:
			var x: int = roundi(crown.x + cos(angle) * t)
			var y: int = roundi(crown.y + sin(angle) * t + droop * t * t)
			canvas.px(x, y, c("leaf_light") if t * 2 < length else c("leaf"))
			canvas.px(x, y + 1, c("leaf_dark") if t > length - 4 else c("leaf"))
			# Leaflets hanging off the middle of the frond.
			if t > 2 and t < length - 2 and t % 2 == 0:
				canvas.px(x, y + 2, c("leaf_dark"))

	# Dates under the crown.
	canvas.ellipse(17.5, 17.5, 1.5, 1.5, c("gold_dark"))
	canvas.ellipse(20.5, 17.5, 1.5, 1.5, c("trunk_dark"))

	canvas.outline(c("ink"))
	canvas.ellipse(16, 46.5, 8, 1.6, c("sand_dark"), 999, true)
	return image


## A broken-down Cairo-style Lada taxi, black and white, facing right, with
## its bonnet up and steam coming out. 48×32, base (wheels) at y = 29.
func _draw_lada_taxi() -> Image:
	var image := Image.create_empty(48, 32, false, Image.FORMAT_RGBA8)
	var canvas := Canvas.new(image, Vector2i.ZERO, Vector2i(48, 32))

	# Steam puffs behind the raised bonnet.
	canvas.ellipse(42, 9, 2.5, 2, c("car_white"))
	canvas.ellipse(44.5, 5, 2, 1.8, c("sand_pale"))

	# Body: black lower half, white doors, white cabin with two windows.
	canvas.rect(3, 15, 42, 9, c("car_black"))
	canvas.rect(12, 16, 22, 5, c("car_white"))
	canvas.vline(23, 16, 20, c("car_gray"))
	canvas.rect(11, 8, 22, 8, c("car_white"))
	canvas.rect(13, 10, 8, 5, c("glass"))
	canvas.rect(23, 10, 8, 5, c("glass"))
	canvas.px(14, 10, c("sand_pale"))
	canvas.px(24, 10, c("sand_pale"))
	canvas.rect(20, 6, 4, 2, c("gold_light"))  # Taxi sign.

	# The bonnet, propped open at an angle.
	for i: int in 7:
		canvas.rect(34 + i, 14 - i, 2, 1, c("car_black"))

	# Bumpers and lights.
	canvas.rect(2, 21, 3, 2, c("chrome"))
	canvas.rect(43, 21, 3, 2, c("chrome"))
	canvas.px(44, 18, c("gold_light"))
	canvas.px(3, 18, c("rose"))

	# Wheels.
	for wheel_x: float in [12.5, 35.5]:
		canvas.ellipse(wheel_x, 25.5, 4, 4, c("car_black"))
		canvas.ellipse(wheel_x, 25.5, 1.5, 1.5, c("chrome"))

	canvas.outline(c("ink"))
	canvas.ellipse(24, 30, 21, 1.8, c("sand_dark"), 999, true)
	return image


# --- Drawing helpers --------------------------------------------------------

## Draws into one frame of an image. Coordinates are relative to the frame,
## and pixels outside it are ignored, so frames never bleed into each other.
class Canvas:
	var _image: Image
	var _origin: Vector2i
	var _size: Vector2i

	func _init(image: Image, origin: Vector2i, size: Vector2i) -> void:
		_image = image
		_origin = origin
		_size = size

	func px(x: int, y: int, color: Color) -> void:
		if x >= 0 and y >= 0 and x < _size.x and y < _size.y:
			_image.set_pixel(_origin.x + x, _origin.y + y, color)

	func is_empty(x: int, y: int) -> bool:
		if x < 0 or y < 0 or x >= _size.x or y >= _size.y:
			return true
		return _image.get_pixel(_origin.x + x, _origin.y + y).a == 0.0

	func rect(x: int, y: int, w: int, h: int, color: Color) -> void:
		for yy: int in range(y, y + h):
			for xx: int in range(x, x + w):
				px(xx, yy, color)

	## Inclusive at both ends.
	func hline(x0: int, x1: int, y: int, color: Color) -> void:
		for x: int in range(x0, x1 + 1):
			px(x, y, color)

	## Inclusive at both ends.
	func vline(x: int, y0: int, y1: int, color: Color) -> void:
		for y: int in range(y0, y1 + 1):
			px(x, y, color)

	## Fills every pixel whose centre is inside the ellipse. Rows below
	## [param max_y] are skipped. With [param under] it only fills empty
	## pixels, which is how ground shadows go behind what is already drawn.
	func ellipse(cx: float, cy: float, rx: float, ry: float, color: Color, max_y: int = 999, under: bool = false) -> void:
		for y: int in range(floori(cy - ry), ceili(cy + ry) + 1):
			if y > max_y:
				continue
			for x: int in range(floori(cx - rx), ceili(cx + rx) + 1):
				var nx: float = (x + 0.5 - cx) / rx
				var ny: float = (y + 0.5 - cy) / ry
				if nx * nx + ny * ny <= 1.0 and (not under or is_empty(x, y)):
					px(x, y, color)

	## Draws a 1-pixel outline around everything drawn so far, so sprites read
	## clearly against the sand.
	func outline(color: Color) -> void:
		var edge: Array[Vector2i] = []
		for y: int in _size.y:
			for x: int in _size.x:
				if is_empty(x, y) and (not is_empty(x - 1, y) or not is_empty(x + 1, y)
						or not is_empty(x, y - 1) or not is_empty(x, y + 1)):
					edge.append(Vector2i(x, y))
		for p: Vector2i in edge:
			px(p.x, p.y, color)
