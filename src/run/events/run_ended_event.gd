class_name RunEndedEvent
extends RunEvent
## The run is over. Emitted once, by the step that ended it; the Run ignores
## every step after that.

## How it ended. Only defeat ("You said yes.") exists so far.
var outcome: Run.Outcome = Run.Outcome.NONE

## On a defeat, the type id of the admirer who took the last of her Patience,
## e.g. &"dowry_uncle". The wedding photo shows her next to him.
var last_touching_type: StringName = &""


func _init(p_outcome: Run.Outcome, p_last_touching_type: StringName) -> void:
	outcome = p_outcome
	last_touching_type = p_last_touching_type


func to_dict() -> Dictionary[String, Variant]:
	return {
		"event": "run_ended",
		"outcome": Run.outcome_name(outcome),
		"last_touching_type": last_touching_type,
	}
