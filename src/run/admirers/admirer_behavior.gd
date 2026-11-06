class_name AdmirerBehavior
extends RefCounted
## Base class for admirer behaviors: the small class that gives an admirer
## type its logic (see the glossary). Each type's data names its behavior by
## ID, and ContentRegistry.ADMIRER_BEHAVIORS maps that ID to a class.
##
## The Run asks the behavior where an admirer wants to go, then moves him and
## keeps the crowd apart itself. So a behavior only has to describe intent,
## and every behavior gets crowd separation for free.
##
## To add one: extend this class, override [method desired_velocity], and add
## its ID to ContentRegistry.ADMIRER_BEHAVIORS.
##
## One instance is shared by every admirer of a type, so keep per-admirer
## state on the Admirer record, not here. Never use randomness or time from
## outside the Run, or runs stop being reproducible.


## Returns the velocity (pixels per second) [param admirer] wants this step,
## given where Shireen is. The base class stands still.
func desired_velocity(_admirer: Admirer, _shireen_position: Vector2) -> Vector2:
	return Vector2.ZERO
