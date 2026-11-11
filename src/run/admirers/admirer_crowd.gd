class_name AdmirerCrowd
extends RefCounted
## Every admirer in a run, and the rules for how they move as a crowd and
## how they are dazzled.
##
## Each step, every admirer's behavior says where he wants to go and he walks
## there. Then the crowd is pushed apart: wherever two body circles overlap,
## the admirers are nudged away from each other, and anyone inside Shireen's
## body is moved back to its edge. That's what makes them spread out around
## her instead of stacking into one blob (spec story 50). There is no physics
## engine; a SpatialGrid keeps it cheap with hundreds of admirers.
##
## The crowd also says who is touching Shireen once everyone has moved (see
## Admirer.touching). What a touch costs her is the Run's business.
##
## Weapons find admirers with [method nearest] and [method in_circle] and
## lower their HP with [method damage]. At 0 HP an admirer is dazzled: he
## moves from [member admirers] to [member dazzled] at once, so from that
## moment he blocks nobody, can't be hit and doesn't count as chasing. He
## swoons where he stands, walks off, and is removed once he's off screen.

## How many times per step the overlaps are pushed apart. Fixing one pair can
## push into the next, but with the give-way rule below one pass already keeps
## overlaps to a few percent in a crush of 300 (measured: a second pass
## costs double for almost no gain).
const SEPARATION_PASSES: int = 1

## How sharply the admirer farther from Shireen gives way in an overlap (see
## [method _give_way_share]). At 8 the split is all-or-nothing unless the pair
## is almost exactly level with her; 0 would split every overlap evenly. Tuned
## together with SEPARATION_PASSES for the crush of 300; the tests depend on it.
const GIVE_WAY: float = 8.0

## Admirers exactly on top of each other have no direction to be pushed in.
## They're split along a direction picked from their ids, so the result is
## still the same every run.
const GOLDEN_ANGLE: float = 2.39996323

## An admirer touches Shireen when his body circle is within this many pixels
## of hers. An admirer pressed against her stands exactly on her edge, give or
## take float rounding, and one jostled by his neighbours a fraction of a pixel
## outside it. On screen both look like contact, so both count.
const TOUCH_SLACK: float = 1.0

## Timers here add up one small step at a time, which doesn't land exactly
## on a round number: 36 steps of 1/60 s can come out a hair under 0.6 s.
## A timer this close to its end counts as over.
const TIMER_SLACK: float = 1e-9

## How far past the screen edge a dazzled admirer walks before he's removed:
## a sprite's height, so no part of him is still showing when he goes.
const OFF_SCREEN_MARGIN: float = 32.0

## The admirers chasing Shireen, in spawn order (oldest first).
var admirers: Array[Admirer] = []

## The dazzled admirers, swooning or walking off, in the order dazzled.
var dazzled: Array[Admirer] = []

## The admirers dazzled since the last [method step], in the order dazzled.
## The Run reads it after the weapon has had its turn, to drop their cash.
var dazzled_this_step: Array[Admirer] = []

## How many admirers have been dazzled this run.
var dazzled_count: int = 0

var _shireen_radius: float
var _grid: SpatialGrid
## The largest body radius of any admirer type, so a query around one
## admirer is sure to find everyone who could be touching him.
var _max_radius: float
## Half the screen plus OFF_SCREEN_MARGIN. A dazzled admirer farther than
## this from Shireen, left-right or up-down, is off screen.
var _off_screen_half_size: Vector2
## The chasing admirers' positions and radii, always in step with
## [member admirers]: entry i belongs to admirers[i]. Packed arrays of plain
## numbers are much faster to loop over in GDScript than the Admirer objects.
var _positions: PackedVector2Array = PackedVector2Array()
var _radii: PackedFloat32Array = PackedFloat32Array()
## Whether the grid matches [member _positions]. The separation pass leaves
## it one nudge behind, and anyone arriving or being dazzled changes the
## list, so [method in_circle] rebuilds it when needed.
var _grid_is_current: bool = false
## Reused for every grid query, so a step doesn't allocate hundreds of arrays.
var _nearby: Array[int] = []
## Working list for [method nearest].
var _nearest_distances: PackedFloat64Array = PackedFloat64Array()


