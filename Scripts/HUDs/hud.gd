extends Node2D

var player_path: NodePath = "/root/GameScene/Player"
var player
var camera_path: NodePath = "/root/GameScene/Player/Camera2D"
var camera

@onready var boxStats = $HBoxContainer

var hud_offset: Vector2 = global_position
var level_up_popup
const RARE_OPTION_IDS = ["Shield_Protection", "Recoil_Explosion", "Double_Dash"]

func _ready() -> void:
	player = get_node_or_null(player_path)
	camera = get_node_or_null(camera_path)
	
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
	else:
		print("Jogador ou câmera não encontrados!")

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
			player.attack_damage += player.attack_damage * 0.1
		"option_4":
			player.add_attack_speed_bonus(0.05)
		"glass_canon":
			player.attack_damage += player.attack_damage * 0.25
			player.max_health = int(player.max_health * 0.8)
			player.current_health = min(player.current_health, player.max_health)
			_on_hp_updated(player.current_health, player.max_health)
		"tanky":
			player.max_health = int(player.max_health * 1.2)
			player.current_health = int(min(player.current_health * 1.2, player.max_health))
			player.attack_damage *= 0.75
			_on_hp_updated(player.current_health, player.max_health)
		"deadly_slow":
			player.recoil_force *= 0.5
			player.attack_damage += player.attack_damage * 0.5
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
			player.has_shield = true
		"Recoil_Explosion":
			player.recoil_explosion_enabled = true
		"Double_Dash":
			player.max_dash_charges = 2
			player.double_dash_charges = max(player.double_dash_charges, 1)

func _remove_rare_effect(option: String) -> void:
	match option:
		"Shield_Protection":
			player.has_shield = false
		"Recoil_Explosion":
			player.recoil_explosion_enabled = false
		"Double_Dash":
			player.max_dash_charges = 1
			player.double_dash_charges = 0

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
