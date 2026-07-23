extends Control

const SETTINGS_OVERLAY_SCRIPT = preload("res://Scripts/HUDs/settings_overlay.gd")

const GAME_SCENE_PATH: NodePath = "/root/GameScene"
const PLAYER_PATH: NodePath = "/root/GameScene/Player"
const PAUSE_MENU_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/PauseControl/PauseMenu"
const OPTIONS_MENU_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/PauseControl/PauseMenu/OptionsMenu"
const HEALTH_LABEL_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/HBoxContainer/BarraLateralDireita/MarginContainer/VBoxContainer/HP_MaxHealth"
const ATTACK_LABEL_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/HBoxContainer/BarraLateralDireita/MarginContainer/VBoxContainer/Ataque"
const ATK_SPEED_LABEL_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/HBoxContainer/BarraLateralDireita/MarginContainer/VBoxContainer/Atk_Speed"
const RECOIL_LABEL_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/HBoxContainer/BarraLateralDireita/MarginContainer/VBoxContainer/Recoil"
const GAME_OVER_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/PauseControl/GameOver"
const GAME_WIN_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/PauseControl/GameWin"
const GAME_OVER_TEXTURE_EN: Texture2D = preload("res://Sprites/Menu/UI_morte_en.png")
const GAME_OVER_TEXTURE_PT: Texture2D = preload("res://Sprites/Menu/UI_morte_pt.png")
const GAME_WIN_TEXTURE_EN: Texture2D = preload("res://Sprites/Menu/UI_vitoria_en.png")
const GAME_WIN_TEXTURE_PT: Texture2D = preload("res://Sprites/Menu/UI_vitoria_pt.png")
const OPTIONS_MENU_DEFAULT_SEPARATION: int = 7
const OPTIONS_LANGUAGE_BUTTON_SIZE: Vector2 = Vector2(64.0, 36.0)
const OPTIONS_LANGUAGE_BUTTON_FONT_SIZE: int = 12
const OPTIONS_LANGUAGE_BUTTON_Y_OFFSET: float = 4.5
const OPTIONS_ADVANCED_BUTTON_SIZE: Vector2 = Vector2(280.0, 42.0)
const OPTIONS_FOOTER_MARGIN: Vector2 = Vector2(34.0, 40.0)
const OPTIONS_LABEL_COLOR: Color = Color(1.0, 0.64, 0.28, 1.0)
const OPTIONS_LABEL_HOVER_COLOR: Color = Color(1.0, 0.78, 0.38, 1.0)
const DEATH_RECAP_BUTTON_RECT: Rect2 = Rect2(896.0, 32.0, 232.0, 52.0)
const STATS_FONT_MIN_SIZE: int = 10
const STATS_FONT_MAX_SIZE: int = 15
const STATS_TEXT_EDGE_PADDING: float = 4.0

var game_scene
var player
var pause_menu: Panel
var options_menu: Panel
var health_label: Label
var attack_label: Label
var atk_speed_label: Label
var recoil_label: Label
var heal_after_wave_label: Label
var dash_cooldown_label: Label
var rerolls_label: Label
var healing_received_label: Label
var game_over: Panel
var game_over_background: TextureRect
var game_win: Panel
var game_win_background: TextureRect
var stats_panel: Control
var death_recap_parent: Panel
var death_recap_background: Panel
var death_recap_scroll: ScrollContainer
var death_recap_label: Label
var death_recap_button: Button
var death_recap_updated: bool = false
var death_recap_open: bool = false
var language_button: Button
var music_slider: HSlider
var sfx_slider: HSlider
var level_up_stats_preview_visible: bool = false
var settings_overlay: SettingsOverlay
var advanced_settings_button: Button
var continue_endless_button: Button
var stats_font_layout_signature: String = ""

var can_move: bool = true

