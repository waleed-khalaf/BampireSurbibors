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

## In a buff track: the ranks that grant this change. Empty means every rank.
## "+1 zill at ranks 1, 3 and 5" lists 1, 3 and 5. An ability has no ranks,
## so leave it empty there; the content registry rejects anything else.
@export var ranks: PackedInt32Array = PackedInt32Array()


## How many times a track at [param rank] has granted this change.
func times_at_rank(rank: int) -> int:
	if ranks.is_empty():
		return maxi(rank, 0)
	var times: int = 0
	for granting_rank: int in ranks:
		if granting_rank <= rank:
			times += 1
	return times
