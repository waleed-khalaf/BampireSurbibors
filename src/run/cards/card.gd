class_name Card
extends RefCounted
## One card on the level-up screen (design §5): a buff for one of the
## weapon's tracks, an ability at levels 5, 10 and 15, or one of the two
## fallbacks once every buff is maxed. A plain data record made by
## CardGenerator; the Run offers up to three at a time and the player picks
## one by index with Run.choose_card.
##
## The snapshot hands out copies (see [method copy]), so changing one never
## changes the Run.

enum Kind {
	## Adds a rank to one of the weapon's buff tracks. [member id] is the
	## track's id and [member rank] the rank it gives.
	BUFF,
	## Gives the weapon a new ability. [member id] is the ability's id.
	ABILITY,
	## Bonus cash, offered once every buff is maxed.
	BIG_TIP,
	## Restores some Patience, offered once every buff is maxed.
	SIP_OF_TEA,
}

## The ids of the two fallback cards.
const BIG_TIP_ID: StringName = &"big_tip"
const SIP_OF_TEA_ID: StringName = &"sip_of_tea"

## What sort of card it is, which says how to read [member id] and
## [member rank].
var kind: Kind = Kind.BUFF

## What the card gives: a buff track's id, an ability's id, or one of the
## fallback ids above, by [member kind].
var id: StringName = &""

## The name on the card, like "Throw rate" or "Big tip".
var name: String = ""

## For a buff, the rank the card gives (1 up to [member max_rank]). 0 for
## the other kinds.
var rank: int = 0

## For a buff, the track's highest rank, so the card can read "rank 2 of 5".
## 0 for the other kinds.
var max_rank: int = 0

## What changes, in the player's words: "+1 zill", "+30 Patience".
var description: String = ""


## A copy for the snapshot, so the view and tests can't change the Run's card.
func copy() -> Card:
	var card := Card.new()
	card.kind = kind
	card.id = id
	card.name = name
	card.rank = rank
	card.max_rank = max_rank
	card.description = description
	return card


## "buff", "ability", "big_tip" or "sip_of_tea", for debug dumps.
static func kind_name(kind: Kind) -> String:
	var key: String = Kind.find_key(kind)
	return key.to_lower()


## Plain-data form, for comparing snapshots and for debug dumps.
func to_dict() -> Dictionary[String, Variant]:
	return {"kind": kind_name(kind), "id": id, "name": name, "rank": rank, "max_rank": max_rank, "description": description}
