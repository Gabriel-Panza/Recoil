extends Node2D

# Fundo / Arena
@onready var arena_nodes = [$Arenas/ArenaEnemy, $Arenas/Pecado1, $Arenas/Pecado2, $Arenas/Pecado3, $Arenas/Pecado4, $Arenas/Pecado5, $Arenas/Pecado6, $Arenas/Pecado7]
var current_arena: Node2D

const FADE_DURATION: float = 0.4
const ENEMY_ARENA_PLAYER_POSITION: Vector2 = Vector2(770, 414)
const SPAWN_WALL_PADDING: float = 8.0
const SPAWN_PLAYER_MIN_DISTANCE: float = 100.0
const ARENA_CLAMP_BINARY_SEARCH_STEPS: int = 18
const ARENA_CLAMP_EDGE_NUDGE_MULTIPLIERS = [1.0, 2.0, 4.0, 8.0]
const WAVE_SPAWN_INTERVAL: float = 0.75
const CAMERA_LIMIT_MARGIN: int = 50
const ARENA_TILESET_TEXTURE = preload("res://Sprites/tileset_hell.png")
const ENVY_ARENA_TILESET_TEXTURE = preload("res://Sprites/tileset_mirror.png")
const ARENA_TILE_SIZE: Vector2i = Vector2i(48, 48)
const ARENA_TILESET_MARGIN: Vector2i = Vector2i(5, 8)
const ARENA_GRID_SIZE: Vector2i = Vector2i(40, 25)
const ARENA_TILE_VISUAL_SCALE: float = 0.64
const ARENA_TILE_SOURCE_ID: int = 0
const ARENA_TILESET_HELL: String = "hell"
const ARENA_TILESET_MIRROR: String = "mirror"
const ARENA_FILL_TILEMAP: String = "tilemap"
const ARENA_FILL_ROUND_TILES: String = "round_tiles"
const ARENA_FILL_MIRROR_SURFACE: String = "mirror_surface"
const ARENA_DETAIL_MIRROR_PANELS: String = "mirror_panels"
const ARENA_SHAPE_RECT: String = "rect"
const ARENA_SHAPE_ROUNDED_RECT: String = "rounded_rect"
const ARENA_SHAPE_ELLIPSE: String = "ellipse"
const ARENA_SHAPE_FLAME_CIRCLE: String = "flame_circle"
const ARENA_SHAPE_SERPENT: String = "serpent"
const ARENA_SHAPE_GOBLET: String = "goblet"
const ARENA_SHAPE_CROWN: String = "crown"
const ARENA_POLYGON_SEGMENTS: int = 64
const ARENA_ROUNDED_RECT_SEGMENTS: int = 10
const ARENA_PURPLE_TILE: Vector2i = Vector2i(0, 0)
const ARENA_RED_TILE: Vector2i = Vector2i(6, 0)
const ARENA_LAVA_TILE: Vector2i = Vector2i(12, 0)
const MIRROR_DARK_TILE: Vector2i = Vector2i(2, 5)
const MIRROR_LIGHT_TILE: Vector2i = Vector2i(8, 5)
const MIRROR_ACCENT_TILE: Vector2i = Vector2i(5, 5)
const MIRROR_REFLECT_TILE: Vector2i = Vector2i(11, 5)
const MIRROR_PANEL_TILE: Vector2i = Vector2i(2, 1)
const MIRROR_PANEL_ALT_TILE: Vector2i = Vector2i(8, 8)
const MIRROR_TILE_SCALE: float = 0.42
const MIRROR_BASE_COLOR: Color = Color(0.47, 0.54, 0.55, 1.0)
const MIRROR_PANEL_COLOR: Color = Color(0.62, 0.69, 0.70, 0.68)
const MIRROR_PANEL_ALT_COLOR: Color = Color(0.38, 0.45, 0.46, 0.64)
const MIRROR_PANEL_LINE_COLOR: Color = Color(0.93, 0.98, 1.0, 0.34)
const MIRROR_PANEL_LINE_WIDTH: float = 2.4
const MIRROR_PANEL_COUNT: int = 5
const MIRROR_INNER_MARGIN: float = 18.0
const MIRROR_HIGHLIGHT_COLOR: Color = Color(0.97, 1.0, 1.0, 0.22)
const ROUND_ARENA_TILE_RADIUS: float = 16.5
const ROUND_ARENA_TILE_SPACING: float = 31.0
const ROUND_ARENA_TILE_SEGMENTS: int = 18
const GLUTTONY_PLATE_FILL_COLOR: Color = Color(0.17, 0.055, 0.052, 1.0)
const GLUTTONY_INNER_RING_COLOR: Color = Color(0.16, 0.07, 0.04, 0.34)
const HELL_FLOOR_UNDERLAY_COLOR: Color = Color(0.25, 0.105, 0.095, 1.0)
const HELL_ROUND_DARK_TILE_COLOR: Color = Color(0.22, 0.17, 0.22, 1.0)
const HELL_ROUND_RED_TILE_COLOR: Color = Color(0.43, 0.095, 0.075, 1.0)
const HELL_ROUND_LAVA_TILE_COLOR: Color = Color(0.78, 0.33, 0.055, 1.0)
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
var starting_arm_layer: CanvasLayer
var is_transitioning: bool = false

var arena_tile_sets: Dictionary = {}

# Preload dos inimigos
const MELEE_ENEMY = preload("res://Cenas/Inimigos/melee_enemy.tscn")
const RANGED_ENEMY = preload("res://Cenas/Inimigos/ranged_enemy.tscn")
const SPREAD_ENEMY = preload("res://Cenas/Inimigos/spread_enemy.tscn")
const TANK_ENEMY = preload("res://Cenas/Inimigos/tank_enemy.tscn")
const AGILE_ENEMY = preload("res://Cenas/Inimigos/agile_enemy.tscn")
const BOSS_ENEMY = preload("res://Cenas/Inimigos/boss.tscn")

const WAVE_SETS = {
	1: [  # Sloth
		{"melee": 3, "ranged": 0, "agile": 0, "tank": 0, "spread": 0},
		{"melee": 3, "ranged": 1, "agile": 0, "tank": 0, "spread": 0},
		{"melee": 4, "ranged": 2, "agile": 0, "tank": 0, "spread": 0},
		{"melee": 5, "ranged": 3, "agile": 0, "tank": 0, "spread": 0}
	],
	2: [  # Gluttony
		{"melee": 3, "ranged": 1, "agile": 0, "tank": 1, "spread": 0},
		{"melee": 4, "ranged": 2, "agile": 0, "tank": 1, "spread": 0},
		{"melee": 5, "ranged": 3, "agile": 0, "tank": 2, "spread": 0},
		{"melee": 5, "ranged": 3, "agile": 0, "tank": 2, "spread": 0}
	],
	3: [  # Envy
		{"melee": 4, "ranged": 2, "agile": 1, "tank": 1, "spread": 0},
		{"melee": 5, "ranged": 3, "agile": 1, "tank": 1, "spread": 0},
		{"melee": 6, "ranged": 3, "agile": 2, "tank": 2, "spread": 0},
		{"melee": 6, "ranged": 4, "agile": 2, "tank": 2, "spread": 0}
	],
	4: [  # Wrath
		{"melee": 4, "ranged": 3, "agile": 1, "tank": 1, "spread": 1},
		{"melee": 5, "ranged": 3, "agile": 2, "tank": 1, "spread": 1},
		{"melee": 6, "ranged": 4, "agile": 2, "tank": 2, "spread": 2},
		{"melee": 6, "ranged": 4, "agile": 3, "tank": 3, "spread": 2}
	],
	5: [  # Lust
		{"melee": 5, "ranged": 3, "agile": 2, "tank": 1, "spread": 1},
		{"melee": 6, "ranged": 4, "agile": 2, "tank": 2, "spread": 2},
		{"melee": 7, "ranged": 4, "agile": 3, "tank": 2, "spread": 2},
		{"melee": 7, "ranged": 4, "agile": 3, "tank": 3, "spread": 3}
	],
	6: [  # Greed
		{"melee": 5, "ranged": 4, "agile": 2, "tank": 2, "spread": 2},
		{"melee": 6, "ranged": 4, "agile": 3, "tank": 2, "spread": 2},
		{"melee": 7, "ranged": 4, "agile": 3, "tank": 3, "spread": 3},
		{"melee": 7, "ranged": 4, "agile": 4, "tank": 3, "spread": 3}
	],
	7: [  # Pride
		{"melee": 6, "ranged": 4, "agile": 3, "tank": 3, "spread": 2},
		{"melee": 7, "ranged": 4, "agile": 3, "tank": 3, "spread": 3},
		{"melee": 8, "ranged": 5, "agile": 4, "tank": 3, "spread": 3},
		{"melee": 8, "ranged": 5, "agile": 4, "tank": 3, "spread": 4}
	]
}

