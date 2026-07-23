extends Node2D

const PLAYER_PATH: NodePath = "/root/GameScene/Player"
const CAMERA_PATH: NodePath = "/root/GameScene/Player/Camera2D"

var player
var camera

@onready var boxStats = $HBoxContainer

var hud_offset: Vector2 = global_position
var level_up_popup
var active_skill_title_label: Label
var active_skill_e_label: Label
var active_skill_r_label: Label
var passive_status_label: Label
var arm_mutation_tooltip_area: Control
var special_passive_tooltip_area: Control
var skill_status_top_background: TextureRect
var skill_status_list_background: NinePatchRect
var arm_mutation_toast_layer: CanvasLayer
var arm_mutation_toast: Button
var arm_mutation_toast_tween: Tween
var arm_mutation_popup_owns_pause: bool = false
var skill_hud_font_layout_signature: String = ""
const SKILL_STATUS_TOP_TEXTURE = preload("res://Sprites/Menu/hud_skills_and_passives.png")
const SKILL_STATUS_LIST_TEXTURE = preload("res://Sprites/Menu/hud_list_of_passives.png")
const HUD_PIXEL_FONT = preload("res://Fonts/cg-pixel-4x5.otf")
const SKILL_STATUS_POSITION = Vector2(10.0, 86.0)
const SKILL_STATUS_SCALE = 3.0
const SKILL_STATUS_TOP_SIZE = Vector2(69.0, 40.0) * SKILL_STATUS_SCALE
const SKILL_STATUS_LIST_WIDTH = 69.0 * SKILL_STATUS_SCALE
const SKILL_STATUS_LIST_MIN_HEIGHT = 10.0 * SKILL_STATUS_SCALE
const SKILL_STATUS_LIST_VERTICAL_PADDING = 10.0
const SKILL_STATUS_PASSIVE_LINE_HEIGHT = 21.0
const SKILL_STATUS_ARM_MUTATION_LINE_COUNT = 4
const SKILL_STATUS_SPECIAL_PASSIVE_LINE_COUNT = 6
const SKILL_STATUS_LIST_PATCH_LEFT = 3
const SKILL_STATUS_LIST_PATCH_RIGHT = 6
const SKILL_STATUS_LIST_PATCH_BOTTOM = 6
const ACTIVE_SKILL_TITLE_OFFSET = Vector2(10.0, 4.0)
const ACTIVE_SKILL_E_OFFSET = Vector2(46.0, 28.0)
const ACTIVE_SKILL_R_OFFSET = Vector2(46.0, 62.0)
const SKILL_STATUS_BACKGROUND_ALPHA = 0.72
const SKILL_STATUS_LABEL_ALPHA = 0.88
const SKILL_STATUS_Z_INDEX: int = 2
const ARM_MUTATION_TOAST_SIZE: Vector2 = Vector2(650.0, 205.0)
const ARM_MUTATION_TOAST_LAYER: int = 125
const ARM_MUTATION_TOAST_SCREEN_MARGIN: float = 24.0

func _ready() -> void:
	player = get_node_or_null(PLAYER_PATH)
	camera = get_node_or_null(CAMERA_PATH)
	_setup_skill_status_background()
	_setup_active_skill_hud_labels()
	_setup_passive_status_label()
	I18n.language_changed.connect(_on_language_changed)
	
	level_up_popup = preload("res://Cenas/HUDs/levelUpPopup.tscn").instantiate()
	add_child(level_up_popup)
	level_up_popup.connect("option_selected", Callable(self, "_apply_effect"))
	level_up_popup.connect("active_discard_selected", Callable(self, "_on_active_discard_selected"))
	level_up_popup.connect("rare_discard_selected", Callable(self, "_on_rare_discard_selected"))
	level_up_popup.connect("boss_passive_discard_selected", Callable(self, "_on_boss_passive_discard_selected"))
	
	if player and camera:
		hud_offset = global_position - camera.global_position

		# Conecte os sinais do jogador ao HUD
		player.connect("hp_updated", Callable(self, "_on_hp_updated"))
		player.connect("xp_updated", Callable(self, "_on_xp_updated"))
		player.connect("level_updated", Callable(self, "_on_level_updated"))
		player.connect("stats_updated", Callable(self, "_update_status_hud_labels"))
		if player.has_signal("arm_mutation_unlocked"):
			player.connect("arm_mutation_unlocked", Callable(self, "_on_arm_mutation_unlocked"))
		_refresh_localized_text()
		_update_status_hud_labels()
	else:
		print("Player or camera not found!")

func _process(_delta: float) -> void:
	_update_status_hud_labels()

func _on_language_changed(_language: String) -> void:
	_refresh_localized_text()
	_update_status_hud_labels()

func _refresh_localized_text() -> void:
	if active_skill_title_label != null:
		active_skill_title_label.text = I18n.t("hud.active_skills")
		active_skill_title_label.tooltip_text = Global.wrap_tooltip_text(I18n.t("hud.active_skills_tooltip"))
	if passive_status_label != null and passive_status_label.text == "":
		passive_status_label.text = "- %s" % I18n.t("common.none")
	var level_label = get_node_or_null("Label")
	if level_label is Label and player != null:
		(level_label as Label).text = I18n.t("level.label", [int(player.get("level")) if player.get("level") != null else 1])

