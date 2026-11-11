class_name WeaponBehavior
extends RefCounted
## Base class for weapon behaviors: the class that gives a weapon its logic
## (see the glossary). A weapon's data names its behavior by ID, and
## ContentRegistry.WEAPON_BEHAVIORS maps that ID to a class. A Run has
## exactly one weapon, so one instance belongs to one Run and keeps state.
##
## This class is the part every weapon shares:
##
## - Its stats (see Stats), started from the data's base_stats.
## - Its buff track ranks, each of which changes the stats.
## - The attack loop: the weapon charges up over cooldown / rate seconds,
##   then attacks as soon as it can.
## - The ability hooks (see AbilityBehavior): gained abilities are called
##   before every attack, on every Nth attack, before every hit and on their
##   own timers, and their stat modifiers are applied.
##
## To add a weapon: extend this class, override [method _attack] (and
## [method _can_attack], [method _advance], [method add_projectiles_to] and
## [method stat_ranges] as needed), land hits through [method hit] so the
## on-hit hooks run, and add its ID to ContentRegistry.WEAPON_BEHAVIORS.
##
## Never use randomness or time from outside the Run, or runs stop being
## reproducible.

## The charge that counts as a full cooldown. Adding 72 small steps doesn't
## land on exactly 1, so "just short of 1" has to count, or a 1.2 s cooldown
## would sometimes take 73 steps instead of 72.
const READY: float = 1.0 - 1e-9

var data: WeaponData
var stats: Stats

## Set at the start of every step, for the weapon and its abilities to read.
var crowd: AdmirerCrowd
var shireen_position: Vector2 = Vector2.ZERO
var shireen_facing: Vector2 = Vector2.RIGHT

## Track id -> rank, for every track in the data.
var _buff_ranks: Dictionary[StringName, int] = {}
var _abilities: Array[AbilityBehavior] = []
## Seconds since each ability's periodic hook last ran, by ability index.
var _period_elapsed: PackedFloat64Array = PackedFloat64Array()
## How far through the cooldown the weapon is: 0 right after an attack, 1
## when it is ready for the next.
var _charge: float = 0.0
var _attack_count: int = 0


func _init(p_data: WeaponData) -> void:
	data = p_data
	stats = Stats.new(p_data.base_stats)
	for track: BuffTrackData in p_data.buff_tracks:
		_buff_ranks[track.id] = 0


## The stats this weapon reads and the range each must be in, as
## name -> [lowest, highest]. The content registry checks a weapon's
## base_stats against it, and what the weapon's buff tracks and abilities can
## make of them. Subclasses add their own stats to the result.
## (A pair in an Array, not a Vector2: a Vector2 holds 32-bit numbers, which
## would turn 0.05 into 0.0500000007 in the error message.)
func stat_ranges() -> Dictionary[StringName, Array]:
	return {
		Stats.DAMAGE: [0.1, 10000.0],
		Stats.COOLDOWN: [0.05, 60.0],
		Stats.RATE: [0.1, 10.0],
		Stats.AREA: [1.0, 200.0],
	}


## Advances the weapon by one fixed step: moves what it has already thrown,
## then attacks if the cooldown is over, then runs the periodic hooks.
func step(delta: float, p_shireen_position: Vector2, p_shireen_facing: Vector2, p_crowd: AdmirerCrowd) -> void:
	shireen_position = p_shireen_position
	shireen_facing = p_shireen_facing
	crowd = p_crowd

	_advance(delta)

	# A weapon that is ready but can't attack yet (nobody to throw at) stops
	# charging. It attacks the moment it can, and the time it waited doesn't
	# shorten the cooldown after that.
	if _charge < READY:
		_charge += delta * stats.value(Stats.RATE) / stats.value(Stats.COOLDOWN)
	if _charge >= READY and _can_attack():
		# What is over a full charge counts toward the next attack. A
		# cooldown is rarely a whole number of steps, and dropping the rest
		# would round every wait up: "+12% throw rate" would give 10.8%.
		_charge -= 1.0
		_attack_count += 1
		var attack := WeaponAttack.new(_attack_count)
		for ability: AbilityBehavior in _abilities:
			ability.on_fire(self, attack)
		for ability: AbilityBehavior in _abilities:
			var nth: int = ability.every_nth()
			if nth > 0 and attack.number % nth == 0:
				ability.on_nth_attack(self, attack)
		_attack(attack)

	for i: int in _abilities.size():
		var period: float = _abilities[i].period()
		if period <= 0.0:
			continue
		_period_elapsed[i] += delta
		if _period_elapsed[i] >= period * READY:
			# What is over the period counts toward the next one, as with the
			# cooldown. (Never more than a whole period: the hook runs at
			# most once a step.)
			_period_elapsed[i] = minf(_period_elapsed[i] - period, period)
			_abilities[i].on_period(self)


