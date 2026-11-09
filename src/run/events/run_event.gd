class_name RunEvent
extends RefCounted
## Something that happened during one step of a Run. Run.step returns the
## step's events in the order they happened, so the view can react to a
## moment (show a screen, later play a sound) without comparing snapshots.
##
## Each kind of event is a small class extending this one, holding what the
## view needs to know about it. Tell them apart with `is`:
##     for event: RunEvent in run.step(Run.TIMESTEP, direction):
##         if event is RunEndedEvent:
##             ...


## Plain-data form, for comparing the events of two runs and for debug dumps.
func to_dict() -> Dictionary[String, Variant]:
	return {}