func _ready() -> void:
	player = get_node_or_null(PLAYER_PATH)
	game_scene = get_node_or_null(GAME_SCENE_PATH)
	pause_menu = get_node_or_null(PAUSE_MENU_PATH)
	options_menu = get_node_or_null(OPTIONS_MENU_PATH)
	health_label = get_node_or_null(HEALTH_LABEL_PATH)
	attack_label = get_node_or_null(ATTACK_LABEL_PATH)
	atk_speed_label = get_node_or_null(ATK_SPEED_LABEL_PATH)
	recoil_label = get_node_or_null(RECOIL_LABEL_PATH)
	_setup_heal_after_wave_label()
	_setup_dash_cooldown_label()
	_setup_rerolls_label()
	_setup_healing_received_label()
	game_over = get_node_or_null(GAME_OVER_PATH)
	game_over_background = get_node_or_null("GameOver/Fundo") as TextureRect
	game_win = get_node_or_null(GAME_WIN_PATH)
	game_win_background = get_node_or_null("GameWin/Fundo") as TextureRect
	stats_panel = get_node_or_null("../HBoxContainer") as Control
	_setup_audio_sliders()
	_setup_language_button()
	_setup_advanced_settings()
	_setup_continue_endless_button()
	_setup_end_screen_action_buttons()
	I18n.language_changed.connect(_on_language_changed)
	_refresh_localized_text()

	if player:
		player.connect("stats_updated", Callable(self, "update_status_labels"))
	_sync_stats_panel_visibility()

func _setup_audio_sliders() -> void:
	if options_menu == null:
		return

	music_slider = options_menu.get_node_or_null("VBoxContainer/HSlider") as HSlider
	sfx_slider = options_menu.get_node_or_null("VBoxContainer/HSlider2") as HSlider
	Global.configure_music_slider(music_slider)
	Global.configure_sfx_slider(sfx_slider)
	Global.apply_audio_volumes()

func _setup_heal_after_wave_label() -> void:
	if recoil_label == null:
		return

	var stats_container = recoil_label.get_parent()
	if stats_container == null:
		return

	heal_after_wave_label = stats_container.get_node_or_null("HealAfterWave")
	if heal_after_wave_label == null:
		heal_after_wave_label = Label.new()
		heal_after_wave_label.name = "HealAfterWave"
		heal_after_wave_label.layout_mode = 2
		heal_after_wave_label.mouse_filter = Control.MOUSE_FILTER_STOP
		heal_after_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		heal_after_wave_label.add_theme_color_override("font_color", Color(1, 0.25882354, 0.2, 1))
		heal_after_wave_label.add_theme_constant_override("outline_size", 4)
		heal_after_wave_label.add_theme_font_size_override("font_size", 12)
		stats_container.add_child(heal_after_wave_label)
		stats_container.move_child(heal_after_wave_label, recoil_label.get_index() + 1)

	heal_after_wave_label.visible = false

func _setup_dash_cooldown_label() -> void:
	if recoil_label == null:
		return

	var stats_container = recoil_label.get_parent()
	if stats_container == null:
		return

	dash_cooldown_label = stats_container.get_node_or_null("DashCooldown")
	if dash_cooldown_label == null:
		dash_cooldown_label = Label.new()
		dash_cooldown_label.name = "DashCooldown"
		dash_cooldown_label.layout_mode = 2
		dash_cooldown_label.mouse_filter = Control.MOUSE_FILTER_STOP
		dash_cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		dash_cooldown_label.add_theme_color_override("font_color", Color(0.45, 0.74, 1.0, 1.0))
		dash_cooldown_label.add_theme_constant_override("outline_size", 4)
		dash_cooldown_label.add_theme_font_size_override("font_size", 12)
		stats_container.add_child(dash_cooldown_label)
		var insert_after = heal_after_wave_label if heal_after_wave_label != null else recoil_label
		stats_container.move_child(dash_cooldown_label, insert_after.get_index() + 1)

	dash_cooldown_label.visible = false

func _setup_healing_received_label() -> void:
	if recoil_label == null:
		return

	var stats_container = recoil_label.get_parent()
	if stats_container == null:
		return

	healing_received_label = stats_container.get_node_or_null("HealingReceived")
	if healing_received_label == null:
		healing_received_label = Label.new()
		healing_received_label.name = "HealingReceived"
		healing_received_label.layout_mode = 2
		healing_received_label.mouse_filter = Control.MOUSE_FILTER_STOP
		healing_received_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		healing_received_label.add_theme_color_override("font_color", Color(0.45, 0.74, 1.0, 1.0))
		healing_received_label.add_theme_constant_override("outline_size", 4)
		healing_received_label.add_theme_font_size_override("font_size", 12)
		stats_container.add_child(healing_received_label)
		var insert_after = rerolls_label if rerolls_label != null else dash_cooldown_label if dash_cooldown_label != null else heal_after_wave_label if heal_after_wave_label != null else recoil_label
		stats_container.move_child(healing_received_label, insert_after.get_index() + 1)

