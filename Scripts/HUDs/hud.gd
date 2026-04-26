extends Node2D

var player_path: NodePath = "/root/GameScene/Player"
var player
var camera_path: NodePath = "/root/GameScene/Player/Camera2D"
var camera

@onready var boxStats = $HBoxContainer

var hud_offset: Vector2 = global_position
var level_up_popup

func _ready() -> void:
	player = get_node_or_null(player_path)
	camera = get_node_or_null(camera_path)
	
	level_up_popup = preload("res://Cenas/HUDs/levelUpPopup.tscn").instantiate()
	add_child(level_up_popup)
	level_up_popup.connect("option_selected", Callable(self, "_apply_effect"))
	
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
	level_up_popup.show_popup()

func _apply_effect(option):
	match option:
		"option_1":
			player.recoil_force += player.recoil_force * 0.05
		"option_2":
			player.current_health += player.current_health * 0.05
			player.max_health += player.max_health * 0.05
			_on_hp_updated(player.health, player.maxHealth)
		"option_3":
			player.attack_damage += player.attack_damage * 0.1
		"option_4":
			player.fire_rate -= 0.025
	player.pause_control.update_status_labels()
