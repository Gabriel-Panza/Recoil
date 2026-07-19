extends CanvasLayer
class_name SettingsOverlay

signal closed

const PANEL_SIZE := Vector2(920.0, 570.0)
const ACTION_LABELS := {
	&"shoot": ["Shoot", "Atirar"],
	&"dash": ["Dash", "Dash"],
	&"active_e": ["Active Skill 1", "Habilidade Ativa 1"],
	&"active_r": ["Active Skill 2", "Habilidade Ativa 2"],
}

var root_control: Control
var panel: PanelContainer
var tabs: TabContainer
var resolution_select: OptionButton
var window_mode_select: OptionButton
var vsync_toggle: CheckButton
var quality_select: OptionButton
var binding_buttons: Dictionary = {}
var capture_action: StringName = &""
var capture_gamepad: bool = false
var capture_message: Label
var first_focus: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 240
	_build_ui()
	hide_overlay()
	I18n.language_changed.connect(_on_language_changed)

func _on_language_changed(_language: String) -> void:
	var was_open = is_open()
	remove_child(root_control)
	root_control.queue_free()
	root_control = null
	binding_buttons.clear()
	_build_ui()
	root_control.visible = was_open
	if was_open:
		_refresh_values()
		first_focus.grab_focus()

func open_overlay() -> void:
	_refresh_values()
	root_control.visible = true
	if first_focus != null:
		first_focus.grab_focus()

func hide_overlay() -> void:
	capture_action = &""
	if root_control != null:
		root_control.visible = false
	closed.emit()

func is_open() -> bool:
	return root_control != null and root_control.visible

func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if capture_action != &"":
		if _try_capture_binding(event):
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		hide_overlay()
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	root_control = Control.new()
	root_control.name = "SettingsOverlay"
	root_control.process_mode = Node.PROCESS_MODE_ALWAYS
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root_control)

	var backdrop = ColorRect.new()
	backdrop.color = Color(0.01, 0.005, 0.01, 0.88)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(backdrop)

	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = -PANEL_SIZE * 0.5
	panel.size = PANEL_SIZE
	panel.custom_minimum_size = PANEL_SIZE
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.075, 0.018, 0.03, 0.99), Color(0.92, 0.22, 0.08), 3))
	root_control.add_child(panel)

	var margin = MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 24)
	panel.add_child(margin)

	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var title = _make_label(_tr("SETTINGS", "CONFIGURACOES"), 32, Color(1.0, 0.64, 0.28))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_font_size_override("font_size", 19)
	layout.add_child(tabs)
	_build_video_tab()
	_build_controls_tab()

	capture_message = _make_label("", 16, Color(1.0, 0.76, 0.38))
	capture_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	capture_message.custom_minimum_size.y = 24.0
	layout.add_child(capture_message)

	var footer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 18)
	layout.add_child(footer)

	var reset_button = _make_button(_tr("Reset Controls", "Restaurar Controles"), Vector2(220, 44))
	reset_button.pressed.connect(_on_reset_controls)
	footer.add_child(reset_button)

	var close_button = _make_button(_tr("Back", "Voltar"), Vector2(180, 44))
	close_button.pressed.connect(hide_overlay)
	footer.add_child(close_button)

func _build_video_tab() -> void:
	var content = VBoxContainer.new()
	content.name = _tr("Video", "Video")
	content.add_theme_constant_override("separation", 14)
	tabs.add_child(content)

	if Global.is_web_build():
		var browser_hint = _make_label(_tr(
			"Canvas size and fullscreen are controlled by the browser or itch.io page.",
			"O tamanho da tela e o modo tela cheia sao controlados pelo navegador ou pela pagina do itch.io."
		), 16, Color(0.82, 0.78, 0.72))
		browser_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(browser_hint)
	else:
		window_mode_select = OptionButton.new()
		window_mode_select.add_item(_tr("Windowed", "Janela"), Global.WINDOW_MODE_WINDOWED)
		window_mode_select.add_item(_tr("Fullscreen", "Tela Cheia"), Global.WINDOW_MODE_FULLSCREEN)
		window_mode_select.add_item(_tr("Borderless", "Sem Bordas"), Global.WINDOW_MODE_BORDERLESS)
		window_mode_select.item_selected.connect(func(index): Global.set_window_mode(window_mode_select.get_item_id(index)))
		_add_setting_row(content, _tr("Display Mode", "Modo de Tela"), window_mode_select)
		first_focus = window_mode_select

		resolution_select = OptionButton.new()
		for resolution in Global.SUPPORTED_RESOLUTIONS:
			resolution_select.add_item("%d x %d" % [resolution.x, resolution.y])
		resolution_select.item_selected.connect(_on_resolution_selected)
		_add_setting_row(content, _tr("Resolution", "Resolucao"), resolution_select)

	quality_select = OptionButton.new()
	quality_select.add_item(_tr("Low", "Baixo"), Global.GRAPHICS_LOW)
	quality_select.add_item(_tr("Medium", "Medio"), Global.GRAPHICS_MEDIUM)
	quality_select.add_item(_tr("High", "Alto"), Global.GRAPHICS_HIGH)
	quality_select.item_selected.connect(func(index): Global.set_graphics_quality(quality_select.get_item_id(index)))
	_add_setting_row(content, _tr("Effects Quality", "Qualidade dos Efeitos"), quality_select)
	if first_focus == null:
		first_focus = quality_select

	if not Global.is_web_build():
		vsync_toggle = CheckButton.new()
		vsync_toggle.text = _tr("Enabled", "Ativado")
		vsync_toggle.toggled.connect(Global.set_vsync_enabled)
		_add_setting_row(content, "VSync", vsync_toggle)

	var deck_hint = _make_label(_tr(
		"Steam Deck: use 1280 x 800 or Fullscreen. UI scaling is automatic.",
		"Steam Deck: use 1280 x 800 ou Tela Cheia. A interface escala automaticamente."
	), 15, Color(0.82, 0.78, 0.72))
	deck_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(deck_hint)