var waves = []
var current_wave_index: int = 0
var is_wave_active: bool = false
var boss_phase: bool = false
var enemies_left_to_spawn: int = 0
var run_finished: bool = false
var wave_finish_pending: bool = false

signal starting_arm_selected

const BOSS_CLEAR_HEAL_RATIO: float = 0.20
const BOSS_SPAWN_DELAY_AFTER_ARENA_ARRIVAL: float = 0.5

func _ready() -> void:
	for musica in get_tree().get_nodes_in_group(Global.GROUP_MUSIC):
		musica.set_volume_db(Global.music_volume_db)
	for som in get_tree().get_nodes_in_group(Global.GROUP_SFX):
		som.set_volume_db(Global.sfx_volume_db)

	randomize()
	Global.pecado = 1
	Global.pecado_changed.connect(_on_pecado_changed)
	_setup_arena_tile_visuals()
	current_arena = arena_nodes[0]
	_setup_fade_overlay()
	set_waves_based_on_pecado()
	_update_camera_limits()
	await _show_starting_arm_selection()
	Global.start_run_timer()
	start_next_wave()

func finish_run() -> bool:
	if run_finished:
		return true

	if not Global.finish_current_run():
		return false

	run_finished = true
	return true

func _show_starting_arm_selection() -> void:
	if $Player == null or not $Player.has_method("apply_starting_arm"):
		return

	get_tree().paused = true
	starting_arm_layer = CanvasLayer.new()
	starting_arm_layer.name = "StartingArmSelectionLayer"
	starting_arm_layer.layer = 120
	starting_arm_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(starting_arm_layer)

	var overlay = Control.new()
	overlay.name = "StartingArmSelection"
	overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	starting_arm_layer.add_child(overlay)

	var backdrop = ColorRect.new()
	backdrop.color = Color(0.02, 0.01, 0.015, 0.88)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(backdrop)

	var panel = PanelContainer.new()
	panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	var viewport_size = get_viewport_rect().size
	var panel_size = Vector2(min(viewport_size.x - 96.0, 1040.0), 380.0)
	panel.custom_minimum_size = panel_size
	panel.size = panel_size
	panel.position = ((viewport_size - panel_size) * 0.5).round()
	panel.add_theme_stylebox_override("panel", _make_starting_arm_style(Color(0.10, 0.045, 0.055, 0.96), Color(0.95, 0.25, 0.12, 0.92), 3))
	overlay.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	var title = Label.new()
	title.text = "O demonio escolhe como segurar seu braco"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.72, 0.42, 1.0))
	layout.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Sua arma e seu movimento tambem. Escolha o pacto que definirá sua run."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.95, 0.86, 0.76, 1.0))
	layout.add_child(subtitle)

	var choices = HBoxContainer.new()
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices.add_theme_constant_override("separation", 16)
	layout.add_child(choices)

	for option in Global.STARTING_ARM_OPTIONS:
		var button = Button.new()
		button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 190)
		button.text = "%s\n\n%s\n%s" % [option["name"], option["summary"], option["details"]]
		button.tooltip_text = str(option["details"])
		button.add_theme_font_size_override("font_size", 17)
		button.add_theme_color_override("font_color", Color(1.0, 0.95, 0.82, 1.0))
		button.add_theme_stylebox_override("normal", _make_starting_arm_style(Color(0.16, 0.07, 0.075, 0.98), Color(0.52, 0.18, 0.12, 0.95), 2))
		button.add_theme_stylebox_override("hover", _make_starting_arm_style(Color(0.26, 0.10, 0.08, 0.98), Color(1.0, 0.54, 0.20, 1.0), 3))
		button.add_theme_stylebox_override("pressed", _make_starting_arm_style(Color(0.34, 0.13, 0.08, 0.98), Color(1.0, 0.76, 0.28, 1.0), 3))
		button.pressed.connect(Callable(self, "_on_starting_arm_button_pressed").bind(str(option["id"])))
		choices.add_child(button)

	await starting_arm_selected

func _on_starting_arm_button_pressed(arm_id: String) -> void:
	if $Player != null and $Player.has_method("apply_starting_arm"):
		$Player.apply_starting_arm(arm_id)

	if starting_arm_layer != null:
		starting_arm_layer.queue_free()
		starting_arm_layer = null

	get_tree().paused = false
	starting_arm_selected.emit()

func _make_starting_arm_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	return style

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
	arena_tile_sets = {
		ARENA_TILESET_HELL: _create_arena_tile_set(ARENA_TILESET_TEXTURE, [ARENA_PURPLE_TILE, ARENA_RED_TILE, ARENA_LAVA_TILE]),
		ARENA_TILESET_MIRROR: _create_arena_tile_set(ENVY_ARENA_TILESET_TEXTURE, [MIRROR_DARK_TILE, MIRROR_LIGHT_TILE, MIRROR_ACCENT_TILE, MIRROR_REFLECT_TILE, MIRROR_PANEL_TILE, MIRROR_PANEL_ALT_TILE])
	}

	for arena_index in range(arena_nodes.size()):
		var arena = arena_nodes[arena_index]
		var profile = _get_arena_profile(arena_index)
		_prepare_arena_node_for_tile_visual(arena)
		_add_arena_floor_underlay(arena, profile)
		_add_arena_tile_layer(arena, profile, arena_index)
		_add_arena_tile_border(arena, profile)
		_add_arena_inner_details(arena, profile)
		_add_arena_mirror_panel_details(arena, profile)
		_resize_arena_collision(arena, profile)

func _create_arena_tile_set(texture: Texture2D, atlas_tiles: Array) -> TileSet:
	var tile_set = TileSet.new()
	tile_set.tile_size = ARENA_TILE_SIZE

	var atlas_source = TileSetAtlasSource.new()
	atlas_source.texture = texture
	atlas_source.texture_region_size = ARENA_TILE_SIZE
	atlas_source.margins = ARENA_TILESET_MARGIN

	for atlas_coords in atlas_tiles:
		if _is_atlas_tile_inside_texture(texture, atlas_coords):
			atlas_source.create_tile(atlas_coords)

	tile_set.add_source(atlas_source, ARENA_TILE_SOURCE_ID)
	return tile_set

func _is_atlas_tile_inside_texture(texture: Texture2D, atlas_coords: Vector2i) -> bool:
	if texture == null:
		return false

	var tile_start = ARENA_TILESET_MARGIN + atlas_coords * ARENA_TILE_SIZE
	return tile_start.x + ARENA_TILE_SIZE.x <= texture.get_width() and tile_start.y + ARENA_TILE_SIZE.y <= texture.get_height()

func _prepare_arena_node_for_tile_visual(arena: Node2D) -> void:
	arena.scale = Vector2.ONE
	if arena is Sprite2D:
		(arena as Sprite2D).texture = null

