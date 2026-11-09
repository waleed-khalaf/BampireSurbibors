class_name WeaponData
extends Resource
## One weapon's tunable numbers (design §6). Each weapon is one .tres file in
## res://content/weapons/: open it in the Godot inspector to change it.
##
## To add a weapon, write its behavior class (see WeaponBehavior), add the
## class to ContentRegistry.WEAPON_BEHAVIORS, and make a data file here that
## names it in [member behavior_id].

## Unique name the run configuration picks the weapon by, like "zills".
@export var id: StringName = &""

## The name shown to the player, like "Zills".
@export var display_name: String = ""

## Which behavior class drives the weapon, by ID. The content registry maps
## IDs to classes (ContentRegistry.WEAPON_BEHAVIORS) and rejects unknown IDs.
@export var behavior_id: StringName = &""

## The weapon's stats before any buff, ability or passive, by stat name.
## Every weapon has "damage", "cooldown" (seconds between attacks), "rate"
## (an attack-speed multiplier, normally 1) and "area" (its reach in pixels).
## Each behavior adds its own, such as "pierce" for Zills, and lists the
## names and sensible ranges it expects in its stat_ranges(). The content
## registry rejects a weapon with a stat missing or out of range.
@export var base_stats: Dictionary[StringName, float] = {}

## The four tracks the weapon's buff cards rank up.
@export var buff_tracks: Array[BuffTrackData] = []

## The pool the ability cards draw from.
@export var abilities: Array[AbilityData] = []
