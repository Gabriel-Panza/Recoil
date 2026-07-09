extends Control

const MAX_VISIBLE_RANKING_RUNS: int = 5
const OPTIONS_MENU_DEFAULT_SEPARATION: int = 7
const OPTIONS_LANGUAGE_BUTTON_CENTER: Vector2 = Vector2(51.4, 31.8)
const OPTIONS_LANGUAGE_BUTTON_SIZE: Vector2 = Vector2(48.0, 28.0)
const OPTIONS_LANGUAGE_BUTTON_FONT_SIZE: int = 16
const ROULETTE_SPIN_DURATION: float = 0.48
const MENU_OPTION_LABEL_POSITION: Vector2 = Vector2(320.0, 291.0)
const MENU_OPTION_LABEL_SIZE: Vector2 = Vector2(820.0, 68.0)
const MENU_OPTION_LABEL_FONT_SIZE: int = 42
const MENU_OPTION_LABEL_KEYS = {
	"start": "menu.option.play",
	"options": "menu.option.options",
	"ranking": "menu.option.ranking",
	"cutscenes": "menu.option.cutscenes",
	"exit": "menu.option.exit",
	"credits": "menu.option.credits"
}
const MENU_PANEL_POSITION: Vector2 = Vector2(164.0, 62.0)
const MENU_PANEL_SIZE: Vector2 = Vector2(800.0, 540.0)
const MENU_PANEL_MARGIN: float = 64.0
const MENU_PANEL_TITLE_HEIGHT: float = 58.0
const MENU_PANEL_BACK_SIZE: Vector2 = Vector2(208.0, 52.0)
const CREDITS_PANEL_POSITION: Vector2 = Vector2.ZERO
const CREDITS_PANEL_SIZE: Vector2 = Vector2(1152.0, 648.0)
const CREDITS_TITLE_POSITION: Vector2 = Vector2(52.0, 30.0)
const CREDITS_TITLE_SIZE: Vector2 = Vector2(1048.0, 58.0)
const CREDITS_GRID_POSITION: Vector2 = Vector2(52.0, 104.0)
const CREDITS_GRID_SIZE: Vector2 = Vector2(1048.0, 438.0)
const CREDITS_CARD_SIZE: Vector2 = Vector2(514.0, 132.0)
const CREDITS_ART_SLOT_SIZE: Vector2 = Vector2(116.0, 116.0)
const CREDITS_BACK_POSITION: Vector2 = Vector2(472.0, 574.0)
const CREDIT_PORTRAIT_ARTHUR: Texture2D = preload("res://Sprites/Menu/Arthur.png")
const CREDIT_PORTRAIT_DEBORA: Texture2D = preload("res://Sprites/Menu/Debora.png")
const CREDIT_PORTRAIT_LOVISI: Texture2D = preload("res://Sprites/Menu/Lovisi.png")
const CREDIT_PORTRAIT_CALBO: Texture2D = preload("res://Sprites/Menu/Calbo.png")
const CREDIT_PORTRAIT_GABRIEL: Texture2D = preload("res://Sprites/Menu/Gabriel.png")
const MENU_MUSIC_STREAM: AudioStream = preload("res://Music&SFX/Music/Recoil Menu OST.mp3")
const CREDIT_ENTRIES = [
	{ "name": "Arthur \"Engispyro\" Pinna", "role_key": "credits.role.game_level_designer" },
	{ "name": "Debora \"Miya\" Serpa", "role_key": "credits.role.artist_2d" },
	{ "name": "Guilherme \"Phantom_gl\" Lovisi", "role_key": "credits.role.programmer" },
	{ "name": "Guilherme \"K4rubo\" Calbo", "role_key": "credits.role.artist_2d" },
	{ "name": "Gabriel \"ImaqtPlayer\" Panza", "role_key": "credits.role.mentor_programmer" }
]

@onready var ranking_panel: Control = $RankingPanel
@onready var ranking_list: VBoxContainer = $RankingPanel/ScrollContainer/RankingList

