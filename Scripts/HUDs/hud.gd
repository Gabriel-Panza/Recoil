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
var skill_status_top_background: TextureRect
var skill_status_list_background: TextureRect
const SKILL_STATUS_TOP_TEXTURE = preload("res://Sprites/Menu/hud_skills_and_passives.png")
const SKILL_STATUS_LIST_TEXTURE = preload("res://Sprites/Menu/hud_list_of_passives.png")
const HUD_PIXEL_FONT = preload("res://Fonts/cg-pixel-4x5.otf")
const SKILL_STATUS_POSITION = Vector2(10.0, 86.0)
const SKILL_STATUS_SCALE = 3.0
const SKILL_STATUS_TOP_SIZE = Vector2(69.0, 40.0) * SKILL_STATUS_SCALE
const SKILL_STATUS_LIST_WIDTH = 69.0 * SKILL_STATUS_SCALE
const SKILL_STATUS_LIST_MIN_HEIGHT = 10.0 * SKILL_STATUS_SCALE
const SKILL_STATUS_LIST_VERTICAL_PADDING = 18.0
const SKILL_STATUS_PASSIVE_LINE_HEIGHT = 24.0
const ACTIVE_SKILL_TITLE_OFFSET = Vector2(10.0, 4.0)
const ACTIVE_SKILL_E_OFFSET = Vector2(46.0, 28.0)
const ACTIVE_SKILL_R_OFFSET = Vector2(46.0, 62.0)
const SKILL_STATUS_BACKGROUND_ALPHA = 0.72
const SKILL_STATUS_LABEL_ALPHA = 0.88

func _ready() -> void:
	player = get_node_or_null(PLAYER_PATH)
	camera = get_node_or_null(CAMERA_PATH)
	_setup_skill_status_background()
	_setup_active_skill_hud_labels()
	_setup_passive_status_label()
	
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
		_update_status_hud_labels()
	else:
		print("Jogador ou câmera não encontrados!")

func _process(_delta: float) -> void:
	_update_status_hud_labels()

func _setup_active_skill_hud_labels() -> void:
	active_skill_title_label = get_node_or_null("ActiveSkillHudTitle")
	if active_skill_title_label == null:
		active_skill_title_label = _create_active_skill_hud_title_label()
	_style_active_skill_hud_title_label(active_skill_title_label)
	_apply_skill_status_label_alpha(active_skill_title_label)

	active_skill_e_label = get_node_or_null("ActiveSkillHudE")
	if active_skill_e_label == null:
		active_skill_e_label = _create_active_skill_hud_label("ActiveSkillHudE")
	active_skill_e_label.position = SKILL_STATUS_POSITION + ACTIVE_SKILL_E_OFFSET
	_apply_skill_status_label_alpha(active_skill_e_label)

	active_skill_r_label = get_node_or_null("ActiveSkillHudR")
	if active_skill_r_label == null:
		active_skill_r_label = _create_active_skill_hud_label("ActiveSkillHudR")
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
	skill_status_top_background.self_modulate = Color(1.0, 1.0, 1.0, SKILL_STATUS_BACKGROUND_ALPHA)

	skill_status_list_background = _get_or_create_skill_status_texture_rect("SkillStatusListBackground")
	skill_status_list_background.position = SKILL_STATUS_POSITION + Vector2(0.0, SKILL_STATUS_TOP_SIZE.y)
	skill_status_list_background.size = Vector2(SKILL_STATUS_LIST_WIDTH, SKILL_STATUS_LIST_MIN_HEIGHT)
	skill_status_list_background.texture = SKILL_STATUS_LIST_TEXTURE
	skill_status_list_background.stretch_mode = TextureRect.STRETCH_SCALE
	skill_status_list_background.self_modulate = Color(1.0, 1.0, 1.0, SKILL_STATUS_BACKGROUND_ALPHA)

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
	texture_rect.z_index = 0
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(texture_rect)
	return texture_rect

func _setup_passive_status_label() -> void:
	passive_status_label = get_node_or_null("PassiveStatusHud")
	if passive_status_label != null:
		_apply_skill_status_label_alpha(passive_status_label)
		return

	passive_status_label = Label.new()
	passive_status_label.name = "PassiveStatusHud"
	passive_status_label.position = SKILL_STATUS_POSITION + Vector2(10.0, SKILL_STATUS_TOP_SIZE.y + 5.0)
	passive_status_label.size = Vector2(SKILL_STATUS_LIST_WIDTH - 20.0, SKILL_STATUS_LIST_MIN_HEIGHT)
	passive_status_label.z_index = 0
	passive_status_label.mouse_filter = Control.MOUSE_FILTER_STOP
	passive_status_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	passive_status_label.add_theme_constant_override("outline_size", 3)
	passive_status_label.add_theme_font_size_override("font_size", 13)
	passive_status_label.text = "- None"
	passive_status_label.tooltip_text = "No passive skills equipped"
	_apply_skill_status_label_alpha(passive_status_label)
	add_child(passive_status_label)

