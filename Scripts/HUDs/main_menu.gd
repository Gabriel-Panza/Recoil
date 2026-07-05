extends Control

const MAX_VISIBLE_RANKING_RUNS: int = 5
const OPTIONS_MENU_DEFAULT_SEPARATION: int = 7
const OPTIONS_LANGUAGE_BUTTON_CENTER: Vector2 = Vector2(51.4, 31.8)
const OPTIONS_LANGUAGE_BUTTON_SIZE: Vector2 = Vector2(48.0, 28.0)
const OPTIONS_LANGUAGE_BUTTON_FONT_SIZE: int = 16

@onready var ranking_panel: Control = $RankingPanel
@onready var ranking_list: VBoxContainer = $RankingPanel/ScrollContainer/RankingList

var language_button: Button

func _ready() -> void:
	ranking_panel.visible = false
	_setup_language_button()
	I18n.language_changed.connect(_on_language_changed)
	_refresh_localized_text()

func _on_start_game_pressed() -> void:
	_play_sfx()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Cenas/General/gameScene.tscn")
	
func _on_exit_button_pressed() -> void:
	_play_sfx()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _on_options_button_pressed() -> void:
	_play_sfx()
	$OptionsMenu.visible = true
	if language_button != null:
		language_button.visible = true
	$Menu.visible = false

func _on_ranking_button_pressed() -> void:
	_play_sfx()
	_refresh_ranking()
	ranking_panel.visible = true
	$Menu.visible = false

func _on_ranking_back_pressed() -> void:
	_play_sfx()
	ranking_panel.visible = false
	$Menu.visible = true

func _refresh_ranking() -> void:
	for child in ranking_list.get_children():
		child.queue_free()

	var runs = Global.get_ranked_runs()
	if runs.is_empty():
		_add_ranking_label(I18n.t("ranking.no_runs"))
		return

	for i in range(min(runs.size(), MAX_VISIBLE_RANKING_RUNS)):
		var run = runs[i]
		var ranking_text = "%02d. %s - %s" % [
			i + 1,
			Global.format_pecados_derrotados(int(run.get("pecados_derrotados", 0))),
			str(run.get("tempo_formatado", "00:00"))
		]
		_add_ranking_label(ranking_text, str(run.get("data", "")))

func _add_ranking_label(text: String, tooltip: String = "") -> void:
	var label = Label.new()
	label.text = text
	label.tooltip_text = tooltip
	label.add_theme_color_override("font_color", Color(0.88, 0.0, 0.0))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_font_size_override("font_size", 24)
	ranking_list.add_child(label)

func _setup_language_button() -> void:
	var options_menu = get_node_or_null("OptionsMenu")
	if options_menu == null:
		return
	var button_parent = options_menu.get_parent()
	if button_parent == null:
		return
	var container = options_menu.get_node_or_null("VBoxContainer")
	if container == null:
		return
	container.add_theme_constant_override("separation", OPTIONS_MENU_DEFAULT_SEPARATION)

	var existing_language_button = button_parent.get_node_or_null("LanguageButton")
	if existing_language_button is Button:
		language_button = existing_language_button as Button
	if language_button == null:
		existing_language_button = options_menu.get_node_or_null("LanguageButton")
		if existing_language_button is Button:
			language_button = existing_language_button as Button
			options_menu.remove_child(language_button)
			button_parent.add_child(language_button)
	if language_button == null:
		existing_language_button = container.get_node_or_null("LanguageButton")
		if existing_language_button is Button:
			language_button = existing_language_button as Button
			container.remove_child(language_button)
			button_parent.add_child(language_button)
	if language_button == null:
		language_button = Button.new()
		language_button.name = "LanguageButton"
		language_button.process_mode = Node.PROCESS_MODE_ALWAYS
		button_parent.add_child(language_button)
	_style_options_language_button(language_button, options_menu as Control)
	language_button.visible = (options_menu as CanvasItem).visible

	var callable = Callable(self, "_on_language_button_pressed")
	if not language_button.pressed.is_connected(callable):
		language_button.pressed.connect(callable)

func _style_options_language_button(button: Button, options_menu: Control) -> void:
	var center_position = options_menu.position + (OPTIONS_LANGUAGE_BUTTON_CENTER * options_menu.scale)
	button.layout_mode = 0
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	button.offset_left = center_position.x - (OPTIONS_LANGUAGE_BUTTON_SIZE.x * 0.5)
	button.offset_top = center_position.y - (OPTIONS_LANGUAGE_BUTTON_SIZE.y * 0.5)
	button.offset_right = button.offset_left + OPTIONS_LANGUAGE_BUTTON_SIZE.x
	button.offset_bottom = button.offset_top + OPTIONS_LANGUAGE_BUTTON_SIZE.y
	button.custom_minimum_size = OPTIONS_LANGUAGE_BUTTON_SIZE
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", OPTIONS_LANGUAGE_BUTTON_FONT_SIZE)
	button.add_theme_constant_override("outline_size", 0)
	button.add_theme_color_override("font_color", Color(1.0, 0.62, 0.24, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.90, 0.58, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.42, 0.18, 1.0))
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _on_language_button_pressed() -> void:
	_play_sfx()
	I18n.toggle_language()

func _on_language_changed(_language: String) -> void:
	_refresh_localized_text()
	if ranking_panel.visible:
		_refresh_ranking()

func _refresh_localized_text() -> void:
	if language_button != null:
		language_button.text = I18n.t("settings.language_button")
		language_button.tooltip_text = I18n.t("settings.language_tooltip")
	var title = get_node_or_null("RankingPanel/Title")
	if title is Label:
		(title as Label).text = I18n.t("ranking.title")
	var back_button = get_node_or_null("RankingPanel/BackButton")
	if back_button is Button:
		(back_button as Button).text = I18n.t("common.back")

func _play_sfx() -> void:
	var sfx = get_node_or_null("SFX_Button")
	if sfx:
		sfx.play()

func _on_back_button_pressed() -> void:
	_play_sfx()
	$OptionsMenu.visible = false
	if language_button != null:
		language_button.visible = false
	$Menu.visible = true
