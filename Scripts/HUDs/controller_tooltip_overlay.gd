extends CanvasLayer

const PIXEL_FONT = preload("res://Fonts/cg-pixel-4x5.otf")
const DISPLAY_TIME: float = 5.0

var root: Control
var panel: PanelContainer
var tooltip_label: Label
var hint_label: Label
var hide_timer: float = 0.0
var tooltip_index: int = -1
var last_scene: Node
var last_focused_control: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 245
	_build_ui()
	Global.input_device_changed.connect(_on_input_device_changed)
	I18n.language_changed.connect(_on_language_changed)

func _process(delta: float) -> void:
	if get_tree().current_scene != last_scene:
		last_scene = get_tree().current_scene
		tooltip_index = -1
		last_focused_control = null
		_hide_tooltip()
	if hide_timer > 0.0:
		hide_timer -= delta
		if hide_timer <= 0.0:
			_hide_tooltip()
	if Global.last_input_is_gamepad:
		var focused = get_viewport().gui_get_focus_owner()
		if focused != last_focused_control:
			last_focused_control = focused
			if focused != null and not focused.tooltip_text.strip_edges().is_empty():
				_show_tooltip(focused.tooltip_text)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inspect_tooltip"):
		_cycle_visible_tooltips()
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	panel = PanelContainer.new()
	panel.anchor_left = 0.18
	panel.anchor_top = 0.73
	panel.anchor_right = 0.82
	panel.anchor_bottom = 0.94
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.01, 0.018, 0.96)
	style.border_color = Color(0.1, 0.78, 0.92, 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(5)
	style.content_margin_left = 18.0
	style.content_margin_top = 14.0
	style.content_margin_right = 18.0
	style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	var layout = VBoxContainer.new()
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_theme_constant_override("separation", 8)
	panel.add_child(layout)

	tooltip_label = Label.new()
	tooltip_label.add_theme_font_override("font", PIXEL_FONT)
	tooltip_label.add_theme_font_size_override("font_size", 14)
	tooltip_label.add_theme_color_override("font_color", Color(0.96, 0.9, 0.78))
	tooltip_label.add_theme_color_override("font_outline_color", Color.BLACK)
	tooltip_label.add_theme_constant_override("outline_size", 3)
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tooltip_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(tooltip_label)

	hint_label = Label.new()
	hint_label.add_theme_font_override("font", PIXEL_FONT)
	hint_label.add_theme_font_size_override("font_size", 10)
	hint_label.add_theme_color_override("font_color", Color(0.08, 0.82, 1.0))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layout.add_child(hint_label)
	_hide_tooltip()

func _cycle_visible_tooltips() -> void:
	var controls = _get_visible_tooltip_controls()
	if controls.is_empty():
		_show_tooltip(I18n.t("tooltip.none"))
		return
	tooltip_index = wrapi(tooltip_index + 1, 0, controls.size())
	var control = controls[tooltip_index] as Control
	_show_tooltip(control.tooltip_text)
	if control.focus_mode != Control.FOCUS_NONE:
		control.grab_focus()

func _get_visible_tooltip_controls() -> Array[Control]:
	var controls: Array[Control] = []
	var scene = get_tree().current_scene
	if scene == null:
		return controls
	_collect_tooltip_controls(scene, controls)
	controls.sort_custom(func(a: Control, b: Control):
		var a_pos = a.get_global_rect().position
		var b_pos = b.get_global_rect().position
		return a_pos.y < b_pos.y if not is_equal_approx(a_pos.y, b_pos.y) else a_pos.x < b_pos.x
	)
	return controls

func _collect_tooltip_controls(node: Node, controls: Array[Control]) -> void:
	if node is Control:
		var control = node as Control
		if control.is_visible_in_tree() and not control.tooltip_text.strip_edges().is_empty() and not _ancestor_has_same_tooltip(control):
			controls.append(control)
	for child in node.get_children():
		_collect_tooltip_controls(child, controls)

func _ancestor_has_same_tooltip(control: Control) -> bool:
	var ancestor = control.get_parent()
	while ancestor is Control:
		if (ancestor as Control).tooltip_text == control.tooltip_text:
			return true
		ancestor = ancestor.get_parent()
	return false

func _show_tooltip(text: String) -> void:
	tooltip_label.text = text
	var gamepad = Global.last_input_is_gamepad
	var binding = Global.get_action_binding_text(&"inspect_tooltip", gamepad)
	hint_label.text = I18n.t("tooltip.controller_hint", [binding])
	panel.visible = true
	hide_timer = DISPLAY_TIME

func _hide_tooltip() -> void:
	if panel != null:
		panel.visible = false
	hide_timer = 0.0

func _on_input_device_changed(is_gamepad: bool) -> void:
	last_focused_control = null
	if not is_gamepad:
		_hide_tooltip()

func _on_language_changed(_language: String) -> void:
	if panel.visible:
		var binding = Global.get_action_binding_text(&"inspect_tooltip", Global.last_input_is_gamepad)
		hint_label.text = I18n.t("tooltip.controller_hint", [binding])