func _setup_active_skill_hud_labels() -> void:
	active_skill_title_label = get_node_or_null("ActiveSkillHudTitle")
	if active_skill_title_label == null:
		active_skill_title_label = _create_active_skill_hud_title_label()
	_style_active_skill_hud_title_label(active_skill_title_label)
	_apply_skill_status_label_alpha(active_skill_title_label)

	active_skill_e_label = get_node_or_null("ActiveSkillHudE")
	if active_skill_e_label == null:
		active_skill_e_label = _create_active_skill_hud_label("ActiveSkillHudE")
	active_skill_e_label.mouse_filter = Control.MOUSE_FILTER_PASS
	active_skill_e_label.position = SKILL_STATUS_POSITION + ACTIVE_SKILL_E_OFFSET
	_apply_skill_status_label_alpha(active_skill_e_label)

	active_skill_r_label = get_node_or_null("ActiveSkillHudR")
	if active_skill_r_label == null:
		active_skill_r_label = _create_active_skill_hud_label("ActiveSkillHudR")
	active_skill_r_label.mouse_filter = Control.MOUSE_FILTER_PASS
	active_skill_r_label.position = SKILL_STATUS_POSITION + ACTIVE_SKILL_R_OFFSET
	_apply_skill_status_label_alpha(active_skill_r_label)

func _setup_skill_status_background() -> void:
	var existing_background = get_node_or_null("SkillStatusBackground")
	if existing_background != null:
		remove_child(existing_background)
		existing_background.queue_free()

	skill_status_top_background = _get_or_create_skill_status_texture_rect("SkillStatusTopBackground")
	skill_status_top_background.position = SKILL_STATUS_POSITION
	skill_status_top_background.size = SKILL_STATUS_TOP_SIZE
	skill_status_top_background.texture = SKILL_STATUS_TOP_TEXTURE
	skill_status_top_background.stretch_mode = TextureRect.STRETCH_SCALE
	skill_status_top_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	skill_status_top_background.self_modulate = Color(1.0, 1.0, 1.0, SKILL_STATUS_BACKGROUND_ALPHA)
	skill_status_top_background.z_index = SKILL_STATUS_Z_INDEX

	skill_status_list_background = _get_or_create_skill_status_nine_patch("SkillStatusListBackground")
	skill_status_list_background.position = SKILL_STATUS_POSITION + Vector2(0.0, SKILL_STATUS_TOP_SIZE.y)
	skill_status_list_background.size = Vector2(SKILL_STATUS_LIST_WIDTH, SKILL_STATUS_LIST_MIN_HEIGHT)
	skill_status_list_background.texture = SKILL_STATUS_LIST_TEXTURE
	skill_status_list_background.patch_margin_left = SKILL_STATUS_LIST_PATCH_LEFT
	skill_status_list_background.patch_margin_right = SKILL_STATUS_LIST_PATCH_RIGHT
	skill_status_list_background.patch_margin_bottom = SKILL_STATUS_LIST_PATCH_BOTTOM
	skill_status_list_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	skill_status_list_background.self_modulate = Color(1.0, 1.0, 1.0, SKILL_STATUS_BACKGROUND_ALPHA)
	skill_status_list_background.z_index = SKILL_STATUS_Z_INDEX

	move_child(skill_status_top_background, 0)
	move_child(skill_status_list_background, 1)

func _get_or_create_skill_status_texture_rect(node_name: String) -> TextureRect:
	var existing_node = get_node_or_null(node_name)
	if existing_node is TextureRect:
		return existing_node as TextureRect

	if existing_node != null:
		remove_child(existing_node)
		existing_node.queue_free()

	var texture_rect = TextureRect.new()
	texture_rect.name = node_name
	texture_rect.z_index = SKILL_STATUS_Z_INDEX
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(texture_rect)
	return texture_rect

func _get_or_create_skill_status_nine_patch(node_name: String) -> NinePatchRect:
	var existing_node = get_node_or_null(node_name)
	if existing_node is NinePatchRect:
		return existing_node as NinePatchRect

	if existing_node != null:
		remove_child(existing_node)
		existing_node.queue_free()

	var nine_patch = NinePatchRect.new()
	nine_patch.name = node_name
	nine_patch.z_index = SKILL_STATUS_Z_INDEX
	nine_patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(nine_patch)
	return nine_patch

func _setup_passive_status_label() -> void:
	passive_status_label = get_node_or_null("PassiveStatusHud")
	if passive_status_label != null:
		passive_status_label.mouse_filter = Control.MOUSE_FILTER_PASS
		passive_status_label.z_index = SKILL_STATUS_Z_INDEX
		_apply_skill_status_label_alpha(passive_status_label)
		_setup_passive_tooltip_areas()
		return

	passive_status_label = Label.new()
	passive_status_label.name = "PassiveStatusHud"
	passive_status_label.position = SKILL_STATUS_POSITION + Vector2(10.0, SKILL_STATUS_TOP_SIZE.y + 5.0)
	passive_status_label.size = Vector2(SKILL_STATUS_LIST_WIDTH - 20.0, SKILL_STATUS_LIST_MIN_HEIGHT)
	passive_status_label.z_index = SKILL_STATUS_Z_INDEX
	passive_status_label.mouse_filter = Control.MOUSE_FILTER_PASS
	passive_status_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	passive_status_label.add_theme_constant_override("outline_size", 3)
	passive_status_label.add_theme_font_size_override("font_size", 11)
	passive_status_label.add_theme_constant_override("line_spacing", 4)
	passive_status_label.text = "- %s" % I18n.t("common.none")
	passive_status_label.tooltip_text = ""
	_apply_skill_status_label_alpha(passive_status_label)
	add_child(passive_status_label)
	_setup_passive_tooltip_areas()

