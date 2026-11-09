class_name Stats
extends RefCounted
## The shared stat model: a set of named numbers, each a base value changed
## by modifiers. A weapon's stats start from its data file; buffs, abilities
## and (from ticket 21) passives all change them through here, so a passive
## like Kohl Eyeliner works with any weapon.
##
## A stat's value is (base + everything added) × (1 + every share). Shares
## are summed, not compounded: two "+20%" modifiers make +40%, not +44%. So
## a Damage track at rank 5 doubles the damage, as "+20% per rank" reads.
##
## Modifiers come in named sources (one buff track, one ability). Setting a
## source again replaces what it gave before, which is how a track ranks up.
##
## Usage:
##     var stats := Stats.new({Stats.DAMAGE: 10.0})
##     stats.set_modifiers(&"buff:damage", track.modifiers, 2)
##     stats.value(Stats.DAMAGE)  # 14.0 with +20% per rank

## Stats every weapon has (see WeaponData.base_stats). Weapon behaviors add
## their own names, e.g. ZillsBehavior.PIERCE.
const DAMAGE: StringName = &"damage"
## Seconds between attacks.
const COOLDOWN: StringName = &"cooldown"
## Attack-speed multiplier, 1 in every weapon's data: the weapon attacks
## every cooldown / rate seconds. "+12% throw rate" adds a 0.12 share here,
## which the cooldown itself couldn't express.
const RATE: StringName = &"rate"
## The weapon's reach in pixels: the radius of a zill, of a shimmy ring...
const AREA: StringName = &"area"

## What one source gives: its modifiers, and how many ranks of them.
class Source:
	var modifiers: Array[StatModifierData]
	var rank: int

	func _init(p_modifiers: Array[StatModifierData], p_rank: int) -> void:
		modifiers = p_modifiers
		rank = p_rank


var _base: Dictionary[StringName, float]
var _sources: Dictionary[StringName, Source] = {}
## Per stat, the totals over all sources. Rebuilt whenever a source changes,
## so reading a value is two lookups.
var _added: Dictionary[StringName, float] = {}
var _shares: Dictionary[StringName, float] = {}


func _init(base: Dictionary[StringName, float]) -> void:
	_base = base.duplicate()


## The stat's current value, with every modifier applied.
func value(stat: StringName) -> float:
	assert(_base.has(stat), "Stats: there is no stat called \"%s\"" % stat)
	# A total share below -100% would flip the sign: stop at zero instead.
	return (_base[stat] + _added.get(stat, 0.0)) * maxf(1.0 + _shares.get(stat, 0.0), 0.0)


## The value as a whole number, rounded down, for stats that count things
## (zills per throw, pierce). The tiny nudge keeps 2.9999999 from being 2.
func whole(stat: StringName) -> int:
	return floori(value(stat) + 0.0001)


## Sets what one source gives, replacing whatever it gave before.
## [param rank] is how many ranks of [param modifiers] it has: a buff track's
## current rank, 1 for an ability. Rank 0 gives nothing.
func set_modifiers(source: StringName, modifiers: Array[StatModifierData], rank: int = 1) -> void:
	_sources[source] = Source.new(modifiers, rank)
	_added.clear()
	_shares.clear()
	for granted: Source in _sources.values():
		for modifier: StatModifierData in granted.modifiers:
			var amount: float = modifier.value * modifier.times_at_rank(granted.rank)
			var totals: Dictionary[StringName, float] = _added if modifier.kind == StatModifierData.Kind.ADD else _shares
			totals[modifier.stat] = totals.get(modifier.stat, 0.0) + amount


## Every stat's current value, for the snapshot and the debug dump.
func values() -> Dictionary[StringName, float]:
	var result: Dictionary[StringName, float] = {}
	for stat: StringName in _base:
		result[stat] = value(stat)
	return result