## One buff track's current rank, 0 until a buff card ranks it up.
func buff_rank(track_id: StringName) -> int:
	assert(_buff_ranks.has(track_id), "Weapon %s has no buff track called \"%s\"" % [data.id, track_id])
	return _buff_ranks[track_id]


## Sets one buff track's rank and applies what that rank gives to the stats.
func set_buff_rank(track_id: StringName, rank: int) -> void:
	for track: BuffTrackData in data.buff_tracks:
		if track.id == track_id:
			assert(rank >= 0 and rank <= track.max_rank, "Weapon %s: rank %d is outside buff track \"%s\" (0 to %d)" % [data.id, rank, track_id, track.max_rank])
			_buff_ranks[track_id] = rank
			stats.set_modifiers("buff:%s" % track_id, track.modifiers, rank)
			return
	assert(false, "Weapon %s has no buff track called \"%s\"" % [data.id, track_id])


## Whether the weapon has gained the ability with [param ability_id].
func has_ability(ability_id: StringName) -> bool:
	for ability: AbilityBehavior in _abilities:
		if ability.data.id == ability_id:
			return true
	return false


## Adds an ability to the weapon: applies its stat modifiers and starts
## calling [param behavior]'s hooks. [param ability] must come from this
## weapon's data, and [param behavior] from the content registry.
func gain_ability(ability: AbilityData, behavior: AbilityBehavior) -> void:
	behavior.data = ability
	_abilities.append(behavior)
	_period_elapsed.append(0.0)
	stats.set_modifiers("ability:%s" % ability.id, ability.modifiers)


## Lands one hit on [param admirer], running the abilities' on-hit hooks
## first. Weapon behaviors deal all their damage through here.
## [param position] is where the hit happens.
func hit(admirer: Admirer, damage: float, position: Vector2) -> void:
	# No abilities is the common case early in a run: skip the hit record.
	if _abilities.is_empty():
		crowd.damage(admirer, damage)
		return
	var landed := WeaponHit.new(admirer, damage, position)
	for ability: AbilityBehavior in _abilities:
		ability.on_hit(self, landed)
	crowd.damage(admirer, landed.damage)


## A copy of the weapon's state for the Run's snapshot.
func snapshot() -> WeaponSnapshot:
	var snap := WeaponSnapshot.new()
	snap.id = data.id
	snap.attacks = _attack_count
	snap.stats = stats.values()
	snap.buffs = _buff_ranks.duplicate()
	for ability: AbilityBehavior in _abilities:
		snap.abilities.append(ability.data.id)
	return snap


## Appends a copy of everything the weapon has in flight to [param _out],
## for the Run's snapshot. The base class has nothing in flight.
func add_projectiles_to(_out: Array[ProjectileSnapshot]) -> void:
	pass


# --- For subclasses ---------------------------------------------------------

## Whether the weapon has anything to attack right now. Called once the
## cooldown is over; while it returns false the weapon waits, ready.
func _can_attack() -> bool:
	return true


## Makes one attack. [param _details] has been through the abilities' hooks:
## multiply the damage and area stats by its scales.
func _attack(_details: WeaponAttack) -> void:
	pass


## Moves whatever earlier attacks left in flight, once per step.
func _advance(_delta: float) -> void:
	pass
