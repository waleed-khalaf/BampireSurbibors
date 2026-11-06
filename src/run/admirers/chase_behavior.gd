class_name ChaseBehavior
extends AdmirerBehavior
## Walks straight at Shireen at the type's speed: the Dowry Uncle's behavior
## (design §7, "walks straight at you").


func desired_velocity(admirer: Admirer, shireen_position: Vector2) -> Vector2:
	var to_shireen: Vector2 = shireen_position - admirer.position
	# Already on top of her: stay put rather than dividing by zero. The crowd
	# separation pushes him back out to the edge of her body anyway.
	if to_shireen.is_zero_approx():
		return Vector2.ZERO
	return to_shireen.normalized() * admirer.type.move_speed
