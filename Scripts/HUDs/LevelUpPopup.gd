extends Panel

var player_path: NodePath = "/root/GameScene/Player"
var player
var game_scene_path: NodePath = "/root/GameScene"
var game_scene
var speedPlayer
var speedEnemy
var speedProjectile
var passive_options = [
	{ "id": "option_1", "text": "Recoil Force (+5%)", "rarity": "passive_common" },
	{ "id": "option_2", "text": "Health (+5%)", "rarity": "passive_common" },
	{ "id": "option_3", "text": "Attack (+10%)", "rarity": "passive_common" },
	{ "id": "option_4", "text": "Atk-Speed (+3%)", "rarity": "passive_common" }
]
var active_options = [
	{ "id": "Shield_Protection", "text": " Gain a one-hit shield", "rarity": "active" }
]
signal option_selected(option)

func _ready() -> void:
	randomize()
	game_scene = get_node_or_null(game_scene_path)
	player = get_node_or_null(player_path)
	visible = false

func show_popup():
	get_tree().paused = true
	
	await get_tree().create_timer(0.25).timeout
	
	# Começa com as opções básicas e randomiza 3 opções do vetor de opções
	var current_pool = passive_options.duplicate()
	current_pool.shuffle()
	visible = true 
	var randomized_options = current_pool.slice(0, 3)
	
	# Verifica a possibilidade de vir uma habilidade ativa
	var active_chance = 0.05
	if randf() < active_chance:
		active_options.shuffle()
		randomized_options[0] = active_options[0]
		randomized_options.shuffle()
	
	# Atualiza os botões com as opções randomizadas
	for i in range(3):
		var button = get_node_or_null("VBoxContainer").get_child(i)
		if i < randomized_options.size():
			button.visible = true
			button.get_child(0).text = randomized_options[i]["text"]
			if randomized_options[i]["rarity"] == "passive_common":
				button.self_modulate = Color(0, 1, 0.2, 1) # Verde
			else:
				button.self_modulate = Color(1, 0, 0.2, 1) # Vermelho
			button.disconnect("pressed", Callable(self, "_on_option_pressed"))
			button.connect("pressed", Callable(self, "_on_option_pressed").bind(randomized_options[i]["id"]))
		else:
			button.visible = false

func _on_option_pressed(option_id: String) -> void:
	emit_signal("option_selected", option_id)
	hide()
	
	get_tree().paused = false
	player.upando = false
	if player.current_xp >= player.xp_to_next_level:
		player.level_up()