var language_button: Button
var credits_panel: Panel
var credits_title_label: Label
var credits_back_button: Button
var credits_list: GridContainer
var cutscenes_panel: Panel
var cutscenes_title_label: Label
var cutscenes_back_button: Button
var cutscenes_grid: GridContainer
var roulette_sprite: Sprite2D
var roulette_button_items: Array = []
var roulette_items_by_action: Dictionary = {}
var roulette_angle: float = 0.0
var roulette_selected_angle: float = 0.0
var roulette_visual_pivot: Vector2 = Vector2.ZERO
var roulette_sprite_visual_offset: Vector2 = Vector2.ZERO
var roulette_tween: Tween
var roulette_is_spinning: bool = false
var roulette_selected_item_index: int = -1
var roulette_navigation_order: Array = []
var selected_option_label: Label
var selected_option_label_text: String = ""
var selected_option_label_tween: Tween

func _ready() -> void:
	_setup_audio()
	ranking_panel.visible = false
	_setup_roulette_menu()
	_setup_secondary_panels()
	_setup_language_button()
	I18n.language_changed.connect(_on_language_changed)
	_refresh_localized_text()
	_open_returned_cutscenes_gallery_if_requested()

func _setup_audio() -> void:
	var music_player = get_node_or_null("MenuMusic") as AudioStreamPlayer
	if music_player == null:
		music_player = AudioStreamPlayer.new()
		music_player.name = "MenuMusic"
		add_child(music_player)
	music_player.stream = Global.make_looping_audio_stream(MENU_MUSIC_STREAM)
	Global.register_audio_player(music_player, Global.GROUP_MUSIC, -5.0)
	if not music_player.playing:
		music_player.play()

	var button_sfx = get_node_or_null("SFX_Button") as AudioStreamPlayer
	if button_sfx != null:
		button_sfx.autoplay = false
		button_sfx.stop()
		Global.register_audio_player(button_sfx, Global.GROUP_SFX, 0.0)

	Global.apply_audio_volumes()

func _open_returned_cutscenes_gallery_if_requested() -> void:
	if not Global.open_cutscenes_gallery_on_menu_ready:
		return

	Global.open_cutscenes_gallery_on_menu_ready = false
	_refresh_secondary_panels()
	_show_content_panel(cutscenes_panel)

func _input(event: InputEvent) -> void:
	if not _is_roulette_input_active():
		return

	if event is InputEventMouseButton and event.pressed:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			get_viewport().set_input_as_handled()
			_request_roulette_navigation_step(-1)
			return
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			get_viewport().set_input_as_handled()
			_request_roulette_navigation_step(1)
			return

	if event.is_action_pressed("ui_up"):
		get_viewport().set_input_as_handled()
		_request_roulette_navigation_step(-1)
	elif event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()
		_request_roulette_navigation_step(1)

func _on_start_game_pressed() -> void:
	_request_roulette_action("start")

func _execute_start_game() -> void:
	_play_sfx()
	Global.intro_cutscene_return_target = Global.INTRO_CUTSCENE_RETURN_GAME
	Global.open_cutscenes_gallery_on_menu_ready = false
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Cenas/HUDs/IntroCutscene.tscn")
	
func _on_exit_button_pressed() -> void:
	_request_roulette_action("exit")

func _execute_exit_game() -> void:
	_play_sfx()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _on_options_button_pressed() -> void:
	_request_roulette_action("options")

func _execute_options_menu() -> void:
	_play_sfx()
	$OptionsMenu.visible = true
	if language_button != null:
		language_button.visible = true
	$Menu.visible = false

func _on_ranking_button_pressed() -> void:
	_request_roulette_action("ranking")

func _execute_ranking_menu() -> void:
	_play_sfx()
	_refresh_ranking()
	_show_content_panel(ranking_panel)

func _on_ranking_back_pressed() -> void:
	_play_sfx()
	_return_to_main_menu()

func _execute_cutscenes_gallery() -> void:
	_play_sfx()
	_refresh_secondary_panels()
	_show_content_panel(cutscenes_panel)

func _execute_credits_menu() -> void:
	_play_sfx()
	_refresh_secondary_panels()
	_show_content_panel(credits_panel)

func _on_cutscenes_back_pressed() -> void:
	_play_sfx()
	_return_to_main_menu()

func _on_credits_back_pressed() -> void:
	_play_sfx()
	_return_to_main_menu()

func _on_placeholder_cutscene_pressed() -> void:
	_play_sfx()

func _on_intro_cutscene_pressed() -> void:
	_play_sfx()
	Global.intro_cutscene_return_target = Global.INTRO_CUTSCENE_RETURN_GALLERY
	Global.open_cutscenes_gallery_on_menu_ready = false
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Cenas/HUDs/IntroCutscene.tscn")

