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
var friction_label_path: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/HBoxContainer/BarraLateralDireita/MarginContainer/VBoxContainer/Friction"
var friction_label: Label

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
	friction_label = get_node_or_null(friction_label_path)

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
	get_tree().paused = true

func _unpause_game():
	options_menu.hide()
	pause_menu.hide()
	$"../HBoxContainer".visible = false
	get_tree().paused = false

func update_status_labels():
	if player:
		health_label.text = "Health: %.2f/%d" % [player.current_health, player.max_health]
		attack_label.text = "Attack: %.1f" % player.attack_damage
		atk_speed_label.text = "Atk-Speed: %.1f%%" % (player.fire_rate * 100)
		recoil_label.text = "Recoil Force: %.1f" % (player.recoil_force/100)
		friction_label.text = "Friction: %.1f" % (player.friction/100)

func freeze():
	canMove = false
	if game_scene:
		game_scene.pause_timers()
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
	if game_scene:
		game_scene.resume_timers()