func _setup_passive_tooltip_areas() -> void:
	arm_mutation_tooltip_area = _get_or_create_passive_tooltip_area("ArmMutationTooltipArea")
	special_passive_tooltip_area = _get_or_create_passive_tooltip_area("SpecialPassiveTooltipArea")
	_update_passive_tooltip_area_layout()

func _get_or_create_passive_tooltip_area(node_name: String) -> Control:
	var existing_node = get_node_or_null(node_name)
	if existing_node is Control:
		return existing_node as Control

	if existing_node != null:
		remove_child(existing_node)
		existing_node.queue_free()

	var area = Control.new()
	area.name = node_name
	area.z_index = 4
	area.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(area)
	return area

func _create_active_skill_hud_label(label_name: String) -> Label:
	var label = Label.new()
	label.name = label_name
	label.size = Vector2(SKILL_STATUS_LIST_WIDTH - 56.0, 20.0)
	label.z_index = SKILL_STATUS_Z_INDEX
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_font_size_override("font_size", 13)
	label.text = I18n.t("common.none")
	_apply_skill_status_label_alpha(label)
	add_child(label)
	return label

func _create_active_skill_hud_title_label() -> Label:
	var label = Label.new()
	label.name = "ActiveSkillHudTitle"
	add_child(label)
	return label

func _style_active_skill_hud_title_label(label: Label) -> void:
	if label == null:
		return

	label.position = SKILL_STATUS_POSITION + ACTIVE_SKILL_TITLE_OFFSET
	label.size = Vector2(SKILL_STATUS_LIST_WIDTH - 20.0, 20.0)
	label.z_index = SKILL_STATUS_Z_INDEX
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	label.add_theme_font_override("font", HUD_PIXEL_FONT)
	label.add_theme_constant_override("outline_size", 0)
	label.add_theme_font_size_override("font_size", 14)
	label.text = I18n.t("hud.active_skills")
	label.tooltip_text = Global.wrap_tooltip_text(I18n.t("hud.active_skills_tooltip"))

func _apply_skill_status_label_alpha(label: Label) -> void:
	if label == null:
		return

	label.self_modulate = Color(1.0, 1.0, 1.0, SKILL_STATUS_LABEL_ALPHA)

func _update_active_skill_hud_labels() -> void:
	if player == null:
		return

	_update_active_skill_hud_label(active_skill_e_label, "E")
	_update_active_skill_hud_label(active_skill_r_label, "R")

func _update_status_hud_labels() -> void:
	_update_active_skill_hud_labels()
	_update_passive_status_label()
	_fit_skill_hud_font_sizes()

func _fit_skill_hud_font_sizes() -> void:
	var signature = "%s|%s|%s|%s|%.1f" % [
		active_skill_title_label.text if active_skill_title_label != null else "",
		active_skill_e_label.text if active_skill_e_label != null else "",
		active_skill_r_label.text if active_skill_r_label != null else "",
		passive_status_label.text if passive_status_label != null else "",
		SKILL_STATUS_LIST_WIDTH,
	]
	if signature == skill_hud_font_layout_signature:
		return
	skill_hud_font_layout_signature = signature

	_fit_label_group_to_width([active_skill_title_label, active_skill_e_label, active_skill_r_label], 10, 18)
	_fit_label_group_to_width([passive_status_label], 9, 16)

func _fit_label_group_to_width(label_candidates: Array, minimum_size: int, maximum_size: int) -> void:
	var labels: Array[Label] = []
	for candidate in label_candidates:
		if candidate is Label:
			labels.append(candidate as Label)
	if labels.is_empty():
		return

	var selected_size = minimum_size
	for candidate_size in range(maximum_size, minimum_size - 1, -1):
		var all_fit = true
		for label in labels:
			var available_width = maxf(label.size.x - 4.0, 1.0)
			var font = label.get_theme_font("font")
			var outline = label.get_theme_constant("outline_size")
			for line in label.text.split("\n"):
				var text_width = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, candidate_size).x + float(outline * 2)
				if text_width > available_width:
					all_fit = false
					break
			if not all_fit:
				break
		if all_fit:
			selected_size = candidate_size
			break

	for label in labels:
		label.add_theme_font_size_override("font_size", selected_size)