func _add_arena_tile_layer(arena: Node2D, profile: Dictionary, arena_index: int) -> void:
	var existing_layer = arena.get_node_or_null("ArenaTileLayer")
	if existing_layer != null:
		arena.remove_child(existing_layer)
		existing_layer.queue_free()

	if str(profile.get("fill", ARENA_FILL_TILEMAP)) == ARENA_FILL_MIRROR_SURFACE:
		_add_mirror_arena_surface(arena, profile, arena_index)
		return

	if str(profile.get("fill", ARENA_FILL_TILEMAP)) == ARENA_FILL_ROUND_TILES:
		_add_round_arena_tile_layer(arena, profile, arena_index)
		return

	var tile_layer = TileMapLayer.new()
	tile_layer.name = "ArenaTileLayer"
	tile_layer.tile_set = _get_tile_set_for_profile(profile)
	tile_layer.scale = Vector2.ONE * _get_arena_tile_visual_scale(profile)
	tile_layer.z_index = 0
	arena.add_child(tile_layer)

	if str(profile.get("shape", ARENA_SHAPE_RECT)) == ARENA_SHAPE_RECT:
		_fill_rect_arena_tile_layer(tile_layer, profile, arena_index)
		return

	var polygon = _build_arena_polygon(profile)
	var bounds = _get_local_polygon_bounds(polygon)
	var tile_parent_size = Vector2(float(ARENA_TILE_SIZE.x), float(ARENA_TILE_SIZE.y)) * _get_arena_tile_visual_scale(profile)
	var min_cell = Vector2i(
		floori(bounds.position.x / tile_parent_size.x) - 1,
		floori(bounds.position.y / tile_parent_size.y) - 1
	)
	var max_cell = Vector2i(
		ceili(bounds.end.x / tile_parent_size.x) + 1,
		ceili(bounds.end.y / tile_parent_size.y) + 1
	)

	for y in range(min_cell.y, max_cell.y + 1):
		for x in range(min_cell.x, max_cell.x + 1):
			var tile_coords = Vector2i(x, y)
			var tile_center = _get_arena_tile_center_position(tile_coords, profile)
			if not _is_tile_visually_inside_arena_polygon(tile_center, tile_parent_size * 0.46, polygon, bool(profile.get("strict_tile_clip", false))):
				continue

			var atlas_coords = _get_arena_tile_atlas_coords(tile_coords, arena_index, profile)
			tile_layer.set_cell(tile_coords, ARENA_TILE_SOURCE_ID, atlas_coords)

func _fill_rect_arena_tile_layer(tile_layer: TileMapLayer, profile: Dictionary, arena_index: int) -> void:
	var size = profile.get("size", _get_arena_pixel_size()) as Vector2
	var tile_parent_size = Vector2(float(ARENA_TILE_SIZE.x), float(ARENA_TILE_SIZE.y)) * _get_arena_tile_visual_scale(profile)
	var cell_count = Vector2i(
		max(1, roundi(size.x / tile_parent_size.x)),
		max(1, roundi(size.y / tile_parent_size.y))
	)
	var filled_size = Vector2(cell_count) * tile_parent_size
	tile_layer.position = -filled_size * 0.5

	for y in range(cell_count.y):
		for x in range(cell_count.x):
			var tile_coords = Vector2i(x, y)
			var atlas_coords = _get_arena_tile_atlas_coords(tile_coords, arena_index, profile)
			tile_layer.set_cell(tile_coords, ARENA_TILE_SOURCE_ID, atlas_coords)

func _add_arena_floor_underlay(arena: Node2D, profile: Dictionary) -> void:
	var existing_underlay = arena.get_node_or_null("ArenaFloorUnderlay")
	if existing_underlay != null:
		arena.remove_child(existing_underlay)
		existing_underlay.queue_free()

	if str(profile.get("fill", ARENA_FILL_TILEMAP)) == ARENA_FILL_ROUND_TILES:
		return

	var underlay = Polygon2D.new()
	underlay.name = "ArenaFloorUnderlay"
	underlay.z_index = 0
	underlay.polygon = _build_visual_floor_polygon(profile)
	underlay.color = profile.get("floor_underlay_color", _get_default_floor_underlay_color(profile))
	arena.add_child(underlay)

func _build_visual_floor_polygon(profile: Dictionary) -> PackedVector2Array:
	var polygon = _build_arena_polygon(profile)
	var bleed = float(profile.get("floor_bleed", 1.0))
	if abs(bleed - 1.0) <= 0.001:
		return polygon

	var expanded = PackedVector2Array()
	for point in polygon:
		expanded.append(point * bleed)
	return expanded

func _get_default_floor_underlay_color(profile: Dictionary) -> Color:
	if str(profile.get("tile_set", ARENA_TILESET_HELL)) == ARENA_TILESET_MIRROR:
		return MIRROR_BASE_COLOR
	return HELL_FLOOR_UNDERLAY_COLOR

func _add_mirror_arena_surface(arena: Node2D, profile: Dictionary, arena_index: int) -> void:
	var layer = Node2D.new()
	layer.name = "ArenaTileLayer"
	layer.z_index = 0
	arena.add_child(layer)

	var base = Polygon2D.new()
	base.name = "MirrorBaseSurface"
	base.polygon = _build_visual_floor_polygon(profile)
	base.color = MIRROR_BASE_COLOR
	layer.add_child(base)

	_add_large_mirror_panels(layer, profile, arena_index)
	_add_mirror_surface_highlights(layer, profile, arena_index)

func _add_large_mirror_panels(layer: Node2D, profile: Dictionary, arena_index: int) -> void:
	var size = profile.get("size", _get_arena_pixel_size()) as Vector2
	var half_size = size * 0.5
	var radius = float(profile.get("radius", 72.0))
	var usable_left = -half_size.x + MIRROR_INNER_MARGIN
	var usable_right = half_size.x - MIRROR_INNER_MARGIN
	var panel_width = (usable_right - usable_left) / float(MIRROR_PANEL_COUNT)

	for panel_index in range(MIRROR_PANEL_COUNT):
		var x_left = usable_left + panel_width * float(panel_index)
		var x_right = usable_left + panel_width * float(panel_index + 1)
		var panel = Polygon2D.new()
		panel.name = "MirrorPanel%d" % panel_index
		panel.polygon = _build_rounded_rect_vertical_slice_polygon(x_left, x_right, half_size, radius, MIRROR_INNER_MARGIN)
		panel.color = _get_mirror_panel_color(panel_index, arena_index)
		layer.add_child(panel)

func _get_mirror_panel_color(panel_index: int, arena_index: int) -> Color:
	var hash_value = abs(panel_index * 9283 + arena_index * 173)
	var base_color = MIRROR_PANEL_COLOR if hash_value % 2 == 0 else MIRROR_PANEL_ALT_COLOR
	var brightness = 0.94 + float(hash_value % 7) * 0.018
	return Color(
		clamp(base_color.r * brightness, 0.0, 1.0),
		clamp(base_color.g * brightness, 0.0, 1.0),
		clamp(base_color.b * brightness, 0.0, 1.0),
		base_color.a
	)

