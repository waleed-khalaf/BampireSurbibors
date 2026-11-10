class_name PickupData
extends Resource
## The ground pickups' tunable numbers (design §4 and §5): how cash flies to
## Shireen and how karkadeh tea drops. The real values live in
## res://content/pickups.tres: open it in the Godot inspector to change them.
## How close cash has to be before it flies is Shireen's own number
## ([member ShireenData.pickup_radius]), since her passives change it.

## How fast cash flies to Shireen once it is inside her pickup radius, in
## pixels per second. Well above her walking speed, so it always catches her.
@export var cash_fly_speed: float = 320.0

## The chance, from 0 to 1, that a dazzled admirer also drops karkadeh tea.
## 0.01 is the design's "about 1% per dazzle".
@export var tea_drop_chance: float = 0.01

## How much Patience a cup of karkadeh tea restores, never past her maximum.
@export var tea_patience: float = 30.0

## A cup's radius in pixels: Shireen picks it up when her body circle
## touches it. Tea never flies to her, so a cup can be left for later. About
## half its 16 px sprite.
@export var tea_radius: float = 5.0