func _show_content_panel(panel: Control) -> void:
	_hide_content_panels()
	if panel != null:
		panel.visible = true
	$Menu.visible = false

func _return_to_main_menu() -> void:
	_hide_content_panels()
	$Menu.visible = true

func _hide_content_panels() -> void:
	ranking_panel.visible = false
	if credits_panel != null:
		credits_panel.visible = false
	if cutscenes_panel != null:
		cutscenes_panel.visible = false

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
	label.tooltip_text = Global.wrap_tooltip_text(tooltip)
	label.add_theme_color_override("font_color", Color(0.88, 0.0, 0.0))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_font_size_override("font_size", 24)
	ranking_list.add_child(label)

func _setup_secondary_panels() -> void:
	credits_panel = _create_credits_panel()
	credits_title_label = _add_credits_panel_title(credits_panel)
	credits_list = GridContainer.new()
	credits_list.columns = 2
	credits_list.position = CREDITS_GRID_POSITION
	credits_list.size = CREDITS_GRID_SIZE
	credits_list.add_theme_constant_override("h_separation", 20)
	credits_list.add_theme_constant_override("v_separation", 16)
	credits_panel.add_child(credits_list)
	credits_back_button = _add_credits_back_button(credits_panel, Callable(self, "_on_credits_back_pressed"))

	cutscenes_panel = _create_content_panel("CutscenesPanel")
	cutscenes_title_label = _add_content_panel_title(cutscenes_panel)
	cutscenes_grid = GridContainer.new()
	cutscenes_grid.columns = 3
	cutscenes_grid.add_theme_constant_override("h_separation", 16)
	cutscenes_grid.add_theme_constant_override("v_separation", 16)
	_add_scroll_content(cutscenes_panel, cutscenes_grid)
	cutscenes_back_button = _add_content_panel_back_button(cutscenes_panel, Callable(self, "_on_cutscenes_back_pressed"))

	_refresh_secondary_panels()

func _create_content_panel(panel_name: String) -> Panel:
	var panel = Panel.new()
	panel.name = panel_name
	panel.visible = false
	panel.z_index = 5
	panel.position = MENU_PANEL_POSITION
	panel.size = MENU_PANEL_SIZE
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(panel)
	return panel

func _create_credits_panel() -> Panel:
	var panel = Panel.new()
	panel.name = "CreditsPanel"
	panel.visible = false
	panel.z_index = 5
	panel.position = CREDITS_PANEL_POSITION
	panel.size = CREDITS_PANEL_SIZE
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(panel)
	return panel

func _add_content_panel_title(panel: Control) -> Label:
	var title = Label.new()
	title.position = Vector2(MENU_PANEL_MARGIN, 34.0)
	title.size = Vector2(MENU_PANEL_SIZE.x - MENU_PANEL_MARGIN * 2.0, MENU_PANEL_TITLE_HEIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.88, 0.0, 0.0))
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_font_size_override("font_size", 36)
	panel.add_child(title)
	return title

func _add_credits_panel_title(panel: Control) -> Label:
	var title = Label.new()
	title.position = CREDITS_TITLE_POSITION
	title.size = CREDITS_TITLE_SIZE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.88, 0.0, 0.0))
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_font_size_override("font_size", 42)
	panel.add_child(title)
	return title

