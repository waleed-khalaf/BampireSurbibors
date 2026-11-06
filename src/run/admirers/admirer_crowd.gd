class_name AdmirerCrowd
extends RefCounted
## Every admirer in a run, and the rules for how they move as a crowd.
##
## Each step, every admirer's behavior says where he wants to go and he walks
## there. Then the crowd is pushed apart: wherever two body circles overlap,
## the admirers are nudged away from each other, and anyone inside Shireen's
## body is moved back to its edge. That's what makes them spread out around
## her instead of stacking into one blob (spec story 50). There is no physics
## engine; a SpatialGrid keeps it cheap with hundreds of admirers.

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

var admirers: Array[Admirer] = []

var _shireen_radius: float
var _grid: SpatialGrid
## The largest body radius of any admirer type, so a query around one
## admirer is sure to find everyone who could be touching him.
var _max_radius: float
## Working copies for the separation passes. Packed arrays of plain numbers
## are much faster to loop over in GDScript than the Admirer objects.
var _positions: PackedVector2Array = PackedVector2Array()
var _radii: PackedFloat32Array = PackedFloat32Array()
## Reused for every grid query, so a step doesn't allocate hundreds of arrays.
var _nearby: Array[int] = []


func _init(shireen_radius: float, max_admirer_radius: float) -> void:
	_shireen_radius = shireen_radius
	_max_radius = max_admirer_radius
	# Two touching admirers are at most two max radii apart, so with cells
	# that size a query only ever looks one cell out.
	_grid = SpatialGrid.new(maxf(max_admirer_radius * 2.0, 1.0))


func add(admirer: Admirer) -> void:
	admirers.append(admirer)
	_radii.append(admirer.type.body_radius)


func size() -> int:
	return admirers.size()


## Moves every admirer by his behavior, then pushes the crowd apart.
func step(delta: float, shireen_position: Vector2) -> void:
	var count: int = admirers.size()
	_positions.resize(count)
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
		admirers[i].position = _positions[i]


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
