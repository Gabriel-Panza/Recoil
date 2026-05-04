extends Node2D

# Fundo / Arena
@onready var arena_nodes = [$Arenas/ArenaEnemy, $Arenas/Pecado1, $Arenas/Pecado2, $Arenas/Pecado3, $Arenas/Pecado4, $Arenas/Pecado5, $Arenas/Pecado6, $Arenas/Pecado7]
var current_arena: Node2D

# Preload dos inimigos
const MELEE_ENEMY = preload("res://Cenas/Inimigos/melee_enemy.tscn")
const RANGED_ENEMY = preload("res://Cenas/Inimigos/ranged_enemy.tscn")
const BOSS_ENEMY = preload("res://Cenas/Inimigos/boss.tscn")

# Conjuntos de Waves baseados no pecado
var wave_sets = {
	1: [  # Pride
		{"melee": 4, "ranged": 0},
		{"melee": 5, "ranged": 2},
		{"melee": 6, "ranged": 3},
		{"melee": 7, "ranged": 4}
	],
	2: [  # Greed
		{"melee": 5, "ranged": 1},
		{"melee": 6, "ranged": 3},
		{"melee": 7, "ranged": 5},
		{"melee": 8, "ranged": 7}
	],
	3: [  # Wrath
		{"melee": 6, "ranged": 2},
		{"melee": 7, "ranged": 4},
		{"melee": 8, "ranged": 6},
		{"melee": 9, "ranged": 8}
	],
	4: [  # Envy
		{"melee": 7, "ranged": 3},
		{"melee": 8, "ranged": 5},
		{"melee": 9, "ranged": 7},
		{"melee": 10, "ranged": 9}
	],
	5: [  # Lust
		{"melee": 8, "ranged": 4},
		{"melee": 9, "ranged": 6},
		{"melee": 10, "ranged": 8},
		{"melee": 11, "ranged": 10}
	],
	6: [  # Gluttony
		{"melee": 9, "ranged": 5},
		{"melee": 10, "ranged": 7},
		{"melee": 11, "ranged": 9},
		{"melee": 12, "ranged": 11}
	],
	7: [  # Sloth
		{"melee": 10, "ranged": 6},
		{"melee": 11, "ranged": 8},
		{"melee": 12, "ranged": 10},
		{"melee": 13, "ranged": 12}
	]
}

var waves = []
var current_wave_index: int = 0
var is_wave_active: bool = false
var waiting_for_pecado_change: bool = false
var boss_phase: bool = false

func _ready() -> void:
	Global.pecado_changed.connect(_on_pecado_changed)
	current_arena = arena_nodes[0]
	set_waves_based_on_pecado()
	start_next_wave()

func set_waves_based_on_pecado():
	waves = wave_sets.get(Global.pecado, wave_sets[1])

func start_next_wave():
	if current_wave_index >= waves.size():
		if current_arena == arena_nodes[0]:
			print("4 waves concluídas na arena principal! Indo para arena do pecado {0}.".format([Global.pecado]))
			current_arena = arena_nodes[Global.pecado] if Global.pecado <= arena_nodes.size() - 1 else arena_nodes[1]
			boss_phase = true
			spawn_boss()  # Spawn o boss primeiro
			return  # Não inicia waves ainda
		else:
			if not waiting_for_pecado_change:
				waiting_for_pecado_change = true
				print("Boss fight concluída! Aguardando mudança de pecado...")
		return
	
	waiting_for_pecado_change = false
	is_wave_active = true
	var wave_data = waves[current_wave_index]
	var arena_type = "principal" if current_arena == arena_nodes[0] else "boss"
	print("Wave {0} do pecado {1} ({2}) iniciada!".format([current_wave_index+1, Global.pecado, arena_type]))
	spawn_wave(wave_data)
	current_wave_index += 1

func spawn_wave(data: Dictionary):
	# Spawna Melee
	for i in range(data["melee"]):
		spawn_enemy(MELEE_ENEMY)
	
	# Spawna Ranged
	for i in range(data["ranged"]):
		spawn_enemy(RANGED_ENEMY)

func spawn_boss():
	var boss = BOSS_ENEMY.instantiate()
	boss.global_position = get_random_camera_edge_position()
	boss.add_to_group("Boss")
	boss.tree_exited.connect(_on_boss_died)
	add_child(boss)

func spawn_enemy(enemy_scene: PackedScene):
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	
	# Posiciona nas bordas da câmera, dentro do mapa
	enemy.global_position = get_random_camera_edge_position()
	
	# Monitora a morte do inimigo
	enemy.tree_exited.connect(_on_enemy_died)

func get_random_camera_edge_position() -> Vector2:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return get_random_edge_position()  # Fallback para viewport
	
	var cam_pos = camera.global_position
	var viewport_size = get_viewport_rect().size
	var cam_rect = Rect2(cam_pos - viewport_size / 2, viewport_size)
	
	var margin = 50.0
	var attempts = 10
	
	for i in range(attempts):
		var side = randi() % 4
		var pos = Vector2.ZERO
		
		match side:
			0: # Cima
				pos = Vector2(randf_range(cam_rect.position.x, cam_rect.end.x), cam_rect.position.y - margin)
			1: # Baixo
				pos = Vector2(randf_range(cam_rect.position.x, cam_rect.end.x), cam_rect.end.y + margin)
			2: # Esquerda
				pos = Vector2(cam_rect.position.x - margin, randf_range(cam_rect.position.y, cam_rect.end.y))
			3: # Direita
				pos = Vector2(cam_rect.end.x + margin, randf_range(cam_rect.position.y, cam_rect.end.y))
		
		# Verifica se a posição está dentro do mapa (polígono de colisão)
		var collision_polygon = current_arena.get_node("StaticBody2D/CollisionPolygon2D")  # Ajuste o path se necessário
		if collision_polygon and Geometry2D.is_point_in_polygon(pos, collision_polygon.polygon):
			var player = get_tree().get_first_node_in_group("Player")
			if player and pos.distance_to(player.global_position) > 100.0:
				return pos
	
	# Fallback se não encontrar posição válida
	return get_random_edge_position()

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

func _on_boss_died():
	if boss_phase:
		boss_phase = false
		current_wave_index = 0
		start_next_wave()

func _on_pecado_changed(new_pecado):
	if new_pecado == 8:
		var player = get_tree().get_first_node_in_group("Player")
		if player and player.has_method("win"):
			player.win()
		return

	if waiting_for_pecado_change:
		print("Pecado mudou para {0}! Voltando para arena principal.".format([new_pecado]))
		current_arena = arena_nodes[0]
		current_wave_index = 0
		set_waves_based_on_pecado()
		start_next_wave()
