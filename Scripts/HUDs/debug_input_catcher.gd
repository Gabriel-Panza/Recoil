class_name DebugInputCatcher
extends Node

signal toggle_debug_requested
signal skip_encounter_requested

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_F10:
			get_viewport().set_input_as_handled()
			toggle_debug_requested.emit()
		KEY_SEMICOLON:
			get_viewport().set_input_as_handled()
			skip_encounter_requested.emit()