func _create_active_skill_hud_label(label_name: String) -> Label:
	var label = Label.new()
	label.name = label_name
	label.size = Vector2(SKILL_STATUS_LIST_WIDTH - 56.0, 20.0)
	label.z_index = 0
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_font_size_override("font_size", 14)
	label.text = "None"
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
	label.z_index = 0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	label.add_theme_font_override("font", HUD_PIXEL_FONT)
	label.add_theme_constant_override("outline_size", 0)
	label.add_theme_font_size_override("font_size", 15)
	label.text = "ACTIVES:"

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

func _update_passive_status_label() -> void:
	if passive_status_label == null or player == null:
		return

	var boss_summaries: Array = []
	if player.has_method("get_equipped_boss_passive_summaries"):
		boss_summaries = player.get_equipped_boss_passive_summaries()

	var rare_summaries: Array = []
	if player.has_method("get_equipped_rare_passive_summaries"):
		rare_summaries = player.get_equipped_rare_passive_summaries()

	var passive_lines := PackedStringArray([
		"BOSS PASSIVES:",
		_get_special_passive_slot_text(boss_summaries, 0),
		_get_special_passive_slot_text(boss_summaries, 1),
		"RARE PASSIVES:",
		_get_special_passive_slot_text(rare_summaries, 0),
		_get_special_passive_slot_text(rare_summaries, 1)
	])
	var tooltip_lines := PackedStringArray()
	_append_passive_tooltip_lines(tooltip_lines, "Boss Passives", boss_summaries)
	_append_passive_tooltip_lines(tooltip_lines, "Rare Passives", rare_summaries)

	passive_status_label.text = "\n".join(passive_lines)
	passive_status_label.tooltip_text = "\n".join(tooltip_lines) if not tooltip_lines.is_empty() else "No special passives equipped"
	_update_skill_status_background(passive_lines.size())

func _get_special_passive_slot_text(summaries: Array, slot_index: int) -> String:
	if slot_index >= summaries.size():
		return "- None"

	var summary = summaries[slot_index]
	return "- %s" % str(summary.get("name", "Passive"))

func _append_passive_tooltip_lines(tooltip_lines: PackedStringArray, section_name: String, summaries: Array) -> void:
	if summaries.is_empty():
		tooltip_lines.append("%s: None" % section_name)
		return

	for summary in summaries:
		var passive_name = str(summary.get("name", "Passive"))
		tooltip_lines.append("%s: %s" % [
			passive_name,
			str(summary.get("description", ""))
		])

func _update_skill_status_background(line_count: int) -> void:
	if skill_status_list_background == null or passive_status_label == null:
		return

	var safe_line_count = max(line_count, 1)
	var list_height = max(SKILL_STATUS_LIST_MIN_HEIGHT, SKILL_STATUS_LIST_VERTICAL_PADDING + float(safe_line_count) * SKILL_STATUS_PASSIVE_LINE_HEIGHT)
	skill_status_list_background.size = Vector2(SKILL_STATUS_LIST_WIDTH, list_height)
	passive_status_label.size = Vector2(SKILL_STATUS_LIST_WIDTH - 20.0, max(20.0, list_height - 10.0))

func _update_active_skill_hud_label(label: Label, slot: String) -> void:
	if label == null:
		return

	var slots = player.get_active_ability_slots() if player.has_method("get_active_ability_slots") else {}
	var ability_id = str(slots.get(slot, ""))
	if ability_id == "":
		label.text = "None"
		label.tooltip_text = "No active skill equipped"
		return

	var ability_name = player.get_active_ability_name(ability_id) if player.has_method("get_active_ability_name") else ability_id
	var cooldown = player.get_active_slot_cooldown(slot) if player.has_method("get_active_slot_cooldown") else 0.0
	if cooldown > 0.0:
		label.text = "%s (%.1fs)" % [ability_name, cooldown]
	else:
		label.text = ability_name

	label.tooltip_text = player.get_active_ability_description(ability_id) if player.has_method("get_active_ability_description") else ability_name

func _on_hp_updated(current_hp, max_health) -> void:
	$ProgressBar2.max_value = max_health
	$ProgressBar2.value = current_hp

