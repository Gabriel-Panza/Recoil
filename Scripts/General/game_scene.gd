extends Node2D

# Fundo / Arena
@onready var arena_nodes = [$Arenas/ArenaEnemy, $Arenas/Pecado1, $Arenas/Pecado2, $Arenas/Pecado3, $Arenas/Pecado4, $Arenas/Pecado5, $Arenas/Pecado6, $Arenas/Pecado7]
var current_arena: Node2D

const FADE_DURATION: float = 0.35
const ENEMY_ARENA_PLAYER_POSITION: Vector2 = Vector2(770, 414)

var fade_layer: CanvasLayer
var fade_rect: ColorRect
var is_transitioning: bool = false

# Troque estes placeholders pelos sprites reais da ArenaEnemy.
# Indice 0 = visual inicial; indice 1 = apos o primeiro boss; indice 2 = apos o segundo boss; etc.
var enemy_arena_textures: Array[Texture2D] = [
	preload("res://Sprites/icon.svg"),
	preload("res://Sprites/icon.svg"),
	preload("res://Sprites/icon.svg"),
	preload("res://Sprites/icon.svg"),
	preload("res://Sprites/icon.svg"),
	preload("res://Sprites/icon.svg"),
	preload("res://Sprites/icon.svg"),
	preload("res://Sprites/icon.svg")
]

# Preload dos inimigos
const MELEE_ENEMY = preload("res://Cenas/Inimigos/melee_enemy.tscn")
const RANGED_ENEMY = preload("res://Cenas/Inimigos/ranged_enemy.tscn")
const BOSS_ENEMY = preload("res://Cenas/Inimigos/boss.tscn")

# Conjuntos de waves baseados no pecado
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
var boss_phase: bool = false

func _ready() -> void:
	Global.pecado_changed.connect(_on_pecado_changed)
	current_arena = arena_nodes[0]
	_setup_fade_overlay()
	_update_enemy_arena_sprite()
	set_waves_based_on_pecado()
	start_next_wave()

func _setup_fade_overlay() -> void:
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)

	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.offset_left = 0
	fade_rect.offset_top = 0
	fade_rect.offset_right = 0
	fade_rect.offset_bottom = 0
	fade_layer.add_child(fade_rect)

func _fade_to(alpha: float) -> void:
	if fade_rect == null:
		return

	var target_color = Color.BLACK
	target_color.a = alpha
	var tween = create_tween()
	tween.tween_property(fade_rect, "color", target_color, FADE_DURATION)
	await tween.finished

func _transition_player_to(target_position: Vector2) -> void:
	if is_transitioning:
		return

	is_transitioning = true
	await _fade_to(1.0)
	$Player.global_position = target_position
	await get_tree().process_frame
	await _fade_to(0.0)
	is_transitioning = false

func _set_player_xp_goal(enemy_count: int) -> void:
	if $Player.has_method("start_wave_xp_goal"):
		$Player.start_wave_xp_goal(enemy_count)

func _wait_for_level_up_selection() -> void:
	while $Player.upando:
		await get_tree().create_timer(0.1).timeout

func _update_enemy_arena_sprite() -> void:
	var texture_index = clamp(Global.pecado - 1, 0, enemy_arena_textures.size() - 1)
	$Arenas/ArenaEnemy.texture = enemy_arena_textures[texture_index]

func set_waves_based_on_pecado():
	waves = wave_sets.get(Global.pecado, wave_sets[1])

func start_next_wave():
	if current_wave_index >= waves.size():
		if current_arena == arena_nodes[0]:
			print("4 waves concluidas na arena principal! Indo para arena do pecado {0}.".format([Global.pecado]))
			current_arena = arena_nodes[Global.pecado] if Global.pecado <= arena_nodes.size() - 1 else arena_nodes[1]
			boss_phase = true
			spawn_boss()
		return

	is_wave_active = true
	var wave_data = waves[current_wave_index]
	var arena_type = "principal" if current_arena == arena_nodes[0] else "boss"
	print("Wave {0} do pecado {1} ({2}) iniciada!".format([current_wave_index + 1, Global.pecado, arena_type]))
	spawn_wave(wave_data)
	current_wave_index += 1

func spawn_wave(data: Dictionary):
	_set_player_xp_goal(data["melee"] + data["ranged"])

	# Spawna melee
	for i in range(data["melee"]):
		spawn_enemy(MELEE_ENEMY)

	# Spawna ranged
	for i in range(data["ranged"]):
		spawn_enemy(RANGED_ENEMY)

func spawn_boss():
	var centro_node = current_arena.get_node("Centro")
	_set_player_xp_goal(1)
	await _transition_player_to(centro_node.global_position)
	await get_tree().create_timer(1).timeout

	var boss = BOSS_ENEMY.instantiate()
	boss.global_position = get_random_camera_edge_position()
	boss.add_to_group("Boss")
	boss.tree_exited.connect(_on_boss_died)
	add_child(boss)

func spawn_enemy(enemy_scene: PackedScene):
	var enemy = enemy_scene.instantiate()
	add_child(enemy)

	# Posiciona nas bordas da camera, dentro do mapa
	enemy.global_position = get_random_camera_edge_position()

	# Monitora a morte do inimigo
	enemy.tree_exited.connect(_on_enemy_died)

func get_random_camera_edge_position() -> Vector2:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return get_random_edge_position()

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

		# Verifica se a posicao esta dentro do mapa (poligono de colisao)
		var collision_polygon = current_arena.get_node("StaticBody2D/CollisionPolygon2D")
		if collision_polygon and Geometry2D.is_point_in_polygon(pos, collision_polygon.polygon):
			var player = get_tree().get_first_node_in_group("Player")
			if player and pos.distance_to(player.global_position) > 100.0:
				return pos

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
			await _wait_for_level_up_selection()
			start_next_wave()

func _on_boss_died():
	if not boss_phase:
		return

	boss_phase = false
	is_wave_active = false
	current_wave_index = 0

	if Global.pecado == 8:
		return

	current_arena = arena_nodes[0]
	set_waves_based_on_pecado()
	_update_enemy_arena_sprite()
	await _wait_for_level_up_selection()
	await _transition_player_to(ENEMY_ARENA_PLAYER_POSITION)
	start_next_wave()

func _on_pecado_changed(new_pecado):
	if new_pecado == 8:
		await _wait_for_level_up_selection()
		var player = get_tree().get_first_node_in_group("Player")
		if player and player.has_method("win"):
			player.win()
