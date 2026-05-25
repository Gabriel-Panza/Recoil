extends Node2D

# Fundo / Arena
@onready var arena_nodes = [$Arenas/ArenaEnemy, $Arenas/Pecado1, $Arenas/Pecado2, $Arenas/Pecado3, $Arenas/Pecado4, $Arenas/Pecado5, $Arenas/Pecado6, $Arenas/Pecado7]
var current_arena: Node2D

const FADE_DURATION: float = 0.4
const ENEMY_ARENA_PLAYER_POSITION: Vector2 = Vector2(770, 414)
const SPAWN_WALL_PADDING: float = 8.0
const SPAWN_PLAYER_MIN_DISTANCE: float = 100.0
const CAMERA_LIMIT_MARGIN: int = 50
const ARENA_TILESET_TEXTURE = preload("res://Sprites/tileset_hell.png")
const ARENA_TILE_SIZE: Vector2i = Vector2i(48, 48)
const ARENA_TILESET_MARGIN: Vector2i = Vector2i(5, 8)
const ARENA_GRID_SIZE: Vector2i = Vector2i(40, 25)
const ARENA_TILE_VISUAL_SCALE: float = 0.64
const ARENA_TILE_SOURCE_ID: int = 0
const ARENA_PURPLE_TILE: Vector2i = Vector2i(0, 0)
const ARENA_RED_TILE: Vector2i = Vector2i(6, 0)
const ARENA_LAVA_TILE: Vector2i = Vector2i(12, 0)
const ARENA_LAVA_PATCHES = [
	Vector2i(7, 1), Vector2i(7, 2), Vector2i(8, 1),
	Vector2i(20, 2), Vector2i(20, 3),
	Vector2i(5, 8), Vector2i(6, 8),
	Vector2i(18, 13), Vector2i(19, 13), Vector2i(20, 13), Vector2i(20, 12), Vector2i(20, 14), Vector2i(21, 14), Vector2i(22, 14), Vector2i(22, 15),
	Vector2i(31, 6), Vector2i(32, 6), Vector2i(32, 7),
	Vector2i(33, 19), Vector2i(34, 19), Vector2i(35, 19), Vector2i(34, 20)
]

var fade_layer: CanvasLayer
var fade_rect: ColorRect
var is_transitioning: bool = false

var arena_tile_set: TileSet

# Preload dos inimigos
const MELEE_ENEMY = preload("res://Cenas/Inimigos/melee_enemy.tscn")
const RANGED_ENEMY = preload("res://Cenas/Inimigos/ranged_enemy.tscn")
const SPREAD_ENEMY = preload("res://Cenas/Inimigos/spread_enemy.tscn")
const TANK_ENEMY = preload("res://Cenas/Inimigos/tank_enemy.tscn")
const AGILE_ENEMY = preload("res://Cenas/Inimigos/agile_enemy.tscn")
const BOSS_ENEMY = preload("res://Cenas/Inimigos/boss.tscn")

# Conjuntos de waves baseados no pecado, com introducao gradual de inimigos.
var wave_sets = {
	1: [  # Sloth
		{"melee": 3, "ranged": 0, "agile": 0, "tank": 0, "spread": 0},
		{"melee": 4, "ranged": 1, "agile": 0, "tank": 0, "spread": 0},
		{"melee": 5, "ranged": 1, "agile": 0, "tank": 0, "spread": 0},
		{"melee": 6, "ranged": 2, "agile": 0, "tank": 0, "spread": 0}
	],
	2: [  # Gluttony
		{"melee": 3, "ranged": 1, "agile": 1, "tank": 0, "spread": 0},
		{"melee": 4, "ranged": 2, "agile": 1, "tank": 0, "spread": 0},
		{"melee": 5, "ranged": 2, "agile": 2, "tank": 0, "spread": 0},
		{"melee": 6, "ranged": 3, "agile": 2, "tank": 0, "spread": 0}
	],
	3: [  # Envy
		{"melee": 4, "ranged": 2, "agile": 1, "tank": 1, "spread": 0},
		{"melee": 5, "ranged": 3, "agile": 1, "tank": 1, "spread": 0},
		{"melee": 6, "ranged": 3, "agile": 2, "tank": 2, "spread": 0},
		{"melee": 7, "ranged": 4, "agile": 2, "tank": 2, "spread": 0}
	],
	4: [  # Wrath
		{"melee": 5, "ranged": 3, "agile": 1, "tank": 1, "spread": 1},
		{"melee": 6, "ranged": 4, "agile": 2, "tank": 2, "spread": 1},
		{"melee": 7, "ranged": 4, "agile": 2, "tank": 2, "spread": 2},
		{"melee": 8, "ranged": 5, "agile": 3, "tank": 3, "spread": 2}
	],
	5: [  # Lust
		{"melee": 6, "ranged": 4, "agile": 2, "tank": 2, "spread": 2},
		{"melee": 6, "ranged": 5, "agile": 3, "tank": 3, "spread": 2},
		{"melee": 7, "ranged": 5, "agile": 3, "tank": 3, "spread": 3},
		{"melee": 8, "ranged": 6, "agile": 4, "tank": 4, "spread": 3}
	],
	6: [  # Greed
		{"melee": 6, "ranged": 5, "agile": 3, "tank": 2, "spread": 3},
		{"melee": 7, "ranged": 6, "agile": 4, "tank": 3, "spread": 3},
		{"melee": 7, "ranged": 6, "agile": 4, "tank": 3, "spread": 4},
		{"melee": 8, "ranged": 7, "agile": 5, "tank": 4, "spread": 4}
	],
	7: [  # Pride
		{"melee": 7, "ranged": 6, "agile": 4, "tank": 3, "spread": 4},
		{"melee": 7, "ranged": 6, "agile": 5, "tank": 4, "spread": 4},
		{"melee": 8, "ranged": 7, "agile": 5, "tank": 4, "spread": 5},
		{"melee": 8, "ranged": 7, "agile": 6, "tank": 5, "spread": 5}
	]
}

