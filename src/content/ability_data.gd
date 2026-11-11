class_name AbilityData
extends Resource
## One ability in a weapon's pool (design §6): a card offered at levels 5, 10
## and 15 that adds a new behavior to the weapon. Abilities live inside their
## weapon's .tres file. The Zills abilities arrive with ticket 12.

## Unique within the weapon, lower case with underscores, like "ricochet".
@export var id: StringName = &""

## The name on the ability card, like "Ricochet".
@export var display_name: String = ""

## What the card says the ability does, like "Zills bounce between up to 3
## admirers".
@export var description: String = ""

## Which behavior class gives it its logic, by ID. The content registry maps
## IDs to classes (ContentRegistry.ABILITY_BEHAVIORS) and rejects unknown
## IDs. See AbilityBehavior for the hooks an ability can use.
@export var behavior_id: StringName = &""

## The one ability in each weapon's pool that lets it carry a run alone.
@export var weakness_fix: bool = false

## Stat changes the weapon gets for as long as it has the ability. This is
## the "stat modifiers" hook: it needs no code.
@export var modifiers: Array[StatModifierData] = []
