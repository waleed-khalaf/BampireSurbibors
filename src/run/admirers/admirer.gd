class_name Admirer
extends RefCounted
## One admirer inside the Run: a plain data record, not a scene-tree node
## (ADR-0001). The Run moves hundreds of these every step and the view draws
## them in one batch, which is far cheaper than a node per admirer.
##
## Only the Run touches these. The view and tests see copies
## (AdmirerSnapshot) through the Run's snapshot.

## Unique within one run, counting up from 1 in spawn order. The view uses it
## to follow the same admirer from one snapshot to the next.
var id: int = 0

## His type's data: speed, HP, drain and so on. Shared by every admirer of
## the type, so never change it from here.
var type: AdmirerData

## The behavior class picked by his type's behavior_id. It decides where he
## wants to go each step. Shared by every admirer of the type.
var behavior: AdmirerBehavior

## Where his feet are, in world pixels.
var position: Vector2 = Vector2.ZERO

## The way he last walked, as a length-1 vector. The view mirrors his sprite
## by it. Being shoved by the crowd doesn't change it, so he doesn't flicker
## left and right in a crush.
var facing: Vector2 = Vector2.RIGHT

## What is left of his resistance to Shireen's dance. Starts at the type's
## max_hp; weapons lower it from ticket 06.
var hp: float = 0.0

## Whether his body is against Shireen's after the latest step. The crowd
## works it out (AdmirerCrowd.step) and the Run drains her Patience by it.
var touching: bool = false


func _init(p_id: int, p_type: AdmirerData, p_behavior: AdmirerBehavior, p_position: Vector2) -> void:
	id = p_id
	type = p_type
	behavior = p_behavior
	position = p_position
	hp = p_type.max_hp
