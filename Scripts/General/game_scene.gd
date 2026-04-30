extends Node2D

# Preload dos inimigos
const MELEE_ENEMY = preload("res://Cenas/Inimigos/melee_enemy.tscn")
const RANGED_ENEMY = preload("res://Cenas/Inimigos/ranged_enemy.tscn")

# Estrutura das Waves
var waves = [
	{"melee": 5, "ranged": 0},
	{"melee": 7, "ranged": 3},
	{"melee": 10, "ranged": 5},
	{"melee": 13, "ranged": 7}
]

var current_wave_index: int = 0
var is_wave_active: bool = false

func _ready() -> void:
	start_next_wave()

func start_next_wave():
	if current_wave_index >= waves.size():
		print("Todas as waves concluídas!")
		return
	
	is_wave_active = true
	var wave_data = waves[current_wave_index]
	print("Wave {0} iniciada!".format([current_wave_index+1]))
	spawn_wave(wave_data)
	current_wave_index += 1

func spawn_wave(data: Dictionary):
	# Spawna Melee
	for i in range(data["melee"]):
		spawn_enemy(MELEE_ENEMY)
	
	# Spawna Ranged
	for i in range(data["ranged"]):
		spawn_enemy(RANGED_ENEMY)

func spawn_enemy(enemy_scene: PackedScene):
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	
	# Posiciona nas bordas
	enemy.global_position = get_random_edge_position()
	
	# Monitora a morte do inimigo
	enemy.tree_exited.connect(_on_enemy_died)

func get_random_edge_position() -> Vector2:
	var viewport_rect = get_viewport_rect()
	var margin = 50.0
	
	var side = randi() % 4 # 0: Cima, 1: Baixo, 2: Esquerda, 3: Direita
	var spawn_pos = Vector2.ZERO
	
	match side:
		0: # Cima
			spawn_pos = Vector2(randf_range(0, viewport_rect.size.x), -margin)
		1: # Baixo
			spawn_pos = Vector2(randf_range(0, viewport_rect.size.x), viewport_rect.size.y + margin)
		2: # Esquerda
			spawn_pos = Vector2(-margin, randf_range(0, viewport_rect.size.y))
		3: # Direita
			spawn_pos = Vector2(viewport_rect.size.x + margin, randf_range(0, viewport_rect.size.y))
			
	return spawn_pos

func _on_enemy_died() -> void:
	if not is_wave_active:
		return
	
	if get_tree():
		await get_tree().process_frame
	
		# Checa se ainda existem inimigos vivos
		if not get_tree().get_nodes_in_group("Enemy"):
			is_wave_active = false
			await get_tree().create_timer(0.5).timeout
			start_next_wave()

func pause_timers():
	pass

func resume_timers():
	pass