func _build_rounded_rect_vertical_slice_polygon(x_left: float, x_right: float, half_size: Vector2, radius: float, inset: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	var samples = 6
	for sample in range(samples + 1):
		var t = float(sample) / float(samples)
		var x = lerp(x_left, x_right, t)
		points.append(Vector2(x, _get_rounded_rect_edge_y_for_x(x, half_size, radius, true) + inset))

	for sample in range(samples, -1, -1):
		var t = float(sample) / float(samples)
		var x = lerp(x_left, x_right, t)
		points.append(Vector2(x, _get_rounded_rect_edge_y_for_x(x, half_size, radius, false) - inset))

	return points

func _get_rounded_rect_edge_y_for_x(x: float, half_size: Vector2, radius: float, top: bool) -> float:
	var safe_radius = min(radius, min(half_size.x, half_size.y) - 4.0)
	var straight_half_width = half_size.x - safe_radius
	var abs_x = abs(x)
	if abs_x <= straight_half_width:
		return -half_size.y if top else half_size.y

	var dx = min(abs_x - straight_half_width, safe_radius)
	var circle_y = sqrt(max(safe_radius * safe_radius - dx * dx, 0.0))
	if top:
		return -half_size.y + safe_radius - circle_y
	return half_size.y - safe_radius + circle_y

func _add_mirror_surface_highlights(layer: Node2D, profile: Dictionary, arena_index: int) -> void:
	var size = profile.get("size", _get_arena_pixel_size()) as Vector2
	var half_size = size * 0.5
	var radius = float(profile.get("radius", 72.0))
	var usable_left = -half_size.x + MIRROR_INNER_MARGIN
	var usable_right = half_size.x - MIRROR_INNER_MARGIN
	var panel_width = (usable_right - usable_left) / float(MIRROR_PANEL_COUNT)

	for panel_index in range(MIRROR_PANEL_COUNT):
		var x_left = usable_left + panel_width * float(panel_index)
		var x_right = usable_left + panel_width * float(panel_index + 1)
		var top_y = max(
			_get_rounded_rect_edge_y_for_x(x_left, half_size, radius, true),
			_get_rounded_rect_edge_y_for_x(x_right, half_size, radius, true)
		) + MIRROR_INNER_MARGIN + 18.0
		var line = Line2D.new()
		line.width = 3.0 if panel_index % 2 == 0 else 2.0
		line.default_color = MIRROR_HIGHLIGHT_COLOR
		line.points = PackedVector2Array([
			Vector2(x_left + panel_width * 0.18, top_y + float((panel_index + arena_index) % 3) * 34.0),
			Vector2(x_right - panel_width * 0.24, top_y + 180.0 + float(panel_index % 2) * 54.0)
		])
		layer.add_child(line)

func _add_round_arena_tile_layer(arena: Node2D, profile: Dictionary, arena_index: int) -> void:
	var layer = Node2D.new()
	layer.name = "ArenaTileLayer"
	layer.z_index = 0
	arena.add_child(layer)

	var polygon = _build_arena_polygon(profile)
	var plate_fill = Polygon2D.new()
	plate_fill.name = "GluttonyPlateFill"
	plate_fill.polygon = polygon
	plate_fill.color = GLUTTONY_PLATE_FILL_COLOR
	layer.add_child(plate_fill)

	var bounds = _get_local_polygon_bounds(polygon)
	var min_cell = Vector2i(
		floori(bounds.position.x / ROUND_ARENA_TILE_SPACING) - 1,
		floori(bounds.position.y / ROUND_ARENA_TILE_SPACING) - 1
	)
	var max_cell = Vector2i(
		ceili(bounds.end.x / ROUND_ARENA_TILE_SPACING) + 1,
		ceili(bounds.end.y / ROUND_ARENA_TILE_SPACING) + 1
	)
	var round_tile_polygon = _build_circle_polygon(ROUND_ARENA_TILE_RADIUS, ROUND_ARENA_TILE_SEGMENTS)

	for y in range(min_cell.y, max_cell.y + 1):
		for x in range(min_cell.x, max_cell.x + 1):
			var stagger_offset = ROUND_ARENA_TILE_SPACING * 0.5 if abs(y) % 2 == 1 else 0.0
			var tile_center = Vector2(float(x) * ROUND_ARENA_TILE_SPACING + stagger_offset, float(y) * ROUND_ARENA_TILE_SPACING)
			if not _is_round_tile_visually_inside_arena_polygon(tile_center, ROUND_ARENA_TILE_RADIUS * 0.78, polygon):
				continue

			var tile = Polygon2D.new()
			tile.polygon = round_tile_polygon
			tile.position = tile_center
			tile.color = _get_round_arena_tile_color(Vector2i(x, y), arena_index)
			layer.add_child(tile)

func _is_round_tile_visually_inside_arena_polygon(tile_center: Vector2, radius: float, polygon: PackedVector2Array) -> bool:
	if not Geometry2D.is_point_in_polygon(tile_center, polygon):
		return false

	var samples = [
		tile_center + Vector2(radius, 0.0),
		tile_center + Vector2(-radius, 0.0),
		tile_center + Vector2(0.0, radius),
		tile_center + Vector2(0.0, -radius)
	]
	for sample in samples:
		if not Geometry2D.is_point_in_polygon(sample, polygon):
			return false

	return true

func _get_round_arena_tile_color(tile_coords: Vector2i, arena_index: int) -> Color:
	if _should_place_lava_tile(tile_coords, arena_index):
		return HELL_ROUND_LAVA_TILE_COLOR
	return HELL_ROUND_RED_TILE_COLOR if (tile_coords.x + tile_coords.y) % 2 == 0 else HELL_ROUND_DARK_TILE_COLOR

func _get_tile_set_for_profile(profile: Dictionary) -> TileSet:
	var tile_set_id = str(profile.get("tile_set", ARENA_TILESET_HELL))
	return arena_tile_sets.get(tile_set_id, arena_tile_sets.get(ARENA_TILESET_HELL, TileSet.new()))

func _get_arena_tile_visual_scale(profile: Dictionary) -> float:
	return float(profile.get("tile_scale", ARENA_TILE_VISUAL_SCALE))

func _get_arena_tile_center_position(tile_coords: Vector2i, profile: Dictionary) -> Vector2:
	return (Vector2(tile_coords) + Vector2(0.5, 0.5)) * Vector2(float(ARENA_TILE_SIZE.x), float(ARENA_TILE_SIZE.y)) * _get_arena_tile_visual_scale(profile)

func _is_tile_visually_inside_arena_polygon(tile_center: Vector2, tile_half_size: Vector2, polygon: PackedVector2Array, strict_clip: bool) -> bool:
	if not Geometry2D.is_point_in_polygon(tile_center, polygon):
		return false
	if not strict_clip:
		return true

	var samples = [
		tile_center + Vector2(tile_half_size.x, tile_half_size.y),
		tile_center + Vector2(-tile_half_size.x, tile_half_size.y),
		tile_center + Vector2(tile_half_size.x, -tile_half_size.y),
		tile_center + Vector2(-tile_half_size.x, -tile_half_size.y)
	]
	for sample in samples:
		if not Geometry2D.is_point_in_polygon(sample, polygon):
			return false
	return true

func _get_arena_tile_atlas_coords(tile_coords: Vector2i, arena_index: int, profile: Dictionary) -> Vector2i:
	if str(profile.get("tile_set", ARENA_TILESET_HELL)) == ARENA_TILESET_MIRROR:
		return _get_mirror_arena_tile_atlas_coords(tile_coords, arena_index)

	if _should_place_lava_tile(tile_coords, arena_index):
		return ARENA_LAVA_TILE

	return ARENA_RED_TILE if (tile_coords.x + tile_coords.y) % 2 == 0 else ARENA_PURPLE_TILE

func _should_place_lava_tile(tile_coords: Vector2i, arena_index: int) -> bool:
	var hash_value = abs(tile_coords.x * 928371 + tile_coords.y * 1237 + arena_index * 8191)
	return hash_value % 101 < 5

func _should_place_mirror_accent_tile(tile_coords: Vector2i, arena_index: int) -> bool:
	var hash_value = abs(tile_coords.x * 1439 + tile_coords.y * 7877 + arena_index * 3167)
	return hash_value % 101 < 9

func _get_mirror_arena_tile_atlas_coords(tile_coords: Vector2i, arena_index: int) -> Vector2i:
	var panel_width = 4
	var panel_height = 5
	var local_x = posmod(tile_coords.x, panel_width)
	var local_y = posmod(tile_coords.y, panel_height)
	var panel_hash = abs(floori(tile_coords.x / float(panel_width)) * 9173 + floori(tile_coords.y / float(panel_height)) * 5279 + arena_index * 233)

	if local_x == 0 or local_y == 0:
		return MIRROR_LIGHT_TILE if panel_hash % 2 == 0 else MIRROR_REFLECT_TILE

	if local_x == panel_width - 1 and local_y == panel_height - 1:
		return MIRROR_ACCENT_TILE

	if _should_place_mirror_accent_tile(tile_coords, arena_index):
		return MIRROR_REFLECT_TILE

	match panel_hash % 4:
		0:
			return MIRROR_PANEL_TILE
		1:
			return MIRROR_PANEL_ALT_TILE
		2:
			return MIRROR_DARK_TILE
		_:
			return MIRROR_ACCENT_TILE

func _add_arena_tile_border(arena: Node2D, profile: Dictionary) -> void:
	var backer = arena.get_node_or_null("ArenaTileBorderBacker") as Line2D
	if backer == null:
		backer = Line2D.new()
		backer.name = "ArenaTileBorderBacker"
		backer.z_index = 1
		backer.joint_mode = Line2D.LINE_JOINT_ROUND
		arena.add_child(backer)

	var border = arena.get_node_or_null("ArenaTileBorder") as Line2D
	if border == null:
		border = Line2D.new()
		border.name = "ArenaTileBorder"
		border.z_index = 3
		arena.add_child(border)

	border.width = float(profile.get("border_width", 6.0))
	border.joint_mode = Line2D.LINE_JOINT_ROUND if bool(profile.get("round_border_joints", false)) else Line2D.LINE_JOINT_SHARP
	border.default_color = profile.get("border_color", Color(0.08, 0.04, 0.05, 1.0))
	var border_points = _build_arena_polygon(profile)
	border_points.append(border_points[0])

	backer.width = border.width + float(profile.get("border_backer_extra", 0.0))
	backer.visible = backer.width > border.width + 0.1
	backer.default_color = profile.get("border_backer_color", Color(0.035, 0.012, 0.012, 1.0))
	backer.joint_mode = border.joint_mode
	backer.points = border_points
	border.points = border_points

func _add_arena_inner_details(arena: Node2D, profile: Dictionary) -> void:
	var detail = arena.get_node_or_null("ArenaInnerDetail") as Line2D
	if detail == null:
		detail = Line2D.new()
		detail.name = "ArenaInnerDetail"
		detail.z_index = 2
		detail.joint_mode = Line2D.LINE_JOINT_ROUND
		arena.add_child(detail)

	detail.width = float(profile.get("detail_width", 4.0))
	detail.default_color = profile.get("detail_color", Color(0.16, 0.07, 0.04, 0.78))
	var detail_points = _build_arena_detail_points(profile)
	detail.visible = not detail_points.is_empty()
	detail.points = detail_points

func _add_arena_mirror_panel_details(arena: Node2D, profile: Dictionary) -> void:
	var existing_panel_lines = arena.get_node_or_null("ArenaMirrorPanelLines")
	if existing_panel_lines != null:
		arena.remove_child(existing_panel_lines)
		existing_panel_lines.queue_free()

	if str(profile.get("detail", "")) != ARENA_DETAIL_MIRROR_PANELS:
		return

	var panel_lines = Node2D.new()
	panel_lines.name = "ArenaMirrorPanelLines"
	panel_lines.z_index = 2
	arena.add_child(panel_lines)

	var size = profile.get("size", _get_arena_pixel_size()) as Vector2
	var half_size = size * 0.5
	var corner_radius = float(profile.get("radius", 72.0))
	var vertical_spacing = (size.x - MIRROR_INNER_MARGIN * 2.0) / float(MIRROR_PANEL_COUNT)
	var vertical_top = -half_size.y + corner_radius * 0.55
	var vertical_bottom = half_size.y - corner_radius * 0.55

	for i in range(1, MIRROR_PANEL_COUNT):
		var x = -half_size.x + MIRROR_INNER_MARGIN + vertical_spacing * float(i)
		_add_mirror_panel_line(panel_lines, Vector2(x, vertical_top), Vector2(x, vertical_bottom))

	var horizontal_left = -half_size.x + corner_radius * 0.8
	var horizontal_right = half_size.x - corner_radius * 0.8
	for y_ratio in [0.18, 0.52]:
		var y = lerp(-half_size.y + corner_radius, half_size.y - corner_radius, float(y_ratio))
		_add_mirror_panel_line(panel_lines, Vector2(horizontal_left, y), Vector2(horizontal_right, y))

func _add_mirror_panel_line(parent: Node, from_position: Vector2, to_position: Vector2) -> void:
	var line = Line2D.new()
	line.width = MIRROR_PANEL_LINE_WIDTH
	line.default_color = MIRROR_PANEL_LINE_COLOR
	line.points = PackedVector2Array([from_position, to_position])
	parent.add_child(line)

func _resize_arena_collision(arena: Node2D, profile: Dictionary) -> void:
	var collision_polygon = arena.get_node_or_null("StaticBody2D/CollisionPolygon2D")
	if collision_polygon == null:
		return

	collision_polygon.polygon = _build_arena_polygon(profile)

func _get_arena_pixel_size() -> Vector2:
	return _get_arena_unscaled_pixel_size() * ARENA_TILE_VISUAL_SCALE

func _get_arena_unscaled_pixel_size() -> Vector2:
	return Vector2(ARENA_GRID_SIZE.x * ARENA_TILE_SIZE.x, ARENA_GRID_SIZE.y * ARENA_TILE_SIZE.y)

func _get_arena_profile(arena_index: int) -> Dictionary:
	var base_size = _get_arena_pixel_size()
	match arena_index:
		0:
			return {"shape": ARENA_SHAPE_RECT, "size": base_size, "tile_set": ARENA_TILESET_HELL}
		1:
			return {"shape": ARENA_SHAPE_RECT, "size": base_size, "tile_set": ARENA_TILESET_HELL}
		2:
			return {
				"shape": ARENA_SHAPE_ELLIPSE,
				"size": Vector2(base_size.x * 0.92, base_size.y * 0.94),
				"tile_set": ARENA_TILESET_HELL,
				"fill": ARENA_FILL_ROUND_TILES,
				"detail": "inner_ellipse",
				"detail_size": Vector2(base_size.x * 0.48, base_size.y * 0.42),
				"detail_color": GLUTTONY_INNER_RING_COLOR
			}
		3:
			return {
				"shape": ARENA_SHAPE_ROUNDED_RECT,
				"size": _get_envy_arena_size(base_size),
				"radius": 96.0,
				"tile_set": ARENA_TILESET_MIRROR,
				"fill": ARENA_FILL_MIRROR_SURFACE,
				"detail": ARENA_DETAIL_MIRROR_PANELS,
				"floor_bleed": 1.018,
				"floor_underlay_color": MIRROR_BASE_COLOR,
				"border_width": 10.0,
				"border_backer_extra": 16.0,
				"border_color": Color(0.08, 0.09, 0.095, 1.0),
				"border_backer_color": Color(0.015, 0.018, 0.02, 1.0),
				"round_border_joints": true,
				"lock_camera_x": true
			}
		4:
			return {
				"shape": ARENA_SHAPE_FLAME_CIRCLE,
				"size": Vector2(base_size.y * 1.08, base_size.y * 0.98),
				"tile_set": ARENA_TILESET_HELL,
				"strict_tile_clip": true,
				"floor_bleed": 1.035,
				"border_width": 10.0,
				"border_backer_extra": 18.0,
				"border_color": Color(0.08, 0.018, 0.012, 1.0),
				"border_backer_color": Color(0.025, 0.004, 0.002, 1.0),
				"round_border_joints": true
			}
		5:
			return {
				"shape": ARENA_SHAPE_SERPENT,
				"size": Vector2(base_size.x * 0.78, base_size.y * 1.02),
				"tile_set": ARENA_TILESET_HELL,
				"strict_tile_clip": true,
				"floor_bleed": 1.04,
				"border_width": 10.0,
				"border_backer_extra": 18.0,
				"border_color": Color(0.09, 0.018, 0.035, 1.0),
				"border_backer_color": Color(0.028, 0.004, 0.012, 1.0),
				"round_border_joints": true,
				"anchors": _build_serpent_anchor_points(Vector2(base_size.x * 0.78, base_size.y * 1.02))
			}
		6:
			return {
				"shape": ARENA_SHAPE_GOBLET,
				"size": Vector2(base_size.x * 0.92, base_size.y * 1.02),
				"tile_set": ARENA_TILESET_HELL,
				"anchors": [Vector2(0.0, -base_size.y * 0.25), Vector2.ZERO, Vector2(0.0, base_size.y * 0.3)]
			}
		7:
			return {
				"shape": ARENA_SHAPE_CROWN,
				"size": Vector2(base_size.x * 0.96, base_size.y * 1.0),
				"tile_set": ARENA_TILESET_HELL,
				"strict_tile_clip": true,
				"floor_bleed": 1.035,
				"border_width": 10.0,
				"border_backer_extra": 18.0,
				"border_color": Color(0.11, 0.048, 0.015, 1.0),
				"border_backer_color": Color(0.028, 0.009, 0.002, 1.0),
				"round_border_joints": true,
				"anchors": [Vector2.ZERO, Vector2(0.0, base_size.y * 0.22), Vector2(-base_size.x * 0.22, 0.0), Vector2(base_size.x * 0.22, 0.0)]
			}

	return {"shape": ARENA_SHAPE_RECT, "size": base_size, "tile_set": ARENA_TILESET_HELL}

func _get_current_arena_profile() -> Dictionary:
	return _get_arena_profile(arena_nodes.find(current_arena))

func _get_envy_arena_size(base_size: Vector2) -> Vector2:
	var camera = $Player.get_node_or_null("Camera2D")
	if camera is Camera2D:
		var visible_size = get_viewport_rect().size / camera.zoom
		return Vector2(visible_size.x, max(base_size.y * 1.8, visible_size.y * 2.35))

	return Vector2(base_size.x * 0.56, base_size.y * 1.8)

func _build_arena_polygon(profile: Dictionary) -> PackedVector2Array:
	var shape = str(profile.get("shape", ARENA_SHAPE_RECT))
	var size = profile.get("size", _get_arena_pixel_size()) as Vector2
	match shape:
		ARENA_SHAPE_ROUNDED_RECT:
			return _build_rounded_rect_points(size, float(profile.get("radius", 72.0)))
		ARENA_SHAPE_ELLIPSE:
			return _build_ellipse_points(size)
		ARENA_SHAPE_FLAME_CIRCLE:
			return _build_flame_circle_points(size)
		ARENA_SHAPE_SERPENT:
			return _build_serpent_points(size)
		ARENA_SHAPE_GOBLET:
			return _build_goblet_points(size)
		ARENA_SHAPE_CROWN:
			return _build_crown_points(size)
		_:
			return _build_rect_points(size)

func _build_rect_points(size: Vector2) -> PackedVector2Array:
	var half_size = size * 0.5
	return PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])