var waves = []
var current_wave_index: int = 0
var is_wave_active: bool = false
var boss_phase: bool = false
var enemies_left_to_spawn: int = 0
var run_finished: bool = false
var wave_finish_pending: bool = false

func _ready() -> void:
	randomize()
	Global.pecado = 1
	Global.start_run_timer()
	Global.pecado_changed.connect(_on_pecado_changed)
	_setup_arena_tile_visuals()
	current_arena = arena_nodes[0]
	_setup_fade_overlay()
	_update_enemy_arena_sprite()
	set_waves_based_on_pecado()
	_update_camera_limits()
	start_next_wave()

func finish_run() -> void:
	if run_finished:
		return

	run_finished = true
	Global.finish_current_run()

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
	_update_camera_limits()
	await get_tree().process_frame
	await _fade_to(0.0)
	is_transitioning = false

func _set_player_xp_goal(enemy_count: int, context: String = "normal", boss_pecado: int = 0) -> void:
	if $Player.has_method("start_wave_xp_goal"):
		$Player.start_wave_xp_goal(enemy_count, context, boss_pecado)

func _wait_for_level_up_selection() -> void:
	while $Player.upando:
		await get_tree().create_timer(0.1, false).timeout

func _setup_arena_tile_visuals() -> void:
	arena_tile_set = _create_arena_tile_set()

	for arena in arena_nodes:
		_prepare_arena_node_for_tile_visual(arena)
		_add_arena_tile_layer(arena)
		_add_arena_tile_border(arena)
		_resize_arena_collision(arena)

func _create_arena_tile_set() -> TileSet:
	var tile_set = TileSet.new()
	tile_set.tile_size = ARENA_TILE_SIZE

	var atlas_source = TileSetAtlasSource.new()
	atlas_source.texture = ARENA_TILESET_TEXTURE
	atlas_source.texture_region_size = ARENA_TILE_SIZE
	atlas_source.margins = ARENA_TILESET_MARGIN

	for atlas_coords in [ARENA_PURPLE_TILE, ARENA_RED_TILE, ARENA_LAVA_TILE]:
		atlas_source.create_tile(atlas_coords)

	tile_set.add_source(atlas_source, ARENA_TILE_SOURCE_ID)
	return tile_set

func _prepare_arena_node_for_tile_visual(arena: Node2D) -> void:
	arena.scale = Vector2.ONE
	if arena is Sprite2D:
		(arena as Sprite2D).texture = null

