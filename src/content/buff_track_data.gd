class_name BuffTrackData
extends Resource
## One of a weapon's four buff tracks (design §6): a buff card adds a rank to
## it, and every rank changes the weapon's stats by the track's modifiers.
## Tracks live inside their weapon's .tres file in res://content/weapons/.

## Unique within the weapon, lower case with underscores, like "throw_rate".
@export var id: StringName = &""

## The name on the buff card, like "Throw rate".
@export var display_name: String = ""

## The highest rank the track can reach, from 1 to 5.
@export var max_rank: int = 5

## What each rank changes. Most tracks have one entry that every rank grants;
## a track like Count has two, each naming the ranks that grant it.
@export var modifiers: Array[StatModifierData] = []