func _setup_rerolls_label() -> void:
	if recoil_label == null:
		return
	var stats_container = recoil_label.get_parent()
	if stats_container == null:
		return
	rerolls_label = stats_container.get_node_or_null("Rerolls") as Label
	if rerolls_label == null:
		rerolls_label = Label.new()
		rerolls_label.name = "Rerolls"
		rerolls_label.layout_mode = 2
		rerolls_label.mouse_filter = Control.MOUSE_FILTER_STOP
		rerolls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rerolls_label.add_theme_color_override("font_color", Color(0.45, 0.74, 1.0, 1.0))
		rerolls_label.add_theme_constant_override("outline_size", 4)
		rerolls_label.add_theme_font_size_override("font_size", 12)
		stats_container.add_child(rerolls_label)
		var insert_after = dash_cooldown_label if dash_cooldown_label != null else recoil_label
		stats_container.move_child(rerolls_label, insert_after.get_index() + 1)
	
func _process(_delta: float) -> void:
	update_status_labels()
	var recap_parent = _get_active_recap_parent()
	if recap_parent != null:
		_setup_death_recap_ui(recap_parent)
		_sync_death_recap_visibility(recap_parent)
	else:
		death_recap_open = false
		_sync_death_recap_visibility()
	if _is_end_screen_visible():
		return
	if settings_overlay != null and settings_overlay.is_open():
		return

	if Input.is_action_just_pressed("pause"):
		if pause_menu != null and pause_menu.is_visible():
			_unpause_game()
		elif not _is_popup_pause_active():
			_pause_game()

func _pause_game() -> void:
	if _is_end_screen_visible() or _is_popup_pause_active():
		return

	pause_menu.show()
	_sync_stats_panel_visibility()
	get_tree().paused = true
	Global.keep_music_playing_during_pause()
	var resume_button = pause_menu.get_node_or_null("HBoxContainer/VBoxContainer/ResumeButton") as BaseButton
	if resume_button != null:
		resume_button.call_deferred("grab_focus")

func _unpause_game() -> void:
	if _is_end_screen_visible():
		return

	options_menu.hide()
	if language_button != null:
		language_button.hide()
	if advanced_settings_button != null:
		advanced_settings_button.hide()
	pause_menu.hide()
	_sync_stats_panel_visibility()
	get_tree().paused = false

func set_level_up_stats_preview_visible(should_show: bool) -> void:
	level_up_stats_preview_visible = should_show
	_sync_stats_panel_visibility()

func _sync_stats_panel_visibility() -> void:
	if stats_panel == null or not is_instance_valid(stats_panel):
		stats_panel = get_node_or_null("../HBoxContainer") as Control
	if stats_panel == null:
		return

	var should_show = level_up_stats_preview_visible or (pause_menu != null and pause_menu.visible)
	stats_panel.visible = should_show
	if should_show:
		update_status_labels()

func _is_end_screen_visible() -> bool:
	return (game_over and game_over.visible) or (game_win and game_win.visible)

func _is_popup_pause_active() -> bool:
	return get_tree().paused and (pause_menu == null or not pause_menu.is_visible())

func _get_active_recap_parent() -> Panel:
	if game_over != null and game_over.visible:
		return game_over
	if game_win != null and game_win.visible:
		return game_win
	return null

func _update_death_recap() -> void:
	if death_recap_updated:
		return

	var recap_parent = _get_active_recap_parent()
	if recap_parent == null:
		return
	_setup_death_recap_ui(recap_parent)
	if death_recap_label == null:
		return

	if player and player.has_method("get_death_recap_text"):
		death_recap_label.text = player.get_death_recap_text()
	else:
		death_recap_label.text = I18n.t("recap.no_data")
		death_recap_updated = true