func _add_arena_tile_layer(arena: Node2D) -> void:
	var existing_layer = arena.get_node_or_null("ArenaTileLayer")
	if existing_layer != null:
		arena.remove_child(existing_layer)
		existing_layer.queue_free()

	var tile_layer = TileMapLayer.new()
	tile_layer.name = "ArenaTileLayer"
	tile_layer.tile_set = arena_tile_set
	tile_layer.position = -_get_arena_unscaled_pixel_size() * 0.5 * ARENA_TILE_VISUAL_SCALE
	tile_layer.scale = Vector2.ONE * ARENA_TILE_VISUAL_SCALE
	tile_layer.z_index = 0
	arena.add_child(tile_layer)

	for y in range(ARENA_GRID_SIZE.y):
		for x in range(ARENA_GRID_SIZE.x):
			var atlas_coords = ARENA_RED_TILE if (x + y) % 2 == 0 else ARENA_PURPLE_TILE
			tile_layer.set_cell(Vector2i(x, y), ARENA_TILE_SOURCE_ID, atlas_coords)

	for lava_coords in ARENA_LAVA_PATCHES:
		if _is_tile_inside_arena_grid(lava_coords):
			tile_layer.set_cell(lava_coords, ARENA_TILE_SOURCE_ID, ARENA_LAVA_TILE)

func _add_arena_tile_border(arena: Node2D) -> void:
	var border = arena.get_node_or_null("ArenaTileBorder") as Line2D
	if border == null:
		border = Line2D.new()
		border.name = "ArenaTileBorder"
		border.z_index = 1
		border.width = 6.0
		border.default_color = Color(0.08, 0.04, 0.05, 1.0)
		border.joint_mode = Line2D.LINE_JOINT_SHARP
		arena.add_child(border)

	var half_size = _get_arena_pixel_size() * 0.5
	border.points = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
		Vector2(-half_size.x, -half_size.y)
	])

func _resize_arena_collision(arena: Node2D) -> void:
	var collision_polygon = arena.get_node_or_null("StaticBody2D/CollisionPolygon2D")
	if collision_polygon == null:
		return

	var half_size = _get_arena_pixel_size() * 0.5
	collision_polygon.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])

func _get_arena_pixel_size() -> Vector2:
	return _get_arena_unscaled_pixel_size() * ARENA_TILE_VISUAL_SCALE

func _get_arena_unscaled_pixel_size() -> Vector2:
	return Vector2(ARENA_GRID_SIZE.x * ARENA_TILE_SIZE.x, ARENA_GRID_SIZE.y * ARENA_TILE_SIZE.y)

func _is_tile_inside_arena_grid(tile_coords: Vector2i) -> bool:
	return tile_coords.x >= 0 and tile_coords.y >= 0 and tile_coords.x < ARENA_GRID_SIZE.x and tile_coords.y < ARENA_GRID_SIZE.y

func _update_enemy_arena_sprite() -> void:
	pass

func _update_camera_limits() -> void:
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		camera = $Player.get_node_or_null("Camera2D")
	if camera == null:
		return

	var arena_rect = _get_current_arena_bounds()
	if arena_rect.size == Vector2.ZERO:
		return

	camera.limit_left = int(floor(arena_rect.position.x)) - (CAMERA_LIMIT_MARGIN*2)
	camera.limit_top = int(floor(arena_rect.position.y)) - (CAMERA_LIMIT_MARGIN*2)
	camera.limit_right = int(ceil(arena_rect.end.x)) + CAMERA_LIMIT_MARGIN
	camera.limit_bottom = int(ceil(arena_rect.end.y)) + CAMERA_LIMIT_MARGIN
	camera.reset_smoothing()

func _get_current_arena_bounds() -> Rect2:
	var collision_polygon = _get_current_arena_collision_polygon()
	if collision_polygon == null or collision_polygon.polygon.is_empty():
		return Rect2(current_arena.global_position, Vector2.ZERO)

	var first_point = collision_polygon.to_global(collision_polygon.polygon[0])
	var arena_rect = Rect2(first_point, Vector2.ZERO)
	for point in collision_polygon.polygon:
		arena_rect = arena_rect.expand(collision_polygon.to_global(point))

	return arena_rect

func set_waves_based_on_pecado():
	waves = wave_sets.get(Global.pecado, wave_sets[1])

func start_next_wave():
	if current_wave_index >= waves.size():
		if current_arena == arena_nodes[0]:
			print("4 waves concluidas na arena principal! Indo para arena do pecado {0}.".format([Global.pecado]))
			current_arena = arena_nodes[Global.pecado] if Global.pecado <= arena_nodes.size() - 1 else arena_nodes[1]
			_update_camera_limits()
			boss_phase = true
			spawn_boss()
		return

	is_wave_active = true
	wave_finish_pending = false
	var wave_data = waves[current_wave_index]
	var arena_type = "principal" if current_arena == arena_nodes[0] else "boss"
	print("Wave {0} do pecado {1} ({2}) iniciada!".format([current_wave_index + 1, Global.pecado, arena_type]))
	spawn_wave(wave_data)
	current_wave_index += 1

