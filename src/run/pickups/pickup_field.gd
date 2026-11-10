class_name PickupField
extends RefCounted
## Every pickup in a run, and the rules for how Shireen collects them.
##
## Cash lies where it dropped until Shireen comes within her pickup radius;
## then it flies straight at her and is collected the moment it reaches her
## (spec story 27). It keeps flying if she walks on: it is faster than her.
## Karkadeh tea stays on the ground until she walks over it, so the player can
## leave a cup for when it's needed.
##
## What a collected pickup does (cash, levels, Patience) is the Run's
## business: after each [method step] it reads [member collected].
##
## Pickup records are pooled: a collected pickup's record is kept and reused
## by the next drop, so a run that drops hundreds of bills never creates a
## record per bill.

## How close Shireen's body circle has to come to a cup of tea to pick it up:
## the cup's own radius, about half its 16 px sprite.
const TEA_RADIUS: float = 5.0

## The pickups on the field, oldest first.
var pickups: Array[Pickup] = []

## The pickups collected in the latest [method step], in field order. Read
## them right after the step; the next step reuses their records.
var collected: Array[Pickup] = []

## Records of collected pickups waiting to be dropped again.
var _spares: Array[Pickup] = []
var _last_id: int = 0


## Drops a pickup of [param kind] worth [param value] at [param position].
func drop(kind: Pickup.Kind, position: Vector2, value: int) -> Pickup:
	var pickup: Pickup = _spares.pop_back() if not _spares.is_empty() else Pickup.new()
	_last_id += 1
	pickup.id = _last_id
	pickup.kind = kind
	pickup.position = position
	pickup.value = value
	pickup.state = Pickup.State.ON_GROUND
	pickups.append(pickup)
	return pickup


## Starts cash inside [param pickup_radius] of Shireen flying, moves flying
## cash [param fly_speed] pixels a second toward her, and collects what
## reaches her and the tea her body circle (of [param shireen_radius])
## touches. Collected pickups end up in [member collected].
func step(delta: float, shireen_position: Vector2, shireen_radius: float, pickup_radius: float, fly_speed: float) -> void:
	# Last step's collected pickups have been dealt with by now: their
	# records go back into the pool.
	_spares.append_array(collected)
	collected.clear()

	var travel: float = fly_speed * delta
	var tea_reach: float = shireen_radius + TEA_RADIUS
	# The pickups still on the field are moved down over the collected ones.
	var kept: int = 0
	for pickup: Pickup in pickups:
		var to_shireen: Vector2 = shireen_position - pickup.position
		var distance_squared: float = to_shireen.length_squared()
		if pickup.kind == Pickup.Kind.CASH:
			if pickup.state == Pickup.State.ON_GROUND and distance_squared <= pickup_radius * pickup_radius:
				pickup.state = Pickup.State.FLYING
			if pickup.state == Pickup.State.FLYING:
				# Within one step's flight of her: it arrives this step.
				if distance_squared <= travel * travel:
					collected.append(pickup)
					continue
				pickup.position += to_shireen / sqrt(distance_squared) * travel
		elif distance_squared <= tea_reach * tea_reach:
			collected.append(pickup)
			continue
		pickups[kept] = pickup
		kept += 1
	pickups.resize(kept)