func _setup_death_recap_ui(recap_parent: Panel) -> void:
	if recap_parent == null:
		return

	if death_recap_parent != recap_parent:
		death_recap_parent = recap_parent
		death_recap_background = null
		death_recap_scroll = null
		death_recap_label = null
		death_recap_button = null
		death_recap_updated = false

	_setup_death_recap_button(recap_parent)
	if death_recap_label != null:
		return

	death_recap_background = recap_parent.get_node_or_null("DeathRecapBackground")
	if death_recap_background == null:
		death_recap_background = Panel.new()
		death_recap_background.name = "DeathRecapBackground"
		death_recap_background.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		death_recap_background.z_index = 2
		death_recap_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		death_recap_background.offset_left = 42.0
		death_recap_background.offset_top = 24.0
		death_recap_background.offset_right = 724.0
		death_recap_background.offset_bottom = 560.0
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.0, 0.0, 0.0, 0.62)
		style.set_corner_radius_all(6)
		death_recap_background.add_theme_stylebox_override("panel", style)
		recap_parent.add_child(death_recap_background)
	death_recap_background.visible = false

	death_recap_scroll = recap_parent.get_node_or_null("DeathRecapScroll")
	if death_recap_scroll == null:
		death_recap_scroll = ScrollContainer.new()
		death_recap_scroll.name = "DeathRecapScroll"
		death_recap_scroll.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		death_recap_scroll.z_index = 3
		death_recap_scroll.offset_left = 56.0
		death_recap_scroll.offset_top = DEATH_RECAP_BUTTON_RECT.position.y
		death_recap_scroll.offset_right = 704.0
		death_recap_scroll.offset_bottom = 548.0
		recap_parent.add_child(death_recap_scroll)
	death_recap_scroll.visible = false

	death_recap_label = death_recap_scroll.get_node_or_null("DeathRecapLabel")
	if death_recap_label == null:
		death_recap_label = Label.new()
		death_recap_label.name = "DeathRecapLabel"
		death_recap_label.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		death_recap_label.custom_minimum_size = Vector2(620.0, 0.0)
		death_recap_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		death_recap_label.add_theme_font_size_override("font_size", 12)
		death_recap_label.add_theme_color_override("font_color", Color(0.96, 0.88, 0.76, 1.0))
		death_recap_label.add_theme_constant_override("outline_size", 3)
		death_recap_scroll.add_child(death_recap_label)
	_sync_death_recap_visibility(recap_parent)

func _setup_death_recap_button(recap_parent: Panel) -> void:
	death_recap_button = recap_parent.get_node_or_null("DeathRecapButton") as Button
	if death_recap_button == null:
		death_recap_button = Button.new()
		death_recap_button.name = "DeathRecapButton"
		death_recap_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		death_recap_button.z_index = 2
		recap_parent.add_child(death_recap_button)

	death_recap_button.layout_mode = 0
	death_recap_button.offset_left = DEATH_RECAP_BUTTON_RECT.position.x
	death_recap_button.offset_top = DEATH_RECAP_BUTTON_RECT.position.y
	death_recap_button.offset_right = DEATH_RECAP_BUTTON_RECT.position.x + DEATH_RECAP_BUTTON_RECT.size.x
	death_recap_button.offset_bottom = DEATH_RECAP_BUTTON_RECT.position.y + DEATH_RECAP_BUTTON_RECT.size.y
	death_recap_button.focus_mode = Control.FOCUS_NONE
	death_recap_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_end_screen_button_style(death_recap_button)
	_update_death_recap_button_text()

	var callable = Callable(self, "_on_death_recap_button_pressed")
	if not death_recap_button.pressed.is_connected(callable):
		death_recap_button.pressed.connect(callable)

func _setup_end_screen_action_buttons() -> void:
	var button_paths = [
		"GameOver/MarginContainer/TextureButton",
		"GameOver/MarginContainer2/TextureButton",
		"GameWin/MarginContainer2/TextureButton",
	]
	for button_path in button_paths:
		var button = get_node_or_null(button_path) as Button
		if button != null:
			_apply_end_screen_button_style(button)

func _apply_end_screen_button_style(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_constant_override("outline_size", 4)
	button.add_theme_color_override("font_color", Color(0.882353, 0.0, 0.0, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.25, 0.2, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.72, 0.45, 1.0))
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.0, 0.0, 0.58)
	style.border_color = Color(0.88, 0.12, 0.05, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	var focus_style = style.duplicate() as StyleBoxFlat
	focus_style.border_color = Color(1.0, 0.45, 0.16, 1.0)
	focus_style.set_border_width_all(3)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new() if button.focus_mode == Control.FOCUS_NONE else focus_style)

