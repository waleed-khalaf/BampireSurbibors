class_name ShireenData
extends Resource
## Shireen's tunable numbers. The real values live in
## res://content/shireen.tres: open it in the Godot inspector to change them.
## Later tickets add her pickup radius here.

## How much Patience she starts a run with, which is also the most she can
## have. Touching admirers drain it, and at 0 the run ends on "You said yes."
@export var max_patience: float = 100.0

## How far she walks in one second, in pixels at the 640×360 base resolution.
@export var move_speed: float = 90.0

## Radius of her body circle in pixels. Admirers press up against its edge
## instead of standing on top of her.
@export var body_radius: float = 6.0