func _build_ellipse_points(size: Vector2) -> PackedVector2Array:
	var points = PackedVector2Array()
	var radius = size * 0.5
	for i in range(ARENA_POLYGON_SEGMENTS):
		var angle = TAU * float(i) / float(ARENA_POLYGON_SEGMENTS)
		points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return points

func _build_circle_polygon(radius: float, segment_count: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(segment_count):
		var angle = TAU * float(i) / float(segment_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _build_rounded_rect_points(size: Vector2, radius: float) -> PackedVector2Array:
	var half_size = size * 0.5
	var safe_radius = min(radius, min(half_size.x, half_size.y) - 4.0)
	var corner_centers = [
		Vector2(half_size.x - safe_radius, -half_size.y + safe_radius),
		Vector2(half_size.x - safe_radius, half_size.y - safe_radius),
		Vector2(-half_size.x + safe_radius, half_size.y - safe_radius),
		Vector2(-half_size.x + safe_radius, -half_size.y + safe_radius)
	]
	var angle_ranges = [
		Vector2(-PI * 0.5, 0.0),
		Vector2(0.0, PI * 0.5),
		Vector2(PI * 0.5, PI),
		Vector2(PI, PI * 1.5)
	]

	var points = PackedVector2Array()
	for corner_index in range(corner_centers.size()):
		var angle_range = angle_ranges[corner_index]
		for segment in range(ARENA_ROUNDED_RECT_SEGMENTS + 1):
			var t = float(segment) / float(ARENA_ROUNDED_RECT_SEGMENTS)
			var angle = lerp(angle_range.x, angle_range.y, t)
			points.append(corner_centers[corner_index] + Vector2(cos(angle), sin(angle)) * safe_radius)

	return points

func _build_flame_circle_points(size: Vector2) -> PackedVector2Array:
	var points = PackedVector2Array()
	var radius = size * 0.5
	for i in range(ARENA_POLYGON_SEGMENTS):
		var t = float(i) / float(ARENA_POLYGON_SEGMENTS)
		var angle = TAU * t
		var tremble = 1.0 + 0.08 * sin(angle * 7.0) + 0.045 * sin(angle * 13.0 + 0.7)
		points.append(Vector2(cos(angle) * radius.x * tremble, sin(angle) * radius.y * tremble))
	return points

func _build_serpent_points(size: Vector2) -> PackedVector2Array:
	var samples = 38
	var amplitude = size.x * 0.26
	var half_height = size.y * 0.5
	var thickness = min(size.x * 0.11, 96.0)
	var left_side = []
	var right_side = []

	for i in range(samples):
		var t = float(i) / float(samples - 1)
		var center = _get_serpent_center_point(t, amplitude, half_height)
		var tangent = _get_serpent_tangent(t, amplitude, half_height)
		var normal = Vector2(-tangent.y, tangent.x).normalized()
		var width = thickness * (0.92 + 0.12 * sin(TAU * t))
		left_side.append(center + normal * width)
		right_side.append(center - normal * width)

	var points = PackedVector2Array()
	for point in left_side:
		points.append(point)
	for i in range(right_side.size() - 1, -1, -1):
		points.append(right_side[i])
	return points

func _get_serpent_center_point(t: float, amplitude: float, half_height: float) -> Vector2:
	return Vector2(sin((t - 0.5) * TAU) * amplitude, lerp(-half_height, half_height, t))

func _get_serpent_tangent(t: float, amplitude: float, half_height: float) -> Vector2:
	var dx = cos((t - 0.5) * TAU) * TAU * amplitude
	var dy = half_height * 2.0
	return Vector2(dx, dy).normalized()

func _build_serpent_anchor_points(size: Vector2) -> Array:
	var anchors = []
	var amplitude = size.x * 0.26
	var half_height = size.y * 0.5
	for t in [0.12, 0.28, 0.44, 0.6, 0.76, 0.9]:
		anchors.append(_get_serpent_center_point(float(t), amplitude, half_height))
	return anchors

func _build_goblet_points(size: Vector2) -> PackedVector2Array:
	var half_size = size * 0.5
	return PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x * 0.82, -half_size.y * 0.48),
		Vector2(half_size.x * 0.54, half_size.y * 0.18),
		Vector2(half_size.x * 0.25, half_size.y),
		Vector2(-half_size.x * 0.25, half_size.y),
		Vector2(-half_size.x * 0.54, half_size.y * 0.18),
		Vector2(-half_size.x * 0.82, -half_size.y * 0.48)
	])