func _sync_death_recap_visibility(recap_parent: Panel = null) -> void:
	if recap_parent == null:
		recap_parent = _get_active_recap_parent()
	var has_recap_parent = recap_parent != null
	if death_recap_button != null:
		death_recap_button.visible = has_recap_parent
		_update_death_recap_button_text()
	var show_recap = death_recap_open and has_recap_parent
	if death_recap_background != null:
		death_recap_background.visible = show_recap
	if death_recap_scroll != null:
		death_recap_scroll.visible = show_recap

func _update_death_recap_button_text() -> void:
	if death_recap_button == null:
		return
	death_recap_button.text = I18n.t("recap.hide_button") if death_recap_open else I18n.t("recap.button")

func _on_death_recap_button_pressed() -> void:
	death_recap_open = not death_recap_open
	if death_recap_open:
		death_recap_updated = false
		_update_death_recap()
	_sync_death_recap_visibility()

func _on_options_button_pressed() -> void:
	options_menu.show()
	if language_button != null:
		language_button.show()
	if advanced_settings_button != null:
		advanced_settings_button.show()
		advanced_settings_button.grab_focus()

func _on_back_button_pressed() -> void:
	options_menu.hide()
	if language_button != null:
		language_button.hide()
	if advanced_settings_button != null:
		advanced_settings_button.hide()

func _setup_advanced_settings() -> void:
	settings_overlay = SETTINGS_OVERLAY_SCRIPT.new()
	add_child(settings_overlay)
	advanced_settings_button = Button.new()
	advanced_settings_button.name = "AdvancedSettingsButton"
	advanced_settings_button.process_mode = Node.PROCESS_MODE_ALWAYS
	advanced_settings_button.text = I18n.t("settings.advanced_button")
	advanced_settings_button.size = OPTIONS_ADVANCED_BUTTON_SIZE
	advanced_settings_button.visible = false
	advanced_settings_button.add_theme_font_size_override("font_size", 14)
	advanced_settings_button.add_theme_color_override("font_color", OPTIONS_LABEL_COLOR)
	advanced_settings_button.add_theme_color_override("font_hover_color", OPTIONS_LABEL_HOVER_COLOR)
	advanced_settings_button.add_theme_color_override("font_focus_color", OPTIONS_LABEL_HOVER_COLOR)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.035, 0.045, 0.98)
	style.border_color = Color(0.88, 0.18, 0.08, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	advanced_settings_button.add_theme_stylebox_override("normal", style)
	advanced_settings_button.add_theme_stylebox_override("hover", style)
	advanced_settings_button.add_theme_stylebox_override("focus", style)
	advanced_settings_button.pressed.connect(settings_overlay.open_overlay)
	options_menu.add_child(advanced_settings_button)
	_position_options_footer_controls(options_menu)

func _setup_language_button() -> void:
	if options_menu == null:
		return
	var container = options_menu.get_node_or_null("VBoxContainer")
	if container == null:
		return
	container.add_theme_constant_override("separation", OPTIONS_MENU_DEFAULT_SEPARATION)

	var existing_language_button = options_menu.get_node_or_null("LanguageButton")
	if existing_language_button is Button:
		language_button = existing_language_button as Button
	if language_button == null:
		existing_language_button = options_menu.get_parent().get_node_or_null("LanguageButton")
		if existing_language_button is Button:
			language_button = existing_language_button as Button
			language_button.reparent(options_menu, false)
	if language_button == null:
		existing_language_button = container.get_node_or_null("LanguageButton")
		if existing_language_button is Button:
			language_button = existing_language_button as Button
			language_button.reparent(options_menu, false)
	if language_button == null:
		language_button = Button.new()
		language_button.name = "LanguageButton"
		language_button.process_mode = Node.PROCESS_MODE_ALWAYS
		options_menu.add_child(language_button)
	_style_options_language_button(language_button, options_menu as Control)
	language_button.visible = (options_menu as CanvasItem).visible

	var callable = Callable(self, "_on_language_button_pressed")
	if not language_button.pressed.is_connected(callable):
		language_button.pressed.connect(callable)

func _style_options_language_button(button: Button, options_menu: Control) -> void:
	button.layout_mode = 0
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	button.custom_minimum_size = OPTIONS_LANGUAGE_BUTTON_SIZE
	button.flat = false
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", OPTIONS_LANGUAGE_BUTTON_FONT_SIZE)
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_color_override("font_color", OPTIONS_LABEL_COLOR)
	button.add_theme_color_override("font_hover_color", OPTIONS_LABEL_HOVER_COLOR)
	button.add_theme_color_override("font_focus_color", OPTIONS_LABEL_HOVER_COLOR)
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.42, 0.18, 1.0))
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.12, 0.035, 0.045, 0.98)
	normal_style.border_color = Color(0.88, 0.18, 0.08, 1.0)
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(5)
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.18, 0.05, 0.06, 0.98)
	hover_style.border_color = Color(1.0, 0.48, 0.18, 1.0)
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.08, 0.02, 0.03, 0.98)
	pressed_style.border_color = Color(1.0, 0.58, 0.2, 1.0)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("disabled", normal_style)
	_position_options_footer_controls(options_menu)