func _update_passive_status_label() -> void:
	if passive_status_label == null or player == null:
		return

	var boss_summaries: Array = []
	if player.has_method("get_equipped_boss_passive_summaries"):
		boss_summaries = player.get_equipped_boss_passive_summaries()

	var rare_summaries: Array = []
	if player.has_method("get_equipped_rare_passive_summaries"):
		rare_summaries = player.get_equipped_rare_passive_summaries()

	var mutation_summaries: Array = []
	if player.has_method("get_arm_mutation_summaries"):
		mutation_summaries = player.get_arm_mutation_summaries()

	var passive_lines := PackedStringArray([
		I18n.t("hud.arm_mutations"),
		_get_special_passive_slot_text(mutation_summaries, 0),
		_get_special_passive_slot_text(mutation_summaries, 1),
		_get_special_passive_slot_text(mutation_summaries, 2),
		I18n.t("hud.boss_passives"),
		_get_special_passive_slot_text(boss_summaries, 0),
		_get_special_passive_slot_text(boss_summaries, 1),
		I18n.t("hud.rare_passives"),
		_get_special_passive_slot_text(rare_summaries, 0),
		_get_special_passive_slot_text(rare_summaries, 1)
	])
	passive_status_label.text = "\n".join(passive_lines)
	passive_status_label.tooltip_text = ""
	_update_passive_tooltips(mutation_summaries, boss_summaries, rare_summaries)
	_update_skill_status_background(passive_lines.size())
	_update_passive_tooltip_area_layout()

func _get_special_passive_slot_text(summaries: Array, slot_index: int) -> String:
	if slot_index >= summaries.size():
		return "- %s" % I18n.t("common.none")

	var summary = summaries[slot_index]
	return "- %s" % str(summary.get("name", I18n.t("hud.passive_fallback")))

func _update_passive_tooltips(mutation_summaries: Array, boss_summaries: Array, rare_summaries: Array) -> void:
	if arm_mutation_tooltip_area == null or special_passive_tooltip_area == null:
		_setup_passive_tooltip_areas()

	var mutation_tooltip = _build_arm_mutation_tooltip(mutation_summaries)
	var special_tooltip = _build_special_passive_tooltip(boss_summaries, rare_summaries)
	if arm_mutation_tooltip_area != null:
		arm_mutation_tooltip_area.tooltip_text = Global.wrap_tooltip_text(mutation_tooltip)
	if special_passive_tooltip_area != null:
		special_passive_tooltip_area.tooltip_text = Global.wrap_tooltip_text(special_tooltip)

func _build_arm_mutation_tooltip(mutation_summaries: Array) -> String:
	var tooltip_lines := PackedStringArray([I18n.t("hud.arm_mutations_tooltip")])
	if mutation_summaries.is_empty():
		tooltip_lines.append("- %s" % I18n.t("common.none"))
		return "\n".join(tooltip_lines)

	for summary in mutation_summaries:
		_append_named_tooltip_entry(tooltip_lines, summary)
	return "\n".join(tooltip_lines)

func _build_special_passive_tooltip(boss_summaries: Array, rare_summaries: Array) -> String:
	var tooltip_lines := PackedStringArray()
	_append_tooltip_section(tooltip_lines, I18n.t("hud.boss_passives_tooltip"), boss_summaries)
	tooltip_lines.append("")
	_append_tooltip_section(tooltip_lines, I18n.t("hud.rare_passives_tooltip"), rare_summaries)
	return "\n".join(tooltip_lines)

func _append_tooltip_section(tooltip_lines: PackedStringArray, section_name: String, summaries: Array) -> void:
	tooltip_lines.append(section_name)
	if summaries.is_empty():
		tooltip_lines.append("- %s" % I18n.t("common.none"))
		return

	for summary in summaries:
		_append_named_tooltip_entry(tooltip_lines, summary)

func _append_named_tooltip_entry(tooltip_lines: PackedStringArray, summary: Dictionary) -> void:
	var passive_name = str(summary.get("name", I18n.t("hud.passive_fallback")))
	var passive_description = str(summary.get("description", ""))
	if passive_description == "":
		tooltip_lines.append("- %s" % passive_name)
	else:
		tooltip_lines.append("- %s: %s" % [passive_name, passive_description])

func _update_skill_status_background(line_count: int) -> void:
	if skill_status_list_background == null or passive_status_label == null:
		return

	var safe_line_count = max(line_count, 1)
	var list_height = max(SKILL_STATUS_LIST_MIN_HEIGHT, SKILL_STATUS_LIST_VERTICAL_PADDING + float(safe_line_count) * SKILL_STATUS_PASSIVE_LINE_HEIGHT)
	skill_status_list_background.size = Vector2(SKILL_STATUS_LIST_WIDTH, list_height)
	passive_status_label.size = Vector2(SKILL_STATUS_LIST_WIDTH - 20.0, max(20.0, list_height - 10.0))

func _update_passive_tooltip_area_layout() -> void:
	if passive_status_label == null:
		return

	var tooltip_position = passive_status_label.position
	var tooltip_width = passive_status_label.size.x
	var arm_height = float(SKILL_STATUS_ARM_MUTATION_LINE_COUNT) * SKILL_STATUS_PASSIVE_LINE_HEIGHT
	var special_height = float(SKILL_STATUS_SPECIAL_PASSIVE_LINE_COUNT) * SKILL_STATUS_PASSIVE_LINE_HEIGHT

	if arm_mutation_tooltip_area != null:
		arm_mutation_tooltip_area.position = tooltip_position
		arm_mutation_tooltip_area.size = Vector2(tooltip_width, arm_height)
	if special_passive_tooltip_area != null:
		special_passive_tooltip_area.position = tooltip_position + Vector2(0.0, arm_height)
		special_passive_tooltip_area.size = Vector2(tooltip_width, special_height)

