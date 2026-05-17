extends Control

var game_scene_path: NodePath = "/root/GameScene"
var game_scene
var player_path: NodePath = "/root/GameScene/Player"
var player
var pause_menu_path: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/PauseControl/PauseMenu"
var pause_menu: Panel
var options_menu_path: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/PauseControl/PauseMenu/OptionsMenu"
var options_menu: Panel
var health_label_path: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/HBoxContainer/BarraLateralDireita/MarginContainer/VBoxContainer/HP_MaxHealth"
var health_label: Label
var attack_label_path: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/HBoxContainer/BarraLateralDireita/MarginContainer/VBoxContainer/Ataque"
var attack_label: Label
var atk_speed_label_path: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/HBoxContainer/BarraLateralDireita/MarginContainer/VBoxContainer/Atk_Speed"
var atk_speed_label: Label
var recoil_label_path: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/HBoxContainer/BarraLateralDireita/MarginContainer/VBoxContainer/Recoil"
var recoil_label: Label
var active_skill_e_label_path: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/HBoxContainer/BarraLateralDireita/MarginContainer/VBoxContainer/ActiveSkillE"
var active_skill_e_label: Label
var active_skill_r_label_path: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/HBoxContainer/BarraLateralDireita/MarginContainer/VBoxContainer/ActiveSkillR"
var active_skill_r_label: Label

var speedEnemy
var speedProjectile

var canMove = true

func _ready() -> void:
	player = get_node_or_null(player_path)
	game_scene = get_node_or_null(game_scene_path)
	pause_menu = get_node_or_null(pause_menu_path)
	options_menu = get_node_or_null(options_menu_path)
	health_label = get_node_or_null(health_label_path)
	attack_label = get_node_or_null(attack_label_path)
	atk_speed_label = get_node_or_null(atk_speed_label_path)
	recoil_label = get_node_or_null(recoil_label_path)
	active_skill_e_label = get_node_or_null(active_skill_e_label_path)
	active_skill_r_label = get_node_or_null(active_skill_r_label_path)

	if player:
		player.connect("stats_updated", Callable(self, "update_status_labels"))
	
func _process(delta):
	update_status_labels()
	if Input.is_action_just_pressed("ui_cancel"):
		if not pause_menu.is_visible():
			_pause_game()
		else:
			_unpause_game()

func _pause_game():
	pause_menu.show()
	$"../HBoxContainer".visible = true
	update_status_labels()
	get_tree().paused = true

func _unpause_game():
	options_menu.hide()
	pause_menu.hide()
	$"../HBoxContainer".visible = false
	get_tree().paused = false

func update_status_labels():
	if player:
		if health_label:
			health_label.text = "Health: %.2f/%d" % [player.current_health, player.max_health]
		if attack_label:
			attack_label.text = "Attack: %.1f" % player.attack_damage
		if atk_speed_label:
			var attack_speed_percent = (1.0 / max(player.fire_rate, 0.001)) * 100.0
			if player.has_method("get_attack_speed_percent"):
				attack_speed_percent = player.get_attack_speed_percent()
			atk_speed_label.text = "Atk-Speed: %.1f%%" % attack_speed_percent
		if recoil_label:
			recoil_label.text = "Recoil Force: %.1f" % (player.recoil_force/100)
		_update_active_skill_labels()

func _update_active_skill_labels() -> void:
	_update_active_skill_slot_label(active_skill_e_label, "E")
	_update_active_skill_slot_label(active_skill_r_label, "R")

func _update_active_skill_slot_label(label: Label, slot: String) -> void:
	if not label:
		return

	if not player.has_method("get_active_ability_slots"):
		label.text = "%s: -" % slot
		label.tooltip_text = "No active skill equipped"
		return

	var active_slots = player.get_active_ability_slots()
	var ability_id = active_slots.get(slot, "")
	if ability_id == "":
		label.text = "%s: -" % slot
		label.tooltip_text = "No active skill equipped"
		return

	var skill_name = ability_id
	var skill_description = ability_id
	if player.has_method("get_active_ability_name"):
		skill_name = player.get_active_ability_name(ability_id)
	if player.has_method("get_active_ability_description"):
		skill_description = player.get_active_ability_description(ability_id)

	var cooldown = 0.0
	if player.has_method("get_active_slot_cooldown"):
		cooldown = player.get_active_slot_cooldown(slot)

	if cooldown > 0.0:
		label.text = "%s: %s (%.1fs)" % [slot, skill_name, cooldown]
	else:
		label.text = "%s: %s" % [slot, skill_name]

	label.tooltip_text = "%s\nCooldown: %.1fs" % [skill_description, cooldown]

func freeze():
	canMove = false
	for obj in get_tree().get_nodes_in_group("Vivos"):
		if obj in get_tree().get_nodes_in_group("Inimigo"):
			speedEnemy = obj.speed
		else:
			speedProjectile = obj.speed
		obj.speed = 0
	
func unfreeze():
	canMove = true
	for obj in get_tree().get_nodes_in_group("Vivos"):
		if obj in get_tree().get_nodes_in_group("Inimigo"):
			obj.speed = speedEnemy
		else:
			obj.speed = speedProjectile