func _position_options_footer_controls(options_menu_control: Control) -> void:
	if options_menu_control == null:
		return
	var frame = options_menu_control.get_node_or_null("NinePatchRect") as Control
	if frame == null:
		return

	var inverse_scale = Vector2(
		1.0 / max(options_menu_control.scale.x, 0.001),
		1.0 / max(options_menu_control.scale.y, 0.001)
	)
	var frame_end = frame.position + frame.size
	var footer_bottom = frame_end.y - OPTIONS_FOOTER_MARGIN.y * inverse_scale.y

	if language_button != null:
		language_button.scale = inverse_scale
		language_button.position = Vector2(
			frame.position.x + OPTIONS_FOOTER_MARGIN.x * inverse_scale.x,
			footer_bottom - OPTIONS_LANGUAGE_BUTTON_SIZE.y * inverse_scale.y + OPTIONS_LANGUAGE_BUTTON_Y_OFFSET * inverse_scale.y
		)
		language_button.size = OPTIONS_LANGUAGE_BUTTON_SIZE

	if advanced_settings_button != null:
		advanced_settings_button.scale = inverse_scale
		advanced_settings_button.position = Vector2(
			frame_end.x - (OPTIONS_FOOTER_MARGIN.x + OPTIONS_ADVANCED_BUTTON_SIZE.x) * inverse_scale.x,
			footer_bottom - OPTIONS_ADVANCED_BUTTON_SIZE.y * inverse_scale.y
		)
		advanced_settings_button.size = OPTIONS_ADVANCED_BUTTON_SIZE

func _on_language_button_pressed() -> void:
	I18n.toggle_language()

func _on_language_changed(_language: String) -> void:
	_refresh_localized_text()
	update_status_labels()
	if _get_active_recap_parent() != null and death_recap_open:
		death_recap_updated = false
		_update_death_recap()
	_sync_death_recap_visibility()

func _refresh_localized_text() -> void:
	_update_game_over_texture()
	_update_game_win_texture()

	if language_button != null:
		language_button.text = I18n.t("settings.language_button")
		_set_control_tooltip(language_button, I18n.t("settings.language_tooltip"))
	if advanced_settings_button != null:
		advanced_settings_button.text = I18n.t("settings.advanced_button")

	var retry_button = get_node_or_null("GameOver/MarginContainer/TextureButton") as Button
	if retry_button != null:
		retry_button.text = I18n.t("common.retry")
	var game_over_menu_button = get_node_or_null("GameOver/MarginContainer2/TextureButton") as Button
	if game_over_menu_button != null:
		game_over_menu_button.text = I18n.t("common.menu")
	var game_win_menu_button = get_node_or_null("GameWin/MarginContainer2/TextureButton") as Button
	if game_win_menu_button != null:
		game_win_menu_button.text = I18n.t("common.menu")
	if continue_endless_button != null:
		continue_endless_button.text = I18n.t("endless.continue")
	_update_death_recap_button_text()

func _update_game_over_texture() -> void:
	if game_over_background == null:
		game_over_background = get_node_or_null("GameOver/Fundo") as TextureRect
	if game_over_background == null:
		return
	game_over_background.texture = GAME_OVER_TEXTURE_PT if I18n.get_language() == I18n.LANG_PT_BR else GAME_OVER_TEXTURE_EN