func _add_scroll_content(panel: Control, content: Control) -> ScrollContainer:
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(MENU_PANEL_MARGIN, 112.0)
	scroll.size = Vector2(MENU_PANEL_SIZE.x - MENU_PANEL_MARGIN * 2.0, 318.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if content is VBoxContainer:
		(content as VBoxContainer).add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	return scroll

func _add_content_panel_back_button(panel: Control, callable: Callable) -> Button:
	var button = Button.new()
	button.position = Vector2((MENU_PANEL_SIZE.x - MENU_PANEL_BACK_SIZE.x) * 0.5, 460.0)
	button.size = MENU_PANEL_BACK_SIZE
	button.focus_mode = Control.FOCUS_NONE
	_style_panel_button(button)
	panel.add_child(button)
	if not button.pressed.is_connected(callable):
		button.pressed.connect(callable)
	return button

func _add_credits_back_button(panel: Control, callable: Callable) -> Button:
	var button = Button.new()
	button.position = CREDITS_BACK_POSITION
	button.size = MENU_PANEL_BACK_SIZE
	button.focus_mode = Control.FOCUS_NONE
	_style_panel_button(button)
	panel.add_child(button)
	if not button.pressed.is_connected(callable):
		button.pressed.connect(callable)
	return button

func _refresh_secondary_panels() -> void:
	if credits_title_label != null:
		credits_title_label.text = I18n.t("credits.title")
	if credits_back_button != null:
		credits_back_button.text = I18n.t("common.back")
	_populate_credits_panel()

	if cutscenes_title_label != null:
		cutscenes_title_label.text = I18n.t("cutscenes.title")
	if cutscenes_back_button != null:
		cutscenes_back_button.text = I18n.t("common.back")
	_populate_cutscenes_panel()

func _populate_credits_panel() -> void:
	if credits_list == null:
		return
	_clear_children(credits_list)

	for entry in CREDIT_ENTRIES:
		var person_name = str(entry["name"])
		credits_list.add_child(_create_credit_card(person_name, I18n.t(str(entry["role_key"])), _get_credit_portrait(person_name)))

func _get_credit_portrait(person_name: String) -> Texture2D:
	if person_name.contains("Arthur"):
		return CREDIT_PORTRAIT_ARTHUR
	if person_name.contains("Miya"):
		return CREDIT_PORTRAIT_DEBORA
	if person_name.contains("Phantom_gl"):
		return CREDIT_PORTRAIT_LOVISI
	if person_name.contains("K4rubo"):
		return CREDIT_PORTRAIT_CALBO
	if person_name.contains("ImaqtPlayer"):
		return CREDIT_PORTRAIT_GABRIEL
	return null

func _create_credit_card(person_name: String, role_text: String, portrait: Texture2D) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = CREDITS_CARD_SIZE
	card.add_theme_stylebox_override("panel", _make_card_style())

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(row)

	var art_slot = PanelContainer.new()
	art_slot.custom_minimum_size = CREDITS_ART_SLOT_SIZE
	art_slot.size = CREDITS_ART_SLOT_SIZE
	art_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	art_slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	art_slot.clip_contents = true
	art_slot.add_theme_stylebox_override("panel", _make_art_slot_style())
	row.add_child(art_slot)

	var portrait_rect = TextureRect.new()
	portrait_rect.texture = portrait
	portrait_rect.custom_minimum_size = Vector2.ZERO
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_slot.add_child(portrait_rect)

	var text_box = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override("separation", 8)
	row.add_child(text_box)

	var name_label = Label.new()
	name_label.text = person_name
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.36))
	name_label.add_theme_constant_override("outline_size", 3)
	name_label.add_theme_font_size_override("font_size", 24)
	text_box.add_child(name_label)

	var role_label = Label.new()
	role_label.text = role_text
	role_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	role_label.add_theme_color_override("font_color", Color(0.96, 0.9, 0.76))
	role_label.add_theme_constant_override("outline_size", 2)
	role_label.add_theme_font_size_override("font_size", 19)
	text_box.add_child(role_label)

	return card

func _populate_cutscenes_panel() -> void:
	if cutscenes_grid == null:
		return
	_clear_children(cutscenes_grid)

	cutscenes_grid.add_child(_create_cutscene_card(I18n.t("cutscenes.intro_title"), Callable(self, "_on_intro_cutscene_pressed")))
	for i in range(5):
		cutscenes_grid.add_child(_create_cutscene_card(I18n.t("cutscenes.coming_soon"), Callable(self, "_on_placeholder_cutscene_pressed")))

func _create_cutscene_card(label_text: String, callable: Callable) -> Button:
	var card = Button.new()
	card.text = label_text
	card.custom_minimum_size = Vector2(210.0, 120.0)
	card.focus_mode = Control.FOCUS_NONE
	card.alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_theme_font_size_override("font_size", 25)
	card.add_theme_constant_override("outline_size", 4)
	card.add_theme_color_override("font_color", Color(1.0, 0.78, 0.36))
	card.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.62))
	card.add_theme_color_override("font_pressed_color", Color(1.0, 0.52, 0.28))
	card.add_theme_stylebox_override("normal", _make_card_style())
	card.add_theme_stylebox_override("hover", _make_card_style(Color(0.18, 0.05, 0.06, 0.96), Color(1.0, 0.36, 0.18, 1.0)))
	card.add_theme_stylebox_override("pressed", _make_card_style(Color(0.12, 0.03, 0.04, 0.98), Color(1.0, 0.48, 0.2, 1.0)))
	if not card.pressed.is_connected(callable):
		card.pressed.connect(callable)
	return card