func _update_active_skill_hud_label(label: Label, slot: String) -> void:
	if label == null:
		return

	var slots = player.get_active_ability_slots() if player.has_method("get_active_ability_slots") else {}
	var ability_id = str(slots.get(slot, ""))
	if ability_id == "":
		label.text = I18n.t("common.none")
		label.tooltip_text = Global.wrap_tooltip_text(I18n.t("hud.no_active"))
		return

	var ability_name = player.get_active_ability_name(ability_id) if player.has_method("get_active_ability_name") else ability_id
	var cooldown = player.get_active_slot_cooldown(slot) if player.has_method("get_active_slot_cooldown") else 0.0
	if cooldown > 0.0:
		label.text = "%s (%.1fs)" % [ability_name, cooldown]
	else:
		label.text = ability_name

	var tooltip = player.get_active_ability_description(ability_id) if player.has_method("get_active_ability_description") else ability_name
	label.tooltip_text = Global.wrap_tooltip_text(tooltip)

func _on_hp_updated(current_hp, max_health) -> void:
	$ProgressBar2.max_value = max_health
	$ProgressBar2.value = current_hp

func _on_xp_updated(current_xp, xp_to_next_level) -> void:
	$ProgressBar.value = current_xp
	$ProgressBar.max_value = xp_to_next_level

func _on_level_updated(level, current_xp, xp_to_next_level) -> void:
	$Label.text = I18n.t("level.label", [level])
	$ProgressBar.value = current_xp
	$ProgressBar.max_value = xp_to_next_level
	level_up_popup.show_popup(player.level_up_context, player.level_up_boss_pecado)

func _on_arm_mutation_unlocked(tier: int, _arm_id: String, mutation_name: String, mutation_description: String, color: Color) -> void:
	_show_arm_mutation_toast(tier, mutation_name, mutation_description, color)

func _show_arm_mutation_toast(tier: int, mutation_name: String, mutation_description: String, color: Color) -> void:
	_clear_arm_mutation_toast()
	arm_mutation_popup_owns_pause = not get_tree().paused
	get_tree().paused = true

	arm_mutation_toast_layer = CanvasLayer.new()
	arm_mutation_toast_layer.name = "ArmMutationToastLayer"
	arm_mutation_toast_layer.layer = ARM_MUTATION_TOAST_LAYER
	arm_mutation_toast_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(arm_mutation_toast_layer)

	var root = Control.new()
	root.name = "ArmMutationToastRoot"
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	arm_mutation_toast_layer.add_child(root)

	var panel = Button.new()
	panel.name = "ArmMutationToast"
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.custom_minimum_size = _get_arm_mutation_toast_size()
	panel.size = _get_arm_mutation_toast_size()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.focus_mode = Control.FOCUS_ALL
	panel.text = ""
	panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var panel_style = PopupStyle.make_style(PopupStyle.PANEL_BG, Color(color.r, color.g, color.b, 0.95), 3)
	for style_name in ["normal", "hover", "pressed", "focus"]:
		panel.add_theme_stylebox_override(style_name, panel_style)
	_anchor_arm_mutation_toast_panel(panel)
	root.add_child(panel)
	arm_mutation_toast = panel
	panel.pressed.connect(_dismiss_arm_mutation_popup)

	var margin = MarginContainer.new()
	margin.process_mode = Node.PROCESS_MODE_ALWAYS
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var layout = VBoxContainer.new()
	layout.process_mode = Node.PROCESS_MODE_ALWAYS
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(layout)

	var title = _make_arm_mutation_toast_label(
		I18n.t("arm_mutation.toast_title", [_get_arm_mutation_tier_label(tier)]),
		Color(color.r, color.g, color.b, 1.0),
		22,
		5
	)
	layout.add_child(title)

	var name_label = _make_arm_mutation_toast_label(mutation_name, PopupStyle.TITLE_COLOR, 16, 4)
	layout.add_child(name_label)

	var description = _make_arm_mutation_toast_label(mutation_description, PopupStyle.TEXT_COLOR, 10, 3)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(_get_arm_mutation_toast_size().x - 44.0, 34.0)
	layout.add_child(description)

	var dismiss_hint = _make_arm_mutation_toast_label(I18n.t("arm_mutation.dismiss_hint"), Color(0.55, 0.82, 1.0), 10, 3)
	layout.add_child(dismiss_hint)

	arm_mutation_toast_tween = create_tween().bind_node(panel)
	arm_mutation_toast_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	arm_mutation_toast_tween.tween_property(panel, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	panel.grab_focus.call_deferred()

func _make_arm_mutation_toast_label(text: String, color: Color, font_size: int, outline_size: int) -> Label:
	var label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", HUD_PIXEL_FONT)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", _get_web_safe_toast_outline_size(outline_size))
	label.add_theme_font_size_override("font_size", font_size)
	label.text = text
	return label

func _get_arm_mutation_toast_size() -> Vector2:
	var viewport_size = get_viewport_rect().size
	var max_width = max(viewport_size.x - ARM_MUTATION_TOAST_SCREEN_MARGIN * 2.0, 260.0)
	return Vector2(min(ARM_MUTATION_TOAST_SIZE.x, max_width), ARM_MUTATION_TOAST_SIZE.y)

func _anchor_arm_mutation_toast_panel(panel: Control) -> void:
	var toast_size = _get_arm_mutation_toast_size()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -toast_size.x * 0.5
	panel.offset_right = toast_size.x * 0.5
	panel.offset_top = -toast_size.y * 0.5
	panel.offset_bottom = toast_size.y * 0.5

