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


## Plain-data form, for comparing snapshots and for debug dumps.
func to_dict() -> Dictionary[String, Variant]:
	return {"id": id, "type": type_id, "position": position, "facing": facing, "touching": touching}