func _make_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.02, 0.025, 0.94)
	style.border_color = Color(0.88, 0.18, 0.08, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.content_margin_left = 16
	style.content_margin_top = 16
	style.content_margin_right = 16
	style.content_margin_bottom = 16
	return style

func _make_card_style(bg_color: Color = Color(0.12, 0.035, 0.045, 0.96), border_color: Color = Color(0.62, 0.16, 0.1, 1.0)) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style

func _make_art_slot_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.12, 0.13, 0.94)
	style.border_color = Color(0.78, 0.42, 0.26, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style

func _style_panel_button(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_constant_override("outline_size", 4)
	button.add_theme_color_override("font_color", Color(0.96, 0.9, 0.76))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.78, 0.36))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.42, 0.18))
	button.add_theme_stylebox_override("normal", _make_card_style())
	button.add_theme_stylebox_override("hover", _make_card_style(Color(0.18, 0.05, 0.06, 0.96), Color(1.0, 0.36, 0.18, 1.0)))
	button.add_theme_stylebox_override("pressed", _make_card_style(Color(0.12, 0.03, 0.04, 0.98), Color(1.0, 0.48, 0.2, 1.0)))

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _setup_roulette_menu() -> void:
	roulette_sprite = find_child("Roleta", true, false) as Sprite2D
	roulette_button_items.clear()
	roulette_items_by_action.clear()
	if roulette_sprite == null:
		return

	roulette_sprite_visual_offset = _get_roulette_sprite_visual_offset()
	roulette_visual_pivot = roulette_sprite.position + roulette_sprite_visual_offset
	var roulette_parent = roulette_sprite.get_parent()
	if roulette_parent == null:
		return

	for child in roulette_parent.get_children():
		if not child is Control:
			continue
		var holder = child as Control
		var button = _get_first_button(holder)
		if button == null:
			continue
		var action_id = _get_roulette_action_for_button(button)
		if action_id == "":
			continue

		var base_center = holder.position + holder.size * 0.5
		var item = {
			"action": action_id,
			"button": button,
			"holder": holder,
			"base_center": base_center,
			"base_z_index": holder.z_index,
		}
		roulette_button_items.append(item)
		if not roulette_items_by_action.has(action_id):
			roulette_items_by_action[action_id] = []
		roulette_items_by_action[action_id].append(roulette_button_items.size() - 1)
		_connect_roulette_button(button, roulette_button_items.size() - 1)

	_update_roulette_slot_geometry()
	_update_selected_roulette_slot()
	_update_roulette_navigation_order()

	_apply_roulette_angle(roulette_angle)
	roulette_selected_item_index = _get_current_roulette_selected_item_index()
	_raise_selected_roulette_item(roulette_selected_item_index)
	_setup_selected_option_label(roulette_parent)

func _get_roulette_sprite_visual_offset() -> Vector2:
	if roulette_sprite == null or roulette_sprite.texture == null:
		return Vector2.ZERO

	var image = roulette_sprite.texture.get_image()
	if image == null or image.is_empty():
		return Vector2.ZERO

	var min_x = image.get_width()
	var min_y = image.get_height()
	var max_x = -1
	var max_y = -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.03:
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				max_x = max(max_x, x)
				max_y = max(max_y, y)

	if max_x < min_x or max_y < min_y:
		return Vector2.ZERO

	var texture_center = Vector2(image.get_width(), image.get_height()) * 0.5
	var visual_center = Vector2(float(min_x + max_x) * 0.5, float(min_y + max_y) * 0.5)
	var texture_offset = visual_center - texture_center
	return Vector2(texture_offset.x * roulette_sprite.scale.x, texture_offset.y * roulette_sprite.scale.y)

