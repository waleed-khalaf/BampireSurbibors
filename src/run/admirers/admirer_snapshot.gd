class_name AdmirerSnapshot
extends RefCounted
## A copy of one admirer's state, inside a RunSnapshot. Changing it never
## changes the Run.

## Unique within the run, in spawn order. The same admirer keeps his id from
## one snapshot to the next, so the view can follow him.
var id: int = 0

## His type's id, e.g. &"dowry_uncle". The view picks his sprite by it.
var type_id: StringName = &""

## Where his feet are, in world pixels.
var position: Vector2 = Vector2.ZERO

## The way he last walked, as a length-1 vector.
var facing: Vector2 = Vector2.RIGHT

## Whether he is touching Shireen, and so draining her Patience.
var touching: bool = false

## What is left of his HP. 0 once he's dazzled.
var hp: float = 0.0

## What he's doing: chasing Shireen, or, once dazzled, swooning and then
## leaving. The view picks his frame by it.
var state: Admirer.State = Admirer.State.CHASING

## Seconds since he entered his current state, counted once he's dazzled.
var state_time: float = 0.0


## Plain-data form, for comparing snapshots and for debug dumps.
func to_dict() -> Dictionary[String, Variant]:
	return {
		"id": id, "type": type_id, "position": position, "facing": facing, "touching": touching,
		"hp": hp, "state": Admirer.State.keys()[state].to_lower(), "state_time": state_time,
	}
