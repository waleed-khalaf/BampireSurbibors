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

## The Dowry Uncle's sheet: one row of 32×32 frames. A 2-frame walk, then
## the swoon he does when dazzled. Every admirer sheet has this layout.
## Keep art/README.md in sync if this changes.
const UNCLE_FRAMES: Array[Dictionary] = [
	{"bob": 0, "step": 1, "swoon": false},  # Left foot forward.
	{"bob": -1, "step": 2, "swoon": false},  # Right foot forward, body up 1 px.
	{"bob": 0, "step": 0, "swoon": true},  # Dazzled: feet together, hand on heart.
]

## Projectile sheets are one row of 16×16 frames, centred on (8, 8).
const PROJECTILE_FRAME_SIZE: Vector2i = Vector2i(16, 16)

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
	_save_image(_draw_uncle_sheet(), "res://art/admirers/dowry_uncle.png")
	_save_image(_draw_zill_sheet(), "res://art/projectiles/zill.png")
	_save_image(_draw_heart_sheet(), "res://art/effects/heart.png")
	_save_image(_draw_cash_sheet(), "res://art/pickups/cash.png")
	_save_image(_draw_tea_sheet(), "res://art/pickups/karkadeh_tea.png")
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


# --- Admirers ---------------------------------------------------------------