func _update_roulette_slot_geometry() -> void:
	for i in range(roulette_button_items.size()):
		var item = roulette_button_items[i]
		var base_center = item.get("base_center", Vector2.ZERO) as Vector2
		var from_pivot = base_center - roulette_visual_pivot
		item["base_from_pivot"] = from_pivot
		item["base_slot_angle"] = from_pivot.angle()
		roulette_button_items[i] = item

func _get_first_button(root: Node) -> BaseButton:
	if root is BaseButton:
		return root as BaseButton
	for child in root.get_children():
		var button = _get_first_button(child)
		if button != null:
			return button
	return null

func _get_roulette_action_for_button(button: BaseButton) -> String:
	match str(button.name):
		"PlayButton":
			return "start"
		"OptionsButton":
			return "options"
		"RankingButton":
			return "ranking"
		"CutscenesGaleryButton":
			return "cutscenes"
		"ExitButton":
			return "exit"
		"CreditsButton":
			return "credits"
	return ""

func _connect_roulette_button(button: BaseButton, item_index: int) -> void:
	for connection in button.pressed.get_connections():
		var callable = connection.get("callable", Callable())
		if callable.is_valid() and callable.get_object() == self:
			button.pressed.disconnect(callable)

	var callable = Callable(self, "_request_roulette_item_action").bind(item_index)
	if not button.pressed.is_connected(callable):
		button.pressed.connect(callable)

func _update_selected_roulette_slot() -> void:
	var selected_angle = 0.0
	var selected_x = -INF
	for item in roulette_button_items:
		var base_center = item.get("base_center", Vector2.ZERO) as Vector2
		if base_center.x > selected_x:
			selected_x = base_center.x
			selected_angle = float(item.get("base_slot_angle", 0.0))

	roulette_selected_angle = selected_angle

func _update_roulette_navigation_order() -> void:
	roulette_navigation_order.clear()
	for i in range(roulette_button_items.size()):
		roulette_navigation_order.append(i)
	roulette_navigation_order.sort_custom(func(a, b):
		return _get_roulette_navigation_sort_key(int(a)) < _get_roulette_navigation_sort_key(int(b))
	)

func _get_roulette_navigation_sort_key(item_index: int) -> float:
	if item_index < 0 or item_index >= roulette_button_items.size():
		return 0.0

	var item = roulette_button_items[item_index]
	return wrapf(float(item.get("base_slot_angle", 0.0)) - roulette_selected_angle, -PI, PI)

func _get_current_roulette_selected_item_index() -> int:
	var best_index = -1
	var best_delta = INF
	for i in range(roulette_button_items.size()):
		var item = roulette_button_items[i]
		var item_angle = float(item.get("base_slot_angle", 0.0)) + roulette_angle
		var angle_delta = abs(wrapf(item_angle - roulette_selected_angle, -PI, PI))
		if angle_delta < best_delta:
			best_delta = angle_delta
			best_index = i
	return best_index

func _is_roulette_input_active() -> bool:
	if roulette_is_spinning or roulette_button_items.is_empty():
		return false
	var menu = get_node_or_null("Menu")
	return menu is CanvasItem and (menu as CanvasItem).visible

func _request_roulette_navigation_step(direction: int) -> void:
	if roulette_navigation_order.is_empty():
		return
	if roulette_selected_item_index < 0:
		roulette_selected_item_index = _get_current_roulette_selected_item_index()

	var order_position = roulette_navigation_order.find(roulette_selected_item_index)
	if order_position < 0:
		return

	var next_order_position = (order_position + direction) % roulette_navigation_order.size()
	if next_order_position < 0:
		next_order_position += roulette_navigation_order.size()
	_request_roulette_focus(int(roulette_navigation_order[next_order_position]))

func _request_roulette_action(action_id: String) -> void:
	if not roulette_items_by_action.has(action_id):
		return
	var item_indexes = roulette_items_by_action[action_id]
	if item_indexes.is_empty():
		return
	_request_roulette_item_action(int(item_indexes[0]))

func _request_roulette_item_action(item_index: int) -> void:
	if roulette_is_spinning or not $Menu.visible:
		return
	if item_index < 0 or item_index >= roulette_button_items.size():
		return
	if roulette_selected_item_index < 0:
		roulette_selected_item_index = _get_current_roulette_selected_item_index()

	if item_index == roulette_selected_item_index:
		await _execute_roulette_item(item_index)
		return

	await _request_roulette_focus(item_index)