func spawn_wave(data: Dictionary):
	var level_context = "pre_boss" if current_arena == arena_nodes[0] and current_wave_index == waves.size() - 1 else "normal"
	
	var total_enemies = data["melee"] + data["ranged"] + data["spread"] + data["tank"] + data["agile"]
	_set_player_xp_goal(total_enemies, level_context, Global.pecado)

	if $Player.greed_cursed_level_enabled:
		$Player.grant_bonus_level_up("normal")
		await _wait_for_level_up_selection()

	# Cria filas separadas
	var melee_queue = []
	var other_queue = []
	
	# Coloca todos os melees na primeira fila
	for i in range(data["melee"]): 
		melee_queue.append(MELEE_ENEMY)

	# Coloca o resto na segunda fila
	for i in range(data["ranged"]): other_queue.append(RANGED_ENEMY)
	for i in range(data["spread"]): other_queue.append(SPREAD_ENEMY)
	for i in range(data["tank"]): other_queue.append(TANK_ENEMY)
	for i in range(data["agile"]): other_queue.append(AGILE_ENEMY)
	
	# Embaralha APENAS a fila do resto (ranged, spread, tank, agile)
	other_queue.shuffle()
	
	# Junta as duas filas (Melees na frente, resto bagunçado atrás)
	var spawn_queue = melee_queue + other_queue
	
	enemies_left_to_spawn = spawn_queue.size()

	# Spawna um por um com delay
	for enemy_scene in spawn_queue:
		# Se a wave foi cancelada ou o player morreu, para de spawnar
		if not is_inside_tree() or not is_wave_active: 
			break
			
		spawn_enemy(enemy_scene)
		enemies_left_to_spawn -= 1
		
		# Espera 0.8 segundos entre cada inimigo
		await get_tree().create_timer(2, false).timeout

	await _try_finish_wave()
		
func spawn_boss():
	var centro_node = current_arena.get_node("Centro")
	_set_player_xp_goal(1, "boss", Global.pecado)
	await _transition_player_to(centro_node.global_position)
	await get_tree().create_timer(1, false).timeout

	var boss = BOSS_ENEMY.instantiate()
	_apply_enemy_spawn_modifiers(boss)
	var spawn_margin = _get_body_spawn_margin(boss)
	boss.global_position = get_random_camera_edge_position(spawn_margin)
	boss.add_to_group("Boss")
	boss.connect("boss_defeated", Callable(self, "_on_boss_died"))
	add_child(boss)

func spawn_enemy(enemy_scene: PackedScene):
	var enemy = enemy_scene.instantiate()
	_apply_enemy_spawn_modifiers(enemy)
	add_child(enemy)

	var spawn_margin = _get_body_spawn_margin(enemy)
	enemy.global_position = get_random_camera_edge_position(spawn_margin)

	# Monitora a morte do inimigo
	enemy.tree_exited.connect(_on_enemy_died)

func _apply_enemy_spawn_modifiers(enemy: Node) -> void:
	if $Player.greed_cursed_level_enabled and enemy.get("speed") != null:
		enemy.set("speed", enemy.get("speed") * 1.25)

func get_random_camera_edge_position(spawn_margin: float = 0.0) -> Vector2:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return get_random_arena_position(spawn_margin)

	var cam_pos = camera.global_position
	var viewport_size = get_viewport_rect().size
	var cam_rect = Rect2(cam_pos - viewport_size / 2, viewport_size)

	var margin = 50.0
	var attempts = 20

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

		if _is_position_safe_in_current_arena(pos, spawn_margin):
			var player = get_tree().get_first_node_in_group("Player")
			if player == null or pos.distance_to(player.global_position) > SPAWN_PLAYER_MIN_DISTANCE:
				return pos

	return get_random_arena_position(spawn_margin)

func get_random_arena_position(spawn_margin: float = 0.0) -> Vector2:
	var collision_polygon = _get_current_arena_collision_polygon()
	if collision_polygon == null:
		return current_arena.global_position

	var global_points = []
	for point in collision_polygon.polygon:
		global_points.append(collision_polygon.to_global(point))

	var arena_rect = Rect2(global_points[0], Vector2.ZERO)
	for point in global_points:
		arena_rect = arena_rect.expand(point)

	for i in range(80):
		var pos = Vector2(
			randf_range(arena_rect.position.x, arena_rect.end.x),
			randf_range(arena_rect.position.y, arena_rect.end.y)
		)
		if _is_position_safe_in_current_arena(pos, spawn_margin):
			var player = get_tree().get_first_node_in_group("Player")
			if player == null or pos.distance_to(player.global_position) > SPAWN_PLAYER_MIN_DISTANCE:
				return pos

	return clamp_position_to_current_arena(current_arena.global_position, spawn_margin)

