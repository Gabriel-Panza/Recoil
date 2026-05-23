extends Node2D

var player_path: NodePath = "/root/GameScene/Player"
var player
var camera_path: NodePath = "/root/GameScene/Player/Camera2D"
var camera

@onready var boxStats = $HBoxContainer

var hud_offset: Vector2 = global_position
var level_up_popup
var active_skill_e_label: Label
var active_skill_r_label: Label
var passive_status_label: Label
var skill_status_background: ColorRect
const RARE_OPTION_IDS = ["Shield_Protection", "Recoil_Explosion", "Double_Dash", "Offensive_Dash"]

func _ready() -> void:
	player = get_node_or_null(player_path)
	camera = get_node_or_null(camera_path)
	_setup_skill_status_background()
	_setup_active_skill_hud_labels()
	_setup_passive_status_label()
	
	level_up_popup = preload("res://Cenas/HUDs/levelUpPopup.tscn").instantiate()
	add_child(level_up_popup)
	level_up_popup.connect("option_selected", Callable(self, "_apply_effect"))
	level_up_popup.connect("active_discard_selected", Callable(self, "_on_active_discard_selected"))
	level_up_popup.connect("rare_discard_selected", Callable(self, "_on_rare_discard_selected"))
	
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
	active_skill_e_label = get_node_or_null("ActiveSkillHudE")
	if active_skill_e_label == null:
		active_skill_e_label = _create_active_skill_hud_label("ActiveSkillHudE", Vector2(16.0, 86.0))

	active_skill_r_label = get_node_or_null("ActiveSkillHudR")
	if active_skill_r_label == null:
		active_skill_r_label = _create_active_skill_hud_label("ActiveSkillHudR", Vector2(16.0, 104.0))

func _setup_skill_status_background() -> void:
	skill_status_background = get_node_or_null("SkillStatusBackground")
	if skill_status_background != null:
		return

	skill_status_background = ColorRect.new()
	skill_status_background.name = "SkillStatusBackground"
	skill_status_background.position = Vector2(10.0, 80.0)
	skill_status_background.size = Vector2(240.0, 72.0)
	skill_status_background.color = Color(0.0, 0.0, 0.0, 0.45)
	skill_status_background.z_index = 1
	skill_status_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(skill_status_background)

func _setup_passive_status_label() -> void:
	passive_status_label = get_node_or_null("PassiveStatusHud")
	if passive_status_label != null:
		return

	passive_status_label = Label.new()
	passive_status_label.name = "PassiveStatusHud"
	passive_status_label.position = Vector2(16.0, 126.0)
	passive_status_label.size = Vector2(224.0, 72.0)
	passive_status_label.z_index = 2
	passive_status_label.mouse_filter = Control.MOUSE_FILTER_STOP
	passive_status_label.add_theme_color_override("font_color", Color(1.0, 0.58, 0.16, 1.0))
	passive_status_label.add_theme_constant_override("outline_size", 3)
	passive_status_label.add_theme_font_size_override("font_size", 13)
	passive_status_label.text = "Passives:\n- None"
	passive_status_label.tooltip_text = "No passive skills equipped"
	add_child(passive_status_label)

func _create_active_skill_hud_label(label_name: String, label_position: Vector2) -> Label:
	var label = Label.new()
	label.name = label_name
	label.position = label_position
	label.size = Vector2(224.0, 18.0)
	label.z_index = 2
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.35, 1.0))
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_font_size_override("font_size", 14)
	label.text = "%s - None" % ("E" if label_name.ends_with("E") else "R")
	add_child(label)
	return label

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

	var summaries: Array = []
	if player.has_method("get_equipped_passive_summaries"):
		summaries = player.get_equipped_passive_summaries()

	if summaries.is_empty():
		passive_status_label.text = "Passives:\n- None"
		passive_status_label.tooltip_text = "No passive skills equipped"
		_update_skill_status_background(4)
		return

	var passive_lines := PackedStringArray()
	var tooltip_lines := PackedStringArray()
	for summary in summaries:
		var passive_name = str(summary.get("name", "Passive"))
		passive_lines.append("- %s" % passive_name)
		tooltip_lines.append("%s: %s" % [
			passive_name,
			str(summary.get("description", ""))
		])

	passive_status_label.text = "Passives:\n%s" % "\n".join(passive_lines)
	passive_status_label.tooltip_text = "\n".join(tooltip_lines)
	_update_skill_status_background(3 + passive_lines.size())

