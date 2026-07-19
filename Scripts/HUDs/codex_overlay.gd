extends CanvasLayer
class_name CodexOverlay

signal closed

const ENEMY_ENTRIES = [
	{"id": "melee", "en": "Melee", "pt": "Corpo a Corpo", "en_desc": "Pursues the player and attacks at close range.", "pt_desc": "Persegue o jogador e ataca de perto."},
	{"id": "ranged", "en": "Ranged", "pt": "Atirador", "en_desc": "Keeps its distance and fires aimed projectiles.", "pt_desc": "Mantem distancia e dispara projeteis mirados."},
	{"id": "spread", "en": "Spread", "pt": "Dispersao", "en_desc": "Fires several projectiles across a wide angle.", "pt_desc": "Dispara varios projeteis em um angulo amplo."},
	{"id": "tank", "en": "Tank", "pt": "Tanque", "en_desc": "Slow, durable and difficult to remove from the arena.", "pt_desc": "Lento, resistente e dificil de remover da arena."},
	{"id": "agile", "en": "Agile", "pt": "Agil", "en_desc": "Moves quickly and pressures unsafe positions.", "pt_desc": "Move rapidamente e pressiona posicoes inseguras."},
]
const ELITE_ENTRIES = [
	{"id": "armored", "en": "Armored Elite", "pt": "Elite Blindado", "en_desc": "Light gray outline. Takes reduced damage.", "pt_desc": "Contorno cinza claro. Recebe menos dano."},
	{"id": "unstable", "en": "Unstable Elite", "pt": "Elite Instavel", "en_desc": "Yellow-orange outline. Explodes when defeated.", "pt_desc": "Contorno amarelo-laranja. Explode ao ser derrotado."},
	{"id": "vampiric", "en": "Vampiric Elite", "pt": "Elite Vampirico", "en_desc": "Blood-red outline. Heals when it damages the player.", "pt_desc": "Contorno vermelho sangue. Cura ao causar dano no jogador."},
]
const SIN_ENTRIES = [
	{"id": "sloth", "en": "Sloth", "pt": "Preguica", "en_desc": "Controls space by slowing the rhythm of combat.", "pt_desc": "Controla espaco reduzindo o ritmo do combate."},
	{"id": "gluttony", "en": "Gluttony", "pt": "Gula", "en_desc": "Consumes the arena and overwhelms with its size.", "pt_desc": "Consome a arena e domina com seu tamanho."},
	{"id": "envy", "en": "Envy", "pt": "Inveja", "en_desc": "Copies attacks and challenges the player's positioning.", "pt_desc": "Copia ataques e desafia o posicionamento do jogador."},
	{"id": "wrath", "en": "Wrath", "pt": "Ira", "en_desc": "Escalates aggression and rewards constant movement.", "pt_desc": "Escala a agressividade e exige movimento constante."},
	{"id": "lust", "en": "Lust", "pt": "Luxuria", "en_desc": "Builds walls and reshapes safe paths through the arena.", "pt_desc": "Cria paredes e altera os caminhos seguros da arena."},
	{"id": "greed", "en": "Greed", "pt": "Ganancia", "en_desc": "Turns treasure and falling coins into weapons.", "pt_desc": "Transforma tesouros e moedas em armas."},
	{"id": "pride", "en": "Pride", "pt": "Orgulho", "en_desc": "Alternates distant lasers with dangerous close pressure.", "pt_desc": "Alterna lasers distantes com pressao perigosa de perto."},
]

var root_control: Control
var category_select: OptionButton
var entries_list: VBoxContainer
var back_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 230
	_build_ui()
	hide_overlay()
	I18n.language_changed.connect(_on_language_changed)

func _on_language_changed(_language: String) -> void:
	var was_open = is_open()
	remove_child(root_control)
	root_control.queue_free()
	root_control = null
	_build_ui()
	root_control.visible = was_open
	if was_open:
		_refresh_entries()
		category_select.grab_focus()

func open_overlay() -> void:
	root_control.visible = true
	_refresh_entries()
	category_select.grab_focus()

func hide_overlay() -> void:
	if root_control != null:
		root_control.visible = false
	closed.emit()

func is_open() -> bool:
	return root_control != null and root_control.visible