func _request_roulette_focus(item_index: int) -> void:
	if roulette_is_spinning or not $Menu.visible:
		return
	if item_index < 0 or item_index >= roulette_button_items.size():
		return
	var item = roulette_button_items[item_index]
	roulette_is_spinning = true
	_set_roulette_buttons_disabled(true)
	_raise_selected_roulette_item(item_index)
	_animate_selected_option_label_to(_get_menu_option_label_text(str(item.get("action", ""))), ROULETTE_SPIN_DURATION)
	await _spin_roulette_to_item(item)
	roulette_selected_item_index = item_index
	_raise_selected_roulette_item(item_index)
	_set_roulette_buttons_disabled(false)
	roulette_is_spinning = false

func _execute_roulette_item(item_index: int) -> void:
	if item_index < 0 or item_index >= roulette_button_items.size():
		return
	var item = roulette_button_items[item_index]
	var action_id = str(item.get("action", ""))
	roulette_is_spinning = true
	await _execute_roulette_action(action_id)
	if is_inside_tree():
		roulette_is_spinning = false

func _spin_roulette_to_item(item: Dictionary) -> void:
	if item.is_empty():
		return

	if roulette_tween != null:
		roulette_tween.kill()

	var target_angle = _nearest_equivalent_angle(roulette_selected_angle - float(item["base_slot_angle"]), roulette_angle)
	if is_equal_approx(target_angle, roulette_angle):
		_apply_roulette_angle(target_angle)
		return

	var start_angle = roulette_angle
	roulette_tween = create_tween()
	roulette_tween.set_trans(Tween.TRANS_CUBIC)
	roulette_tween.set_ease(Tween.EASE_OUT)
	roulette_tween.tween_method(
		Callable(self, "_apply_roulette_transition").bind(start_angle, target_angle),
		0.0,
		1.0,
		ROULETTE_SPIN_DURATION
	)
	await roulette_tween.finished
	_apply_roulette_angle(target_angle)

func _apply_roulette_transition(progress: float, start_angle: float, target_angle: float) -> void:
	_apply_roulette_angle(lerpf(start_angle, target_angle, progress))

func _get_roulette_holder_position(item: Dictionary, angle: float) -> Vector2:
	var holder = item.get("holder") as Control
	var holder_size = holder.size if holder != null else Vector2.ZERO
	var base_center = item.get("base_center", Vector2.ZERO) as Vector2
	var from_pivot = item.get("base_from_pivot", base_center - roulette_visual_pivot) as Vector2
	var center = roulette_visual_pivot + from_pivot.rotated(angle)
	return center - holder_size * 0.5

func _apply_roulette_angle(angle: float) -> void:
	roulette_angle = angle
	if roulette_sprite != null:
		roulette_sprite.position = roulette_visual_pivot - roulette_sprite_visual_offset.rotated(roulette_angle)
		roulette_sprite.rotation = roulette_angle

	for item in roulette_button_items:
		var holder = item.get("holder") as Control
		if holder == null:
			continue
		holder.position = _get_roulette_holder_position(item, roulette_angle)

func _nearest_equivalent_angle(target_angle: float, from_angle: float) -> float:
	return from_angle + wrapf(target_angle - from_angle, -PI, PI)

func _set_roulette_buttons_disabled(is_disabled: bool) -> void:
	for item in roulette_button_items:
		var button = item.get("button") as BaseButton
		if button != null:
			button.disabled = is_disabled

func _raise_selected_roulette_item(item_index: int) -> void:
	for i in range(roulette_button_items.size()):
		var item = roulette_button_items[i]
		var holder = item.get("holder") as Control
		if holder == null:
			continue
		holder.z_index = int(item.get("base_z_index", 0)) + (2 if i == item_index else 0)

