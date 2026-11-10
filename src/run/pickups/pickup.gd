class_name Pickup
extends RefCounted
## One pickup inside the Run, cash or karkadeh tea: a plain data record, not
## a scene-tree node (ADR-0001). A long run drops hundreds of these, so they
## are pooled by PickupField and reused once collected.
##
## Only the Run touches these. The view and tests see copies
## (PickupSnapshot) through the Run's snapshot.

enum Kind {
	## A bill dropped by a dazzled admirer. Fills the level bar.
	CASH,
	## A cup of karkadeh tea. Restores Patience.
	TEA,
}

enum State {
	## Lying on the sand where it dropped.
	ON_GROUND,
	## Cash on its way to Shireen: it came inside her pickup radius.
	FLYING,
}

## Unique within one run, counting up from 1 in the order dropped. The view
## uses it to follow the same pickup from one snapshot to the next.
var id: int = 0

## Cash or karkadeh tea.
var kind: Kind = Kind.CASH

## Where it is, in world pixels, on the ground like an admirer's feet.
var position: Vector2 = Vector2.ZERO

## How much cash it is worth. 0 for tea.
var value: int = 0

## Lying on the sand, or (cash only) flying to Shireen.
var state: State = State.ON_GROUND