func _update_skill_status_background(line_count: int) -> void:
	if skill_status_background == null or passive_status_label == null:
		return

	var height = max(72.0, 30.0 + float(line_count) * 18.0)
	skill_status_background.size = Vector2(240.0, height)
	passive_status_label.size = Vector2(224.0, max(44.0, height - 44.0))

func _update_active_skill_hud_label(label: Label, slot: String) -> void:
	if label == null:
		return

	var slots = player.get_active_ability_slots() if player.has_method("get_active_ability_slots") else {}
	var ability_id = str(slots.get(slot, ""))
	if ability_id == "":
		label.text = "%s - None" % slot
		label.tooltip_text = "No active skill equipped"
		return

	var ability_name = player.get_active_ability_name(ability_id) if player.has_method("get_active_ability_name") else ability_id
	var cooldown = player.get_active_slot_cooldown(slot) if player.has_method("get_active_slot_cooldown") else 0.0
	if cooldown > 0.0:
		label.text = "%s - %s (%.1fs)" % [slot, ability_name, cooldown]
	else:
		label.text = "%s - %s" % [slot, ability_name]

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

func _apply_effect(option):
	if player.has_method("is_active_ability_id") and player.is_active_ability_id(option):
		if not player.learn_active_ability(option):
			_show_active_discard_popup(option)
		return

	if _is_rare_option(option):
		if player.current_rare_option != "" and player.current_rare_option != option:
			level_up_popup.show_rare_discard_popup(player.current_rare_option, option)
			return

		_equip_rare_option(option)
		return

	match option:
		"option_1":
			player.recoil_force += player.recoil_force * 0.05
		"option_2":
			player.current_health += player.current_health * 0.05
			player.max_health += player.max_health * 0.05
			_on_hp_updated(player.current_health, player.max_health)
		"option_3":
			player.attack_damage += player.attack_damage * 0.15
		"option_4":
			player.add_attack_speed_bonus(0.05)
		"glass_canon":
			player.attack_damage += player.attack_damage * 0.5
			player.max_health = int(player.max_health * 0.75)
			player.current_health = min(player.current_health, player.max_health)
			_on_hp_updated(player.current_health, player.max_health)
		"tanky":
			player.max_health = int(player.max_health * 1.25)
			player.current_health = int(min(player.current_health * 1.25, player.max_health))
			player.attack_damage *= 0.5
			_on_hp_updated(player.current_health, player.max_health)
		"deadly_slow":
			player.recoil_force *= 0.5
			player.attack_damage *= 2.0
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
			player.greed_cursed_level_enabled = true

	_finish_effect_application()

func _is_rare_option(option: String) -> bool:
	return option in RARE_OPTION_IDS

func _equip_rare_option(option: String) -> void:
	if player.current_rare_option != "" and player.current_rare_option != option:
		_remove_rare_effect(player.current_rare_option)

	player.current_rare_option = option
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
			player.max_dash_charges = 2
			player.double_dash_charges = max(player.double_dash_charges, 1)
		"Offensive_Dash":
			player.offensive_dash_enabled = true

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
			player.max_dash_charges = 1
			player.double_dash_charges = 0
		"Offensive_Dash":
			player.offensive_dash_enabled = false

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

	if discarded_option == old_option:
		_equip_rare_option(new_option)

func _show_active_discard_popup(option: String) -> void:
	level_up_popup.show_active_discard_popup(option, player.get_active_ability_slots())
