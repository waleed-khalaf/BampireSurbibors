class_name PickupSnapshot
extends RefCounted
## A copy of one pickup's state, inside a RunSnapshot. Changing it never
## changes the Run.

## Unique within the run, in the order dropped. The same pickup keeps its id
## from one snapshot to the next, so the view can follow it as it flies.
var id: int = 0

## Cash or karkadeh tea. The view picks the sprite by it.
var kind: Pickup.Kind = Pickup.Kind.CASH

## Where it is, in world pixels, on the ground like an admirer's feet.
var position: Vector2 = Vector2.ZERO

## How much cash it is worth: the view picks the bill's size by it. 0 for tea.
var value: int = 0

## Lying on the sand, or (cash only) flying to Shireen.
var state: Pickup.State = Pickup.State.ON_GROUND


## Plain-data form, for comparing snapshots and for debug dumps.
func to_dict() -> Dictionary[String, Variant]:
	return {
		"id": id, "kind": Pickup.Kind.keys()[kind].to_lower(), "position": position,
		"value": value, "state": Pickup.State.keys()[state].to_lower(),
	}