func _update_game_win_texture() -> void:
	if game_win_background == null:
		game_win_background = get_node_or_null("GameWin/Fundo") as TextureRect
	if game_win_background == null:
		return
	game_win_background.texture = GAME_WIN_TEXTURE_PT if I18n.get_language() == I18n.LANG_PT_BR else GAME_WIN_TEXTURE_EN

func _on_h_slider_value_changed(value: float) -> void:
	Global.set_music_volume_from_slider(value)

func _on_h_slider_2_value_changed(value: float) -> void:
	Global.set_sfx_volume_from_slider(value)

func _on_retry_button_pressed() -> void:
	_finish_current_run_if_end_screen_visible()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_button_pressed() -> void:
	_finish_current_run_if_end_screen_visible()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Cenas/HUDs/MainMenu.tscn")

func _setup_continue_endless_button() -> void:
	if game_win == null:
		return
	continue_endless_button = game_win.get_node_or_null("ContinueEndlessButton") as Button
	if continue_endless_button == null:
		continue_endless_button = Button.new()
		continue_endless_button.name = "ContinueEndlessButton"
		continue_endless_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		continue_endless_button.position = Vector2(408.0, 538.0)
		continue_endless_button.size = Vector2(336.0, 54.0)
		continue_endless_button.add_theme_font_size_override("font_size", 15)
		PopupStyle.apply_button(continue_endless_button)
		game_win.add_child(continue_endless_button)
	continue_endless_button.text = I18n.t("endless.continue")
	continue_endless_button.visible = Global.is_story_mode()
	if not continue_endless_button.pressed.is_connected(_on_continue_endless_pressed):
		continue_endless_button.pressed.connect(_on_continue_endless_pressed)

func _on_continue_endless_pressed() -> void:
	_finish_current_run_if_end_screen_visible()
	Global.mark_story_completed()
	Global.selected_game_mode = Global.GAME_MODE_ENDLESS
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Cenas/General/gameScene.tscn")

func _finish_current_run_if_end_screen_visible() -> void:
	if not _is_end_screen_visible():
		return

	if game_scene and game_scene.has_method("finish_run"):
		if game_scene.finish_run():
			return

	Global.finish_current_run()