## [param play_area] is the size of the visible screen, which stays centred
## on Shireen.
func _init(shireen_radius: float, max_admirer_radius: float, play_area: Vector2) -> void:
	_shireen_radius = shireen_radius
	_max_radius = max_admirer_radius
	_off_screen_half_size = play_area / 2.0 + Vector2(OFF_SCREEN_MARGIN, OFF_SCREEN_MARGIN)
	# Two touching admirers are at most two max radii apart, so with cells
	# that size a query only ever looks one cell out.
	_grid = SpatialGrid.new(maxf(max_admirer_radius * 2.0, 1.0))


func add(admirer: Admirer) -> void:
	admirers.append(admirer)
	_positions.append(admirer.position)
	_radii.append(admirer.type.body_radius)
	_grid_is_current = false


## How many admirers are chasing Shireen. Dazzled ones don't count.
func size() -> int:
	return admirers.size()


## Moves every chasing admirer by his behavior, pushes the crowd apart and
## marks who ended up touching Shireen, then moves the dazzled ones along.
func step(delta: float, shireen_position: Vector2) -> void:
	dazzled_this_step.clear()
	var count: int = admirers.size()
	for i: int in count:
		var admirer: Admirer = admirers[i]
		var velocity: Vector2 = admirer.behavior.desired_velocity(admirer, shireen_position)
		if not velocity.is_zero_approx():
			admirer.position += velocity * delta
			admirer.facing = velocity.normalized()
		_positions[i] = admirer.position

	for pass_index: int in SEPARATION_PASSES:
		_separate(shireen_position)

	for i: int in count:
		var admirer: Admirer = admirers[i]
		admirer.position = _positions[i]
		var reach: float = _radii[i] + _shireen_radius + TOUCH_SLACK
		admirer.touching = _positions[i].distance_squared_to(shireen_position) <= reach * reach
	_grid_is_current = false

	_step_dazzled(delta, shireen_position)


## Fills [param out] with up to [param count] chasing admirers within
## [param max_distance] of [param position] (measured to their feet), nearest
## first. Weapons aim with it.
func nearest(position: Vector2, max_distance: float, count: int, out: Array[Admirer]) -> void:
	out.clear()
	# The distances of the admirers in out, squared, in the same order.
	_nearest_distances.clear()
	var farthest_allowed: float = max_distance * max_distance
	for i: int in _positions.size():
		var distance: float = _positions[i].distance_squared_to(position)
		if distance > farthest_allowed:
			continue
		# Once the list is full, only someone nearer than its last entry
		# gets in, and that entry drops out.
		if out.size() == count:
			if distance >= _nearest_distances[count - 1]:
				continue
			out.pop_back()
			_nearest_distances.remove_at(count - 1)
		var slot: int = out.size()
		while slot > 0 and _nearest_distances[slot - 1] > distance:
			slot -= 1
		out.insert(slot, admirers[i])
		_nearest_distances.insert(slot, distance)


## Fills [param out] with the chasing admirers whose body circle touches the
## circle at [param center] with [param radius]. Weapons check their hits
## with it. It looks only at the admirers the spatial grid has near that
## spot, not at the whole crowd.
func in_circle(center: Vector2, radius: float, out: Array[Admirer]) -> void:
	out.clear()
	if not _grid_is_current:
		_grid.rebuild(_positions)
		_grid_is_current = true
	_grid.query(center, radius + _max_radius, _nearby)
	for i: int in _nearby:
		var reach: float = radius + _radii[i]
		if _positions[i].distance_squared_to(center) <= reach * reach:
			out.append(admirers[i])


## Takes [param amount] off a chasing admirer's HP. At 0 he is dazzled.
func damage(admirer: Admirer, amount: float) -> void:
	if admirer.state != Admirer.State.CHASING:
		return
	admirer.hp = maxf(admirer.hp - amount, 0.0)
	if admirer.hp == 0.0:
		_dazzle(admirer)


## Takes a dazzled admirer out of the chasing crowd on the spot, so nothing
## later in this step (or any other) treats him as in the way.
func _dazzle(admirer: Admirer) -> void:
	var index: int = admirers.find(admirer)
	admirers.remove_at(index)
	_positions.remove_at(index)
	_radii.remove_at(index)
	_grid_is_current = false
	admirer.state = Admirer.State.SWOONING
	admirer.state_time = 0.0
	# However close he still stands, he no longer counts as touching her.
	admirer.touching = false
	dazzled.append(admirer)
	dazzled_this_step.append(admirer)
	dazzled_count += 1


