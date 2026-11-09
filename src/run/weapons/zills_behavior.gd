class_name ZillsBehavior
extends WeaponBehavior
## Zills (finger cymbals): thrown projectiles (design §6.1). Every cooldown,
## Shireen throws one zill at each of the nearest admirers within range. A
## zill flies in a straight line and hits the first admirer whose body it
## touches. With pierce it flies on through that many more admirers, hitting
## each once. It is gone after its last hit, or once it has flown its range.
##
## The zills in flight are plain data records kept here, not nodes
## (ADR-0001); the view draws them from the Run's snapshot.

## The Zills' own stats, on top of the ones every weapon has (see Stats).
## How many zills one throw sends out, one at each of the nearest admirers.
const COUNT: StringName = &"count"
## How many admirers a zill passes through after its first hit.
const PIERCE: StringName = &"pierce"
## How fast a zill flies, in pixels per second.
const SPEED: StringName = &"speed"
## How far a zill flies, in pixels. Admirers farther away aren't thrown at.
const RANGE: StringName = &"range"

## What the snapshot calls a zill. The view picks its sprite by it.
const KIND: StringName = &"zill"


## One zill in flight.
class Zill:
	var id: int = 0
	var position: Vector2 = Vector2.ZERO
	var velocity: Vector2 = Vector2.ZERO
	var radius: float = 0.0
	var damage: float = 0.0
	var distance_left: float = 0.0
	## How many more admirers it may pass through.
	var pierce_left: int = 0
	## The ids of the admirers it has hit, so it hits each only once.
	var hit_ids: PackedInt32Array = PackedInt32Array()


var _zills: Array[Zill] = []
## Zills that have landed, kept to be thrown again, so a long run doesn't
## create a new record for every throw.
var _spares: Array[Zill] = []
var _last_zill_id: int = 0
## Who the next throw goes to, nearest first. Filled by [method _can_attack].
var _targets: Array[Admirer] = []
## Working list: the admirers a zill is touching this step.
var _touched: Array[Admirer] = []


func stat_ranges() -> Dictionary[StringName, Array]:
	var ranges: Dictionary[StringName, Array] = super()
	ranges[COUNT] = [1.0, 20.0]
	ranges[PIERCE] = [0.0, 100.0]
	# A zill only checks for hits where it stands after each step. At 600
	# px/s that is every 10 px (15 with the speed buffs maxed), still less
	# than the width of an admirer; much faster and it could jump over one.
	ranges[SPEED] = [20.0, 600.0]
	ranges[RANGE] = [16.0, 2000.0]
	return ranges


func add_projectiles_to(out: Array[ProjectileSnapshot]) -> void:
	for zill: Zill in _zills:
		var copy := ProjectileSnapshot.new()
		copy.id = zill.id
		copy.kind = KIND
		copy.position = zill.position
		copy.velocity = zill.velocity
		copy.radius = zill.radius
		out.append(copy)


func _can_attack() -> bool:
	crowd.nearest(shireen_position, stats.value(RANGE), stats.whole(COUNT), _targets)
	return not _targets.is_empty()


func _attack(attack: WeaponAttack) -> void:
	var speed: float = stats.value(SPEED)
	for i: int in stats.whole(COUNT):
		# With fewer admirers in range than zills, the spare zills go round
		# the same admirers again, nearest first.
		var target: Admirer = _targets[i % _targets.size()]
		var to_target: Vector2 = target.position - shireen_position
		var direction: Vector2 = to_target.normalized() if not to_target.is_zero_approx() else shireen_facing
		var zill: Zill = _spares.pop_back() if not _spares.is_empty() else Zill.new()
		_last_zill_id += 1
		zill.id = _last_zill_id
		zill.position = shireen_position
		zill.velocity = direction * speed
		zill.radius = stats.value(Stats.AREA) * attack.area_scale
		zill.damage = stats.value(Stats.DAMAGE) * attack.damage_scale
		zill.distance_left = stats.value(RANGE)
		zill.pierce_left = stats.whole(PIERCE)
		zill.hit_ids.clear()
		_zills.append(zill)
	_targets.clear()


func _advance(delta: float) -> void:
	# Zills that are still flying are moved down over the ones that landed.
	var kept: int = 0
	for zill: Zill in _zills:
		zill.position += zill.velocity * delta
		zill.distance_left -= zill.velocity.length() * delta
		if _hit_touched_admirers(zill) and zill.distance_left > 0.0:
			_zills[kept] = zill
			kept += 1
		else:
			_spares.append(zill)
	_zills.resize(kept)


## Hits the admirers [param zill] is touching, nearest first, as far as its
## pierce allows. Returns false once it has landed its last hit.
func _hit_touched_admirers(zill: Zill) -> bool:
	# The crowd looks them up in its spatial grid.
	crowd.in_circle(zill.position, zill.radius, _touched)
	while not _touched.is_empty():
		var nearest: int = -1
		var nearest_distance: float = INF
		for i: int in _touched.size():
			var distance: float = _touched[i].position.distance_squared_to(zill.position)
			if distance < nearest_distance and not zill.hit_ids.has(_touched[i].id):
				nearest = i
				nearest_distance = distance
		if nearest == -1:
			break
		var admirer: Admirer = _touched[nearest]
		_touched.remove_at(nearest)
		hit(admirer, zill.damage, zill.position)
		if zill.pierce_left == 0:
			_touched.clear()
			return false
		zill.pierce_left -= 1
		zill.hit_ids.append(admirer.id)
	_touched.clear()
	return true