func _build_crown_points(size: Vector2) -> PackedVector2Array:
	var half_size = size * 0.5
	return PackedVector2Array([
		Vector2(-half_size.x, half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(half_size.x * 0.96, half_size.y * 0.35),
		Vector2(half_size.x * 0.70, half_size.y * 0.52),
		Vector2(half_size.x * 0.58, -half_size.y * 0.46),
		Vector2(half_size.x * 0.36, half_size.y * 0.12),
		Vector2(half_size.x * 0.15, -half_size.y),
		Vector2(0.0, -half_size.y * 0.12),
		Vector2(-half_size.x * 0.15, -half_size.y),
		Vector2(-half_size.x * 0.36, half_size.y * 0.12),
		Vector2(-half_size.x * 0.58, -half_size.y * 0.46),
		Vector2(-half_size.x * 0.70, half_size.y * 0.52),
		Vector2(-half_size.x * 0.96, half_size.y * 0.35)
	])

func _build_arena_detail_points(profile: Dictionary) -> PackedVector2Array:
	if str(profile.get("detail", "")) != "inner_ellipse":
		return PackedVector2Array()

	var detail_profile = {
		"shape": ARENA_SHAPE_ELLIPSE,
		"size": profile.get("detail_size", Vector2(360.0, 220.0))
	}
	var detail_points = _build_arena_polygon(detail_profile)
	detail_points.append(detail_points[0])
	return detail_points

func _get_local_polygon_bounds(polygon: PackedVector2Array) -> Rect2:
	if polygon.is_empty():
		return Rect2(Vector2.ZERO, Vector2.ZERO)

	var rect = Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		rect = rect.expand(point)
	return rect

func _is_tile_inside_arena_grid(tile_coords: Vector2i) -> bool:
	return tile_coords.x >= 0 and tile_coords.y >= 0 and tile_coords.x < ARENA_GRID_SIZE.x and tile_coords.y < ARENA_GRID_SIZE.y

func _update_camera_limits() -> void:
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		camera = $Player.get_node_or_null("Camera2D")
	if camera == null:
		return

	var arena_rect = _get_current_arena_bounds()
	if arena_rect.size == Vector2.ZERO:
		return

	var profile = _get_current_arena_profile()
	if bool(profile.get("lock_camera_x", false)):
		var visible_size = get_viewport_rect().size / camera.zoom
		var arena_center = _get_current_arena_center()
		camera.limit_left = int(floor(arena_center.x - visible_size.x * 0.5))
		camera.limit_right = int(ceil(arena_center.x + visible_size.x * 0.5))
	else:
		camera.limit_left = int(floor(arena_rect.position.x)) - (CAMERA_LIMIT_MARGIN*2)
		camera.limit_right = int(ceil(arena_rect.end.x)) + CAMERA_LIMIT_MARGIN

	camera.limit_top = int(floor(arena_rect.position.y)) - (CAMERA_LIMIT_MARGIN*2)
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

func set_waves_based_on_pecado() -> void:
	waves = WAVE_SETS.get(Global.pecado, WAVE_SETS[1])

func start_next_wave() -> void:
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

func spawn_wave(data: Dictionary) -> void:
	var level_context = "pre_boss" if current_arena == arena_nodes[0] and current_wave_index == waves.size() - 1 else "normal"
	
	var total_enemies = data["melee"] + data["ranged"] + data["spread"] + data["tank"] + data["agile"]
	_set_player_xp_goal(total_enemies, level_context, Global.pecado)

	if $Player.greed_cursed_level_enabled and $Player.has_method("apply_golden_debt_wave_cost"):
		$Player.apply_golden_debt_wave_cost()
		if $Player.current_health <= 0:
			return

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
	for i in range(spawn_queue.size()):
		var enemy_scene = spawn_queue[i]
		# Se a wave foi cancelada ou o player morreu, para de spawnar
		if not is_inside_tree() or not is_wave_active: 
			break
			
		spawn_enemy(enemy_scene)
		enemies_left_to_spawn -= 1
		
		if i < spawn_queue.size() - 1:
			await get_tree().create_timer(WAVE_SPAWN_INTERVAL, false).timeout

	await _try_finish_wave()
		
func spawn_boss() -> void:
	var centro_node = current_arena.get_node("Centro")
	_set_player_xp_goal(1, "boss", Global.pecado)
	await _transition_player_to(centro_node.global_position)
	await get_tree().create_timer(BOSS_SPAWN_DELAY_AFTER_ARENA_ARRIVAL, false).timeout
	await get_tree().process_frame

	var boss = BOSS_ENEMY.instantiate()
	_apply_enemy_spawn_modifiers(boss)
	var spawn_margin = _get_body_spawn_margin(boss)
	boss.global_position = get_camera_top_center_position(spawn_margin)
	boss.add_to_group(Global.GROUP_BOSS)
	boss.connect("boss_defeated", Callable(self, "_on_boss_died"))
	add_child(boss)

func spawn_enemy(enemy_scene: PackedScene) -> void:
	var enemy = enemy_scene.instantiate()
	_apply_enemy_spawn_modifiers(enemy)
	add_child(enemy)

	var spawn_margin = _get_body_spawn_margin(enemy)
	enemy.global_position = get_random_camera_edge_position(spawn_margin)

	# Monitora a morte do inimigo
	enemy.tree_exited.connect(_on_enemy_died)

func _apply_enemy_spawn_modifiers(_enemy: Node) -> void:
	pass

func get_random_camera_edge_position(spawn_margin: float = 0.0) -> Vector2:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return get_random_arena_position(spawn_margin)

	var cam_pos = camera.global_position
	var viewport_size = get_viewport_rect().size / camera.zoom
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
			var player = get_tree().get_first_node_in_group(Global.GROUP_PLAYER)
			if player == null or pos.distance_to(player.global_position) > SPAWN_PLAYER_MIN_DISTANCE:
				return pos

	return get_random_arena_edge_position(spawn_margin)

func get_camera_top_center_position(spawn_margin: float = 0.0) -> Vector2:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return get_random_arena_position(spawn_margin)

	var viewport_size = get_viewport_rect().size / camera.zoom
	var top_center = camera.global_position + Vector2(0.0, -viewport_size.y * 0.5 + spawn_margin + SPAWN_WALL_PADDING)
	return clamp_position_to_current_arena(top_center, spawn_margin)

func get_random_arena_position(spawn_margin: float = 0.0) -> Vector2:
	return _get_random_arena_position(spawn_margin, true)

func get_random_arena_position_anywhere(spawn_margin: float = 0.0) -> Vector2:
	return _get_random_arena_position(spawn_margin, false)

func _get_random_arena_position(spawn_margin: float, avoid_player: bool) -> Vector2:
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
			var player = get_tree().get_first_node_in_group(Global.GROUP_PLAYER)
			if not avoid_player or player == null or pos.distance_to(player.global_position) > SPAWN_PLAYER_MIN_DISTANCE:
				return pos

	return clamp_position_to_current_arena(current_arena.global_position, spawn_margin)

func get_random_arena_edge_position(spawn_margin: float = 0.0) -> Vector2:
	var collision_polygon = _get_current_arena_collision_polygon()
	if collision_polygon == null or collision_polygon.polygon.is_empty():
		return get_random_arena_position(spawn_margin)

	var global_points = _get_arena_global_polygon_points(collision_polygon)
	var player = get_tree().get_first_node_in_group(Global.GROUP_PLAYER)
	for i in range(80):
		var segment_index = randi() % global_points.size()
		var segment_start: Vector2 = global_points[segment_index]
		var segment_end: Vector2 = global_points[(segment_index + 1) % global_points.size()]
		var edge_point = segment_start.lerp(segment_end, randf())
		var inward_normal = _get_current_arena_edge_normal(edge_point)
		var candidate = clamp_position_to_current_arena(edge_point + inward_normal * max(spawn_margin + SPAWN_WALL_PADDING, 16.0), spawn_margin)
		if not _is_position_safe_in_current_arena(candidate, spawn_margin):
			continue
		if player == null or candidate.distance_to(player.global_position) > SPAWN_PLAYER_MIN_DISTANCE:
			return candidate

	return get_random_arena_position(spawn_margin)

func clamp_position_to_current_arena(global_pos: Vector2, safety_margin: float = 0.0) -> Vector2:
	if _is_position_safe_in_current_arena(global_pos, safety_margin):
		return global_pos

	var collision_polygon = _get_current_arena_collision_polygon()
	if collision_polygon == null or collision_polygon.polygon.is_empty():
		return global_pos

	var global_points = _get_arena_global_polygon_points(collision_polygon)
	var safe_candidates = []
	_append_safe_arena_edge_candidates(safe_candidates, global_pos, global_points, safety_margin)
	_append_safe_arena_anchor_candidates(safe_candidates, global_pos, safety_margin)
	if not safe_candidates.is_empty():
		return _get_closest_arena_candidate(global_pos, safe_candidates)

	var center = _get_current_arena_center()
	if not _is_position_safe_in_current_arena(center, safety_margin):
		center = current_arena.global_position

	if not _is_position_safe_in_current_arena(center, 0.0):
		return global_pos

	var best_position = center
	var low = 0.0
	var high = 1.0
	for i in range(ARENA_CLAMP_BINARY_SEARCH_STEPS):
		var mid = (low + high) * 0.5
		var candidate = center.lerp(global_pos, mid)
		if _is_position_safe_in_current_arena(candidate, safety_margin):
			best_position = candidate
			low = mid
		else:
			high = mid

	return best_position

func _get_arena_global_polygon_points(collision_polygon: CollisionPolygon2D) -> Array:
	var global_points = []
	for point in collision_polygon.polygon:
		global_points.append(collision_polygon.to_global(point))
	return global_points

func _append_safe_arena_edge_candidates(candidates: Array, global_pos: Vector2, global_points: Array, safety_margin: float) -> void:
	var point_count = global_points.size()
	if point_count < 2:
		return

	var base_nudge = max(safety_margin + 1.0, 1.0)
	for i in range(point_count):
		var segment_start: Vector2 = global_points[i]
		var segment_end: Vector2 = global_points[(i + 1) % point_count]
		var edge = segment_end - segment_start
		if edge.length_squared() <= 0.001:
			continue

		var closest_point = _get_closest_point_on_segment(global_pos, segment_start, segment_end)
		var normal = Vector2(-edge.y, edge.x).normalized()
		_try_add_safe_arena_candidate(candidates, closest_point, safety_margin)
		for direction in [normal, -normal]:
			for multiplier in ARENA_CLAMP_EDGE_NUDGE_MULTIPLIERS:
				_try_add_safe_arena_candidate(candidates, closest_point + direction * base_nudge * float(multiplier), safety_margin)

func _append_safe_arena_anchor_candidates(candidates: Array, global_pos: Vector2, safety_margin: float) -> void:
	var anchors = [
		_get_current_arena_center(),
		current_arena.global_position
	]
	for local_anchor in _get_current_arena_local_anchor_points():
		anchors.append(current_arena.to_global(local_anchor))

	for anchor in anchors:
		if not _is_position_safe_in_current_arena(anchor, 0.0):
			continue
		_try_add_safe_arena_candidate(candidates, anchor, safety_margin)
		_try_add_safe_arena_ray_candidate(candidates, anchor, global_pos, safety_margin)

func _try_add_safe_arena_ray_candidate(candidates: Array, safe_anchor: Vector2, target_pos: Vector2, safety_margin: float) -> void:
	var best_position = safe_anchor
	var found_safe_position = _is_position_safe_in_current_arena(safe_anchor, safety_margin)
	var low = 0.0
	var high = 1.0
	for i in range(ARENA_CLAMP_BINARY_SEARCH_STEPS):
		var mid = (low + high) * 0.5
		var candidate = safe_anchor.lerp(target_pos, mid)
		if _is_position_safe_in_current_arena(candidate, safety_margin):
			best_position = candidate
			found_safe_position = true
			low = mid
		else:
			high = mid

	if found_safe_position:
		_try_add_safe_arena_candidate(candidates, best_position, safety_margin)

func _try_add_safe_arena_candidate(candidates: Array, candidate: Vector2, safety_margin: float) -> void:
	if _is_position_safe_in_current_arena(candidate, safety_margin):
		candidates.append(candidate)

func _get_closest_arena_candidate(global_pos: Vector2, candidates: Array) -> Vector2:
	var closest_position: Vector2 = candidates[0]
	var closest_distance = global_pos.distance_squared_to(closest_position)
	for candidate in candidates:
		var distance = global_pos.distance_squared_to(candidate)
		if distance < closest_distance:
			closest_distance = distance
			closest_position = candidate
	return closest_position

func _get_closest_point_on_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> Vector2:
	var segment = segment_end - segment_start
	var segment_length_squared = segment.length_squared()
	if segment_length_squared <= 0.001:
		return segment_start

	var t = clamp((point - segment_start).dot(segment) / segment_length_squared, 0.0, 1.0)
	return segment_start + segment * t

func _get_current_arena_edge_normal(global_pos: Vector2) -> Vector2:
	var collision_polygon = _get_current_arena_collision_polygon()
	if collision_polygon == null or collision_polygon.polygon.is_empty():
		return Vector2.ZERO

	var global_points = _get_arena_global_polygon_points(collision_polygon)
	var closest_segment_start = Vector2.ZERO
	var closest_segment_end = Vector2.ZERO
	var closest_point = Vector2.ZERO
	var closest_distance = INF
	for i in range(global_points.size()):
		var segment_start: Vector2 = global_points[i]
		var segment_end: Vector2 = global_points[(i + 1) % global_points.size()]
		var point_on_segment = _get_closest_point_on_segment(global_pos, segment_start, segment_end)
		var distance = global_pos.distance_squared_to(point_on_segment)
		if distance < closest_distance:
			closest_distance = distance
			closest_segment_start = segment_start
			closest_segment_end = segment_end
			closest_point = point_on_segment

	var edge = closest_segment_end - closest_segment_start
	if edge.length_squared() <= 0.001:
		return Vector2.ZERO

	var normal = Vector2(-edge.y, edge.x).normalized()
	if _is_position_inside_current_arena(closest_point + normal * 8.0):
		return normal
	if _is_position_inside_current_arena(closest_point - normal * 8.0):
		return -normal

	var center_direction = closest_point.direction_to(_get_current_arena_center())
	return center_direction.normalized() if center_direction != Vector2.ZERO else normal

func _get_current_arena_local_anchor_points() -> Array:
	var profile = _get_current_arena_profile()
	return profile.get("anchors", [])

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

	if get_tree().get_nodes_in_group(Global.GROUP_ENEMY):
		return

	wave_finish_pending = true
	is_wave_active = false
	if $Player.has_method("apply_heal_after_wave"):
		$Player.apply_heal_after_wave()
	await get_tree().create_timer(0.5, false).timeout
	if not is_inside_tree():
		return
	await _wait_for_level_up_selection()
	if not is_inside_tree():
		return
	wave_finish_pending = false
	start_next_wave()

func _on_boss_died() -> void:
	if not boss_phase:
		return

	boss_phase = false
	is_wave_active = false
	current_wave_index = 0
	_heal_player_after_boss()

	if Global.pecado == 8:
		return

	current_arena = arena_nodes[0]
	set_waves_based_on_pecado()
	_update_camera_limits()
	await _wait_for_level_up_selection()
	await _transition_player_to(ENEMY_ARENA_PLAYER_POSITION)
	start_next_wave()

func _heal_player_after_boss() -> void:
	var player = get_tree().get_first_node_in_group(Global.GROUP_PLAYER)
	if player == null or not player.has_method("heal"):
		return

	var max_player_health = float(player.get("max_health")) if player.get("max_health") != null else 0.0
	if max_player_health <= 0.0:
		return

	player.heal(max_player_health * BOSS_CLEAR_HEAL_RATIO)

func _on_pecado_changed(new_pecado: int) -> void:
	if new_pecado > 7:
		await _wait_for_level_up_selection()
		var player = get_tree().get_first_node_in_group(Global.GROUP_PLAYER)
		if player and player.has_method("win"):
			player.win()