func _unhandled_input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed("ui_cancel"):
		hide_overlay()
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root_control)
	var backdrop = ColorRect.new()
	backdrop.color = Color(0.015, 0.008, 0.018, 0.96)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(backdrop)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 32
	panel.offset_top = 24
	panel.offset_right = -32
	panel.offset_bottom = -24
	panel.add_theme_stylebox_override("panel", _style(Color(0.07, 0.018, 0.03, 0.99), Color(0.76, 0.18, 0.1), 3))
	root_control.add_child(panel)

	var margin = MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 22)
	panel.add_child(margin)
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	layout.add_child(header)
	var title = _label(_tr("CODEX", "CODEX"), 36, Color(1.0, 0.64, 0.26))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	category_select = OptionButton.new()
	category_select.custom_minimum_size = Vector2(300, 44)
	category_select.add_item(_tr("Enemies", "Inimigos"), 0)
	category_select.add_item(_tr("Elites", "Elites"), 1)
	category_select.add_item(_tr("Sins", "Pecados"), 2)
	category_select.add_item(_tr("Passives", "Passivas"), 3)
	category_select.add_item(_tr("Achievements", "Conquistas"), 4)
	category_select.item_selected.connect(func(_index): _refresh_entries())
	header.add_child(category_select)

	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	entries_list = VBoxContainer.new()
	entries_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries_list.add_theme_constant_override("separation", 9)
	scroll.add_child(entries_list)

	back_button = Button.new()
	back_button.text = _tr("Back", "Voltar")
	back_button.custom_minimum_size = Vector2(190, 46)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.add_theme_font_size_override("font_size", 20)
	back_button.pressed.connect(hide_overlay)
	layout.add_child(back_button)

func _refresh_entries() -> void:
	if entries_list == null:
		return
	for child in entries_list.get_children():
		child.queue_free()
	match category_select.selected:
		0:
			_populate_static_entries("enemies", ENEMY_ENTRIES)
		1:
			_populate_static_entries("elites", ELITE_ENTRIES)
		2:
			_populate_static_entries("sins", SIN_ENTRIES)
		3:
			_populate_passives()
		4:
			_populate_achievements()

func _populate_static_entries(category: String, entries: Array) -> void:
	for entry in entries:
		var discovered = Global.is_codex_discovered(category, str(entry.id))
		var name = _tr(str(entry.en), str(entry.pt)) if discovered else "???"
		var description = _tr(str(entry.en_desc), str(entry.pt_desc)) if discovered else _tr("Not encountered yet.", "Ainda nao encontrado.")
		entries_list.add_child(_entry_card(name, description, discovered))

func _populate_passives() -> void:
	var all_options: Array = []
	all_options.append_array(Global.PASSIVE_UPGRADE_OPTIONS)
	all_options.append_array(Global.CURSED_PASSIVE_OPTIONS)
	all_options.append_array(Global.RARE_PASSIVE_OPTIONS)
	all_options.append_array(Global.BOSS_REWARD_OPTIONS)
	for option in all_options:
		var option_id = str(option.get("id", ""))
		var discovered = Global.is_codex_discovered("passives", option_id)
		var name = I18n.option_text(option_id, str(option.get("text", option.get("name", option_id)))) if discovered else "???"
		var description = I18n.option_description(option_id, str(option.get("description", ""))) if discovered else _tr("Not encountered yet.", "Ainda nao encontrada.")
		entries_list.add_child(_entry_card(name, description, discovered))

func _populate_achievements() -> void:
	var summary = I18n.t("achievement.summary", [
		AchievementManager.get_unlocked_count(),
		AchievementManager.get_definitions().size(),
	])
	entries_list.add_child(_entry_card(I18n.t("achievement.category"), summary, true))
	for definition in AchievementManager.get_definitions():
		var achievement_id = str(definition.get("id", ""))
		var unlocked = AchievementManager.is_unlocked(achievement_id)
		var hidden = bool(definition.get("hidden", false))
		var title = I18n.t("achievement.%s.name" % achievement_id)
		var description = I18n.t("achievement.%s.description" % achievement_id)
		if hidden and not unlocked:
			title = I18n.t("achievement.hidden_name")
			description = I18n.t("achievement.hidden_description")
		elif not unlocked and AchievementManager.get_target(achievement_id) > 1:
			description += "\n" + I18n.t("achievement.progress", [
				AchievementManager.get_progress(achievement_id),
				AchievementManager.get_target(achievement_id),
			])
		entries_list.add_child(_entry_card(title, description, unlocked))

func _entry_card(title: String, description: String, discovered: bool) -> Button:
	var card = Button.new()
	card.custom_minimum_size = Vector2(0, 82)
	card.text = "%s\n%s" % [title, description]
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_theme_font_size_override("font_size", 17)
	card.add_theme_color_override("font_color", Color(0.94, 0.87, 0.76) if discovered else Color(0.55, 0.52, 0.52))
	var card_style = _style(
		Color(0.12, 0.032, 0.045, 0.98) if discovered else Color(0.045, 0.035, 0.04, 0.96),
		Color(0.62, 0.16, 0.1) if discovered else Color(0.25, 0.22, 0.23),
		2
	)
	card.add_theme_stylebox_override("normal", card_style)
	card.add_theme_stylebox_override("hover", card_style)
	var focus_style = card_style.duplicate()
	focus_style.border_color = Color(1.0, 0.65, 0.22)
	focus_style.set_border_width_all(3)
	card.add_theme_stylebox_override("focus", focus_style)
	return card

func _tr(en: String, pt: String) -> String:
	return en if I18n.current_language == I18n.LANG_EN else pt

func _label(text: String, size: int, color: Color) -> Label:
	var result = Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.add_theme_constant_override("outline_size", 3)
	return result

func _style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(5)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style