## Dazzled admirers swoon on the spot, then walk straight away from where
## Shireen was when the swoon ended, until they are off screen.
func _step_dazzled(delta: float, shireen_position: Vector2) -> void:
	# The ones still on the field are moved down over the ones who have gone.
	var kept: int = 0
	for admirer: Admirer in dazzled:
		admirer.state_time += delta
		if admirer.state == Admirer.State.SWOONING:
			if admirer.state_time >= admirer.type.swoon_seconds - TIMER_SLACK:
				admirer.state = Admirer.State.LEAVING
				admirer.state_time = 0.0
				var away: Vector2 = admirer.position - shireen_position
				admirer.facing = away.normalized() if not away.is_zero_approx() else Vector2.RIGHT.rotated(admirer.id * GOLDEN_ANGLE)
		else:
			admirer.position += admirer.facing * admirer.type.leave_speed * delta
			var from_shireen: Vector2 = (admirer.position - shireen_position).abs()
			if from_shireen.x > _off_screen_half_size.x or from_shireen.y > _off_screen_half_size.y:
				continue
		dazzled[kept] = admirer
		kept += 1
	dazzled.resize(kept)


## One pass over every overlapping pair, then Shireen's body.
func _separate(shireen_position: Vector2) -> void:
	_grid.rebuild(_positions)
	for i: int in _positions.size():
		var a: Vector2 = _positions[i]
		var radius_a: float = _radii[i]
		_grid.query(a, radius_a + _max_radius, _nearby)
		for j: int in _nearby:
			# Each pair once: the lower index handles it.
			if j <= i:
				continue
			var b: Vector2 = _positions[j]
			var min_distance: float = radius_a + _radii[j]
			var apart: Vector2 = a - b
			var distance_squared: float = apart.length_squared()
			if distance_squared >= min_distance * min_distance:
				continue
			var distance: float = sqrt(distance_squared)
			var direction: Vector2
			if distance < 0.001:
				direction = Vector2.RIGHT.rotated((admirers[i].id * 31 + admirers[j].id) * GOLDEN_ANGLE)
			else:
				direction = apart / distance
			var overlap: float = min_distance - distance
			var a_share: float = _give_way_share(a, b, shireen_position)
			a += direction * overlap * a_share
			_positions[j] = b - direction * overlap * (1.0 - a_share)
		_positions[i] = _keep_out_of_shireen(a, radius_a + _shireen_radius, shireen_position, admirers[i].id)


## How much of an overlap admirer [param a] takes against [param b], from 0
## to 1. In practice the one farther from Shireen takes all of it: he's the
## one pushing in from behind, and the one in front is already pressed against
## someone. Splitting every overlap evenly instead lets the weight of the whole
## crowd squeeze the inner rings together.
##
## Only a pair almost exactly level with her shares the push. The split runs
## on squared distances and saturates once their difference reaches 1/16 of
## their sum, about 6% apart in plain distance: at 50 px from her, a neighbour
## at 51 px takes 66%, at 52 px 81%, at 53 px 97%, and from 53.2 px on, all.
static func _give_way_share(a: Vector2, b: Vector2, shireen_position: Vector2) -> float:
	var a_distance: float = a.distance_squared_to(shireen_position)
	var b_distance: float = b.distance_squared_to(shireen_position)
	# The + 1.0 keeps the division safe when both stand exactly on Shireen.
	return clampf(0.5 + (a_distance - b_distance) / (a_distance + b_distance + 1.0) * GIVE_WAY, 0.0, 1.0)


## Shireen doesn't get shoved: an admirer inside her body circle is moved to
## its edge. So a crowd presses around her rather than piling onto her, and
## when she walks into them they're pushed aside.
static func _keep_out_of_shireen(position: Vector2, min_distance: float, shireen_position: Vector2, id: int) -> Vector2:
	var apart: Vector2 = position - shireen_position
	if apart.length_squared() >= min_distance * min_distance:
		return position
	var direction: Vector2 = apart.normalized() if not apart.is_zero_approx() else Vector2.RIGHT.rotated(id * GOLDEN_ANGLE)
	return shireen_position + direction * min_distance