func _build_controls_tab() -> void:
	var scroll = ScrollContainer.new()
	scroll.name = _tr("Controls", "Controles")
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	content.add_child(header)
	header.add_child(_make_sized_label(_tr("Action", "Acao"), 290))
	header.add_child(_make_sized_label(_tr("Keyboard / Mouse", "Teclado / Mouse"), 230))
	header.add_child(_make_sized_label(_tr("Controller", "Controle"), 230))

	for action in Global.REMAPPABLE_ACTIONS:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		content.add_child(row)
		row.add_child(_make_sized_label(_action_label(action), 290))
		var keyboard_button = _make_button("-", Vector2(230, 42))
		keyboard_button.pressed.connect(_begin_binding_capture.bind(action, false))
		row.add_child(keyboard_button)
		var gamepad_button = _make_button("-", Vector2(230, 42))
		gamepad_button.pressed.connect(_begin_binding_capture.bind(action, true))
		row.add_child(gamepad_button)
		binding_buttons["%s_keyboard" % action] = keyboard_button
		binding_buttons["%s_gamepad" % action] = gamepad_button

	var aim_hint = _make_label(_tr(
		"Controller aim: Right Stick. A/RT shoot, B dashes, Start pauses. In menus, A confirms and B returns.",
		"Mira no controle: Analogico Direito. A/RT atiram, B usa dash e Start pausa. Nos menus, A confirma e B volta."
	), 15, Color(0.82, 0.78, 0.72))
	aim_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(aim_hint)

func _add_setting_row(parent: VBoxContainer, label_text: String, control: Control) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	parent.add_child(row)
	row.add_child(_make_sized_label(label_text, 360))
	control.custom_minimum_size = Vector2(360, 42)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)

func _refresh_values() -> void:
	if window_mode_select != null:
		_select_option_id(window_mode_select, Global.window_mode)
	if quality_select != null:
		_select_option_id(quality_select, Global.graphics_quality)
	if vsync_toggle != null:
		vsync_toggle.button_pressed = Global.vsync_enabled
	if resolution_select != null:
		for i in range(Global.SUPPORTED_RESOLUTIONS.size()):
			if Global.SUPPORTED_RESOLUTIONS[i] == Global.window_resolution:
				resolution_select.select(i)
				break
	for action in Global.REMAPPABLE_ACTIONS:
		(binding_buttons["%s_keyboard" % action] as Button).text = Global.get_action_binding_text(action, false)
		(binding_buttons["%s_gamepad" % action] as Button).text = Global.get_action_binding_text(action, true)
	capture_message.text = ""

func _select_option_id(option: OptionButton, id: int) -> void:
	for index in range(option.item_count):
		if option.get_item_id(index) == id:
			option.select(index)
			return

func _on_resolution_selected(index: int) -> void:
	if index >= 0 and index < Global.SUPPORTED_RESOLUTIONS.size():
		Global.set_window_resolution(Global.SUPPORTED_RESOLUTIONS[index])

func _begin_binding_capture(action: StringName, gamepad: bool) -> void:
	capture_action = action
	capture_gamepad = gamepad
	capture_message.text = _tr(
		"Press a %s input. Esc cancels." % ("controller" if gamepad else "keyboard/mouse"),
		"Pressione uma entrada de %s. Esc cancela." % ("controle" if gamepad else "teclado/mouse")
	)

func _try_capture_binding(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		capture_action = &""
		capture_message.text = ""
		return true
	var valid = false
	if capture_gamepad:
		valid = event is InputEventJoypadButton and event.pressed
		if event is InputEventJoypadMotion:
			valid = abs(event.axis_value) >= 0.7
	else:
		valid = (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed)
	if not valid:
		return false
	Global.set_action_binding(capture_action, event, capture_gamepad)
	capture_action = &""
	_refresh_values()
	return true

func _on_reset_controls() -> void:
	Global.reset_control_bindings()
	_refresh_values()

func _action_label(action: StringName) -> String:
	var labels: Array = ACTION_LABELS.get(action, [str(action), str(action)])
	return str(labels[0] if I18n.current_language == I18n.LANG_EN else labels[1])

func _tr(en: String, pt: String) -> String:
	return en if I18n.current_language == I18n.LANG_EN else pt

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 3)
	return label

func _make_sized_label(text: String, width: float) -> Label:
	var label = _make_label(text, 18, Color(0.95, 0.88, 0.76))
	label.custom_minimum_size = Vector2(width, 42)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _make_button(text: String, minimum_size: Vector2) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = minimum_size
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.96, 0.9, 0.78))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.72, 0.32))
	button.add_theme_color_override("font_focus_color", Color(1.0, 0.72, 0.32))
	button.add_theme_stylebox_override("normal", _make_style(Color(0.13, 0.035, 0.05), Color(0.55, 0.14, 0.09), 2))
	button.add_theme_stylebox_override("hover", _make_style(Color(0.21, 0.055, 0.05), Color(1.0, 0.38, 0.12), 2))
	button.add_theme_stylebox_override("focus", _make_style(Color(0.21, 0.055, 0.05), Color(1.0, 0.7, 0.24), 3))
	return button

func _make_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(5)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style
