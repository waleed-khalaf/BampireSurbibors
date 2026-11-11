class_name CardGenerator
extends RefCounted
## Makes the cards for one level-up (design §5):
##
## - At an ability level (5, 10 and 15, from the leveling data), up to three
##   distinct random abilities the weapon doesn't have yet.
## - Otherwise, or with no ability left to offer, up to three distinct random
##   buff cards from the weapon's unmaxed tracks.
## - Once every track is maxed, the Big tip and Sip of tea fallbacks.
##
## One belongs to one Run and draws from the Run's RNG, so a seed replays
## every offer.

## How many cards a level-up offers at most.
const CARDS_PER_OFFER: int = 3

var _weapon: WeaponBehavior
var _leveling: LevelingData
var _rng: RandomNumberGenerator


func _init(weapon: WeaponBehavior, leveling: LevelingData, rng: RandomNumberGenerator) -> void:
	_weapon = weapon
	_leveling = leveling
	_rng = rng


## The cards to offer on reaching [param level].
func offer(level: int) -> Array[Card]:
	var cards: Array[Card] = []
	if _leveling.is_ability_level(level):
		var abilities: Array[AbilityData] = _unowned_abilities()
		for i: int in _draw(abilities.size()):
			cards.append(_ability_card(abilities[i]))
	if cards.is_empty():
		var tracks: Array[BuffTrackData] = _unmaxed_tracks()
		for i: int in _draw(tracks.size()):
			cards.append(_buff_card(tracks[i]))
	if cards.is_empty():
		cards.append(_fallback(Card.Kind.BIG_TIP, Card.BIG_TIP_ID, "Big tip", "+%d cash" % _leveling.big_tip_cash))
		cards.append(_fallback(Card.Kind.SIP_OF_TEA, Card.SIP_OF_TEA_ID, "Sip of tea", "+%s Patience" % _format_number(_leveling.sip_of_tea_patience)))
	return cards


## The weapon's buff tracks that can still rank up, in data order.
func _unmaxed_tracks() -> Array[BuffTrackData]:
	var tracks: Array[BuffTrackData] = []
	for track: BuffTrackData in _weapon.data.buff_tracks:
		if _weapon.buff_rank(track.id) < track.max_rank:
			tracks.append(track)
	return tracks


## The abilities in the weapon's pool it hasn't gained, in data order.
func _unowned_abilities() -> Array[AbilityData]:
	var abilities: Array[AbilityData] = []
	for ability: AbilityData in _weapon.data.abilities:
		if not _weapon.has_ability(ability.id):
			abilities.append(ability)
	return abilities


## Up to [constant CARDS_PER_OFFER] distinct indices out of [param count],
## in random order: which of the choices to offer. (Fisher-Yates over the
## indices with the Run's RNG: Array.shuffle would use the global one, and
## the run would stop replaying from its seed.)
func _draw(count: int) -> PackedInt32Array:
	var indices := PackedInt32Array(range(count))
	for i: int in range(count - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var swapped: int = indices[i]
		indices[i] = indices[j]
		indices[j] = swapped
	return indices.slice(0, mini(count, CARDS_PER_OFFER))


## The card for [param track]'s next rank. It says what that rank changes,
## and only that: Count at rank 2 reads "+15% zill size", not "+1 zill" too.
func _buff_card(track: BuffTrackData) -> Card:
	var card := Card.new()
	card.kind = Card.Kind.BUFF
	card.id = track.id
	card.name = track.display_name
	card.rank = _weapon.buff_rank(track.id) + 1
	card.max_rank = track.max_rank
	var changes := PackedStringArray()
	for modifier: StatModifierData in track.modifiers:
		if modifier.times_at_rank(card.rank) > modifier.times_at_rank(card.rank - 1):
			changes.append(modifier.describe())
	card.description = ", ".join(changes)
	return card


## The card for gaining [param ability].
func _ability_card(ability: AbilityData) -> Card:
	var card := Card.new()
	card.kind = Card.Kind.ABILITY
	card.id = ability.id
	card.name = ability.display_name
	card.description = ability.description
	return card


## One of the two cards offered once every buff is maxed.
static func _fallback(kind: Card.Kind, id: StringName, name: String, description: String) -> Card:
	var card := Card.new()
	card.kind = kind
	card.id = id
	card.name = name
	card.description = description
	return card


## 30.0 -> "30", 7.5 -> "7.5": cards read like the design, not code.
static func _format_number(value: float) -> String:
	return str(int(value)) if value == floorf(value) else str(value)
