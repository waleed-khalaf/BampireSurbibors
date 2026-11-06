class_name ShireenData
extends Resource
## Shireen's tunable numbers. The real values live in
## res://content/shireen.tres: open it in the Godot inspector to change them.
## Later tickets add her Patience and pickup radius here.

## How far she walks in one second, in pixels at the 640×360 base resolution.
@export var move_speed: float = 90.0

## Radius of her body circle in pixels. Admirers press up against its edge
## instead of standing on top of her.
@export var body_radius: float = 6.0