func _draw_uncle_sheet() -> Image:
	var image := Image.create_empty(FRAME_SIZE.x * UNCLE_FRAMES.size(), FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	for i: int in UNCLE_FRAMES.size():
		var canvas := Canvas.new(image, Vector2i(FRAME_SIZE.x * i, 0), FRAME_SIZE)
		_draw_uncle(canvas, UNCLE_FRAMES[i].bob, UNCLE_FRAMES[i].step, UNCLE_FRAMES[i].swoon)
	return image


## The Dowry Uncle facing right (the game mirrors him to face left): a
## dignified older gentleman in a white thobe and a red-checked ghutra with a
## black agal, a neat grey beard, a gold watch, and the briefcase with the
## dowry offer. Feet at y = 29, like Shireen. [param bob] lifts his upper
## body, [param step] picks which foot is forward (1 left, 2 right, 0 feet
## together). With [param swoon] he is dazzled: a heart for an eye, a blush,
## his hand on his heart and the briefcase dropped at his feet.
func _draw_uncle(canvas: Canvas, bob: int, step: int, swoon: bool) -> void:
	# Ghutra falling behind his shoulders.
	canvas.rect(10, 9 + bob, 5, 8, c("car_white"))
	canvas.vline(10, 10 + bob, 16 + bob, c("chrome"))

	# Long white thobe, slightly wider at the hem.
	for i: int in 14:
		var y: int = 15 + i
		var half: int = 5 + (1 if i > 8 else 0)
		canvas.hline(16 - half, 15 + half, y, c("car_white"))
		canvas.px(16 - half, y, c("chrome"))
		canvas.px(16 - half + 1, y, c("chrome"))
	# The button placket down his front.
	canvas.vline(18, 16 + bob, 21, c("chrome"))

	# Sandals peeking out under the hem, one foot ahead of the other.
	var back_foot: int = 12 if step == 1 else 14
	var front_foot: int = 19 if step == 1 else 17
	if step == 0:
		back_foot = 13
		front_foot = 17
	canvas.rect(back_foot, 29, 3, 1, c("trunk_dark"))
	canvas.rect(front_foot, 29, 3, 1, c("trunk"))

	# Face, turned to the right, framed by the ghutra.
	canvas.ellipse(16, 9 + bob, 5.5, 5.5, c("car_white"))
	canvas.ellipse(17.5, 10 + bob, 3, 3.5, c("skin"))
	canvas.px(15, 10 + bob, c("skin_shadow"))
	if swoon:
		canvas.px(19, 9 + bob, c("rose"))  # A heart for an eye.
		canvas.px(18, 11 + bob, c("rose"))  # Blush.
		canvas.hline(18, 20, 7 + bob, c("car_gray"))  # Brow, raised.
	else:
		canvas.px(19, 9 + bob, c("ink"))  # Eye.
		canvas.hline(18, 20, 8 + bob, c("car_gray"))  # Brow.
	# Neat grey beard and moustache.
	canvas.hline(17, 20, 12 + bob, c("car_gray"))
	canvas.hline(17, 19, 13 + bob, c("car_gray"))
	canvas.px(20, 11 + bob, c("chrome"))
	# Red checks on the ghutra.
	for check: Vector2i in [Vector2i(12, 6), Vector2i(14, 5), Vector2i(12, 9), Vector2i(11, 12), Vector2i(13, 14), Vector2i(12, 16)]:
		canvas.px(check.x, check.y + bob, c("rose"))
	# Black agal: two cords round the crown.
	canvas.hline(12, 20, 4 + bob, c("hair"))
	canvas.hline(12, 20, 5 + bob, c("hair_light"))

	if swoon:
		# Front arm bent up, hand on his heart, the gold watch at his wrist.
		canvas.rect(18, 16 + bob, 3, 2, c("car_white"))
		canvas.hline(18, 20, 17 + bob, c("chrome"))
		canvas.px(17, 16 + bob, c("gold"))
		canvas.px(16, 16 + bob, c("skin"))
		# The briefcase, dropped on the sand beside him.
		canvas.rect(22, 25, 7, 4, c("trunk"))
		canvas.hline(22, 28, 28, c("trunk_dark"))
		canvas.hline(24, 26, 24, c("trunk_dark"))  # Handle.
		canvas.px(25, 26, c("gold_light"))  # Clasp.
	else:
		# Front arm down, holding the briefcase, with a gold watch.
		canvas.rect(19, 16 + bob, 2, 6, c("car_white"))
		canvas.vline(19, 16 + bob, 21 + bob, c("chrome"))
		canvas.px(20, 21 + bob, c("gold"))
		canvas.px(20, 22 + bob, c("skin"))
		canvas.hline(20, 23, 22 + bob, c("trunk_dark"))  # Handle.
		canvas.rect(19, 23 + bob, 7, 5, c("trunk"))
		canvas.hline(19, 25, 27 + bob, c("trunk_dark"))
		canvas.px(22, 24 + bob, c("gold_light"))  # Clasp.

	canvas.outline(c("ink"))
	canvas.ellipse(16, 30, 7, 1.6, c("sand_dark"), 999, true)


# --- Projectiles and effects ------------------------------------------------

## A zill (finger cymbal) spinning in flight: two 16×16 frames, face-on and
## edge-on. The disc is 4 px in radius, the zill's size in the weapon data.
func _draw_zill_sheet() -> Image:
	var image := Image.create_empty(PROJECTILE_FRAME_SIZE.x * 2, PROJECTILE_FRAME_SIZE.y, false, Image.FORMAT_RGBA8)

	# Face-on: a brass disc with a raised boss in the middle and a glint.
	var face := Canvas.new(image, Vector2i(0, 0), PROJECTILE_FRAME_SIZE)
	face.ellipse(8, 8, 4.5, 4.5, c("gold"))
	face.ellipse(8.5, 8.5, 3.5, 3.5, c("gold_dark"), 999, false)
	face.ellipse(7.5, 7.5, 3.5, 3.5, c("gold"))
	face.ellipse(8, 8, 1.5, 1.5, c("gold_dark"))
	face.px(6, 5, c("gold_light"))
	face.px(5, 6, c("gold_light"))
	face.px(7, 7, c("gold_light"))
	face.outline(c("ink"))

	# Edge-on: the same disc seen from the side, with the boss on top.
	var edge := Canvas.new(image, Vector2i(PROJECTILE_FRAME_SIZE.x, 0), PROJECTILE_FRAME_SIZE)
	edge.ellipse(8, 8.5, 4.5, 1.5, c("gold"))
	edge.hline(5, 10, 9, c("gold_dark"))
	edge.hline(7, 8, 6, c("gold"))
	edge.px(6, 7, c("gold_light"))
	edge.outline(c("ink"))
	return image


## The heart that pops over a dazzled admirer: two 16×16 frames, a small
## heart and then the full one, both centred on (8, 8).
func _draw_heart_sheet() -> Image:
	var image := Image.create_empty(PROJECTILE_FRAME_SIZE.x * 2, PROJECTILE_FRAME_SIZE.y, false, Image.FORMAT_RGBA8)

	var small := Canvas.new(image, Vector2i(0, 0), PROJECTILE_FRAME_SIZE)
	small.px(6, 6, c("rose"))
	small.px(8, 6, c("rose"))
	small.hline(5, 9, 7, c("rose"))
	small.hline(6, 8, 8, c("rose"))
	small.px(7, 9, c("rose"))
	small.outline(c("ink"))

	var big := Canvas.new(image, Vector2i(PROJECTILE_FRAME_SIZE.x, 0), PROJECTILE_FRAME_SIZE)
	big.hline(4, 5, 4, c("rose"))
	big.hline(9, 10, 4, c("rose"))
	big.hline(3, 6, 5, c("rose"))
	big.hline(8, 11, 5, c("rose"))
	big.hline(3, 11, 6, c("rose"))
	big.hline(3, 11, 7, c("rose"))
	big.hline(4, 10, 8, c("rose"))
	big.hline(5, 9, 9, c("rose"))
	big.hline(6, 8, 10, c("rose"))
	big.px(7, 11, c("rose"))
	big.px(4, 5, c("car_white"))  # Shine.
	big.px(5, 5, c("car_white"))
	big.px(4, 6, c("car_white"))
	big.outline(c("ink"))
	return image


# --- Pickups ----------------------------------------------------------------

## The cash dazzled admirers drop: three 16×16 frames, each centred on (8, 8),
## for bigger and bigger bills: one bill, a small stack, and a fat wad with a
## gold band. The game picks the frame by the bill's value.
func _draw_cash_sheet() -> Image:
	var image := Image.create_empty(PROJECTILE_FRAME_SIZE.x * 3, PROJECTILE_FRAME_SIZE.y, false, Image.FORMAT_RGBA8)

	var one := Canvas.new(image, Vector2i(0, 0), PROJECTILE_FRAME_SIZE)
	_draw_bill(one, 4, 6, 8, 5)
	one.outline(c("ink"))

	# Two bills, the top one shifted up and across.
	var stack := Canvas.new(image, Vector2i(PROJECTILE_FRAME_SIZE.x, 0), PROJECTILE_FRAME_SIZE)
	_draw_bill(stack, 3, 7, 9, 5)
	_draw_bill(stack, 4, 4, 9, 5)
	stack.outline(c("ink"))

	# A wad: a thick edge under a big bill, with a gold band around it.
	var wad := Canvas.new(image, Vector2i(PROJECTILE_FRAME_SIZE.x * 2, 0), PROJECTILE_FRAME_SIZE)
	wad.rect(3, 10, 11, 2, c("leaf_dark"))
	_draw_bill(wad, 3, 3, 11, 7)
	wad.vline(8, 3, 11, c("gold"))
	wad.vline(9, 3, 11, c("gold_light"))
	wad.outline(c("ink"))
	return image


## One banknote lying flat: a green rectangle with a lighter border and a
## gold seal in the middle. [param w] and [param h] are at least 5.
func _draw_bill(canvas: Canvas, x: int, y: int, w: int, h: int) -> void:
	canvas.rect(x, y, w, h, c("leaf"))
	canvas.rect(x + 1, y + 1, w - 2, h - 2, c("leaf_light"))
	canvas.rect(x + 2, y + 2, w - 4, h - 4, c("leaf"))
	@warning_ignore("integer_division")
	canvas.px(x + w / 2, y + h / 2, c("gold_light"))


## A cup of karkadeh tea: a glass of ruby-red tea on a saucer, with a wisp of
## steam. One 16×16 frame centred on (8, 8).
func _draw_tea_sheet() -> Image:
	var image := Image.create_empty(PROJECTILE_FRAME_SIZE.x, PROJECTILE_FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	var cup := Canvas.new(image, Vector2i(0, 0), PROJECTILE_FRAME_SIZE)
	# The saucer.
	cup.ellipse(8, 12.5, 5.5, 1.5, c("car_white"))
	cup.hline(4, 11, 13, c("chrome"))
	# The glass, full of tea, with a shine down its left side.
	cup.rect(5, 5, 6, 7, c("rose"))
	cup.hline(5, 10, 4, c("car_white"))
	cup.vline(5, 5, 11, c("chrome"))
	cup.vline(10, 5, 11, c("chrome"))
	cup.px(6, 6, c("gold_light"))
	cup.px(6, 7, c("car_white"))
	# The handle.
	cup.px(11, 6, c("chrome"))
	cup.vline(12, 7, 9, c("chrome"))
	cup.px(11, 10, c("chrome"))
	# Steam.
	cup.px(7, 2, c("car_white"))
	cup.px(9, 1, c("car_white"))
	cup.outline(c("ink"))
	return image


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