func _get_web_safe_toast_outline_size(outline_size: int) -> int:
	if Global.is_web_build():
		return mini(outline_size, 2)
	return outline_size

func _get_arm_mutation_tier_label(tier: int) -> String:
	match tier:
		1:
			return "I"
		2:
			return "II"
		3:
			return "III"
	return str(tier)

func _clear_arm_mutation_toast() -> void:
	if arm_mutation_toast_tween != null:
		arm_mutation_toast_tween.kill()
		arm_mutation_toast_tween = null
	if is_instance_valid(arm_mutation_toast_layer):
		arm_mutation_toast_layer.queue_free()
	arm_mutation_toast_layer = null
	if is_instance_valid(arm_mutation_toast):
		arm_mutation_toast.queue_free()
	arm_mutation_toast = null
	if arm_mutation_popup_owns_pause and get_tree() != null:
		get_tree().paused = false
	arm_mutation_popup_owns_pause = false

func _dismiss_arm_mutation_popup() -> void:
	_clear_arm_mutation_toast()

func _apply_effect(option) -> void:
	var option_data = option if option is Dictionary else {}
	var option_id = str(option_data.get("id", option))
	var stat_multiplier = _get_option_stat_multiplier(option_data)
	var percent_effects = _get_option_percent_effects(option_data, option_id, stat_multiplier)

	if player.has_method("is_active_ability_id") and player.is_active_ability_id(option_id):
		if not player.learn_active_ability(option_id):
			_show_active_discard_popup(option_id)
		else:
			_record_applied_upgrade(option_data)
		return

	if _is_boss_passive_option(option_id):
		var can_equip_boss_passive = player.can_equip_boss_passive(option_id) if player.has_method("can_equip_boss_passive") else true
		if not can_equip_boss_passive:
			var equipped_boss_passives = player.get_boss_passive_options() if player.has_method("get_boss_passive_options") else []
			level_up_popup.show_boss_passive_discard_popup(equipped_boss_passives, option_id)
			return

		_equip_boss_passive_option(option_id)
		return

	if _is_rare_option(option_id):
		var can_equip_rare = player.can_equip_rare_passive(option_id) if player.has_method("can_equip_rare_passive") else player.current_rare_option == "" or player.current_rare_option == option_id
		if not can_equip_rare:
			var equipped_rares = player.get_rare_passive_options() if player.has_method("get_rare_passive_options") else [player.current_rare_option]
			level_up_popup.show_rare_discard_popup(equipped_rares, option_id)
			return

		_equip_rare_option(option_id)
		return

	match option_id:
		"endless_heal_potion":
			player.heal(float(player.max_health) * 0.25 * stat_multiplier)
			_on_hp_updated(player.current_health, player.max_health)
		"endless_greater_heal_potion":
			player.heal(float(player.max_health) * 0.50 * stat_multiplier)
			_on_hp_updated(player.current_health, player.max_health)
		"endless_reroll_token":
			if player.has_method("add_reroll_tokens"):
				player.add_reroll_tokens(maxi(1, int(round(stat_multiplier))))
		"option_1":
			player.add_recoil_force_bonus(0.05 * stat_multiplier)
		"option_2":
			if player.has_method("apply_common_health_upgrade"):
				player.apply_common_health_upgrade(stat_multiplier)
			_on_hp_updated(player.current_health, player.max_health)
		"option_3":
			if player.has_method("apply_common_attack_upgrade"):
				player.apply_common_attack_upgrade(stat_multiplier)
		"option_4":
			player.add_attack_speed_bonus(0.05 * stat_multiplier)
		"option_5":
			player.add_projectile_size_bonus(0.05 * stat_multiplier)
		"option_6":
			player.add_heal_after_wave_bonus(0.03 * stat_multiplier)
		"option_7":
			player.add_dash_cooldown_reduction_bonus(0.05 * stat_multiplier)
		"glass_canon":
			_apply_attack_percent(float(percent_effects.get("attack", 0.5 * stat_multiplier)))
			_apply_max_health_percent(float(percent_effects.get("health", -0.3 * stat_multiplier)))
		"tanky":
			_apply_max_health_percent(float(percent_effects.get("health", 0.5 * stat_multiplier)))
			_apply_attack_percent(float(percent_effects.get("attack", -0.3 * stat_multiplier)))
		"deadly_slow":
			_apply_recoil_force_percent(float(percent_effects.get("recoil_force", -0.2 * stat_multiplier)))
			_apply_attack_percent(float(percent_effects.get("attack", 0.4 * stat_multiplier)))
		"fast_but_small":
			player.add_attack_speed_bonus(float(percent_effects.get("atk_speed", 0.3 * stat_multiplier)))
			player.add_projectile_size_bonus(float(percent_effects.get("bullet_size", -0.3 * stat_multiplier)))
		"blood_tax":
			_apply_attack_percent(float(percent_effects.get("attack", 0.4 * stat_multiplier)))
			if player.has_method("add_healing_received_multiplier_bonus"):
				player.add_healing_received_multiplier_bonus(float(percent_effects.get("heal", -0.45 * stat_multiplier)))
		"cursed_luck":
			if player.has_method("add_special_level_up_chance_bonus"):
				player.add_special_level_up_chance_bonus(max(1.5 * stat_multiplier - 1.0, 0.0))
			if player.has_method("add_damage_taken_multiplier_bonus"):
				player.add_damage_taken_multiplier_bonus(float(percent_effects.get("damage_taken", 0.3 * stat_multiplier)))
			else:
				player.damage_taken_multiplier *= _get_safe_stat_multiplier(float(percent_effects.get("damage_taken", 0.3 * stat_multiplier)))
		"thin_blood":
			_apply_max_health_percent(float(percent_effects.get("health", -0.4 * stat_multiplier)))
			if player.has_method("add_healing_received_multiplier_bonus"):
				player.add_healing_received_multiplier_bonus(float(percent_effects.get("heal", 1.0 * stat_multiplier)))
		"sloth_slow_aura":
			player.sloth_slow_aura_enabled = true
		"gluttony_heal_kill":
			player.gluttony_heal_kill_enabled = true
		"envy_mirror_shot":
			player.envy_mirror_shot_enabled = true
		"wrath_overheat":
			player.wrath_overheat_enabled = true
		"lust_for_vengeance":
			player.lust_for_vengeance_enabled = true
		"greed_cursed_level":
			_enable_golden_debt()

	_record_applied_upgrade(option_data)
	_finish_effect_application()

