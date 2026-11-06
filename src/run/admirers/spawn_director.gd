class_name SpawnDirector
extends RefCounted
## Decides when admirers arrive and where (demo spec, "Spawn director").
##
## They appear on a ring just outside the visible screen around Shireen, so
## they never pop in on top of her, and they arrive at a rate that climbs as
## the run goes on. Ticket 10 grows this into the full spawn timeline.
##
## All randomness comes from the Run's RNG, which is passed in, so a seed
## replays the same spawns.

var _data: SpawnRampData
var _rng: RandomNumberGenerator
## Half the screen size plus the margin: the ring is the edge of this box,
## centred on Shireen.
var _ring_half_size: Vector2
## Spawns that are due but haven't happened yet. The rate is fractional
## (1.5 per second is one every 40 steps), so whole admirers come out of this
## as it fills up.
var _due: float = 0.0


func _init(data: SpawnRampData, play_area: Vector2, rng: RandomNumberGenerator) -> void:
	_data = data
	_rng = rng
	_ring_half_size = play_area / 2.0 + Vector2(data.spawn_margin, data.spawn_margin)


## The admirer type this director spawns.
func admirer_id() -> StringName:
	return _data.admirer_id


## How many admirers per second arrive at [param time] seconds into the run.
func rate_at(time: float) -> float:
	return _data.spawns_per_second_at_start + _data.extra_spawns_per_second_each_minute * time / 60.0


## How many admirers to spawn this step, given the time and how many are
## already in the run.
func spawns_due(delta: float, time: float, admirer_count: int) -> int:
	var room: int = _data.max_admirers - admirer_count
	if room <= 0:
		# At the cap, don't save up spawns: when space frees up later, the
		# crowd should refill at the normal rate, not in one burst.
		_due = minf(_due, 1.0)
		return 0
	_due += rate_at(time) * delta
	var count: int = mini(floori(_due), room)
	_due -= count
	return count


## A random point on the spawn ring around [param shireen_position]: the edge
## of a box a little bigger than the screen. Every point of the edge is
## equally likely, so the long top and bottom edges get more spawns than the
## short sides, and the crowd comes from all around.
func spawn_position(shireen_position: Vector2) -> Vector2:
	var w: float = _ring_half_size.x * 2.0
	var h: float = _ring_half_size.y * 2.0
	var along: float = _rng.randf() * (w + h) * 2.0
	var corner: Vector2 = shireen_position - _ring_half_size
	if along < w:
		return corner + Vector2(along, 0.0)  # Top edge.
	along -= w
	if along < h:
		return corner + Vector2(w, along)  # Right edge.
	along -= h
	if along < w:
		return corner + Vector2(w - along, h)  # Bottom edge.
	along -= w
	return corner + Vector2(0.0, h - along)  # Left edge.
