class_name StatModifierData
extends Resource
## One change to one of a weapon's stats: "+20% damage" or "+1 pierce". Buff
## tracks and abilities are lists of these (see BuffTrackData, AbilityData),
## and the Stats class adds them up.

enum Kind {
	## A plain amount added to the base value: 1 is "+1 pierce".
	ADD,
	## A share of the stat: 0.2 is "+20%", -0.08 is "-8%". Shares from all
	## sources are summed before they multiply, so +20% and +15% make +35%.
	MULTIPLY,
}

## The stat to change, e.g. "damage". It must be one of the weapon's
## base_stats; the content registry rejects any other name.
@export var stat: StringName = &""

@export var kind: Kind = Kind.ADD

## How much, per rank that grants it.
@export var value: float = 0.0

## What the level-up card says this change does, in the player's words:
## "+1 zill", "+15% zill size". Left empty, the card falls back to the
## numbers and the stat's name, like "+15% area" (see [method describe]).
@export var description: String = ""

## In a buff track: the ranks that grant this change. Empty means every rank.
## "+1 zill at ranks 1, 3 and 5" lists 1, 3 and 5. An ability has no ranks,
## so leave it empty there; the content registry rejects anything else.
@export var ranks: PackedInt32Array = PackedInt32Array()


## The words for this change on a card: [member description], or, when
## that is empty, the numbers: "+20% damage" for a share, "+1 pierce" for a
## plain amount. Stat names are lower case with underscores, so "throw_rate"
## would read "throw rate".
func describe() -> String:
	if description != "":
		return description
	var stat_words: String = String(stat).replace("_", " ")
	if kind == Kind.MULTIPLY:
		return "%+d%% %s" % [roundi(value * 100.0), stat_words]
	if value == floorf(value):
		return "%+d %s" % [int(value), stat_words]
	return "%+.2f %s" % [value, stat_words]


## How many times a track at [param rank] has granted this change.
func times_at_rank(rank: int) -> int:
	if ranks.is_empty():
		return maxi(rank, 0)
	var times: int = 0
	for granting_rank: int in ranks:
		if granting_rank <= rank:
			times += 1
	return times