func _get_option_stat_multiplier(option_data: Dictionary) -> float:
	return max(float(option_data.get("stat_multiplier", 1.0)), 0.0)

func _get_option_percent_effects(option_data: Dictionary, option_id: String, stat_multiplier: float) -> Dictionary:
	var source_data = option_data
	if source_data.is_empty():
		source_data = _get_option_by_id(option_id)

	var text = str(source_data.get("text", ""))
	var effects = {}
	var regex = RegEx.new()
	if regex.compile("([^,()]+)\\s*\\(([+-])([0-9]+(?:\\.[0-9]+)?)%\\)") != OK:
		return effects

	for match_result in regex.search_all(text):
		var groups = match_result.get_strings()
		if groups.size() < 4:
			continue

		var effect_key = _normalize_percent_effect_label(groups[1])
		if effect_key == "":
			continue

		var sign_multiplier = -1.0 if groups[2] == "-" else 1.0
		effects[effect_key] = sign_multiplier * float(groups[3]) * 0.01 * stat_multiplier

	return effects

func _normalize_percent_effect_label(raw_label: String) -> String:
	return raw_label.strip_edges().to_lower().replace("-", "_").replace(" ", "_")

func _apply_attack_percent(percent: float) -> void:
	player.attack_damage *= _get_safe_stat_multiplier(percent)

func _apply_recoil_force_percent(percent: float) -> void:
	if percent >= 0.0:
		player.add_recoil_force_bonus(percent)
		return

	player.multiply_base_recoil_force(_get_safe_stat_multiplier(percent))

func _apply_max_health_percent(percent: float) -> void:
	var health_multiplier = _get_safe_stat_multiplier(percent)
	if percent >= 0.0:
		var health_gain = float(player.current_health) * percent
		player.max_health = max(1, int(round(float(player.max_health) * health_multiplier)))
		player.heal(health_gain)
	else:
		player.max_health = max(1, int(round(float(player.max_health) * health_multiplier)))
		player.current_health = min(player.current_health, player.max_health)

	_on_hp_updated(player.current_health, player.max_health)

func _get_safe_stat_multiplier(percent: float) -> float:
	return max(1.0 + percent, 0.01)

func _record_applied_upgrade(option_data: Dictionary) -> void:
	if player and player.has_method("record_upgrade"):
		player.record_upgrade(option_data)

func _is_rare_option(option: String) -> bool:
	return option in Global.RARE_OPTION_IDS

func _is_boss_passive_option(option: String) -> bool:
	return option in Global.SIN_PASSIVE_IDS

func _get_option_by_id(option_id: String) -> Dictionary:
	for pool in [Global.PASSIVE_UPGRADE_OPTIONS, Global.CURSED_PASSIVE_OPTIONS, Global.RARE_PASSIVE_OPTIONS, Global.BOSS_REWARD_OPTIONS]:
		for option in pool:
			if str(option.get("id", "")) == option_id:
				return option.duplicate(true)

	return { "id": option_id, "text": option_id, "description": I18n.t("common.unknown"), "rarity": "passive_common" }

func _equip_boss_passive_option(option: String) -> void:
	var already_equipped = player.has_boss_passive(option) if player.has_method("has_boss_passive") else false

	if player.has_method("equip_boss_passive_id"):
		player.equip_boss_passive_id(option)

	if not already_equipped:
		_apply_boss_passive_effect(option)
		_record_applied_upgrade(_get_option_by_id(option))
	_finish_effect_application()

func _apply_boss_passive_effect(option: String) -> void:
	match option:
		"sloth_slow_aura":
			player.sloth_slow_aura_enabled = true
		"gluttony_heal_kill":
			player.gluttony_heal_kill_enabled = true
		"envy_mirror_shot":
			player.envy_mirror_shot_enabled = true
		"wrath_overheat":
			player.wrath_overheat_enabled = true
		"lust_for_vengeance":
			player.lust_for_vengeance_enabled = true
		"greed_cursed_level":
			_enable_golden_debt()

