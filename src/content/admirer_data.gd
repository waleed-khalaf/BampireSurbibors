class_name AdmirerData
extends Resource
## One admirer type's tunable numbers (design §7). Each type is one .tres file
## in res://content/admirers/: open it in the Godot inspector to change it.
##
## To add a new type, copy a file in that folder and change its id. If it
## needs new logic, write a behavior class too (see AdmirerBehavior) and name
## its ID in [member behavior_id].

## Unique name the rest of the content refers to, e.g. the spawn data.
## Lower case with underscores, like "dowry_uncle".
@export var id: StringName = &""

## How much dazzle power it takes before he swoons (ticket 06).
@export var max_hp: float = 30.0

## How far he walks in one second, in pixels at the 640×360 base resolution.
@export var move_speed: float = 40.0

## Patience lost per second while he touches Shireen (ticket 05).
@export var drain_per_second: float = 10.0

## How much cash he drops when dazzled (ticket 07).
@export var cash: int = 2

## Radius of his body circle in pixels. Admirers keep their circles apart, so
## this sets how tightly a crowd packs. About half his sprite's width.
@export var body_radius: float = 7.0

## Which behavior class drives him, by ID. The content registry maps IDs to
## classes (ContentRegistry.ADMIRER_BEHAVIORS), and rejects unknown IDs.
@export var behavior_id: StringName = &"chase"