func _setup_selected_option_label(roulette_parent: Node) -> void:
	if roulette_parent == null:
		return

	var existing_label = roulette_parent.get_node_or_null("SelectedOptionLabel")
	if existing_label is Label:
		selected_option_label = existing_label as Label
	elif selected_option_label == null:
		selected_option_label = Label.new()
		selected_option_label.name = "SelectedOptionLabel"
		roulette_parent.add_child(selected_option_label)

	selected_option_label.position = MENU_OPTION_LABEL_POSITION
	selected_option_label.size = MENU_OPTION_LABEL_SIZE
	selected_option_label.z_index = 12
	selected_option_label.mouse_filter = Control.MOUSE_FILTER_PASS
	selected_option_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	selected_option_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected_option_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	selected_option_label.add_theme_font_size_override("font_size", MENU_OPTION_LABEL_FONT_SIZE)
	selected_option_label.add_theme_color_override("font_color", Color8(168, 132, 243, 255))
	selected_option_label.add_theme_color_override("font_outline_color", Color.BLACK)
	selected_option_label.add_theme_constant_override("outline_size", 8)
	var callable = Callable(self, "_on_selected_option_label_gui_input")
	if not selected_option_label.gui_input.is_connected(callable):
		selected_option_label.gui_input.connect(callable)
	_set_selected_option_label_for_current_item(false)

func _on_selected_option_label_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event = event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not _is_roulette_input_active():
		return
	get_viewport().set_input_as_handled()
	_request_selected_option_label_action()

func _request_selected_option_label_action() -> void:
	if roulette_selected_item_index < 0:
		roulette_selected_item_index = _get_current_roulette_selected_item_index()
	if roulette_selected_item_index < 0:
		return
	await _request_roulette_item_action(roulette_selected_item_index)

func _set_selected_option_label_for_current_item(animate: bool, duration: float = ROULETTE_SPIN_DURATION) -> void:
	var action_id = _get_selected_roulette_action_id()
	var label_text = _get_menu_option_label_text(action_id)
	if animate:
		_animate_selected_option_label_to(label_text, duration)
		return

	if selected_option_label_tween != null:
		selected_option_label_tween.kill()
		selected_option_label_tween = null
	selected_option_label_text = label_text
	if selected_option_label != null:
		selected_option_label.text = selected_option_label_text

func _animate_selected_option_label_to(new_text: String, duration: float) -> void:
	if selected_option_label == null or selected_option_label_text == new_text:
		return

	if selected_option_label_tween != null:
		selected_option_label_tween.kill()

	var old_text = selected_option_label_text
	selected_option_label_tween = create_tween()
	selected_option_label_tween.set_trans(Tween.TRANS_LINEAR)
	selected_option_label_tween.tween_method(
		Callable(self, "_apply_selected_option_label_transition").bind(old_text, new_text),
		0.0,
		1.0,
		duration
	)
	selected_option_label_tween.finished.connect(func():
		selected_option_label_text = new_text
		if selected_option_label != null:
			selected_option_label.text = new_text
	)

func _apply_selected_option_label_transition(progress: float, old_text: String, new_text: String) -> void:
	if selected_option_label == null:
		return

	if progress < 0.5:
		var erase_progress = progress / 0.5
		var visible_characters = int(round(lerpf(float(old_text.length()), 0.0, erase_progress)))
		selected_option_label.text = old_text.substr(0, visible_characters)
		return

	var write_progress = (progress - 0.5) / 0.5
	var visible_characters = int(round(lerpf(0.0, float(new_text.length()), write_progress)))
	selected_option_label.text = new_text.substr(0, visible_characters)

func _get_selected_roulette_action_id() -> String:
	if roulette_selected_item_index < 0 or roulette_selected_item_index >= roulette_button_items.size():
		return ""
	return str(roulette_button_items[roulette_selected_item_index].get("action", ""))

func _get_menu_option_label_text(action_id: String) -> String:
	var key = str(MENU_OPTION_LABEL_KEYS.get(action_id, ""))
	if key == "":
		return action_id.to_upper()
	return I18n.t(key)

func _execute_roulette_action(action_id: String) -> void:
	match action_id:
		"start":
			await _execute_start_game()
		"options":
			_execute_options_menu()
		"ranking":
			_execute_ranking_menu()
		"cutscenes":
			_execute_cutscenes_gallery()
		"exit":
			await _execute_exit_game()
		"credits":
			_execute_credits_menu()

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
		language_button.tooltip_text = Global.wrap_tooltip_text(I18n.t("settings.language_tooltip"))
	_set_selected_option_label_for_current_item(false)
	var title = get_node_or_null("RankingPanel/Title")
	if title is Label:
		(title as Label).text = I18n.t("ranking.title")
	var back_button = get_node_or_null("RankingPanel/BackButton")
	if back_button is Button:
		(back_button as Button).text = I18n.t("common.back")
	_refresh_secondary_panels()

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