func _remove_boss_passive_effect(option: String) -> void:
	match option:
		"sloth_slow_aura":
			player.sloth_slow_aura_enabled = false
		"gluttony_heal_kill":
			player.gluttony_heal_kill_enabled = false
		"envy_mirror_shot":
			player.envy_mirror_shot_enabled = false
		"wrath_overheat":
			player.wrath_overheat_enabled = false
		"lust_for_vengeance":
			player.lust_for_vengeance_enabled = false
		"greed_cursed_level":
			_disable_golden_debt()
	if player.has_method("clear_option_visuals"):
		player.clear_option_visuals(option)

func _enable_golden_debt() -> void:
	if player.has_method("enable_golden_debt"):
		player.enable_golden_debt()
		return

	player.greed_cursed_level_enabled = true
	player.attack_damage *= 1.2
	player.add_attack_speed_bonus(0.1)

func _disable_golden_debt() -> void:
	if player.has_method("disable_golden_debt"):
		player.disable_golden_debt()
		return

	player.greed_cursed_level_enabled = false
	player.attack_damage /= 1.2
	player.add_attack_speed_bonus(-0.1)

func _equip_rare_option(option: String) -> void:
	var already_equipped = player.has_rare_passive(option) if player.has_method("has_rare_passive") else player.current_rare_option == option

	if player.has_method("equip_rare_passive_id"):
		player.equip_rare_passive_id(option)
	else:
		player.current_rare_option = option

	if not already_equipped:
		_apply_rare_effect(option)
		_record_applied_upgrade(_get_option_by_id(option))
	_finish_effect_application()

func _apply_rare_effect(option: String) -> void:
	match option:
		"Shield_Protection":
			if player.has_method("enable_shield_protection"):
				player.enable_shield_protection()
			else:
				player.has_shield = true
		"Recoil_Explosion":
			player.recoil_explosion_enabled = true
		"Double_Dash":
			if player.has_method("enable_double_dash"):
				player.enable_double_dash()
			else:
				player.max_dash_charges = 2
				player.double_dash_charges = player.max_dash_charges
		"Offensive_Dash":
			player.offensive_dash_enabled = true
		"Thorn_Clothes":
			if player.has_method("enable_thorn_clothes"):
				player.enable_thorn_clothes()
			else:
				player.thorn_clothes_enabled = true
		"Kinetic_Reload":
			if player.has_method("enable_kinetic_reload"):
				player.enable_kinetic_reload()
			else:
				player.kinetic_reload_enabled = true
		"Splintered_Chamber":
			if player.has_method("enable_splintered_chamber"):
				player.enable_splintered_chamber()
			else:
				player.splintered_chamber_enabled = true

func _remove_rare_effect(option: String) -> void:
	match option:
		"Shield_Protection":
			if player.has_method("disable_shield_protection"):
				player.disable_shield_protection()
			else:
				player.has_shield = false
		"Recoil_Explosion":
			player.recoil_explosion_enabled = false
		"Double_Dash":
			if player.has_method("disable_double_dash"):
				player.disable_double_dash()
			else:
				player.max_dash_charges = 1
				player.double_dash_charges = min(player.double_dash_charges, player.max_dash_charges)
		"Offensive_Dash":
			player.offensive_dash_enabled = false
		"Thorn_Clothes":
			if player.has_method("disable_thorn_clothes"):
				player.disable_thorn_clothes()
			else:
				player.thorn_clothes_enabled = false
		"Kinetic_Reload":
			if player.has_method("disable_kinetic_reload"):
				player.disable_kinetic_reload()
			else:
				player.kinetic_reload_enabled = false
				player.kinetic_reload_cooldown_remaining = 0.0
		"Splintered_Chamber":
			if player.has_method("disable_splintered_chamber"):
				player.disable_splintered_chamber()
			else:
				player.splintered_chamber_enabled = false
				player.splintered_chamber_shot_count = 0
	if player.has_method("clear_option_visuals"):
		player.clear_option_visuals(option)

func _finish_effect_application() -> void:
	if player.pause_control:
		player.pause_control.update_status_labels()
	player.emit_signal("stats_updated")

func _on_active_discard_selected(discarded_slot: String, new_option: String) -> void:
	if discarded_slot == "new":
		return

	player.replace_active_ability(discarded_slot, new_option)
	_record_applied_upgrade(_get_option_by_id(new_option))
	if player.pause_control:
		player.pause_control.update_status_labels()

func _on_rare_discard_selected(discarded_option: String, old_option: String, new_option: String) -> void:
	if discarded_option == new_option:
		return

	_remove_rare_effect(discarded_option)
	if player.has_method("replace_rare_passive_id"):
		player.replace_rare_passive_id(discarded_option, new_option)
	else:
		player.current_rare_option = new_option
	_apply_rare_effect(new_option)
	_record_applied_upgrade(_get_option_by_id(new_option))
	_finish_effect_application()

func _on_boss_passive_discard_selected(discarded_option: String, old_option: String, new_option: String) -> void:
	if discarded_option == new_option:
		return

	_remove_boss_passive_effect(discarded_option)
	if player.has_method("replace_boss_passive_id"):
		player.replace_boss_passive_id(discarded_option, new_option)
	_apply_boss_passive_effect(new_option)
	_record_applied_upgrade(_get_option_by_id(new_option))
	_finish_effect_application()

func _show_active_discard_popup(option: String) -> void:
	level_up_popup.show_active_discard_popup(option, player.get_active_ability_slots())
