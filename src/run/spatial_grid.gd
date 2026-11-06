class_name SpatialGrid
extends RefCounted
## A uniform grid for "who is near this point?" questions, so the Run never
## compares every admirer with every other one. 300 admirers checked pairwise
## would be ~45,000 distance checks per step; with the grid each admirer only
## looks at the few others in the cells around it.
##
## The cells are always the same size, however far apart the points are. An
## earlier version let the cells grow with the crowd's bounding box, and that
## made a cliff: once Shireen had walked away for minutes, the stragglers far
## behind blew the cells up to 100+ px, and a query around one packed admirer
## returned a large part of the crowd instead of his few neighbors (see the
## strung-out crowd test in tests/run/dowry_uncle_test.gd).
##
## The world is endless, so instead of growing, the grid wraps around like
## the screen in Pac-Man: cell coordinates are taken modulo
## [constant CELLS_PER_SIDE] on each axis, so a point 32 cells (about 450 px
## with the Uncles' cells) to the right lands in the same cell as one here.
## The grid stays the same size whatever the crowd does. Points closer than
## 32 cells never share a cell by accident, so a query one cell wide never
## sees the same cell twice, and a crowd strung out far behind Shireen is
## smeared evenly over the grid: it adds a few wrong candidates to each query,
## which the caller's exact distance check throws out, never a cliff.
##
## It's rebuilt from scratch every step: [method rebuild] sorts the points
## into cells (a counting sort into flat arrays, which is much faster in
## GDScript than a dictionary of lists), then [method query] lists the points
## near a position. Cells in one row sit next to each other in [member _items],
## so one row of a query is one continuous run, except where it wraps.
##
## It stores indices into the caller's array, not objects, so the same grid
## works for admirer separation now and for hit queries later.

## The wrapped grid is 32 × 32 cells. A power of two, so the modulo is a
## bitwise AND, which also does the right thing for negative coordinates
## (unlike %). Fewer cells would make a crowd of 300 touching Uncles wrap onto
## itself; more would make the running-total loop in [method rebuild] slower.
const CELLS_PER_SIDE_BITS: int = 5
const CELLS_PER_SIDE: int = 1 << CELLS_PER_SIDE_BITS
const CELL_MASK: int = CELLS_PER_SIDE - 1
const CELL_COUNT: int = CELLS_PER_SIDE * CELLS_PER_SIDE

var _cell_size: float
## Point indices sorted by cell. The points in cell c are
## _items[_cell_starts[c]] up to (not including) _items[_cell_starts[c + 1]].
var _items: PackedInt32Array = PackedInt32Array()
var _cell_starts: PackedInt32Array = PackedInt32Array()
## Each point's cell, kept between the two passes of the counting sort.
var _cell_of_item: PackedInt32Array = PackedInt32Array()


## [param cell_size] should be at least the largest query radius, so a query
## never has to look further than one cell in each direction.
func _init(cell_size: float) -> void:
	assert(cell_size > 0.0, "SpatialGrid: cell_size must be positive")
	_cell_size = cell_size
	_cell_starts.resize(CELL_COUNT + 1)


## Sorts [param points] into cells. Call it again whenever they move.
func rebuild(points: PackedVector2Array) -> void:
	var count: int = points.size()
	_items.resize(count)
	_cell_of_item.resize(count)
	_cell_starts.fill(0)

	# Count the points in each cell...
	for i: int in count:
		var point: Vector2 = points[i]
		var cell: int = ((floori(point.y / _cell_size) & CELL_MASK) << CELLS_PER_SIDE_BITS) \
				| (floori(point.x / _cell_size) & CELL_MASK)
		_cell_of_item[i] = cell
		_cell_starts[cell] += 1
	# ...turn the counts into running totals, so each entry is where its cell
	# ends and the last entry is the total...
	for cell: int in range(1, CELL_COUNT + 1):
		_cell_starts[cell] += _cell_starts[cell - 1]
	# ...then fill each cell from its end backwards. Afterwards each entry has
	# moved down to where its cell starts, and the next entry is where it
	# ends. Filling backwards saves copying the whole array to track the next
	# free slot per cell, which this used to do every step.
	for i: int in count:
		var cell: int = _cell_of_item[i]
		_cell_starts[cell] -= 1
		_items[_cell_starts[cell]] = i


## Fills [param out] with the indices of the points in every cell the circle
## at [param position] with [param radius] touches. That's a superset: callers
## still check the exact distance. Reusing one [param out] array for many
## queries saves allocating a new one each time.
func query(position: Vector2, radius: float, out: Array[int]) -> void:
	out.clear()
	var first_column: int = floori((position.x - radius) / _cell_size)
	var first_row: int = floori((position.y - radius) / _cell_size)
	# A circle wider than the whole wrapped grid would come round to the same
	# cells again, so stop after one lap.
	var last_column: int = mini(floori((position.x + radius) / _cell_size), first_column + CELL_MASK)
	var last_row: int = mini(floori((position.y + radius) / _cell_size), first_row + CELL_MASK)
	var first_wrapped_column: int = first_column & CELL_MASK
	var last_wrapped_column: int = last_column & CELL_MASK
	for row: int in range(first_row, last_row + 1):
		var row_start: int = (row & CELL_MASK) << CELLS_PER_SIDE_BITS
		if first_wrapped_column <= last_wrapped_column:
			for k: int in range(_cell_starts[row_start + first_wrapped_column], _cell_starts[row_start + last_wrapped_column + 1]):
				out.append(_items[k])
		else:
			# The columns wrap past the right edge: the run is first..31, then
			# 0..last.
			for k: int in range(_cell_starts[row_start + first_wrapped_column], _cell_starts[row_start + CELLS_PER_SIDE]):
				out.append(_items[k])
			for k: int in range(_cell_starts[row_start], _cell_starts[row_start + last_wrapped_column + 1]):
				out.append(_items[k])
