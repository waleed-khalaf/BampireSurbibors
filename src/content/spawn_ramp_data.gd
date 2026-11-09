class_name SpawnRampData
extends Resource
## How fast admirers arrive. The real values live in
## res://content/spawn_ramp.tres: open it in the Godot inspector to change them.
##
## For now one admirer type arrives at a rate that climbs steadily. Ticket 10
## replaces this with the full spawn timeline (several types, swarms, start
## times).

## The admirer type that spawns, by its [member AdmirerData.id].
@export var admirer_id: StringName = &"dowry_uncle"

## Admirers per second at 0:00.
@export var spawns_per_second_at_start: float = 1.0

## How much the rate grows each minute. With 1.0 and a start of 1.0, it is
## 2 per second at 1:00, 3 at 2:00 and so on.
@export var extra_spawns_per_second_each_minute: float = 1.0

## The director stops spawning while this many admirers are chasing Shireen,
## so the crowd never grows past what the game can draw smoothly (design
## §13). Dazzled admirers on their way out don't count: each one makes room
## for a new arrival at once.
@export var max_admirers: int = 300

## How far outside the screen edge admirers appear, in pixels. At least a
## sprite's height, so an admirer standing just below the bottom edge doesn't
## poke his head into view.
@export var spawn_margin: float = 32.0
