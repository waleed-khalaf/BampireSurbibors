class_name DefeatScreen
extends Control
## The "You said yes." screen, shown over the frozen run when Shireen's
## Patience runs out. It holds no rules: RunView hands it the Run's final
## snapshot, and it reports Enter back through [signal restart_requested].
##
## The wedding photo is a placeholder: Shireen's sprite next to the sprite of
## the admirer type that touched her last, in a gold frame. Ticket 25 replaces
## it with a drawn photo per type and gives the screen its final layout
## (defeat_screen.tscn; open it in the editor to move things around).

## Enter was pressed while the screen was up.
signal restart_requested

@onready var _photo_admirer: Sprite2D = %PhotoAdmirer
@onready var _caption: Label = %Caption
@onready var _stats: Label = %Stats


func _ready() -> void:
	# Hidden until the run ends. The scene file leaves it visible so it can
	# be seen and edited in the editor.
	visible = false


## Fills in the screen from the run's final [param snapshot] and shows it.
func show_defeat(snapshot: RunSnapshot) -> void:
	_stats.text = "Time survived: %s\nAdmirers dazzled: %d\nCash collected: %d" % [
		RunView.format_run_time(snapshot.time), snapshot.admirers_dazzled, snapshot.cash_collected,
	]
	# Who she said yes to. Empty only if Patience ran out with nobody on her,
	# which nothing in the game can do yet; then she's in the photo alone.
	var groom: StringName = snapshot.last_touching_type
	var sheet: Texture2D = AdmirerRenderer.load_sheet(groom) if groom != &"" else null
	_photo_admirer.texture = sheet
	_photo_admirer.hframes = AdmirerRenderer.WALK_FRAMES
	_photo_admirer.visible = sheet != null
	if groom == &"":
		_caption.text = "Shireen"
	else:
		# "dowry_uncle" -> "Dowry Uncle". Admirer types have no display name
		# of their own yet; the final end screens are ticket 25.
		_caption.text = "Shireen & the %s" % String(groom).capitalize()
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	# The "accept" action is Enter (Project Settings > Input Map). A key held
	# down doesn't count as a new press, so holding Enter can't skip the screen.
	if visible and event.is_action_pressed("accept"):
		get_viewport().set_input_as_handled()
		restart_requested.emit()
