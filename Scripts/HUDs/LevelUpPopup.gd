extends Panel

var player_path: NodePath = "/root/GameScene/Player"
var player
var game_scene_path: NodePath = "/root/GameScene"
var game_scene
var speedPlayer
var speedEnemy
var speedProjectile
var passive_options = [
	{ "id": "option_1", "text": "Speed (+3%)", "rarity": "passive_common" },
	{ "id": "option_2", "text": "Health (+5%)", "rarity": "passive_common" },
	{ "id": "option_3", "text": "Attack (+10%)", "rarity": "passive_common" },
	{ "id": "option_4", "text": "Atk-Speed (+3%)", "rarity": "passive_common" }
]
var active_options = [
	{ "id": "Shield_Protection", "text": " Gain a one-hit shield", "rarity": "active" }
]
signal option_selected(option)

var confetti

func _ready() -> void:
	randomize()
	game_scene = get_node_or_null(game_scene_path)
	player = get_node_or_null(player_path)
	visible = false

func show_popup():
	player.is_attacking = false
	get_tree().paused = true
	
	await get_tree().create_timer(0.25).timeout
	spawn_confetti()
	
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
	confetti.queue_free()
	if player.current_xp >= player.xp_to_next_level:
		player.level_up()

func spawn_confetti():
	confetti = CPUParticles2D.new()
	add_child(confetti)
	
	# --- Posicionamento ---
	confetti.position = Vector2((get_viewport_rect().size.x / 2) - 200, -250)
	confetti.z_index = 10 
	
	# --- Configuração das Partículas ---
	confetti.amount = 750
	confetti.lifetime = 5.0
	confetti.one_shot = false
	confetti.explosiveness = 0.0
	confetti.direction = Vector2(0, 1)
	confetti.spread = 60.0
	confetti.gravity = Vector2(0, 250)
	confetti.initial_velocity_min = 100.0
	confetti.initial_velocity_max = 200.0
	
	# --- Formato e Emissão ---
	confetti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	confetti.emission_rect_extents = Vector2(get_viewport_rect().size.x / 2, 1)
	
	# --- Cores ---
	var gradient = Gradient.new()
	gradient.set_offsets(PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0]))
	gradient.set_colors(PackedColorArray([
		Color.RED, Color.YELLOW, Color.GREEN, Color.CYAN, Color.MAGENTA, Color.ORANGE
	]))
	confetti.color_initial_ramp = gradient
	
	# --- Estética ---
	confetti.scale_amount_min = 5.0
	confetti.scale_amount_max = 10.0
	
	confetti.hue_variation_min = -1.0
	confetti.hue_variation_max = 1.0
	confetti.color = Color(1, 0.1, 0.1)
	
	confetti.angular_velocity_min = 100.0
	confetti.angular_velocity_max = 300.0
	confetti.emitting = true