func clamp_position_to_current_arena(global_pos: Vector2, safety_margin: float = 0.0) -> Vector2:
	if _is_position_safe_in_current_arena(global_pos, safety_margin):
		return global_pos

	var center = _get_current_arena_center()
	if not _is_position_safe_in_current_arena(center, safety_margin):
		center = current_arena.global_position

	if not _is_position_safe_in_current_arena(center, 0.0):
		return global_pos

	var best_position = center
	var low = 0.0
	var high = 1.0
	for i in range(18):
		var mid = (low + high) * 0.5
		var candidate = center.lerp(global_pos, mid)
		if _is_position_safe_in_current_arena(candidate, safety_margin):
			best_position = candidate
			low = mid
		else:
			high = mid

	return best_position

func _is_position_safe_in_current_arena(global_pos: Vector2, safety_margin: float = 0.0) -> bool:
	if not _is_position_inside_current_arena(global_pos):
		return false

	if safety_margin <= 0.0:
		return true

	var diagonal_margin = safety_margin * 0.70710678
	var offsets = [
		Vector2(safety_margin, 0.0),
		Vector2(-safety_margin, 0.0),
		Vector2(0.0, safety_margin),
		Vector2(0.0, -safety_margin),
		Vector2(diagonal_margin, diagonal_margin),
		Vector2(-diagonal_margin, diagonal_margin),
		Vector2(diagonal_margin, -diagonal_margin),
		Vector2(-diagonal_margin, -diagonal_margin)
	]

	for offset in offsets:
		if not _is_position_inside_current_arena(global_pos + offset):
			return false

	return true

func _get_body_spawn_margin(body: Node) -> float:
	if body.has_method("_get_separation_radius"):
		return float(body.call("_get_separation_radius")) + SPAWN_WALL_PADDING

	var collision = body.get_node_or_null("CollisionShape2D")
	return _get_collision_shape_radius(collision) + SPAWN_WALL_PADDING

func _get_collision_shape_radius(collision) -> float:
	if collision == null or not (collision is CollisionShape2D) or collision.shape == null:
		return 24.0

	if collision.shape is CapsuleShape2D:
		return max(collision.shape.radius, collision.shape.height * 0.25)
	if collision.shape is CircleShape2D:
		return collision.shape.radius
	if collision.shape is RectangleShape2D:
		return min(collision.shape.size.x, collision.shape.size.y) * 0.5

	return 24.0

func _get_current_arena_center() -> Vector2:
	var center_marker = current_arena.get_node_or_null("Centro")
	if center_marker is Node2D:
		return center_marker.global_position

	return current_arena.global_position

func _is_position_inside_current_arena(global_pos: Vector2) -> bool:
	var collision_polygon = _get_current_arena_collision_polygon()
	if collision_polygon == null:
		return true

	var local_pos = collision_polygon.to_local(global_pos)
	return Geometry2D.is_point_in_polygon(local_pos, collision_polygon.polygon)

func _get_current_arena_collision_polygon() -> CollisionPolygon2D:
	return current_arena.get_node_or_null("StaticBody2D/CollisionPolygon2D")

func _on_enemy_died() -> void:
	if not is_inside_tree() or not is_wave_active:
		return

	await get_tree().process_frame
	await _try_finish_wave()

func _try_finish_wave() -> void:
	if not is_inside_tree() or not is_wave_active or wave_finish_pending:
		return

	if enemies_left_to_spawn > 0:
		return

	if get_tree().get_nodes_in_group("Enemy"):
		return

	wave_finish_pending = true
	is_wave_active = false
	await get_tree().create_timer(0.5, false).timeout
	if not is_inside_tree():
		return
	await _wait_for_level_up_selection()
	if not is_inside_tree():
		return
	wave_finish_pending = false
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
	_update_camera_limits()
	await _wait_for_level_up_selection()
	await _transition_player_to(ENEMY_ARENA_PLAYER_POSITION)
	start_next_wave()

func _on_pecado_changed(new_pecado):
	if new_pecado > 7:
		await _wait_for_level_up_selection()
		var player = get_tree().get_first_node_in_group("Player")
		if player and player.has_method("win"):
			player.win()