func update_status_labels() -> void:
	if player:
		if health_label:
			health_label.text = I18n.t("hud.health", [player.current_health, player.max_health])
			_set_control_tooltip(health_label, I18n.t("hud.health_tooltip"))
		if attack_label:
			attack_label.text = I18n.t("hud.attack", [player.attack_damage])
			_set_control_tooltip(attack_label, I18n.t("hud.attack_tooltip"))
		if atk_speed_label:
			var attack_speed_percent = (1.0 / max(player.fire_rate, 0.001)) * 100.0
			if player.has_method("get_attack_speed_percent"):
				attack_speed_percent = player.get_attack_speed_percent()
			var shot_cooldown = player.get_shot_cooldown() if player.has_method("get_shot_cooldown") else player.fire_rate
			var base_shot_cooldown = player.get_base_shot_cooldown() if player.has_method("get_base_shot_cooldown") else 1.1
			var max_attack_speed_percent = player.get_max_attack_speed_percent() if player.has_method("get_max_attack_speed_percent") else attack_speed_percent
			var arm_upgrade_scale_percent = player.get_attack_speed_upgrade_scale_percent() if player.has_method("get_attack_speed_upgrade_scale_percent") else 100.0
			var arm_name = player.get_current_arm_name() if player.has_method("get_current_arm_name") else I18n.t("common.base")
			atk_speed_label.text = I18n.t("hud.atk_speed", [attack_speed_percent])
			_set_control_tooltip(atk_speed_label, I18n.t("hud.atk_speed_tooltip", [arm_name, base_shot_cooldown, shot_cooldown, arm_upgrade_scale_percent, max_attack_speed_percent]))
		if recoil_label:
			recoil_label.text = I18n.t("hud.recoil", [player.recoil_force / 100.0])
			var max_recoil_force = player.get_max_recoil_force() if player.has_method("get_max_recoil_force") else 800.0
			_set_control_tooltip(recoil_label, I18n.t("hud.recoil_tooltip", [max_recoil_force / 100.0]))
		if heal_after_wave_label:
			var heal_after_wave_percent = player.get_heal_after_wave_percent() if player.has_method("get_heal_after_wave_percent") else 0.0
			heal_after_wave_label.visible = heal_after_wave_percent > 0.0
			if heal_after_wave_label.visible:
				var max_heal_after_wave_percent = player.get_max_heal_after_wave_percent() if player.has_method("get_max_heal_after_wave_percent") else 15.0
				heal_after_wave_label.text = I18n.t("hud.heal_wave", [heal_after_wave_percent])
				_set_control_tooltip(heal_after_wave_label, I18n.t("hud.heal_wave_tooltip", [heal_after_wave_percent, max_heal_after_wave_percent]))
		if dash_cooldown_label:
			var dash_cooldown_reduction_percent = player.get_dash_cooldown_reduction_percent() if player.has_method("get_dash_cooldown_reduction_percent") else 0.0
			dash_cooldown_label.visible = dash_cooldown_reduction_percent > 0.0
			if dash_cooldown_label.visible:
				var max_dash_cooldown_reduction_percent = player.get_max_dash_cooldown_reduction_percent() if player.has_method("get_max_dash_cooldown_reduction_percent") else 40.0
				var base_dash_cooldown = player.get_base_dash_cooldown() if player.has_method("get_base_dash_cooldown") else 5.0
				var current_dash_cooldown = player.get_dash_cooldown() if player.has_method("get_dash_cooldown") else player.dash_cooldown
				dash_cooldown_label.text = I18n.t("hud.dash_cd", [dash_cooldown_reduction_percent])
				_set_control_tooltip(dash_cooldown_label, I18n.t("hud.dash_cd_tooltip", [dash_cooldown_reduction_percent, base_dash_cooldown, current_dash_cooldown, max_dash_cooldown_reduction_percent]))
		if rerolls_label:
			var rerolls = player.get_reroll_tokens() if player.has_method("get_reroll_tokens") else int(player.get("reroll_tokens"))
			rerolls_label.text = I18n.t("hud.rerolls", [rerolls])
			_set_control_tooltip(rerolls_label, I18n.t("hud.rerolls_tooltip"))
		if healing_received_label:
			var healing_received_percent = player.get_healing_received_percent() if player.has_method("get_healing_received_percent") else 100.0
			healing_received_label.text = I18n.t("hud.heal_received", [healing_received_percent])
			_set_control_tooltip(healing_received_label, I18n.t("hud.heal_received_tooltip"))
		_fit_stats_font_to_panel()

func _fit_stats_font_to_panel() -> void:
	if recoil_label == null:
		return
	var stats_container = recoil_label.get_parent() as Control
	if stats_container == null or stats_container.size.x <= 0.0:
		return

	var labels: Array[Label] = []
	for candidate in [health_label, attack_label, atk_speed_label, recoil_label, heal_after_wave_label, dash_cooldown_label, rerolls_label, healing_received_label]:
		if candidate is Label and (candidate as Label).visible:
			labels.append(candidate as Label)
	if labels.is_empty():
		return

	var signature_parts := PackedStringArray(["%.1f" % stats_container.size.x])
	for label in labels:
		signature_parts.append(label.text)
	var signature = "|".join(signature_parts)
	if signature == stats_font_layout_signature:
		return
	stats_font_layout_signature = signature

	var available_width = maxf(stats_container.size.x - STATS_TEXT_EDGE_PADDING, 1.0)
	var selected_size = STATS_FONT_MIN_SIZE
	for candidate_size in range(STATS_FONT_MAX_SIZE, STATS_FONT_MIN_SIZE - 1, -1):
		var all_fit = true
		for label in labels:
			var font = label.get_theme_font("font")
			var outline = label.get_theme_constant("outline_size")
			var text_width = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, candidate_size).x + float(outline * 2)
			if text_width > available_width:
				all_fit = false
				break
		if all_fit:
			selected_size = candidate_size
			break

	for label in labels:
		label.add_theme_font_size_override("font_size", selected_size)

func _set_control_tooltip(control: Control, text: String) -> void:
	if control == null:
		return
	control.tooltip_text = Global.wrap_tooltip_text(text)
