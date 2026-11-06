class_name SpatialGrid
extends RefCounted
## A uniform grid for "who is near this point?" questions, so the Run never
## compares every admirer with every other one. 300 admirers checked pairwise
## would be ~45,000 distance checks per step; with the grid each admirer only
## looks at the few others in the cells around it.
##
## The world is endless, so the grid only covers the box around the points it
## was last built from. It's rebuilt from scratch every step: [method rebuild]
## sorts the points into cells (a counting sort into flat arrays, which is much
## faster in GDScript than a dictionary of lists), then [method query] lists
## the points near a position.
##
## It stores indices into the caller's array, not objects, so the same grid
## works for admirer separation now and for hit queries later.

## Upper limit on cells along each side. If the points are spread far apart
## (Shireen sprinting away from a trailing crowd), cells grow instead of the
## grid growing without limit. Bigger cells are still correct, just slower.
const MAX_CELLS_PER_SIDE: int = 64

var _min_cell_size: float
var _cell_size: float = 1.0
var _origin: Vector2 = Vector2.ZERO
var _columns: int = 0
var _rows: int = 0
## Point indices sorted by cell. The points in cell c are
## _items[_cell_starts[c]] up to (not including) _items[_cell_starts[c + 1]].
var _items: PackedInt32Array = PackedInt32Array()
var _cell_starts: PackedInt32Array = PackedInt32Array()
## Each point's cell, kept between the two passes of the counting sort.
var _cell_of_item: PackedInt32Array = PackedInt32Array()


## [param min_cell_size] should be at least the largest query radius, so a
## query never has to look further than one cell in each direction.
func _init(min_cell_size: float) -> void:
	assert(min_cell_size > 0.0, "SpatialGrid: min_cell_size must be positive")
	_min_cell_size = min_cell_size


## Sorts [param points] into cells. Call it again whenever they move.
func rebuild(points: PackedVector2Array) -> void:
	var count: int = points.size()
	_items.resize(count)
	_cell_of_item.resize(count)
	if count == 0:
		_columns = 0
		_rows = 0
		return

	var low: Vector2 = points[0]
	var high: Vector2 = points[0]
	for point: Vector2 in points:
		low = low.min(point)
		high = high.max(point)
	var extent: Vector2 = high - low
	_cell_size = maxf(_min_cell_size, maxf(extent.x, extent.y) / (MAX_CELLS_PER_SIDE - 1))
	_origin = low
	_columns = floori(extent.x / _cell_size) + 1
	_rows = floori(extent.y / _cell_size) + 1

	# Count the points in each cell, turn the counts into start offsets, then
	# drop every point into its slot.
	_cell_starts.resize(_columns * _rows + 1)
	_cell_starts.fill(0)
	for i: int in count:
		var offset: Vector2 = points[i] - _origin
		var cell: int = floori(offset.y / _cell_size) * _columns + floori(offset.x / _cell_size)
		_cell_of_item[i] = cell
		_cell_starts[cell + 1] += 1
	for cell: int in _columns * _rows:
		_cell_starts[cell + 1] += _cell_starts[cell]
	var next_slot: PackedInt32Array = _cell_starts.duplicate()
	for i: int in count:
		var cell: int = _cell_of_item[i]
		_items[next_slot[cell]] = i
		next_slot[cell] += 1


## Fills [param out] with the indices of the points in every cell the circle
## at [param position] with [param radius] touches. That's a superset: callers
## still check the exact distance. Reusing one [param out] array for many
## queries saves allocating a new one each time.
func query(position: Vector2, radius: float, out: Array[int]) -> void:
	out.clear()
	if _columns == 0:
		return
	var first_x: int = maxi(floori((position.x - radius - _origin.x) / _cell_size), 0)
	var last_x: int = mini(floori((position.x + radius - _origin.x) / _cell_size), _columns - 1)
	var first_y: int = maxi(floori((position.y - radius - _origin.y) / _cell_size), 0)
	var last_y: int = mini(floori((position.y + radius - _origin.y) / _cell_size), _rows - 1)
	if first_x > last_x or first_y > last_y:
		return
	for cy: int in range(first_y, last_y + 1):
		# Cells in one row sit next to each other in _items, so one row of
		# the query is one continuous run.
		var row: int = cy * _columns
		for k: int in range(_cell_starts[row + first_x], _cell_starts[row + last_x + 1]):
			out.append(_items[k])