func _on_xp_updated(current_xp, xp_to_next_level) -> void:
	$ProgressBar.value = current_xp
	$ProgressBar.max_value = xp_to_next_level

func _on_level_updated(level, current_xp, xp_to_next_level) -> void:
	$Label.text = "Level: %d" % level
	$ProgressBar.value = current_xp
	$ProgressBar.max_value = xp_to_next_level
	level_up_popup.show_popup(player.level_up_context, player.level_up_boss_pecado)

func _apply_effect(option) -> void:
	var option_data = option if option is Dictionary else {}
	var option_id = str(option_data.get("id", option))
	var stat_multiplier = _get_option_stat_multiplier(option_data)

	if player.has_method("is_active_ability_id") and player.is_active_ability_id(option_id):
		if not player.learn_active_ability(option_id):
			_show_active_discard_popup(option_id)
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
		"option_1":
			player.add_recoil_force_bonus(0.05 * stat_multiplier)
		"option_2":
			var health_bonus = 0.05 * stat_multiplier
			var health_gain = player.current_health * health_bonus
			player.max_health += player.max_health * health_bonus
			player.heal(health_gain)
			_on_hp_updated(player.current_health, player.max_health)
		"option_3":
			player.attack_damage += player.attack_damage * 0.10 * stat_multiplier
		"option_4":
			player.add_attack_speed_bonus(0.05 * stat_multiplier)
		"option_5":
			player.add_projectile_size_bonus(0.05 * stat_multiplier)
		"option_6":
			player.add_heal_after_wave_bonus(0.03 * stat_multiplier)
		"option_7":
			player.add_dash_cooldown_reduction_bonus(0.05 * stat_multiplier)
		"glass_canon":
			player.attack_damage += player.attack_damage * 0.5 * stat_multiplier
			player.max_health = int(player.max_health * _get_remaining_stat_multiplier(0.25, stat_multiplier))
			player.current_health = min(player.current_health, player.max_health)
			_on_hp_updated(player.current_health, player.max_health)
		"tanky":
			var max_health_multiplier = 1.0 + 0.25 * stat_multiplier
			var health_gain = player.current_health * (max_health_multiplier - 1.0)
			player.max_health = int(player.max_health * max_health_multiplier)
			player.heal(health_gain)
			player.attack_damage *= _get_remaining_stat_multiplier(0.5, stat_multiplier)
			_on_hp_updated(player.current_health, player.max_health)
		"deadly_slow":
			player.multiply_base_recoil_force(_get_remaining_stat_multiplier(0.25, stat_multiplier))
			player.attack_damage += player.attack_damage * 0.75 * stat_multiplier
		"fast_but_small":
			player.add_attack_speed_bonus(0.3 * stat_multiplier)
			player.add_projectile_size_bonus(-0.3 * stat_multiplier)
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

	_finish_effect_application()

func _get_option_stat_multiplier(option_data: Dictionary) -> float:
	return max(float(option_data.get("stat_multiplier", 1.0)), 0.0)

func _get_remaining_stat_multiplier(base_penalty: float, stat_multiplier: float) -> float:
	return max(1.0 - base_penalty * stat_multiplier, 0.01)

func _is_rare_option(option: String) -> bool:
	return option in Global.RARE_OPTION_IDS

func _is_boss_passive_option(option: String) -> bool:
	return option in Global.SIN_PASSIVE_IDS

func _equip_boss_passive_option(option: String) -> void:
	var already_equipped = player.has_boss_passive(option) if player.has_method("has_boss_passive") else false

	if player.has_method("equip_boss_passive_id"):
		player.equip_boss_passive_id(option)

	if not already_equipped:
		_apply_boss_passive_effect(option)
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

func _finish_effect_application() -> void:
	if player.pause_control:
		player.pause_control.update_status_labels()
	player.emit_signal("stats_updated")

func _on_active_discard_selected(discarded_slot: String, new_option: String) -> void:
	if discarded_slot == "new":
		return

	player.replace_active_ability(discarded_slot, new_option)
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
	_finish_effect_application()

func _on_boss_passive_discard_selected(discarded_option: String, old_option: String, new_option: String) -> void:
	if discarded_option == new_option:
		return

	_remove_boss_passive_effect(discarded_option)
	if player.has_method("replace_boss_passive_id"):
		player.replace_boss_passive_id(discarded_option, new_option)
	_apply_boss_passive_effect(new_option)
	_finish_effect_application()

func _show_active_discard_popup(option: String) -> void:
	level_up_popup.show_active_discard_popup(option, player.get_active_ability_slots())
