extends CharacterBody2D
class_name Boss

enum BossState { SLOTH, GLUTTONY, ENVY, WRATH, LUST, GREED, PRIDE }
enum BossSubState { INTRO, DECIDE, TELEGRAPH, ATTACK, RECOVERY, PHASE_CHANGE, SPECIAL, DEAD }

signal boss_defeated

@export var max_health: int = 500
@export var speed: float = 85.0
@export var damage: int = 50
@export var xp_drop: int = 1
@export var forced_sin_id: int = 0
@export var advances_story_progress: bool = true
@export var grants_progression_reward: bool = true
@export var endless_health_multiplier: float = 1.0
@export var endless_damage_multiplier: float = 1.0
@export var endless_speed_multiplier: float = 1.0
@export var endless_action_cooldown_multiplier: float = 1.0

const ENRAGE_HEALTH_RATIO: float = 0.5
const ENRAGE_STAT_MULTIPLIER: float = 1.25
const PROJECTILE_SCENE = preload("res://Cenas/Inimigos/enemyProjectile.tscn")
const MELEE_ENEMY_SCENE = preload("res://Cenas/Inimigos/melee_enemy.tscn")
const RANGED_ENEMY_SCENE = preload("res://Cenas/Inimigos/ranged_enemy.tscn")
const SLOTH_BOSS_SHEET = preload("res://Sprites/Bosses/Sloth_Spritesheet.png")
const GLUTTONY_BOSS_SHEET = preload("res://Sprites/Bosses/Gluttony_Spritesheet.png")
const ENVY_BOSS_SHEET = preload("res://Sprites/Bosses/Envy_Spritesheet.png")
const WRATH_BOSS_SHEET = preload("res://Sprites/Bosses/Wrath_Spritesheet.png")
const LUST_BOSS_SHEET = preload("res://Sprites/Bosses/Lust_Spritesheet.png")
const GREED_BOSS_SHEET = preload("res://Sprites/Bosses/Greed_Spritesheet.png")
const PRIDE_BOSS_SHEET = preload("res://Sprites/Bosses/Pride_Spritesheet.png")
const FOOTSTEP_SFX_STREAM: AudioStream = preload("res://Music&SFX/SFX/FootStepsGravel_SFX.wav")

const WRATH_BOMB_RADIUS: float = 20.0
const WRATH_BOMB_EXPLOSION_RADIUS: float = 110.0
const WRATH_BOMB_PUSH_SPEED: float = 550.0
const WRATH_BOMB_DAMAGE: float = 40.0
const WRATH_FISSURE_WIDTH: float = 46.0
const WRATH_FISSURE_LENGTH_PHASE_1: float = 330.0
const WRATH_FISSURE_LENGTH_PHASE_2: float = 430.0
const WRATH_FISSURE_DAMAGE_MULTIPLIER: float = 0.78
const WRATH_BOMB_TELEGRAPH_DURATION: float = 0.56
const WRATH_FISSURE_TELEGRAPH_DURATION: float = 0.40
const WRATH_FISSURE_DAMAGE_DURATION: float = 0.32
const LUST_WALL_THICKNESS: float = 24.0
const LUST_WALL_LENGTH: float = 260.0
const LUST_BREAKABLE_WALL_MAX_HITS: int = 2
const LUST_SERPENT_LASH_SEGMENTS: int = 11
const LUST_SERPENT_LASH_RADIUS: float = 34.0
const LUST_SERPENT_LASH_TELEGRAPH_DURATION: float = 0.75
const LUST_SERPENT_LASH_DAMAGE_DURATION: float = 0.32
const LUST_SERPENT_LASH_SEGMENT_INTERVAL: float = 0.035
const LUST_SERPENT_LASH_DAMAGE_MULTIPLIER: float = 0.85
const LUST_SERPENT_LASH_HIT_META: String = "lust_serpent_lash_hit_id"
const LUST_WALL_BASE_CHANCE_PHASE_1: float = 0.30
const LUST_WALL_BASE_CHANCE_PHASE_2: float = 0.22
const LUST_WALL_EXISTING_CHANCE_PENALTY: float = 0.12
const LUST_WALL_MIN_CHANCE: float = 0.04
const LUST_WALL_STOCK_LIMIT_PHASE_1: int = 4
const LUST_WALL_STOCK_LIMIT_PHASE_2: int = 5
const LUST_NAVIGATION_MARGIN: float = 20.0
const LUST_NAVIGATION_SAMPLE_STEP: float = 30.0
const LUST_NAVIGATION_WAYPOINT_REACHED: float = 36.0
const LUST_NAVIGATION_FALLBACK_DISTANCE: float = 150.0
const LUST_NAVIGATION_REPATH_INTERVAL: float = 0.18
const SLOTH_SLOW_ZONE_RADIUS: float = 100.0
const SLOTH_SUMMON_SPAWN_INTERVAL: float = 2.5
const SLOTH_ZONE_TELEGRAPH_DURATION: float = 0.75
const SLOTH_ZONE_SPAWN_INTERVAL: float = 1.25
const SLOTH_SLOW_ZONE_LIFETIME: float = 12.0
const SLOTH_BOSS_PLAYER_DASH_SPEED_MULTIPLIER: float = 0.75
const SLOTH_BOSS_PLAYER_VELOCITY_MULTIPLIER: float = 0.75
const SLOTH_BOSS_ZONE_DPS: float = 5.0
const SLOTH_BOSS_ENEMY_SLOW_EFFECT_RATIO: float = 0.45
const SLOTH_BOSS_ENEMY_SLOW_REFERENCE_DASH_MULTIPLIER: float = 0.65
const GLUTTONY_FOOD_SPAWN_INTERVAL: float = 3.0
const GLUTTONY_FOOD_SPEED_PHASE_1: float = 137.5
const GLUTTONY_FOOD_SPEED_PHASE_2: float = 157.5
const GLUTTONY_FOOD_DASH_DURATION: float = 0.3
const GLUTTONY_FOOD_DASH_DISTANCE_PHASE_1: float = 177.5
const GLUTTONY_FOOD_DASH_DISTANCE_PHASE_2: float = 217.5
const GLUTTONY_FOOD_DASH_ARENA_MARGIN: float = 30.0
const GLUTTONY_STRESS_DURATION_PHASE_1: float = 5.0
const GLUTTONY_STRESS_DURATION_PHASE_2: float = 7.5
const ENVY_CLONE_MAX_HEALTH: float = 180.0
const ENVY_CLONE_VISUAL_MODULATE: Color = Color(0.55, 0.95, 1.0, 0.56)
const ENVY_PINCER_TELEGRAPH_DURATION: float = 0.75
const ENVY_SWAP_TELEGRAPH_DURATION: float = 0.75
const ENVY_ATTACK_DISTANCE_PHASE_1: float = 110.0
const ENVY_ATTACK_DISTANCE_PHASE_2: float = 100.0
const ENVY_ATTACK_READY_BUFFER: float = 70.0
const GREED_TREASURE_RADIUS: float = 20.0
const GREED_TREASURE_LIMIT_PHASE_1: int = 5
const GREED_TREASURE_LIMIT_PHASE_2: int = 8
const GREED_TREASURE_TELEGRAPH_DURATION: float = 1.0
const GREED_COIN_WARNING_DURATION: float = 1.0
const GREED_TREASURE_BOSS_COLLECT_RADIUS: float = 50.0
const GREED_COIN_RAIN_CLUSTER_RADIUS_PHASE_1: float = 116.0
const GREED_COIN_RAIN_CLUSTER_RADIUS_PHASE_2: float = 142.0
const GREED_COIN_RAIN_WARNING_RADIUS: float = 18.0
const GREED_PLAYER_TREASURE_HEAL_RATIO: float = 0.01
const GREED_BOSS_TREASURE_HEAL_RATIO: float = 0.02
const GREED_JACKPOT_STACK_INTERVAL: int = 3
const GREED_JACKPOT_DAMAGE_MULTIPLIER: float = 0.55
const MIN_TELEGRAPH_DURATION: float = 0.75
const MAX_BOSS_CIRCLE_VFX_RADIUS: float = 180.0
const ISO_AOE_VISUAL_Y_SCALE: float = 0.7
const DEFAULT_BOSS_VISUAL_SCALE: Vector2 = Vector2.ONE

const SLOTH_COLOR: Color = Color(0.25, 0.95, 1.0, 1.0)
const GLUTTONY_COLOR: Color = Color(0.961, 0.89, 0.263, 1.0)
const ENVY_COLOR: Color = Color(0.25, 0.95, 1.0, 1.0)
const WRATH_COLOR: Color = Color(1.0, 0.333, 0.051, 1.0)
const WRATH_ATTACK_COLOR: Color = Color(1.0, 0.58, 0.04, 1.0)
const WRATH_TELEGRAPH_COLOR: Color = Color(1.0, 0.84, 0.18, 1.0)
const WRATH_OUTLINE_COLOR: Color = Color(0.12, 0.025, 0.004, 0.96)
const LUST_COLOR: Color = Color(1.0, 0.09, 0.451, 1.0)
const GREED_COLOR: Color = Color(1.0, 0.78, 0.0, 1.0)
const PRIDE_LIGHT_COLOR: Color = Color(1.0, 0.961, 0.765, 1.0)
const PRIDE_FIRE_COLOR: Color = Color(1.0, 0.46, 0.14, 1.0)
const BOSS_FOOTSTEP_SFX_VOICE_KEY: String = "boss_footstep"
const BOSS_FOOTSTEP_SFX_MAX_VOICES: int = 1
const BOSS_FOOTSTEP_SFX_PLAY_DISTANCE: float = 500.0
const PRIDE_EDGE_BEAM_WIDTH: float = 30.0
const PRIDE_EDGE_BEAM_DELAY_PHASE_1: float = 0.75
const PRIDE_EDGE_BEAM_DELAY_PHASE_2: float = 0.75
const PRIDE_EDGE_BEAM_DURATION: float = 0.4
const PRIDE_EDGE_OVERLAY_CHANCE_PHASE_1: float = 0.45
const PRIDE_EDGE_OVERLAY_CHANCE_PHASE_2: float = 0.58
const PRIDE_EDGE_OVERLAY_COOLDOWN_PHASE_1: float = 3.8
const PRIDE_EDGE_OVERLAY_COOLDOWN_PHASE_2: float = 2.9
const PRIDE_EDGE_CROSSBAR_LENGTH: float = 155.0
const PRIDE_EDGE_CROSSBAR_OFFSET_RATIO: float = 0.65
const PRIDE_MOVEMENT_DEFAULT: String = "default"
const PRIDE_MOVEMENT_LASER: String = "laser"
const PRIDE_MOVEMENT_CLOSE: String = "close"
const PRIDE_DEFAULT_DISTANCE: float = 210.0
const PRIDE_LASER_DISTANCE: float = 245.0
const PRIDE_CLOSE_DISTANCE: float = 135.0
const PRIDE_VISIBLE_MARGIN: float = 72.0
const PRIDE_EDGE_SAFETY_MARGIN: float = 34.0
const PRIDE_DODGE_SCAN_INTERVAL: float = 0.12
const PRIDE_DODGE_DETECTION_RADIUS: float = 245.0
const PRIDE_DODGE_PREDICTION_TIME: float = 0.42
const PRIDE_DODGE_TRIGGER_DISTANCE: float = 72.0
const PRIDE_DODGE_DISTANCE: float = 105.0
const PRIDE_DODGE_DURATION: float = 0.34
const PRIDE_DODGE_COOLDOWN: float = 0.62
const PRIDE_ORBIT_SWITCH_MIN_TIME: float = 1.6
const PRIDE_ORBIT_SWITCH_MAX_TIME: float = 2.8
const PRIDE_FIRE_ORB_DAMAGE_MULTIPLIER: float = 0.65
const PRIDE_AIMED_FIREBALL_DAMAGE_MULTIPLIER: float = 0.65
const PRIDE_EDGE_BEAM_DAMAGE_MULTIPLIER: float = 0.8
const PRIDE_INVERTED_CROSS_DAMAGE_MULTIPLIER: float = 0.8
const PRIDE_LIGHT_BEAM_DAMAGE_MULTIPLIER: float = 0.8
const PRIDE_JUDGEMENT_BEAM_DAMAGE_MULTIPLIER: float = 0.8
const BOSS_INDICATOR_LAYER: int = 0
const BOSS_INDICATOR_PADDING: float = 35.0
const DAMAGE_FEEDBACK_COLOR: Color = Color(1.0, 0.08, 0.08, 1.0)
const HEAL_FEEDBACK_COLOR: Color = Color(0.18, 1.0, 0.32, 1.0)

const BOSS_CONFIG = {
	1: { "max_health": 550, "speed": 0.0, "damage": 40, "state": BossState.SLOTH, "animation": "pecado1", "sprite_sheet": SLOTH_BOSS_SHEET, "frame_size": Vector2i(44, 58), "frame_count": 8, "visual_scale": Vector2(1.35, 1.35) },
	2: { "max_health": 1100, "speed": 90.0, "damage": 50, "state": BossState.GLUTTONY, "animation": "pecado2", "sprite_sheet": GLUTTONY_BOSS_SHEET, "frame_size": Vector2i(150, 140), "frame_count": 4, "visual_scale": Vector2(0.82, 0.82), "hurtbox_scale": Vector2(1.2, 1.15) },
	3: { "max_health": 1500, "speed": 90.0, "damage": 50, "state": BossState.ENVY, "animation": "pecado3", "sprite_sheet": ENVY_BOSS_SHEET, "frame_size": Vector2i(69, 98), "frame_count": 4, "visual_scale": Vector2(0.9, 0.9) },
	4: { "max_health": 2000, "speed": 90.0, "damage": 90, "state": BossState.WRATH, "animation": "pecado4", "sprite_sheet": WRATH_BOSS_SHEET, "frame_size": Vector2i(78, 74), "frame_count": 8, "visual_scale": Vector2(1.08, 1.08) },
	5: { "max_health": 3000, "speed": 90.0, "damage": 66, "state": BossState.LUST, "animation": "pecado5", "sprite_sheet": LUST_BOSS_SHEET, "frame_size": Vector2i(60, 80), "frame_count": 6, "visual_scale": Vector2(1.08, 1.08) },
	6: { "max_health": 4000, "speed": 90.0, "damage": 75, "state": BossState.GREED, "animation": "pecado6", "sprite_sheet": GREED_BOSS_SHEET, "frame_size": Vector2i(60, 88), "frame_count": 4, "visual_scale": Vector2(1.05, 1.05) },
	7: { "max_health": 5000, "speed": 90.0, "damage": 90, "state": BossState.PRIDE, "animation": "pecado7", "sprite_sheet": PRIDE_BOSS_SHEET, "frame_size": Vector2i(109, 67), "frame_count": 6, "visual_scale": Vector2(0.98, 0.98) },
}

var current_health: int
var sin_id: int = 1
var player: Node2D
var aparencia
var health_bar: ProgressBar
var health_feedback_tween: Tween
var health_feedback_base_modulate: Color = Color.WHITE
var boss_health_bar_y_offset: float = -36.0
var is_dead: bool = false
var is_enraged: bool = false
var is_invulnerable: bool = false
var is_cleaning_up: bool = false

var base_speed: float
var base_damage: int
var phase: int = 1
var current_state: BossState
var current_sub_state: BossSubState = BossSubState.INTRO
var action_cooldown: float = 1.0
var is_performing_action: bool = false

var active_bombs: Array = []
var active_slow_zones: Array = []
var sloth_boss_zone_damage_accumulator: float = 0.0
var boss_summons: Array = []
var gluttony_foods: Array = []
var gluttony_stress_timers: Array = []
var gluttony_food_dash_tween: Tween
var is_gluttony_food_dashing: bool = false
var active_lust_walls: Array = []
var lust_invulnerability_cooldown: float = 4.0
var lust_invulnerability_active: bool = false
var lust_navigation_waypoint: Vector2 = Vector2.ZERO
var lust_navigation_repath_timer: float = 0.0
var lust_navigation_anchor_cache: Array = []
var envy_clone: Area2D
var envy_clone_fire_cooldown: float = 0.8
var envy_clone_shot_pending: bool = false
var envy_boss_buff_remaining: float = 0.0
var envy_clone_shot_pattern_index: int = 0
var envy_clone_movement_locked: bool = false
var active_treasures: Array = []
var greed_money_stacks: int = 0
var greed_shield_remaining: float = 0.0
var greed_tax_active: bool = false
var greed_tax_timer: float = 0.0
var greed_tax_meter: float = 0.0
var greed_previous_player_position: Vector2 = Vector2.ZERO
var greed_previous_can_shoot: bool = true
var pride_edge_overlay_cooldown: float = 0.0
var pride_movement_mode: String = PRIDE_MOVEMENT_DEFAULT
var pride_orbit_direction: float = 1.0
var pride_orbit_switch_timer: float = 0.0
var pride_dodge_scan_timer: float = 0.0
var pride_dodge_cooldown: float = 0.0
var pride_dodge_remaining: float = 0.0
var pride_dodge_direction: Vector2 = Vector2.ZERO
var boss_indicator_layer: CanvasLayer
var boss_indicator_node: Node2D
var footstep_sfx_player: AudioStreamPlayer
var has_footstep_sfx_voice: bool = false

func _ready() -> void:
	z_index = Global.CHARACTER_RENDER_Z_INDEX
	z_as_relative = false
	player = get_tree().get_first_node_in_group(Global.GROUP_PLAYER)
	add_to_group(Global.GROUP_BOSS)
	add_to_group(Global.GROUP_ENEMY)
	_setup_enemy_body_collision()
	aparencia = $AparenciaAnimada
	health_feedback_base_modulate = aparencia.modulate
	_configure_boss_for_current_sin()
	_setup_footstep_sfx()
	_setup_boss_edge_indicator()
	current_health = max_health
	base_speed = speed
	base_damage = damage
	pride_orbit_direction = -1.0 if randf() < 0.5 else 1.0
	pride_orbit_switch_timer = randf_range(PRIDE_ORBIT_SWITCH_MIN_TIME, PRIDE_ORBIT_SWITCH_MAX_TIME)
	if player:
		greed_previous_player_position = player.global_position
		greed_previous_can_shoot = player.can_shoot
	call_deferred("_setup_health_bar")
	call_deferred("_begin_intro")

func _exit_tree() -> void:
	_stop_footstep_sfx()

func _configure_boss_for_current_sin() -> void:
	sin_id = clampi(forced_sin_id if forced_sin_id > 0 else Global.pecado, 1, 7)
	var config = BOSS_CONFIG.get(sin_id, BOSS_CONFIG[7])
	max_health = maxi(1, int(round(float(config["max_health"]) * endless_health_multiplier)))
	speed = float(config["speed"]) * endless_speed_multiplier
	damage = maxi(1, int(round(float(config["damage"]) * endless_damage_multiplier)))
	current_state = config["state"]
	if aparencia:
		_configure_boss_sprite_frames(config)
		var visual_scale = config.get("visual_scale", DEFAULT_BOSS_VISUAL_SCALE) as Vector2
		aparencia.scale = visual_scale
		var frame_size = config.get("frame_size", Vector2i(24, 24)) as Vector2i
		boss_health_bar_y_offset = -float(frame_size.y) * visual_scale.y * 0.5 - 12.0
	_configure_boss_hurtbox(config)
	_play_boss_animation(str(config["animation"]))

func _configure_boss_sprite_frames(config: Dictionary) -> void:
	var sprite_sheet = config.get("sprite_sheet", null) as Texture2D
	if sprite_sheet == null:
		return

	var animation_name = StringName(str(config.get("animation", "idle")))
	var frame_size = config.get("frame_size", Vector2i(sprite_sheet.get_width(), sprite_sheet.get_height())) as Vector2i
	var frame_count = int(config.get("frame_count", max(1, sprite_sheet.get_width() / max(frame_size.x, 1))))
	var animation_speed = float(config.get("animation_speed", 5.0))
	var sprite_frames = SpriteFrames.new()
	if sprite_frames.has_animation(&"default"):
		sprite_frames.remove_animation(&"default")
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, true)
	sprite_frames.set_animation_speed(animation_name, animation_speed)

	for frame_index in range(frame_count):
		var frame_texture = AtlasTexture.new()
		frame_texture.atlas = sprite_sheet
		frame_texture.region = Rect2(frame_index * frame_size.x, 0, frame_size.x, frame_size.y)
		sprite_frames.add_frame(animation_name, frame_texture)

	aparencia.sprite_frames = sprite_frames
	aparencia.animation = animation_name
	aparencia.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _configure_boss_hurtbox(config: Dictionary) -> void:
	var hurtbox_scale = config.get("hurtbox_scale", Vector2.ONE) as Vector2
	if hurtbox_scale == Vector2.ONE:
		return

	var collision = get_node_or_null("Hurtbox/CollisionShape2D")
	if collision == null or not (collision is CollisionShape2D) or collision.shape == null:
		return

	var shape = collision.shape.duplicate()
	if shape is CapsuleShape2D:
		shape.radius = max(shape.radius * hurtbox_scale.x, 4.0)
		shape.height = max(shape.height * hurtbox_scale.y, shape.radius * 2.0)
	elif shape is CircleShape2D:
		shape.radius = max(shape.radius * max(hurtbox_scale.x, hurtbox_scale.y), 4.0)
	elif shape is RectangleShape2D:
		shape.size *= hurtbox_scale
	collision.shape = shape

func _begin_intro() -> void:
	current_sub_state = BossSubState.INTRO
	_spawn_burst_particles(global_position, _with_alpha(_get_boss_color(), 0.85), 42, 0.5, 160.0)
	action_cooldown = 1.0
	current_sub_state = BossSubState.DECIDE

func _physics_process(delta: float) -> void:
	if is_dead:
		_set_boss_edge_indicator_visible(false)
		return
	if player == null:
		_set_boss_edge_indicator_visible(false)
		return

	_update_boss_edge_indicator()
	_update_phase()
	_update_shared_mechanics(delta)
	_refresh_damage_value()

	match current_state:
		BossState.PRIDE:
			handle_pride(delta)
		BossState.GREED:
			handle_greed(delta)
		BossState.LUST:
			handle_lust(delta)
		BossState.WRATH:
			handle_wrath(delta)
		BossState.ENVY:
			handle_envy(delta)
		BossState.GLUTTONY:
			handle_gluttony(delta)
		BossState.SLOTH:
			handle_sloth(delta)
	_update_footstep_sfx()

func _update_phase() -> void:
	if phase == 2:
		return
	if current_health > max_health * ENRAGE_HEALTH_RATIO:
		return

	phase = 2
	current_sub_state = BossSubState.PHASE_CHANGE
	_try_activate_enrage()
	_spawn_burst_particles(global_position, _with_alpha(_get_boss_color(), 0.9), 58, 0.45, 210.0)
	current_sub_state = BossSubState.DECIDE

func _update_shared_mechanics(delta: float) -> void:
	if action_cooldown > 0.0:
		action_cooldown = max(action_cooldown - delta, 0.0)
	if pride_edge_overlay_cooldown > 0.0:
		pride_edge_overlay_cooldown = max(pride_edge_overlay_cooldown - delta, 0.0)

	_update_wrath_bombs(delta)
	_update_gluttony_foods(delta)
	_update_gluttony_stress(delta)
	_update_lust_walls(delta)
	_update_sloth_slow_zones(delta)
	_update_envy_clone(delta)
	_update_greed_treasures(delta)
	_update_greed_tax(delta)
	_update_greed_shield(delta)
	_update_envy_buff(delta)

func handle_sloth(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	if not _can_start_action():
		return

	if phase == 1:
		if randf() < 0.55:
			_start_sloth_summon(2)
		else:
			_start_sloth_slow_zones(2)
	else:
		if randf() < 0.6:
			_start_sloth_summon(4)
		else:
			_start_sloth_slow_zones(4)

func handle_gluttony(delta: float) -> void:
	if is_gluttony_food_dashing:
		velocity = Vector2.ZERO
		return

	_move_toward_player(delta, 0.82)
	if not _can_start_action():
		return

	if randf() < 0.65:
		_start_gluttony_food_wave(2 if phase == 1 else 4)
	else:
		_start_gluttony_body_slam()

func handle_envy(delta: float) -> void:
	var desired_attack_distance = _get_envy_attack_distance()
	var movement_multiplier = 0.88 if phase == 1 else 1.05 + (0.25 if envy_boss_buff_remaining > 0.0 else 0.0)
	_keep_distance_from_player(delta, desired_attack_distance, movement_multiplier)

	if not is_instance_valid(envy_clone) and not is_performing_action:
		_start_envy_clone()
		return

	if not _can_start_action() or not is_instance_valid(envy_clone):
		return
	if not _is_envy_close_enough_to_attack():
		return

	var roll = randf()
	if phase == 1:
		if roll < 0.65:
			_start_envy_pincer_shot()
		else:
			_start_envy_position_swap()
	else:
		if roll < 0.45:
			_start_envy_pincer_shot()
		elif roll < 0.7:
			_start_envy_position_swap()
		else:
			_start_envy_boss_shot()

func _get_envy_attack_distance() -> float:
	return ENVY_ATTACK_DISTANCE_PHASE_1 if phase == 1 else ENVY_ATTACK_DISTANCE_PHASE_2

func _is_envy_close_enough_to_attack() -> bool:
	if player == null:
		return false
	return global_position.distance_to(player.global_position) <= _get_envy_attack_distance() + ENVY_ATTACK_READY_BUFFER

func handle_wrath(delta: float) -> void:
	_move_toward_player(delta, 1.28)
	if not _can_start_action():
		return

	var roll = randf()
	if phase == 1:
		if roll < 0.62:
			_start_wrath_bomb_volley(4, 2.2)
		else:
			_start_wrath_fissure_combo(3)
	else:
		if roll < 0.46:
			_start_wrath_bomb_volley(6, 1.55)
		else:
			_start_wrath_fissure_combo(4)

func handle_lust(delta: float) -> void:
	_move_lust_around_arena(delta, 0.7)
	if not lust_invulnerability_active:
		lust_invulnerability_cooldown = max(lust_invulnerability_cooldown - delta, 0.0)
		if lust_invulnerability_cooldown <= 0.0:
			_start_lust_invulnerability()

	if not _can_start_action():
		return

	if _should_lust_create_walls():
		_start_lust_wall_pattern()
	else:
		_start_lust_serpent_lash()

func handle_greed(delta: float) -> void:
	_move_greed(delta)
	if not _can_start_action():
		return

	var roll = randf()
	var active_treasure_count = _get_active_greed_treasure_count()
	var should_drop_more_treasure = active_treasure_count < (3 if phase == 1 else 4)
	if should_drop_more_treasure and roll < 0.62:
		_start_greed_treasure_drop(4 if phase == 1 else 6)
	elif roll < 0.76:
		_start_greed_coin_rain()
	else:
		_start_greed_tax_mark()

func _move_greed(delta: float) -> void:
	var target_treasure = _get_closest_active_greed_treasure()
	if target_treasure != null:
		var distance = global_position.distance_to(target_treasure.global_position)
		if distance > GREED_TREASURE_RADIUS + 28.0:
			velocity = global_position.direction_to(target_treasure.global_position) * _get_current_speed(1.1)
			move_and_slide()
			return

	_move_toward_player(delta, 1.0)

func _get_closest_active_greed_treasure() -> Node2D:
	var closest: Node2D = null
	var closest_distance = INF
	for treasure in active_treasures.duplicate():
		if not is_instance_valid(treasure):
			active_treasures.erase(treasure)
			continue
		var distance = global_position.distance_squared_to(treasure.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = treasure
	return closest

func _get_active_greed_treasure_count() -> int:
	var active_count = 0
	for treasure in active_treasures.duplicate():
		if is_instance_valid(treasure):
			active_count += 1
		else:
			active_treasures.erase(treasure)
	return active_count

func handle_pride(delta: float) -> void:
	if is_invulnerable:
		velocity = Vector2.ZERO
		move_and_slide()
	else:
		_move_pride_for_current_attack(delta)

	if not _can_start_action():
		return

	if phase == 1:
		var roll = randf()
		if roll < 0.38:
			_start_pride_edge_bullet_hell(false)
		elif roll < 0.48:
			_maybe_start_pride_edge_beam_overlay(false)
			_start_pride_fire_orbs(false)
		elif roll < 0.70:
			_maybe_start_pride_edge_beam_overlay(false)
			_start_pride_light_cross(false)
		elif roll < 0.90:
			_maybe_start_pride_edge_beam_overlay(false)
			_start_pride_inverted_cross_pattern(false)
		else:
			_maybe_start_pride_edge_beam_overlay(false)
			_start_pride_judgement()
	else:
		var roll = randf()
		if roll < 0.42:
			_start_pride_edge_bullet_hell(true)
		elif roll < 0.50:
			_maybe_start_pride_edge_beam_overlay(true)
			_start_pride_fire_orbs(true)
		elif roll < 0.72:
			_maybe_start_pride_edge_beam_overlay(true)
			_start_pride_inverted_cross_pattern(true)
		elif roll < 0.90:
			_maybe_start_pride_edge_beam_overlay(true)
			_start_pride_light_cross(true)
		else:
			_maybe_start_pride_edge_beam_overlay(true)
			_start_pride_judgement()

func _move_toward_player(_delta: float, speed_multiplier: float = 1.0) -> void:
	if player == null:
		return

	var direction = global_position.direction_to(player.global_position)
	velocity = direction * _get_current_speed(speed_multiplier)
	move_and_slide()

func _move_lust_around_arena(delta: float, speed_multiplier: float = 1.0) -> void:
	if player == null:
		return

	lust_navigation_repath_timer = max(lust_navigation_repath_timer - delta, 0.0)
	if lust_navigation_waypoint == Vector2.ZERO \
			or lust_navigation_repath_timer <= 0.0 \
			or global_position.distance_to(lust_navigation_waypoint) <= LUST_NAVIGATION_WAYPOINT_REACHED:
		lust_navigation_waypoint = _get_lust_navigation_target()
		lust_navigation_repath_timer = LUST_NAVIGATION_REPATH_INTERVAL

	var target_position = lust_navigation_waypoint
	var direction = global_position.direction_to(target_position)
	if direction == Vector2.ZERO:
		velocity = Vector2.ZERO
	else:
		velocity = direction * _get_current_speed(speed_multiplier)
	move_and_slide()

func _get_lust_navigation_target() -> Vector2:
	var player_position = _clamp_to_current_arena(player.global_position, LUST_NAVIGATION_MARGIN)
	var anchor_target = _get_lust_serpent_anchor_target(player_position)
	if anchor_target != Vector2.ZERO:
		return anchor_target

	if _is_segment_safe_in_current_arena(global_position, player_position, LUST_NAVIGATION_MARGIN):
		return player_position

	return _get_lust_fallback_navigation_target(player_position)

func _get_lust_serpent_anchor_target(player_position: Vector2) -> Vector2:
	var anchors = _get_current_arena_anchor_positions()
	if anchors.is_empty():
		return Vector2.ZERO

	anchors.sort_custom(func(a, b): return (a as Vector2).y < (b as Vector2).y)
	var boss_index = _get_closest_anchor_y_index(anchors, global_position)
	var player_index = _get_closest_anchor_y_index(anchors, player_position)
	if boss_index < 0 or player_index < 0:
		return Vector2.ZERO

	var step_direction = signi(player_index - boss_index)
	if step_direction == 0:
		if _is_segment_safe_in_current_arena(anchors[boss_index], player_position, LUST_NAVIGATION_MARGIN):
			return player_position
		step_direction = 1 if player_position.y > global_position.y else -1

	var candidate_index = clampi(boss_index + step_direction, 0, anchors.size() - 1)
	while candidate_index != player_index:
		var candidate = anchors[candidate_index] as Vector2
		if candidate.distance_squared_to(global_position) > LUST_NAVIGATION_WAYPOINT_REACHED * LUST_NAVIGATION_WAYPOINT_REACHED:
			break
		candidate_index = clampi(candidate_index + step_direction, 0, anchors.size() - 1)

	var candidate = anchors[candidate_index] as Vector2
	if candidate_index == player_index and _is_segment_safe_in_current_arena(candidate, player_position, LUST_NAVIGATION_MARGIN):
		return player_position
	return candidate

func _get_closest_anchor_y_index(anchors: Array, position: Vector2) -> int:
	var closest_index = -1
	var closest_distance = INF
	for i in range(anchors.size()):
		var distance = absf(position.y - (anchors[i] as Vector2).y)
		if distance < closest_distance:
			closest_distance = distance
			closest_index = i
	return closest_index

func _get_lust_fallback_navigation_target(target_position: Vector2) -> Vector2:
	var direction = global_position.direction_to(target_position)
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN

	var best_position = global_position
	var best_score = INF
	for angle_degrees in [45.0, -45.0, 90.0, -90.0, 135.0, -135.0, 180.0]:
		var candidate = _clamp_to_current_arena(global_position + direction.rotated(deg_to_rad(angle_degrees)) * LUST_NAVIGATION_FALLBACK_DISTANCE, LUST_NAVIGATION_MARGIN)
		if not _is_segment_safe_in_current_arena(global_position, candidate, LUST_NAVIGATION_MARGIN):
			continue
		var score = candidate.distance_squared_to(target_position)
		if score < best_score:
			best_score = score
			best_position = candidate

	return best_position

func _get_current_arena_anchor_positions() -> Array:
	if not lust_navigation_anchor_cache.is_empty():
		return lust_navigation_anchor_cache

	var tree = get_tree()
	var scene = tree.current_scene if tree != null else null
	if scene == null:
		return []

	var current_arena_node = scene.get("current_arena")
	if not (current_arena_node is Node2D):
		return []

	var anchors: Array = []
	if scene.has_method("_get_current_arena_local_anchor_points"):
		for local_anchor in scene.call("_get_current_arena_local_anchor_points"):
			var anchor_position = (current_arena_node as Node2D).to_global(local_anchor)
			anchor_position = _clamp_to_current_arena(anchor_position, LUST_NAVIGATION_MARGIN)
			if _is_inside_current_arena(anchor_position, LUST_NAVIGATION_MARGIN):
				anchors.append(anchor_position)

	var center = _get_arena_center()
	if anchors.is_empty() and _is_inside_current_arena(center, LUST_NAVIGATION_MARGIN):
		anchors.append(center)
	lust_navigation_anchor_cache = anchors
	return anchors

func _is_segment_safe_in_current_arena(from_position: Vector2, to_position: Vector2, margin: float) -> bool:
	var distance = from_position.distance_to(to_position)
	var steps = max(1, int(ceil(distance / LUST_NAVIGATION_SAMPLE_STEP)))
	for i in range(1, steps + 1):
		var t = float(i) / float(steps)
		if not _is_inside_current_arena(from_position.lerp(to_position, t), margin):
			return false
	return true

func _move_pride_for_current_attack(delta: float) -> void:
	if _update_pride_projectile_dodge(delta):
		return

	pride_orbit_switch_timer -= delta
	if pride_orbit_switch_timer <= 0.0:
		pride_orbit_direction *= -1.0
		pride_orbit_switch_timer = randf_range(PRIDE_ORBIT_SWITCH_MIN_TIME, PRIDE_ORBIT_SWITCH_MAX_TIME)

	var desired_distance = PRIDE_DEFAULT_DISTANCE
	var speed_multiplier = 0.78
	match pride_movement_mode:
		PRIDE_MOVEMENT_CLOSE:
			desired_distance = PRIDE_CLOSE_DISTANCE
			speed_multiplier = 0.96
		PRIDE_MOVEMENT_LASER:
			desired_distance = PRIDE_LASER_DISTANCE
			speed_multiplier = 0.82

	_move_pride_in_visible_orbit(delta, desired_distance, speed_multiplier)

func _move_pride_in_visible_orbit(delta: float, desired_distance: float, speed_multiplier: float) -> void:
	if player == null:
		return

	var visible_rect = _get_pride_visible_rect()
	var to_boss = player.global_position.direction_to(global_position)
	if to_boss == Vector2.ZERO:
		to_boss = Vector2.RIGHT
	var distance = global_position.distance_to(player.global_position)
	var tangent = Vector2(-to_boss.y, to_boss.x) * pride_orbit_direction
	var radial_correction = clampf((distance - desired_distance) / 70.0, -1.0, 1.0)
	var move_direction = (tangent - to_boss * radial_correction * 0.9).normalized()

	if not visible_rect.has_point(global_position):
		move_direction = global_position.direction_to(_clamp_point_to_rect(global_position, visible_rect))

	var movement_speed = _get_current_speed(speed_multiplier)
	var next_position = global_position + move_direction * movement_speed * delta * 2.0
	if not _is_inside_current_arena(next_position, PRIDE_EDGE_SAFETY_MARGIN):
		pride_orbit_direction *= -1.0
		tangent *= -1.0
		move_direction = (tangent + global_position.direction_to(player.global_position) * 0.42).normalized()
		next_position = global_position + move_direction * movement_speed * delta * 2.0
		if not _is_inside_current_arena(next_position, PRIDE_EDGE_SAFETY_MARGIN):
			var safe_target = _clamp_to_current_arena(player.global_position + to_boss * desired_distance, PRIDE_EDGE_SAFETY_MARGIN)
			move_direction = global_position.direction_to(safe_target)

	velocity = move_direction * movement_speed
	move_and_slide()

func _update_pride_projectile_dodge(delta: float) -> bool:
	pride_dodge_scan_timer = max(pride_dodge_scan_timer - delta, 0.0)
	pride_dodge_cooldown = max(pride_dodge_cooldown - delta, 0.0)
	pride_dodge_remaining = max(pride_dodge_remaining - delta, 0.0)

	if pride_dodge_remaining > 0.0 and pride_dodge_direction != Vector2.ZERO:
		var dodge_speed = _get_current_speed(1.38 if phase == 1 else 1.52)
		var next_position = global_position + pride_dodge_direction * dodge_speed * delta * 2.0
		if not _is_inside_current_arena(next_position, PRIDE_EDGE_SAFETY_MARGIN) or not _get_pride_visible_rect().has_point(next_position):
			pride_dodge_remaining = 0.0
			pride_dodge_direction = Vector2.ZERO
			return false
		velocity = pride_dodge_direction * dodge_speed
		move_and_slide()
		return true

	if pride_dodge_cooldown > 0.0 or pride_dodge_scan_timer > 0.0:
		return false
	pride_dodge_scan_timer = PRIDE_DODGE_SCAN_INTERVAL

	var threat = _find_pride_projectile_threat()
	if threat == null:
		return false
	var dodge_chance = 0.62 if phase == 1 else 0.74
	if randf() > dodge_chance:
		pride_dodge_cooldown = PRIDE_DODGE_COOLDOWN * 0.55
		return false

	var projectile_direction = threat.get("direction") as Vector2
	pride_dodge_direction = _choose_pride_dodge_direction(projectile_direction)
	if pride_dodge_direction == Vector2.ZERO:
		return false
	pride_dodge_direction = pride_dodge_direction.rotated(deg_to_rad(randf_range(-9.0, 9.0))).normalized()
	pride_dodge_remaining = PRIDE_DODGE_DURATION
	pride_dodge_cooldown = PRIDE_DODGE_COOLDOWN
	return true

func _find_pride_projectile_threat() -> Node2D:
	var closest_threat: Node2D = null
	var best_score = INF
	var detection_radius_squared = PRIDE_DODGE_DETECTION_RADIUS * PRIDE_DODGE_DETECTION_RADIUS
	for projectile_node in get_tree().get_nodes_in_group(Global.GROUP_PROJECTILE):
		if not (projectile_node is Node2D) or not is_instance_valid(projectile_node):
			continue
		if projectile_node.is_in_group(Global.GROUP_ENEMY_PROJECTILE):
			continue
		var projectile = projectile_node as Node2D
		var distance_squared = projectile.global_position.distance_squared_to(global_position)
		if distance_squared > detection_radius_squared:
			continue
		var projectile_direction = projectile.get("direction") as Vector2
		if projectile_direction == Vector2.ZERO:
			continue
		projectile_direction = projectile_direction.normalized()
		var to_boss = projectile.global_position.direction_to(global_position)
		if projectile_direction.dot(to_boss) < 0.45:
			continue
		var projectile_speed = maxf(float(projectile.get("speed")), 1.0)
		var relative_position = global_position - projectile.global_position
		var closest_time = clampf(relative_position.dot(projectile_direction) / projectile_speed, 0.0, PRIDE_DODGE_PREDICTION_TIME)
		var predicted_position = projectile.global_position + projectile_direction * projectile_speed * closest_time
		var miss_distance = predicted_position.distance_to(global_position)
		if miss_distance > PRIDE_DODGE_TRIGGER_DISTANCE:
			continue
		var threat_score = closest_time * 180.0 + miss_distance + sqrt(distance_squared) * 0.08
		if threat_score < best_score:
			best_score = threat_score
			closest_threat = projectile
	return closest_threat

func _choose_pride_dodge_direction(projectile_direction: Vector2) -> Vector2:
	if projectile_direction == Vector2.ZERO:
		return Vector2.ZERO
	var perpendicular = Vector2(-projectile_direction.y, projectile_direction.x).normalized()
	var visible_rect = _get_pride_visible_rect()
	var best_direction = Vector2.ZERO
	var best_score = -INF
	for side in [-1.0, 1.0]:
		var direction = perpendicular * side
		var candidate = global_position + direction * PRIDE_DODGE_DISTANCE
		if not visible_rect.has_point(candidate):
			continue
		if not _is_inside_current_arena(candidate, PRIDE_EDGE_SAFETY_MARGIN):
			continue
		var player_distance_score = -absf(candidate.distance_to(player.global_position) - PRIDE_DEFAULT_DISTANCE) * 0.16
		var arena_center_score = -candidate.distance_to(_get_arena_center()) * 0.015
		var score = player_distance_score + arena_center_score + randf_range(-8.0, 8.0)
		if score > best_score:
			best_score = score
			best_direction = direction
	return best_direction

func _get_pride_visible_rect() -> Rect2:
	var viewport = get_viewport()
	var camera = viewport.get_camera_2d() if viewport != null else null
	if viewport == null or camera == null:
		return _get_arena_rect().grow(-PRIDE_VISIBLE_MARGIN)
	var visible_size = viewport.get_visible_rect().size / camera.zoom
	return Rect2(camera.global_position - visible_size * 0.5, visible_size).grow(-PRIDE_VISIBLE_MARGIN)

func _clamp_point_to_rect(point: Vector2, rect: Rect2) -> Vector2:
	return Vector2(clampf(point.x, rect.position.x, rect.end.x), clampf(point.y, rect.position.y, rect.end.y))

func _settle_pride_close_attack_position() -> void:
	if player == null:
		return
	if global_position.distance_to(player.global_position) <= PRIDE_CLOSE_DISTANCE + 70.0:
		return
	await get_tree().create_timer(0.45, false).timeout

func _keep_distance_from_player(_delta: float, desired_distance: float, speed_multiplier: float = 0.72) -> void:
	if player == null:
		return

	var distance = global_position.distance_to(player.global_position)
	var direction = player.global_position.direction_to(global_position)
	if distance > desired_distance + 70.0:
		direction = global_position.direction_to(player.global_position)
	elif distance >= desired_distance - 40.0:
		velocity = velocity.move_toward(Vector2.ZERO, base_speed * 4.0 * _delta)
		move_and_slide()
		return

	velocity = direction.normalized() * _get_current_speed(speed_multiplier)
	move_and_slide()

func _get_current_speed(speed_multiplier: float = 1.0) -> float:
	var final_multiplier = speed_multiplier
	if is_enraged:
		final_multiplier *= ENRAGE_STAT_MULTIPLIER
	if envy_boss_buff_remaining > 0.0:
		final_multiplier *= 1.2
	return base_speed * final_multiplier

func _can_start_action() -> bool:
	return not is_performing_action and action_cooldown <= 0.0

func _refresh_damage_value() -> void:
	var multiplier = 1.0
	if is_enraged:
		multiplier *= ENRAGE_STAT_MULTIPLIER
	if current_state == BossState.GLUTTONY:
		multiplier *= 1.0 + float(gluttony_stress_timers.size()) * (0.10 if phase == 1 else 0.15)
	if current_state == BossState.GREED:
		multiplier *= 1.0 + float(greed_money_stacks) * 0.05
	if envy_boss_buff_remaining > 0.0:
		multiplier *= 1.25
	damage = int(round(float(base_damage) * multiplier))

func _setup_enemy_body_collision() -> void:
	collision_mask = collision_mask | Global.ENEMY_COLLISION_MASK
	_shrink_body_collision_shape()

func _shrink_body_collision_shape() -> void:
	var collision = get_node_or_null("CollisionShape2D")
	if collision == null or collision.shape == null:
		return

	var shape = collision.shape.duplicate()
	if shape is CapsuleShape2D:
		shape.radius = max(shape.radius * Global.ENEMY_BODY_COLLISION_SCALE, 4.0)
		shape.height = max(shape.height * Global.ENEMY_BODY_COLLISION_SCALE, shape.radius * 2.0)
	elif shape is CircleShape2D:
		shape.radius = max(shape.radius * Global.ENEMY_BODY_COLLISION_SCALE, 4.0)
	elif shape is RectangleShape2D:
		shape.size *= Global.ENEMY_BODY_COLLISION_SCALE
	collision.shape = shape

func _start_sloth_summon(amount: int) -> void:
	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	_spawn_action_charge_vfx(global_position, 90.0, SLOTH_COLOR, MIN_TELEGRAPH_DURATION, 30)
	await get_tree().create_timer(MIN_TELEGRAPH_DURATION, false).timeout

	current_sub_state = BossSubState.ATTACK
	for i in range(amount):
		var enemy = MELEE_ENEMY_SCENE.instantiate()
		var parent = _get_vfx_parent()
		if parent == null:
			enemy.queue_free()
			return

		parent.add_child(enemy)
		enemy.global_position = _get_random_arena_position_near_player(160.0, 300.0)
		_register_boss_summon(enemy)
		if i < amount - 1:
			await get_tree().create_timer(SLOTH_SUMMON_SPAWN_INTERVAL, false).timeout

	_finish_action(1.7 if phase == 1 else 1.2)

func _start_sloth_slow_zones(amount: int) -> void:
	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	for i in range(amount):
		var zone_position = _get_random_arena_position_near_player(80.0, 280.0)
		var telegraph = _spawn_circle_telegraph(zone_position, SLOTH_SLOW_ZONE_RADIUS, _with_alpha(SLOTH_COLOR, 0.24), SLOTH_ZONE_TELEGRAPH_DURATION)
		await get_tree().create_timer(SLOTH_ZONE_TELEGRAPH_DURATION, false).timeout
		_queue_free_if_valid(telegraph)
		_create_sloth_slow_zone(zone_position)
		if i < amount - 1:
			await get_tree().create_timer(SLOTH_ZONE_SPAWN_INTERVAL, false).timeout

	_trim_node_array(active_slow_zones, 4 if phase == 1 else 7)
	_finish_action(2.0 if phase == 1 else 1.5)

func _create_sloth_slow_zone(zone_position: Vector2) -> void:
	var zone = Area2D.new()
	zone.name = "SlothSlowZone"
	zone.collision_layer = 0
	zone.collision_mask = Global.PLAYER_LAYER_MASK
	zone.set_meta("radius", SLOTH_SLOW_ZONE_RADIUS)
	zone.set_meta("lifetime", SLOTH_SLOW_ZONE_LIFETIME)

	_add_circle_collision(zone, SLOTH_SLOW_ZONE_RADIUS)
	_add_circle_visual(zone, SLOTH_SLOW_ZONE_RADIUS, _with_alpha(SLOTH_COLOR, 0.16), 0)
	_add_ring_visual(zone, SLOTH_SLOW_ZONE_RADIUS, _with_alpha(SLOTH_COLOR, 0.5), 2.0, 0)
	_add_loop_particles(zone, "SlothZoneParticles", _with_alpha(SLOTH_COLOR, 0.34), 42, 1.0, 18.0, 72.0, 0)

	_add_child_at_global(_get_ground_area_vfx_parent(), zone, zone_position)
	active_slow_zones.append(zone)

func _update_sloth_slow_zones(delta: float) -> void:
	if player == null:
		return

	var is_inside_any_zone = false
	var enemies_inside_zone: Array = []
	for zone in active_slow_zones.duplicate():
		if not is_instance_valid(zone):
			active_slow_zones.erase(zone)
			continue
		var lifetime = float(zone.get_meta("lifetime", 0.0)) - delta
		zone.set_meta("lifetime", lifetime)
		if lifetime <= 0.0:
			active_slow_zones.erase(zone)
			zone.queue_free()
			continue
		if _is_point_inside_iso_aoe(player.global_position, zone.global_position, float(zone.get_meta("radius", SLOTH_SLOW_ZONE_RADIUS))):
			is_inside_any_zone = true
		for enemy in get_tree().get_nodes_in_group(Global.GROUP_ENEMY):
			if not _can_sloth_zone_slow_enemy(enemy):
				continue
			if _is_point_inside_iso_aoe(enemy.global_position, zone.global_position, float(zone.get_meta("radius", SLOTH_SLOW_ZONE_RADIUS))):
				if enemy not in enemies_inside_zone:
					enemies_inside_zone.append(enemy)

	if is_inside_any_zone:
		if player.has_method("_set_dash_speed_modifier"):
			player.call("_set_dash_speed_modifier", "sloth_boss_zone", SLOTH_BOSS_PLAYER_DASH_SPEED_MULTIPLIER)
		player.velocity *= SLOTH_BOSS_PLAYER_VELOCITY_MULTIPLIER
		_apply_sloth_zone_player_dot(delta)
	elif player.has_method("_clear_dash_speed_modifier"):
		player.call("_clear_dash_speed_modifier", "sloth_boss_zone")

	_update_sloth_zone_enemy_slow(enemies_inside_zone)

func _apply_sloth_zone_player_dot(delta: float) -> void:
	if player == null:
		return

	sloth_boss_zone_damage_accumulator += SLOTH_BOSS_ZONE_DPS * delta
	var whole_damage = floori(sloth_boss_zone_damage_accumulator)
	if whole_damage <= 0:
		return

	sloth_boss_zone_damage_accumulator -= float(whole_damage)
	if player.has_method("take_damage"):
		player.take_damage(float(whole_damage), global_position, 0.0)

func _can_sloth_zone_slow_enemy(enemy: Node) -> bool:
	return is_instance_valid(enemy) and enemy != self and not enemy.is_in_group(Global.GROUP_BOSS) and enemy.get("speed") != null

func _update_sloth_zone_enemy_slow(enemies_inside_zone: Array) -> void:
	var player_slow_amount = 1.0 - SLOTH_BOSS_ENEMY_SLOW_REFERENCE_DASH_MULTIPLIER
	var enemy_speed_multiplier = 1.0 - player_slow_amount * SLOTH_BOSS_ENEMY_SLOW_EFFECT_RATIO

	for enemy in get_tree().get_nodes_in_group(Global.GROUP_ENEMY):
		if not _can_sloth_zone_slow_enemy(enemy):
			continue
		if enemy in enemies_inside_zone:
			if not enemy.has_meta("sloth_boss_zone_base_speed"):
				enemy.set_meta("sloth_boss_zone_base_speed", float(enemy.get("speed")))
			enemy.set("speed", float(enemy.get_meta("sloth_boss_zone_base_speed")) * enemy_speed_multiplier)
			enemy.set_meta("sloth_boss_zone_active", true)
		elif enemy.has_meta("sloth_boss_zone_active"):
			if enemy.has_meta("sloth_boss_zone_base_speed"):
				enemy.set("speed", float(enemy.get_meta("sloth_boss_zone_base_speed")))
				enemy.remove_meta("sloth_boss_zone_base_speed")
			enemy.remove_meta("sloth_boss_zone_active")

func _start_gluttony_food_wave(amount: int) -> void:
	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	_spawn_action_charge_vfx(global_position, 120.0, GLUTTONY_COLOR, MIN_TELEGRAPH_DURATION, 34)
	await get_tree().create_timer(MIN_TELEGRAPH_DURATION, false).timeout

	current_sub_state = BossSubState.ATTACK
	for i in range(amount):
		_spawn_gluttony_food()
		await get_tree().create_timer(GLUTTONY_FOOD_SPAWN_INTERVAL, false).timeout
	_finish_action(1.75 if phase == 1 else 1.25)

func _spawn_gluttony_food() -> void:
	var food = MELEE_ENEMY_SCENE.instantiate()
	var parent = _get_vfx_parent()
	if parent == null:
		food.queue_free()
		return

	parent.add_child(food)
	food.global_position = _get_random_arena_edge_position()
	food.player = self
	food.speed = GLUTTONY_FOOD_SPEED_PHASE_1 if phase == 1 else GLUTTONY_FOOD_SPEED_PHASE_2
	food.max_health = 45 if phase == 1 else 60
	food.current_health = food.max_health
	food.damage = 10
	food.modulate = _with_alpha(GLUTTONY_COLOR, 1.0)
	food.set_meta("gluttony_food", true)
	food.set_meta("gluttony_delivered", false)
	_add_loop_particles(food, "GluttonyFoodTrail", _with_alpha(GLUTTONY_COLOR, 0.45), 22, 0.6, 10.0, 46.0, 18)
	if food.has_method("_update_health_bar"):
		food.call("_update_health_bar")
	food.tree_exited.connect(Callable(self, "_on_gluttony_food_exited").bind(food))
	gluttony_foods.append(food)
	_register_boss_summon(food)

func _update_gluttony_foods(_delta: float) -> void:
	for food in gluttony_foods.duplicate():
		if not is_instance_valid(food):
			gluttony_foods.erase(food)
			continue
		if food.global_position.distance_to(global_position) <= 40.0:
			food.set_meta("gluttony_delivered", true)
			gluttony_foods.erase(food)
			var heal_amount = max_health * (0.10 if phase == 1 else 0.075)
			heal(heal_amount)
			_spawn_heal_particles(food.global_position)
			_start_gluttony_food_dash()
			food.queue_free()

func _start_gluttony_food_dash() -> void:
	if player == null or is_dead or is_cleaning_up:
		return

	var dash_direction = global_position.direction_to(player.global_position)
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2.RIGHT

	var dash_distance = GLUTTONY_FOOD_DASH_DISTANCE_PHASE_1 if phase == 1 else GLUTTONY_FOOD_DASH_DISTANCE_PHASE_2
	var dash_target = _clamp_to_current_arena(global_position + dash_direction * dash_distance, GLUTTONY_FOOD_DASH_ARENA_MARGIN)
	if dash_target == global_position:
		return

	if gluttony_food_dash_tween != null:
		gluttony_food_dash_tween.kill()

	is_gluttony_food_dashing = true
	velocity = Vector2.ZERO
	_spawn_burst_particles(global_position, _with_alpha(GLUTTONY_COLOR, 0.72), 14, 0.18, 95.0)
	gluttony_food_dash_tween = create_tween().bind_node(self)
	gluttony_food_dash_tween.tween_property(self, "global_position", dash_target, GLUTTONY_FOOD_DASH_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	gluttony_food_dash_tween.tween_callback(Callable(self, "_finish_gluttony_food_dash").bind(gluttony_food_dash_tween))

func _finish_gluttony_food_dash(tween) -> void:
	if gluttony_food_dash_tween == tween:
		gluttony_food_dash_tween = null
	is_gluttony_food_dashing = false
	velocity = Vector2.ZERO

func _on_gluttony_food_exited(food) -> void:
	if is_cleaning_up or is_dead:
		return
	if is_instance_valid(food) and bool(food.get_meta("gluttony_delivered", false)):
		return

	gluttony_stress_timers.append(GLUTTONY_STRESS_DURATION_PHASE_1 if phase == 1 else GLUTTONY_STRESS_DURATION_PHASE_2)
	_spawn_burst_particles(global_position, _with_alpha(GLUTTONY_COLOR, 0.82), 18, 0.24, 120.0)

func _update_gluttony_stress(delta: float) -> void:
	for i in range(gluttony_stress_timers.size() - 1, -1, -1):
		gluttony_stress_timers[i] = float(gluttony_stress_timers[i]) - delta
		if float(gluttony_stress_timers[i]) <= 0.0:
			gluttony_stress_timers.remove_at(i)

func _start_gluttony_body_slam() -> void:
	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	var slam_position = _clamp_to_current_arena(player.global_position, 32.0)
	_spawn_circle_telegraph(slam_position, 115.0, _with_alpha(GLUTTONY_COLOR, 0.24), MIN_TELEGRAPH_DURATION)
	await get_tree().create_timer(MIN_TELEGRAPH_DURATION, false).timeout

	current_sub_state = BossSubState.ATTACK
	global_position = slam_position
	_spawn_ring_vfx(global_position, 115.0, _with_alpha(GLUTTONY_COLOR, 0.44), 0.32)
	_spawn_burst_particles(global_position, _with_alpha(GLUTTONY_COLOR, 0.88), 34, 0.3, 160.0)
	if _is_point_inside_iso_aoe(player.global_position, global_position, 115.0):
		player.take_damage(float(damage) * 1.25, global_position)
	_finish_action(1.75 if phase == 1 else 1.25)

func _start_envy_clone() -> void:
	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	_spawn_action_charge_vfx(global_position, 70.0, ENVY_COLOR, MIN_TELEGRAPH_DURATION, 28)
	await get_tree().create_timer(MIN_TELEGRAPH_DURATION, false).timeout
	_create_envy_clone()
	_finish_action(1.25)

func _create_envy_clone() -> void:
	if is_instance_valid(envy_clone):
		envy_clone.queue_free()

	envy_clone = Area2D.new()
	envy_clone.name = "EnvyMirrorClone"
	var clone_position = _clamp_to_current_arena(global_position * 2.0 - player.global_position, 26.0)
	envy_clone.collision_layer = Global.ENEMY_LAYER_MASK
	envy_clone.collision_mask = 0
	envy_clone.set_meta("projectile_special_owner", self)
	envy_clone.set_meta("special_type", "envy_clone")
	envy_clone.set_meta("health", ENVY_CLONE_MAX_HEALTH)
	envy_clone.set_meta("max_health", ENVY_CLONE_MAX_HEALTH)

	_add_circle_collision(envy_clone, 22.0)
	_add_player_mirror_clone_visual(envy_clone)
	_add_ring_visual(envy_clone, 24.0, _with_alpha(ENVY_COLOR, 0.78), 2.0, 13)
	_add_loop_particles(envy_clone, "EnvyCloneParticles", _with_alpha(ENVY_COLOR, 0.42), 30, 0.65, 12.0, 62.0, 14)
	_add_small_health_bar(envy_clone, 42.0, Vector2(-21.0, -34.0))

	_add_child_at_global(_get_vfx_parent(), envy_clone, clone_position)

func _add_player_mirror_clone_visual(parent: Node) -> void:
	if player == null:
		return

	var player_visual_source = player.get_node_or_null("Aparencia")
	if player_visual_source == null:
		return

	var visual = player_visual_source.duplicate()
	visual.name = "MirroredPlayerCopy"
	if visual is CanvasItem:
		(visual as CanvasItem).modulate = ENVY_CLONE_VISUAL_MODULATE
		(visual as CanvasItem).z_index = 12
	if visual is Node2D and player_visual_source is Node2D:
		(visual as Node2D).position = (player_visual_source as Node2D).position
		(visual as Node2D).scale = (player_visual_source as Node2D).scale
	if visual is AnimatedSprite2D and player_visual_source is AnimatedSprite2D:
		var clone_visual = visual as AnimatedSprite2D
		var player_visual = player_visual_source as AnimatedSprite2D
		clone_visual.animation = player_visual.animation
		clone_visual.frame = player_visual.frame
		clone_visual.flip_h = not player_visual.flip_h
		clone_visual.play()

	parent.add_child(visual)

func _sync_envy_clone_player_visual() -> void:
	if player == null or not is_instance_valid(envy_clone):
		return

	var visual = envy_clone.get_node_or_null("MirroredPlayerCopy")
	var player_visual_source = player.get_node_or_null("Aparencia")
	if visual is CanvasItem:
		(visual as CanvasItem).modulate = ENVY_CLONE_VISUAL_MODULATE
	if visual is AnimatedSprite2D and player_visual_source is AnimatedSprite2D:
		var clone_visual = visual as AnimatedSprite2D
		var player_visual = player_visual_source as AnimatedSprite2D
		clone_visual.animation = player_visual.animation
		clone_visual.frame = player_visual.frame
		clone_visual.flip_h = not player_visual.flip_h
		if player_visual.is_playing() and not clone_visual.is_playing():
			clone_visual.play()

func _aim_envy_clone_visual(direction: Vector2) -> void:
	if not is_instance_valid(envy_clone) or direction == Vector2.ZERO:
		return

	var visual = envy_clone.get_node_or_null("MirroredPlayerCopy")
	if visual is AnimatedSprite2D:
		var clone_visual = visual as AnimatedSprite2D
		clone_visual.flip_h = direction.x < 0.0
		clone_visual.play()

func _update_envy_clone(delta: float) -> void:
	if not is_instance_valid(envy_clone) or player == null:
		return

	_sync_envy_clone_player_visual()
	if envy_clone_movement_locked:
		return

	if envy_clone_shot_pending:
		return

	var mirror_target = global_position * 2.0 - player.global_position
	envy_clone.global_position = envy_clone.global_position.lerp(_clamp_to_current_arena(mirror_target, 28.0), 0.07)
	envy_clone_fire_cooldown = max(envy_clone_fire_cooldown - delta, 0.0)
	if envy_clone_fire_cooldown <= 0.0:
		var direction = _get_envy_clone_shot_direction(envy_clone.global_position)
		_start_envy_clone_weapon_telegraph(envy_clone.global_position, direction)

func _start_envy_clone_weapon_telegraph(spawn_position: Vector2, shot_direction: Vector2) -> void:
	envy_clone_shot_pending = true
	var telegraph_duration = MIN_TELEGRAPH_DURATION
	_aim_envy_clone_visual(shot_direction)
	_spawn_line_telegraph(spawn_position, spawn_position + shot_direction * 160.0, ENVY_COLOR, telegraph_duration, 1.6)
	await get_tree().create_timer(telegraph_duration, false).timeout

	envy_clone_shot_pending = false
	envy_clone_fire_cooldown = _get_envy_clone_fire_cooldown()
	if is_dead or player == null or not is_instance_valid(envy_clone):
		return
	_fire_envy_clone_weapon(spawn_position, shot_direction)

func _get_envy_clone_shot_direction(from_position: Vector2) -> Vector2:
	var direct_direction = from_position.direction_to(player.global_position)
	if direct_direction == Vector2.ZERO:
		direct_direction = Vector2.RIGHT

	var pattern_index = envy_clone_shot_pattern_index % 3
	envy_clone_shot_pattern_index += 1
	match pattern_index:
		0:
			return direct_direction.normalized()
		1:
			var mirrored_direction = Vector2(direct_direction.x, -direct_direction.y)
			return mirrored_direction.normalized() if mirrored_direction != Vector2.ZERO else direct_direction.normalized()
		_:
			var player_velocity = Vector2.ZERO
			if player.get("velocity") != null:
				player_velocity = player.velocity
			var predicted_position = player.global_position + player_velocity * (0.28 if phase == 1 else 0.38)
			var predictive_direction = from_position.direction_to(predicted_position)
			return predictive_direction.normalized() if predictive_direction != Vector2.ZERO else direct_direction.normalized()

func _get_envy_clone_fire_cooldown() -> float:
	match _get_envy_clone_arm_id():
		"fast":
			return 0.62 if phase == 1 else 0.48
		"heavy":
			return 1.25 if phase == 1 else 1.0
		"unstable":
			return 0.9 if phase == 1 else 0.72
	return 1.0 if phase == 1 else 0.75

func _get_envy_clone_arm_id() -> String:
	if player != null and player.get("current_arm_id") != null:
		var arm_id = str(player.get("current_arm_id"))
		if arm_id != "":
			return arm_id
	return "fast"

func _fire_envy_clone_weapon(spawn_position: Vector2, shot_direction: Vector2, damage_multiplier: float = 1.0) -> void:
	if shot_direction == Vector2.ZERO:
		return

	var base_damage = float(damage) * damage_multiplier
	match _get_envy_clone_arm_id():
		"fast":
			var base_angle = shot_direction.angle()
			for angle_offset in [-7.0, 7.0]:
				var direction = Vector2.RIGHT.rotated(base_angle + deg_to_rad(angle_offset))
				var projectile = _spawn_enemy_projectile(spawn_position, direction, base_damage * 0.42, _with_alpha(ENVY_COLOR, 0.9), 530.0)
				projectile.scale *= 0.78
		"heavy":
			var heavy_projectile = _spawn_enemy_projectile(spawn_position, shot_direction, base_damage * 1.05, _with_alpha(ENVY_COLOR, 0.95), 360.0)
			heavy_projectile.scale *= 1.35
		"unstable":
			var unstable_projectile = _spawn_enemy_projectile(spawn_position, shot_direction, base_damage * 0.62, Color(0.68, 0.35, 1.0, 0.95), 470.0)
			_configure_envy_unstable_projectile(unstable_projectile)
		_:
			_spawn_enemy_projectile(spawn_position, shot_direction, base_damage * 0.7, _with_alpha(ENVY_COLOR, 0.9), 440.0)

func _configure_envy_unstable_projectile(projectile: Area2D) -> void:
	if not is_instance_valid(projectile):
		return

	projectile.set_meta("enemy_ricochet_enabled", true)
	projectile.set_meta("ricochet_remaining", 1)
	projectile.collision_mask = Global.PLAYER_LAYER_MASK | Global.WALL_LAYER_MASK

func _start_envy_pincer_shot() -> void:
	if not is_instance_valid(envy_clone) or player == null:
		return

	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	envy_clone_movement_locked = true
	velocity = Vector2.ZERO

	var boss_position = global_position
	var clone_position = envy_clone.global_position
	var boss_direction = boss_position.direction_to(player.global_position)
	var clone_direction = clone_position.direction_to(player.global_position)
	if boss_direction == Vector2.ZERO:
		boss_direction = Vector2.RIGHT
	if clone_direction == Vector2.ZERO:
		clone_direction = Vector2.LEFT

	_spawn_line_telegraph(boss_position, boss_position + boss_direction.normalized() * 210.0, ENVY_COLOR, ENVY_PINCER_TELEGRAPH_DURATION, 2.4)
	_spawn_line_telegraph(clone_position, clone_position + clone_direction.normalized() * 210.0, ENVY_COLOR, ENVY_PINCER_TELEGRAPH_DURATION, 2.4)
	_spawn_ring_vfx(boss_position, 36.0, _with_alpha(ENVY_COLOR, 0.36), ENVY_PINCER_TELEGRAPH_DURATION)
	_spawn_ring_vfx(clone_position, 36.0, _with_alpha(ENVY_COLOR, 0.36), ENVY_PINCER_TELEGRAPH_DURATION)
	await get_tree().create_timer(ENVY_PINCER_TELEGRAPH_DURATION, false).timeout

	envy_clone_movement_locked = false
	if is_dead or player == null or not is_instance_valid(envy_clone):
		_finish_action(0.8)
		return

	current_sub_state = BossSubState.ATTACK
	boss_direction = boss_position.direction_to(player.global_position)
	clone_direction = clone_position.direction_to(player.global_position)
	if boss_direction == Vector2.ZERO:
		boss_direction = Vector2.RIGHT
	if clone_direction == Vector2.ZERO:
		clone_direction = Vector2.LEFT

	_spawn_enemy_projectile(boss_position, boss_direction, float(damage) * (0.62 if phase == 1 else 0.72), _with_alpha(ENVY_COLOR, 0.92), 475.0)
	if phase == 2:
		for angle_offset in [-10.0, 10.0]:
			_spawn_enemy_projectile(boss_position, boss_direction.rotated(deg_to_rad(angle_offset)), float(damage) * 0.48, _with_alpha(ENVY_COLOR, 0.82), 455.0)
	_fire_envy_clone_weapon(clone_position, clone_direction, 0.95)
	_finish_action(1.1 if phase == 1 else 0.85)

func _start_envy_position_swap() -> void:
	if not is_instance_valid(envy_clone):
		return

	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	envy_clone_movement_locked = true
	velocity = Vector2.ZERO

	var boss_position = global_position
	var clone_position = envy_clone.global_position
	_spawn_line_telegraph(boss_position, clone_position, ENVY_COLOR, ENVY_SWAP_TELEGRAPH_DURATION, 3.0)
	_spawn_ring_vfx(boss_position, 46.0, _with_alpha(ENVY_COLOR, 0.42), ENVY_SWAP_TELEGRAPH_DURATION)
	_spawn_ring_vfx(clone_position, 46.0, _with_alpha(ENVY_COLOR, 0.42), ENVY_SWAP_TELEGRAPH_DURATION)
	await get_tree().create_timer(ENVY_SWAP_TELEGRAPH_DURATION, false).timeout

	if is_dead or not is_instance_valid(envy_clone):
		envy_clone_movement_locked = false
		_finish_action(0.8)
		return

	current_sub_state = BossSubState.ATTACK
	global_position = _clamp_to_current_arena(clone_position, 32.0)
	envy_clone.global_position = _clamp_to_current_arena(boss_position, 28.0)
	_spawn_burst_particles(global_position, _with_alpha(ENVY_COLOR, 0.8), 24, 0.24, 110.0)
	_spawn_burst_particles(envy_clone.global_position, _with_alpha(ENVY_COLOR, 0.72), 18, 0.2, 95.0)
	envy_clone_movement_locked = false
	_finish_action(1.0 if phase == 1 else 0.75)

func _start_envy_boss_shot() -> void:
	is_performing_action = true
	current_sub_state = BossSubState.ATTACK
	var telegraph_duration = MIN_TELEGRAPH_DURATION
	for i in range(3):
		var direction = global_position.direction_to(player.global_position).rotated(deg_to_rad((i - 1) * 14.0))
		_spawn_line_telegraph(global_position, global_position + direction * 180.0, ENVY_COLOR, telegraph_duration, 2.0)
	await get_tree().create_timer(telegraph_duration, false).timeout
	for i in range(3):
		var direction = global_position.direction_to(player.global_position).rotated(deg_to_rad((i - 1) * 14.0))
		_spawn_enemy_projectile(global_position, direction, float(damage) * 0.75, _with_alpha(ENVY_COLOR, 0.9), 460.0)
	_finish_action(1.25)

func _update_envy_buff(delta: float) -> void:
	if envy_boss_buff_remaining > 0.0:
		envy_boss_buff_remaining = max(envy_boss_buff_remaining - delta, 0.0)

func _start_wrath_bomb_volley(amount: int, fuse_time: float) -> void:
	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	_spawn_action_charge_vfx(global_position, 80.0, WRATH_TELEGRAPH_COLOR, WRATH_BOMB_TELEGRAPH_DURATION, 34)
	await get_tree().create_timer(WRATH_BOMB_TELEGRAPH_DURATION, false).timeout

	current_sub_state = BossSubState.ATTACK
	for i in range(amount):
		var target = player.global_position + Vector2(randf_range(-90.0, 90.0), randf_range(-70.0, 70.0))
		var bomb_position = global_position + Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0))
		var telegraph_duration = WRATH_BOMB_TELEGRAPH_DURATION
		_spawn_wrath_line_telegraph(bomb_position, target, telegraph_duration)
		await get_tree().create_timer(telegraph_duration, false).timeout
		if is_dead or player == null:
			return
		_create_wrath_bomb(bomb_position, target, fuse_time)
		await get_tree().create_timer(0.48 if phase == 1 else 0.36, false).timeout

	_finish_action(0.36 if phase == 1 else 0.25)

func _start_wrath_fissure_combo(fissure_count: int) -> void:
	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	_spawn_action_charge_vfx(global_position, 92.0, WRATH_TELEGRAPH_COLOR, WRATH_FISSURE_TELEGRAPH_DURATION, 30)
	await get_tree().create_timer(WRATH_FISSURE_TELEGRAPH_DURATION, false).timeout

	current_sub_state = BossSubState.ATTACK
	for i in range(fissure_count):
		if is_dead or player == null:
			return
		var source_position = _clamp_to_current_arena(global_position + Vector2.RIGHT.rotated(randf_range(-PI, PI)) * randf_range(20.0, 72.0), 34.0)
		var target_position = player.global_position
		if player.get("velocity") != null:
			target_position += player.velocity * (0.10 if phase == 1 else 0.16)
		var direction = source_position.direction_to(_clamp_to_current_arena(target_position, 34.0))
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT.rotated(randf_range(-PI, PI))
		direction = direction.rotated(deg_to_rad(randf_range(-10.0, 10.0)))
		_spawn_wrath_fissure(source_position, direction, _get_wrath_fissure_length(), WRATH_FISSURE_TELEGRAPH_DURATION)
		if i < fissure_count - 1:
			await get_tree().create_timer(0.14 if phase == 1 else 0.09, false).timeout

	_finish_action(0.46 if phase == 1 else 0.30)

func _get_wrath_fissure_length() -> float:
	return WRATH_FISSURE_LENGTH_PHASE_2 if phase == 2 else WRATH_FISSURE_LENGTH_PHASE_1

func _spawn_wrath_fissure(origin: Vector2, direction: Vector2, length: float, telegraph_delay: float) -> void:
	if direction == Vector2.ZERO:
		return

	var normalized_direction = direction.normalized()
	var center = _clamp_to_current_arena(origin + normalized_direction * length * 0.5, 28.0)
	var size = Vector2(length, WRATH_FISSURE_WIDTH + (8.0 if phase == 2 else 0.0))
	var angle = normalized_direction.angle()
	var fissure_damage = max(float(roundi(float(damage) * WRATH_FISSURE_DAMAGE_MULTIPLIER / 5.0) * 5), 5.0)
	_spawn_rect_telegraph(center, size, angle, _with_alpha(WRATH_TELEGRAPH_COLOR, 0.42), telegraph_delay, WRATH_OUTLINE_COLOR, 4.0)
	_create_damaging_area_after_delay(center, size, angle, fissure_damage, _with_alpha(WRATH_ATTACK_COLOR, 0.62), telegraph_delay, WRATH_FISSURE_DAMAGE_DURATION, "", WRATH_OUTLINE_COLOR, 3.0)

func _create_wrath_bomb(from_position: Vector2, target_position: Vector2, fuse_time: float) -> void:
	var bomb = Area2D.new()
	bomb.name = "WrathBomb"
	bomb.collision_layer = Global.ENEMY_LAYER_MASK
	bomb.collision_mask = Global.WALL_LAYER_MASK | Global.PLAYER_LAYER_MASK
	bomb.set_meta("projectile_special_owner", self)
	bomb.set_meta("special_type", "wrath_bomb")
	bomb.set_meta("velocity", from_position.direction_to(target_position) * (185.0 if phase == 1 else 215.0))
	bomb.set_meta("fuse", fuse_time)
	bomb.set_meta("pushed", false)

	_add_circle_collision(bomb, WRATH_BOMB_RADIUS)
	_add_circle_visual(bomb, WRATH_BOMB_RADIUS, _with_alpha(WRATH_ATTACK_COLOR, 0.9), 12)
	_add_ring_visual(bomb, WRATH_BOMB_RADIUS + 4.0, WRATH_OUTLINE_COLOR, 5.0, 13)
	_add_ring_visual(bomb, WRATH_BOMB_RADIUS + 3.0, _with_alpha(WRATH_TELEGRAPH_COLOR, 0.98), 2.4, 14)
	_add_loop_particles(bomb, "WrathBombFuse", _with_alpha(WRATH_TELEGRAPH_COLOR, 0.82), 18, 0.38, 12.0, 56.0, 15)

	bomb.body_entered.connect(Callable(self, "_on_wrath_bomb_body_entered").bind(bomb))
	_add_child_at_global(_get_vfx_parent(), bomb, from_position)
	active_bombs.append(bomb)

func _update_wrath_bombs(delta: float) -> void:
	for bomb in active_bombs.duplicate():
		if not is_instance_valid(bomb):
			active_bombs.erase(bomb)
			continue

		var fuse = float(bomb.get_meta("fuse", 0.0)) - delta
		bomb.set_meta("fuse", fuse)
		var bomb_velocity = bomb.get_meta("velocity", Vector2.ZERO)
		bomb.global_position += bomb_velocity * delta
		bomb.rotation += delta * 5.0
		var fuse_alpha = 0.78 + max(0.0, sin(Time.get_ticks_msec() * 0.012)) * 0.22
		bomb.modulate = Color(1.0, 1.0, 1.0, fuse_alpha)

		if bool(bomb.get_meta("pushed", false)) and _is_point_inside_iso_aoe(bomb.global_position, global_position, 38.0):
			_explode_wrath_bomb(bomb, true)
			continue

		if not _is_inside_current_arena(bomb.global_position, WRATH_BOMB_RADIUS):
			_explode_wrath_bomb(bomb, false)
			continue

		if fuse <= 0.0:
			_explode_wrath_bomb(bomb, false)

func _on_wrath_bomb_body_entered(body: Node, bomb) -> void:
	if not is_instance_valid(bomb):
		return
	if body.is_in_group(Global.GROUP_PLAYER):
		_explode_wrath_bomb(bomb, false)
	elif body != self:
		_explode_wrath_bomb(bomb, false)

func _explode_wrath_bomb(bomb, force_boss_damage: bool) -> void:
	if not is_instance_valid(bomb):
		return

	var explosion_position = bomb.global_position
	var was_pushed = bool(bomb.get_meta("pushed", false))
	active_bombs.erase(bomb)
	bomb.queue_free()
	_spawn_burst_particles(explosion_position, _with_alpha(WRATH_ATTACK_COLOR, 0.98), 46, 0.38, 220.0)
	_spawn_circle_telegraph(explosion_position, WRATH_BOMB_EXPLOSION_RADIUS, _with_alpha(WRATH_TELEGRAPH_COLOR, 0.28), MIN_TELEGRAPH_DURATION)
	_spawn_ring_vfx(explosion_position, WRATH_BOMB_EXPLOSION_RADIUS, _with_alpha(WRATH_TELEGRAPH_COLOR, 0.76), 0.28)

	if player and _is_point_inside_iso_aoe(player.global_position, explosion_position, WRATH_BOMB_EXPLOSION_RADIUS):
		player.take_damage(WRATH_BOMB_DAMAGE, explosion_position)

	if (force_boss_damage or was_pushed) and _is_point_inside_iso_aoe(global_position, explosion_position, WRATH_BOMB_EXPLOSION_RADIUS):
		take_self_damage(max_health * 0.10)
	elif not was_pushed and player != null and (phase == 2 or randf() < 0.35):
		var aftershock_direction = explosion_position.direction_to(player.global_position)
		if aftershock_direction == Vector2.ZERO:
			aftershock_direction = Vector2.RIGHT.rotated(randf_range(-PI, PI))
		_spawn_wrath_fissure(explosion_position, aftershock_direction, _get_wrath_fissure_length() * 0.72, 0.34)

func _should_lust_create_walls() -> bool:
	var active_wall_count = _get_active_lust_wall_count()
	if active_wall_count >= _get_lust_wall_stock_limit():
		return false

	var chance = LUST_WALL_BASE_CHANCE_PHASE_1 if phase == 1 else LUST_WALL_BASE_CHANCE_PHASE_2
	chance -= float(active_wall_count) * LUST_WALL_EXISTING_CHANCE_PENALTY
	return randf() < max(chance, LUST_WALL_MIN_CHANCE)

func _get_active_lust_wall_count() -> int:
	var active_count = 0
	for wall in active_lust_walls.duplicate():
		if is_instance_valid(wall):
			active_count += 1
		else:
			active_lust_walls.erase(wall)
	return active_count

func _get_lust_wall_stock_limit() -> int:
	return LUST_WALL_STOCK_LIMIT_PHASE_1 if phase == 1 else LUST_WALL_STOCK_LIMIT_PHASE_2

func _start_lust_wall_pattern() -> void:
	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	var available_wall_slots = max(_get_lust_wall_stock_limit() - _get_active_lust_wall_count(), 1)
	var wall_count = min(2 if phase == 1 else 3, available_wall_slots)
	var wall_lifetime = 4.2 if phase == 1 else 5.0
	var telegraph_duration = MIN_TELEGRAPH_DURATION
	for i in range(wall_count):
		var horizontal = (i % 2 == 0)
		var size = Vector2(LUST_WALL_LENGTH, LUST_WALL_THICKNESS) if horizontal else Vector2(LUST_WALL_THICKNESS, LUST_WALL_LENGTH)
		var position = _get_lust_wall_position(i, wall_count)
		var breakable = randf() < (0.64 if phase == 1 else 0.54)
		var telegraph = _spawn_rect_telegraph(position, size, 0.0, _with_alpha(LUST_COLOR, 0.24), telegraph_duration)
		await get_tree().create_timer(telegraph_duration, false).timeout
		_queue_free_if_valid(telegraph)
		_create_lust_wall(position, size, breakable, wall_lifetime)

	await get_tree().create_timer(0.55, false).timeout
	_finish_action(1.65 if phase == 1 else 1.15)

func _get_lust_wall_position(index: int, wall_count: int) -> Vector2:
	var center = _get_arena_center()
	var offset_index = float(index) - float(wall_count - 1) * 0.5
	var spacing = 86.0 if phase == 1 else 62.0
	if index % 2 == 0:
		return _clamp_to_current_arena(center + Vector2(0.0, offset_index * spacing), 45.0)
	return _clamp_to_current_arena(center + Vector2(offset_index * spacing, 0.0), 45.0)

func _create_lust_wall(wall_position: Vector2, size: Vector2, breakable: bool, lifetime: float) -> void:
	var wall = StaticBody2D.new()
	wall.name = "BreakableLustWall" if breakable else "LustWall"
	wall.collision_layer = Global.WALL_LAYER_MASK
	wall.collision_mask = 0
	wall.set_meta("breakable", breakable)
	wall.set_meta("owner_boss", self)
	wall.set_meta("lifetime", lifetime)
	wall.set_meta("size", size)

	_add_rect_collision(wall, size)
	_add_rect_visual(wall, size, _with_alpha(LUST_COLOR, 0.82) if breakable else Color(0.24, 0.03, 0.12, 0.92), 14)
	add_collision_exception_with(wall)
	wall.add_collision_exception_with(self)

	if breakable:
		wall.set_meta("hits_remaining", LUST_BREAKABLE_WALL_MAX_HITS)
		wall.set_meta("health", float(LUST_BREAKABLE_WALL_MAX_HITS))
		wall.set_meta("max_health", float(LUST_BREAKABLE_WALL_MAX_HITS))
		var hurtbox = Area2D.new()
		hurtbox.name = "BreakableHurtbox"
		hurtbox.collision_layer = Global.ENEMY_LAYER_MASK
		hurtbox.collision_mask = 0
		hurtbox.set_meta("projectile_special_owner", self)
		hurtbox.set_meta("special_type", "lust_wall")
		hurtbox.set_meta("wall", wall)
		_add_rect_collision(hurtbox, size + Vector2(8.0, 8.0))
		wall.add_child(hurtbox)
		var bar_width = 72.0 if size.x < size.y else min(size.x, 90.0)
		_add_small_health_bar(wall, bar_width, Vector2(-bar_width * 0.5, -size.y * 0.5 - 14.0))
		_add_breakable_wall_particles(wall, size)

	_add_child_at_global(_get_vfx_parent(), wall, wall_position)
	active_lust_walls.append(wall)
	_trim_node_array(active_lust_walls, _get_lust_wall_stock_limit())

func _start_lust_serpent_lash() -> void:
	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	var path = _build_lust_serpent_lash_path()
	var lash_id = "lust_lash_%d" % Time.get_ticks_usec()
	_spawn_action_charge_vfx(global_position, 72.0, LUST_COLOR, LUST_SERPENT_LASH_TELEGRAPH_DURATION, 22)
	_spawn_lust_serpent_lash_telegraph(path, LUST_SERPENT_LASH_TELEGRAPH_DURATION)
	await get_tree().create_timer(LUST_SERPENT_LASH_TELEGRAPH_DURATION, false).timeout
	if is_dead or player == null:
		return

	current_sub_state = BossSubState.ATTACK
	var lash_damage = max(float(roundi(float(damage) * LUST_SERPENT_LASH_DAMAGE_MULTIPLIER / 5.0) * 5), 5.0)
	for point in path:
		if is_dead or player == null:
			return
		_create_lust_serpent_lash_area(point, lash_id, lash_damage)
		await get_tree().create_timer(LUST_SERPENT_LASH_SEGMENT_INTERVAL, false).timeout

	_finish_action(1.15 if phase == 1 else 0.85)

func _build_lust_serpent_lash_path() -> PackedVector2Array:
	var path = PackedVector2Array()
	var start_position = _clamp_to_current_arena(global_position, LUST_SERPENT_LASH_RADIUS + 8.0)
	var target_position = player.global_position if player != null else _get_arena_center()
	var direction = start_position.direction_to(target_position)
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN

	var normal = Vector2(-direction.y, direction.x).normalized()
	var lash_length = clamp(start_position.distance_to(target_position) + 180.0, 320.0, 640.0)
	var origin = _clamp_to_current_arena(start_position + direction * 36.0, LUST_SERPENT_LASH_RADIUS + 8.0)
	var end_position = _clamp_to_current_arena(origin + direction * lash_length, LUST_SERPENT_LASH_RADIUS + 8.0)
	var amplitude = 70.0 if phase == 1 else 92.0

	for i in range(LUST_SERPENT_LASH_SEGMENTS):
		var t = float(i) / float(LUST_SERPENT_LASH_SEGMENTS - 1)
		var center = origin.lerp(end_position, t)
		var wave = sin(t * TAU * 1.35) * amplitude * sin(t * PI)
		path.append(_clamp_to_current_arena(center + normal * wave, LUST_SERPENT_LASH_RADIUS + 8.0))

	return path

func _spawn_lust_serpent_lash_telegraph(path: PackedVector2Array, duration: float) -> Node2D:
	var telegraph = Node2D.new()
	telegraph.name = "LustSerpentLashTelegraph"
	var glow = Line2D.new()
	glow.width = LUST_SERPENT_LASH_RADIUS * 1.75
	glow.default_color = _with_alpha(LUST_COLOR, 0.18)
	glow.points = path
	glow.joint_mode = Line2D.LINE_JOINT_ROUND
	telegraph.add_child(glow)

	var edge = Line2D.new()
	edge.width = 3.0
	edge.default_color = _with_alpha(LUST_COLOR, 0.74)
	edge.points = path
	edge.joint_mode = Line2D.LINE_JOINT_ROUND
	telegraph.add_child(edge)

	if not _add_child_at_global(_get_ground_area_vfx_parent(), telegraph, Vector2.ZERO):
		return telegraph

	var tree = get_tree()
	if tree == null:
		return telegraph
	var timer = tree.create_timer(duration, false)
	timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(telegraph))
	return telegraph

func _create_lust_serpent_lash_area(area_position: Vector2, lash_id: String, lash_damage: float) -> void:
	var area = Area2D.new()
	area.name = "LustSerpentLashArea"
	area.collision_layer = 0
	area.collision_mask = Global.PLAYER_LAYER_MASK
	area.set_meta("damage", lash_damage)
	area.set_meta("lash_id", lash_id)
	_add_circle_collision(area, LUST_SERPENT_LASH_RADIUS)
	_add_circle_visual(area, LUST_SERPENT_LASH_RADIUS, _with_alpha(LUST_COLOR, 0.36), 0)
	_add_ring_visual(area, LUST_SERPENT_LASH_RADIUS, _with_alpha(LUST_COLOR, 0.78), 2.0, 1)
	area.body_entered.connect(Callable(self, "_on_lust_serpent_lash_body_entered").bind(area))
	if not _add_child_at_global(_get_ground_area_vfx_parent(), area, area_position):
		return

	if player != null and _is_point_inside_iso_aoe(player.global_position, area_position, LUST_SERPENT_LASH_RADIUS):
		_damage_lust_lash_player(player, area)

	var tree = get_tree()
	if tree == null:
		return
	var cleanup_timer = tree.create_timer(LUST_SERPENT_LASH_DAMAGE_DURATION, false)
	cleanup_timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(area))

func _add_breakable_wall_particles(wall: Node2D, size: Vector2) -> void:
	var particles = CPUParticles2D.new()
	particles.name = "BreakableIndicator"
	particles.amount = 30
	particles.lifetime = 0.55
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 8.0
	particles.initial_velocity_max = 35.0
	particles.emission_rect_extents = size * 0.5
	particles.color = Color(1.0, 1.0, 1.0, 0.72)
	particles.z_index = 18
	wall.add_child(particles)
	particles.emitting = true

	var tween = create_tween().bind_node(particles)
	tween.set_loops()
	tween.tween_property(particles, "modulate:a", 0.25, 0.35)
	tween.tween_property(particles, "modulate:a", 1.0, 0.35)

func _update_lust_walls(delta: float) -> void:
	for wall in active_lust_walls.duplicate():
		if not is_instance_valid(wall):
			active_lust_walls.erase(wall)
			continue
		var lifetime = float(wall.get_meta("lifetime", 0.0)) - delta
		wall.set_meta("lifetime", lifetime)
		if lifetime <= 0.0:
			active_lust_walls.erase(wall)
			wall.queue_free()

func _start_lust_invulnerability() -> void:
	lust_invulnerability_active = true
	is_invulnerable = true
	_spawn_attached_aura(92.0, _with_alpha(LUST_COLOR, 0.34), 1.8)
	_spawn_burst_particles(global_position, _with_alpha(LUST_COLOR, 0.7), 28, 0.32, 125.0)
	await get_tree().create_timer(1.35 if phase == 1 else 1.1, false).timeout
	is_invulnerable = false
	lust_invulnerability_active = false
	lust_invulnerability_cooldown = 7.5 if phase == 1 else 5.25

func _start_greed_treasure_drop(amount: int) -> void:
	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	var telegraph_duration = GREED_TREASURE_TELEGRAPH_DURATION
	for i in range(amount):
		var pos = _get_greed_treasure_drop_position(i, amount)
		var telegraph = _spawn_circle_telegraph(pos, GREED_TREASURE_RADIUS + 14.0, _with_alpha(GREED_COLOR, 0.24), telegraph_duration)
		await get_tree().create_timer(telegraph_duration, false).timeout
		_queue_free_if_valid(telegraph)
		_create_greed_treasure(pos)
	_finish_action(0.8 if phase == 1 else 0.6)

func _get_greed_treasure_drop_position(index: int, amount: int) -> Vector2:
	if player == null:
		return _get_random_arena_position_anywhere(GREED_TREASURE_RADIUS + 20.0)

	var route_t = float(index + 1) / float(amount + 1)
	var route_position = global_position.lerp(player.global_position, route_t)
	var route_direction = global_position.direction_to(player.global_position)
	if route_direction == Vector2.ZERO:
		route_direction = Vector2.RIGHT.rotated(randf_range(-PI, PI))
	var side = -1.0 if index % 2 == 0 else 1.0
	var lateral = Vector2(-route_direction.y, route_direction.x) * side * randf_range(38.0, 86.0)
	var jitter = Vector2.RIGHT.rotated(randf_range(-PI, PI)) * randf_range(0.0, 34.0)
	return _clamp_to_current_arena(route_position + lateral + jitter, GREED_TREASURE_RADIUS + 24.0)

func _create_greed_treasure(treasure_position: Vector2) -> void:
	var treasure = Area2D.new()
	treasure.name = "GreedTreasure"
	treasure.collision_layer = 0
	treasure.collision_mask = Global.PLAYER_LAYER_MASK | Global.ENEMY_LAYER_MASK
	treasure.set_meta("lifetime", 5.6 if phase == 1 else 4.8)

	_add_circle_collision(treasure, GREED_TREASURE_RADIUS)
	_add_circle_visual(treasure, GREED_TREASURE_RADIUS, _with_alpha(GREED_COLOR, 0.88), 14)
	_add_ring_visual(treasure, GREED_TREASURE_RADIUS + 5.0, _with_alpha(GREED_COLOR, 0.82), 2.0, 15)
	_add_loop_particles(treasure, "GreedTreasureSparkles", _with_alpha(GREED_COLOR, 0.55), 20, 0.7, 8.0, 38.0, 16)
	treasure.body_entered.connect(Callable(self, "_on_greed_treasure_body_entered").bind(treasure))
	_add_child_at_global(_get_vfx_parent(), treasure, treasure_position)
	active_treasures.append(treasure)
	_trim_node_array(active_treasures, GREED_TREASURE_LIMIT_PHASE_2 if phase == 2 else GREED_TREASURE_LIMIT_PHASE_1)

func _update_greed_treasures(delta: float) -> void:
	for treasure in active_treasures.duplicate():
		if not is_instance_valid(treasure):
			active_treasures.erase(treasure)
			continue
		var lifetime = float(treasure.get_meta("lifetime", 0.0)) - delta
		treasure.set_meta("lifetime", lifetime)
		treasure.rotation += delta * 2.8
		if global_position.distance_to(treasure.global_position) <= GREED_TREASURE_BOSS_COLLECT_RADIUS:
			_collect_greed_treasure_for_boss(treasure)
		elif lifetime <= 0.0:
			active_treasures.erase(treasure)
			treasure.queue_free()

func _on_greed_treasure_body_entered(body: Node, treasure) -> void:
	if body.is_in_group(Global.GROUP_PLAYER):
		_collect_greed_treasure_for_player(treasure)
	elif body == self or body.is_in_group(Global.GROUP_BOSS):
		_collect_greed_treasure_for_boss(treasure)

func _collect_greed_treasure_for_player(treasure) -> void:
	if not is_instance_valid(treasure):
		return
	AchievementManager.record_greed_treasure_collected()
	active_treasures.erase(treasure)
	treasure.queue_free()
	_spawn_burst_particles(player.global_position, _with_alpha(GREED_COLOR, 0.9), 18, 0.28, 110.0)
	_apply_temporary_player_attack_boost(1.25, 5.0)
	if player != null and player.has_method("heal") and player.get("max_health") != null:
		player.heal(float(player.get("max_health")) * GREED_PLAYER_TREASURE_HEAL_RATIO)
	greed_money_stacks = max(greed_money_stacks - 1, 0)
	greed_shield_remaining = max(greed_shield_remaining - 1.25, 0.0)

func _collect_greed_treasure_for_boss(treasure) -> void:
	if not is_instance_valid(treasure):
		return
	active_treasures.erase(treasure)
	treasure.queue_free()
	greed_money_stacks = min(greed_money_stacks + 1, 8)
	greed_shield_remaining = max(greed_shield_remaining, 2.6)
	heal(float(max_health) * GREED_BOSS_TREASURE_HEAL_RATIO)
	_spawn_marker_on_node(self, 54.0, GREED_COLOR, greed_shield_remaining)
	_spawn_burst_particles(global_position, _with_alpha(GREED_COLOR, 0.9), 24, 0.32, 130.0)
	if greed_money_stacks % GREED_JACKPOT_STACK_INTERVAL == 0:
		_spawn_greed_jackpot_burst()

func _spawn_greed_jackpot_burst() -> void:
	var projectile_count = 8 + min(greed_money_stacks, 8)
	_spawn_ring_vfx(global_position, 96.0, _with_alpha(GREED_COLOR, 0.58), 0.35)
	_spawn_radial_projectiles_from(global_position, projectile_count, float(damage) * GREED_JACKPOT_DAMAGE_MULTIPLIER, _with_alpha(GREED_COLOR, 0.9), 360.0 if phase == 1 else 430.0, randf_range(0.0, TAU))

func _apply_temporary_player_attack_boost(multiplier: float, duration: float) -> void:
	if player == null:
		return
	player.temporary_attack_multiplier = max(player.temporary_attack_multiplier, multiplier)
	var tree = get_tree()
	if tree == null:
		return
	await tree.create_timer(duration, false).timeout
	if is_instance_valid(player) and player.temporary_attack_multiplier <= multiplier + 0.01:
		player.temporary_attack_multiplier = 1.0

func _update_greed_shield(delta: float) -> void:
	if greed_shield_remaining > 0.0:
		greed_shield_remaining = max(greed_shield_remaining - delta, 0.0)

func _start_greed_coin_rain() -> void:
	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	var projectile_count = 9 + greed_money_stacks * 2
	projectile_count = min(projectile_count, 26)
	var warning_duration = GREED_COIN_WARNING_DURATION
	var burst_size = 3 if phase == 1 else 4
	var spawned_count = 0
	while spawned_count < projectile_count:
		var focus_position = _get_greed_coin_rain_focus_position()
		var current_burst_size = mini(burst_size, projectile_count - spawned_count)
		var burst_targets := []
		for i in range(current_burst_size):
			var target_position = _get_greed_coin_rain_target_position(focus_position, i, current_burst_size)
			var spawn_position = target_position + Vector2(randf_range(-26.0, 26.0), -340.0 - randf_range(0.0, 80.0))
			burst_targets.append({
				"target": target_position,
				"spawn": spawn_position
			})
			_spawn_falling_warning(target_position, GREED_COLOR, warning_duration, GREED_COIN_RAIN_WARNING_RADIUS, spawn_position)
		await get_tree().create_timer(warning_duration, false).timeout
		for shot in burst_targets:
			_spawn_enemy_projectile(shot["spawn"], Vector2.DOWN, float(damage) * 0.72, _with_alpha(GREED_COLOR, 0.95), 585.0 if phase == 1 else 650.0)
		spawned_count += current_burst_size
		await get_tree().create_timer(0.24 if phase == 1 else 0.18, false).timeout
	_finish_action(0.9 if phase == 1 else 0.6)

func _get_greed_coin_rain_focus_position() -> Vector2:
	if player == null:
		return _get_random_arena_position_anywhere(32.0)

	var boss_to_player = global_position.direction_to(player.global_position)
	if boss_to_player == Vector2.ZERO:
		return player.global_position

	var focus = player.global_position - boss_to_player * randf_range(10.0, 72.0)
	return _clamp_to_current_arena(focus, 32.0)

func _get_greed_coin_rain_target_position(focus_position: Vector2, index: int, burst_size: int) -> Vector2:
	var cluster_radius = GREED_COIN_RAIN_CLUSTER_RADIUS_PHASE_2 if phase == 2 else GREED_COIN_RAIN_CLUSTER_RADIUS_PHASE_1
	var lane_offset = (float(index) - (float(burst_size) - 1.0) * 0.5) * 42.0
	var sweep_direction = Vector2.RIGHT.rotated(randf_range(-0.35, 0.35))
	var side_direction = sweep_direction.orthogonal()
	var target = focus_position
	target += sweep_direction * lane_offset
	target += side_direction * randf_range(-cluster_radius * 0.38, cluster_radius * 0.38)
	target += Vector2.RIGHT.rotated(randf_range(-PI, PI)) * randf_range(0.0, cluster_radius * 0.22)
	return _clamp_to_current_arena(target, 32.0)

func _start_greed_tax_mark() -> void:
	is_performing_action = true
	greed_tax_active = true
	greed_tax_timer = 4.5 if phase == 1 else 3.0
	greed_tax_meter = 0.0
	greed_previous_player_position = player.global_position
	greed_previous_can_shoot = player.can_shoot
	_spawn_marker_on_node(player, 42.0, GREED_COLOR, greed_tax_timer)
	_spawn_action_charge_vfx(global_position, 70.0, GREED_COLOR, 0.66, 26)
	_finish_action(0.8)

func _update_greed_tax(delta: float) -> void:
	if not greed_tax_active or player == null:
		return

	greed_tax_timer -= delta
	greed_tax_meter += player.global_position.distance_to(greed_previous_player_position) * 0.008
	if greed_previous_can_shoot and not player.can_shoot:
		greed_tax_meter += 2.0
	greed_previous_can_shoot = player.can_shoot
	greed_previous_player_position = player.global_position
	if greed_tax_timer <= 0.0:
		greed_tax_active = false
		if greed_tax_meter > 14.0:
			player.take_damage((greed_tax_meter - 14.0) * 1.6 + 10.0, global_position)
			_spawn_burst_particles(player.global_position, _with_alpha(GREED_COLOR, 0.9), 28, 0.3, 150.0)

func _start_pride_fire_orbs(overlap: bool) -> void:
	pride_movement_mode = PRIDE_MOVEMENT_CLOSE
	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	await _settle_pride_close_attack_position()
	var waves = 2 if not overlap else 3
	for wave in range(waves):
		var projectile_count = 10 if phase == 1 else 16
		var origin = global_position
		var angle_offset = float(wave) * 0.18
		_spawn_action_charge_vfx(origin, 64.0, PRIDE_FIRE_COLOR, MIN_TELEGRAPH_DURATION, 14)
		_spawn_pride_radial_fire_telegraphs(origin, projectile_count, angle_offset, MIN_TELEGRAPH_DURATION)
		await get_tree().create_timer(MIN_TELEGRAPH_DURATION, false).timeout
		if is_dead or player == null:
			return
		current_sub_state = BossSubState.ATTACK
		_spawn_radial_projectiles_from(origin, projectile_count, _get_pride_damage(PRIDE_FIRE_ORB_DAMAGE_MULTIPLIER), _with_alpha(PRIDE_FIRE_COLOR, 0.92), 390.0, angle_offset)
		await get_tree().create_timer(2.0, false).timeout
		current_sub_state = BossSubState.TELEGRAPH
	if overlap:
		_spawn_pride_light_beams(true)
	_finish_action(1.5 if phase == 1 else 1.0)

func _start_pride_light_cross(overlap: bool) -> void:
	pride_movement_mode = PRIDE_MOVEMENT_LASER
	is_performing_action = true
	_spawn_pride_light_beams(overlap)
	if overlap:
		await get_tree().create_timer(MIN_TELEGRAPH_DURATION, false).timeout
		var origin = global_position
		_spawn_pride_radial_fire_telegraphs(origin, 10, 0.0, MIN_TELEGRAPH_DURATION)
		await get_tree().create_timer(MIN_TELEGRAPH_DURATION, false).timeout
		if is_dead or player == null:
			return
		_spawn_radial_projectiles_from(origin, 10, _get_pride_damage(PRIDE_AIMED_FIREBALL_DAMAGE_MULTIPLIER), _with_alpha(PRIDE_FIRE_COLOR, 0.9), 360.0)
	_finish_action(1.5 if phase == 1 else 0.9)

func _start_pride_edge_bullet_hell(overlap: bool) -> void:
	pride_movement_mode = PRIDE_MOVEMENT_LASER
	is_performing_action = true
	current_sub_state = BossSubState.SPECIAL
	var telegraph_delay = PRIDE_EDGE_BEAM_DELAY_PHASE_1 if phase == 1 else PRIDE_EDGE_BEAM_DELAY_PHASE_2
	var batch_count = 3 if overlap else 2
	var beams_per_batch = 3 if overlap else 2
	var beam_spacing = 0.16 if overlap else 0.20
	var batch_gap = 0.45 if overlap else 0.55
	var beam_width = PRIDE_EDGE_BEAM_WIDTH if phase == 1 else PRIDE_EDGE_BEAM_WIDTH + 6.0
	_spawn_action_charge_vfx(global_position, 72.0, PRIDE_LIGHT_COLOR, MIN_TELEGRAPH_DURATION, 24)
	await get_tree().create_timer(MIN_TELEGRAPH_DURATION, false).timeout

	for batch in range(batch_count):
		if is_dead or player == null:
			break
		current_sub_state = BossSubState.TELEGRAPH
		for beam_index in range(beams_per_batch):
			var start_position = _get_pride_edge_beam_start(batch * beams_per_batch + beam_index)
			var target_position = player.global_position
			if phase == 2 and player.get("velocity") != null:
				target_position += player.velocity * 0.12
			var direction = start_position.direction_to(_clamp_to_current_arena(target_position, 28.0))
			if direction == Vector2.ZERO:
				direction = start_position.direction_to(_get_arena_center())
			_spawn_pride_edge_beam(start_position, direction, telegraph_delay, beam_width)
			if beam_index < beams_per_batch - 1:
				await get_tree().create_timer(beam_spacing, false).timeout

		await get_tree().create_timer(telegraph_delay + PRIDE_EDGE_BEAM_DURATION, false).timeout
		if batch < batch_count - 1:
			await get_tree().create_timer(batch_gap, false).timeout
			current_sub_state = BossSubState.TELEGRAPH
			await _start_pride_aimed_fireballs(2 if phase == 1 else 3, 14.0 if phase == 1 else 22.0)
			await get_tree().create_timer(batch_gap, false).timeout

	_finish_action(1.1 if phase == 1 else 0.85)

func _maybe_start_pride_edge_beam_overlay(overlap: bool) -> void:
	if pride_edge_overlay_cooldown > 0.0:
		return

	var chance = PRIDE_EDGE_OVERLAY_CHANCE_PHASE_2 if phase == 2 else PRIDE_EDGE_OVERLAY_CHANCE_PHASE_1
	if randf() > chance:
		return

	pride_edge_overlay_cooldown = PRIDE_EDGE_OVERLAY_COOLDOWN_PHASE_2 if phase == 2 else PRIDE_EDGE_OVERLAY_COOLDOWN_PHASE_1
	_start_pride_edge_beam_overlay(overlap)

func _start_pride_edge_beam_overlay(overlap: bool) -> void:
	if player == null:
		return

	var telegraph_delay = PRIDE_EDGE_BEAM_DELAY_PHASE_1 if phase == 1 else PRIDE_EDGE_BEAM_DELAY_PHASE_2
	var beam_count = 3 if overlap else 2
	var beam_spacing = 0.16 if overlap else 0.2
	var beam_width = PRIDE_EDGE_BEAM_WIDTH + (5.0 if phase == 2 else 0.0)
	for i in range(beam_count):
		if is_dead or player == null:
			return

		var start_position = _get_pride_edge_beam_start(i)
		var target_position = player.global_position
		if phase == 2 and player.get("velocity") != null:
			target_position += player.velocity * 0.1
		var direction = start_position.direction_to(_clamp_to_current_arena(target_position, 28.0))
		if direction == Vector2.ZERO:
			direction = start_position.direction_to(_get_arena_center())
		_spawn_pride_edge_beam(start_position, direction, telegraph_delay, beam_width)
		if i < beam_count - 1:
			await get_tree().create_timer(beam_spacing, false).timeout

func _get_pride_edge_beam_start(index: int) -> Vector2:
	return _get_random_arena_edge_position()

func _spawn_pride_edge_beam(start_position: Vector2, beam_direction: Vector2, telegraph_delay: float, beam_width: float) -> void:
	if beam_direction == Vector2.ZERO:
		return

	beam_direction = beam_direction.normalized()
	var arena_rect = _get_arena_rect()
	var beam_length = arena_rect.size.length() + 180.0
	var beam_center = start_position + beam_direction * beam_length * 0.5
	var beam_size = Vector2(beam_length, beam_width)
	var rotation_angle = beam_direction.angle()
	var telegraph_color = _with_alpha(PRIDE_LIGHT_COLOR, 0.22)

	_spawn_pride_edge_origin_marker(start_position, telegraph_delay)
	_spawn_rect_telegraph(beam_center, beam_size, rotation_angle, telegraph_color, telegraph_delay)
	_create_pride_edge_beam_after_delay(beam_center, beam_size, rotation_angle, telegraph_delay)

func _spawn_pride_edge_origin_marker(start_position: Vector2, duration: float) -> void:
	var marker = Node2D.new()
	_add_circle_visual(marker, 18.0, _with_alpha(PRIDE_LIGHT_COLOR, 0.16), 15)
	_add_ring_visual(marker, 21.0, _with_alpha(PRIDE_LIGHT_COLOR, 0.82), 2.4, 16)
	_add_loop_particles(marker, "PrideEdgeBeamOrigin", _with_alpha(PRIDE_LIGHT_COLOR, 0.5), 22, 0.55, 8.0, 42.0, 17)
	if not _add_child_at_global(_get_ground_area_vfx_parent(), marker, start_position):
		return

	var tree = get_tree()
	if tree == null:
		return
	var timer = tree.create_timer(duration, false)
	timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(marker))

func _create_pride_edge_beam_after_delay(beam_center: Vector2, beam_size: Vector2, beam_rotation: float, delay: float) -> void:
	await get_tree().create_timer(delay, false).timeout
	if is_dead or not is_inside_tree():
		return
	var beam_damage = _get_pride_damage(PRIDE_EDGE_BEAM_DAMAGE_MULTIPLIER)
	var beam_color = _with_alpha(PRIDE_LIGHT_COLOR, 0.4)
	_create_damaging_area(beam_center, beam_size, beam_rotation, beam_damage, beam_color, PRIDE_EDGE_BEAM_DURATION, "pride_laser")
	_spawn_burst_particles(beam_center, _with_alpha(PRIDE_LIGHT_COLOR, 0.55), 8, 0.18, 80.0)

func _start_pride_inverted_cross_pattern(overlap: bool) -> void:
	pride_movement_mode = PRIDE_MOVEMENT_LASER
	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	var cross_count = 1 if phase == 1 else 2
	var telegraph_delay = MIN_TELEGRAPH_DURATION
	var beam_width = PRIDE_EDGE_BEAM_WIDTH + (4.0 if phase == 2 else 0.0)
	_spawn_action_charge_vfx(global_position, 86.0, PRIDE_LIGHT_COLOR, MIN_TELEGRAPH_DURATION, 26)
	await get_tree().create_timer(MIN_TELEGRAPH_DURATION, false).timeout

	for i in range(cross_count):
		if is_dead or player == null:
			return
		var start_position = _get_pride_edge_beam_start(i)
		var direction = start_position.direction_to(_clamp_to_current_arena(player.global_position, 28.0))
		if direction == Vector2.ZERO:
			direction = start_position.direction_to(_get_arena_center())
		_spawn_pride_inverted_cross_beam(start_position, direction, telegraph_delay, beam_width)
		await get_tree().create_timer(telegraph_delay + PRIDE_EDGE_BEAM_DURATION, false).timeout
		if overlap and i < cross_count - 1:
			await _start_pride_aimed_fireballs(2, 18.0)

	_finish_action(1.2 if phase == 1 else 0.95)

func _spawn_pride_inverted_cross_beam(start_position: Vector2, beam_direction: Vector2, telegraph_delay: float, beam_width: float) -> void:
	if beam_direction == Vector2.ZERO:
		return

	beam_direction = beam_direction.normalized()
	var arena_rect = _get_arena_rect()
	var beam_length = arena_rect.size.length() + 180.0
	var main_center = start_position + beam_direction * beam_length * 0.5
	var main_size = Vector2(beam_length, beam_width)
	var rotation_angle = beam_direction.angle()
	var crossbar_distance = beam_length * PRIDE_EDGE_CROSSBAR_OFFSET_RATIO
	if player != null:
		crossbar_distance = clamp(start_position.distance_to(player.global_position) + 80.0, beam_length * 0.34, beam_length * 0.78)
	var crossbar_center = start_position + beam_direction * crossbar_distance
	var crossbar_size = Vector2(PRIDE_EDGE_CROSSBAR_LENGTH if phase == 1 else PRIDE_EDGE_CROSSBAR_LENGTH + 45.0, beam_width)
	var crossbar_rotation = rotation_angle + PI * 0.5
	var telegraph_color = _with_alpha(PRIDE_LIGHT_COLOR, 0.2)

	_spawn_rect_telegraph(main_center, main_size, rotation_angle, telegraph_color, telegraph_delay)
	_spawn_rect_telegraph(crossbar_center, crossbar_size, crossbar_rotation, telegraph_color, telegraph_delay)
	_create_pride_inverted_cross_beam_after_delay(main_center, main_size, rotation_angle, crossbar_center, crossbar_size, crossbar_rotation, telegraph_delay)

func _create_pride_inverted_cross_beam_after_delay(main_center: Vector2, main_size: Vector2, main_rotation: float, crossbar_center: Vector2, crossbar_size: Vector2, crossbar_rotation: float, delay: float) -> void:
	await get_tree().create_timer(delay, false).timeout
	if is_dead or not is_inside_tree():
		return
	var beam_damage = _get_pride_damage(PRIDE_INVERTED_CROSS_DAMAGE_MULTIPLIER)
	var beam_color = _with_alpha(PRIDE_LIGHT_COLOR, 0.36)
	_create_damaging_area(main_center, main_size, main_rotation, beam_damage, beam_color, PRIDE_EDGE_BEAM_DURATION, "pride_laser")
	_create_damaging_area(crossbar_center, crossbar_size, crossbar_rotation, beam_damage, beam_color, PRIDE_EDGE_BEAM_DURATION, "pride_laser")
	_spawn_burst_particles(main_center, _with_alpha(PRIDE_LIGHT_COLOR, 0.55), 10, 0.18, 80.0)

func _start_pride_aimed_fireballs(amount: int, spread_degrees: float) -> void:
	if player == null:
		return

	var direction = global_position.direction_to(player.global_position)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var base_angle = direction.angle()
	var start_offset = -spread_degrees * 0.5
	var step = spread_degrees / max(float(amount - 1), 1.0)
	var shots: Array = []
	for i in range(amount):
		var angle_offset = start_offset + step * float(i)
		var projectile_direction = Vector2.RIGHT.rotated(base_angle + deg_to_rad(angle_offset))
		var spawn_position = global_position + projectile_direction * 34.0
		shots.append({ "position": spawn_position, "direction": projectile_direction })
		_spawn_line_telegraph(spawn_position, spawn_position + projectile_direction * 170.0, PRIDE_FIRE_COLOR, MIN_TELEGRAPH_DURATION, 1.8)

	await get_tree().create_timer(MIN_TELEGRAPH_DURATION, false).timeout
	if is_dead or player == null:
		return

	for shot in shots:
		var projectile = _spawn_enemy_projectile(shot["position"], shot["direction"], _get_pride_damage(PRIDE_AIMED_FIREBALL_DAMAGE_MULTIPLIER), _with_alpha(PRIDE_FIRE_COLOR, 0.94), 395.0 if phase == 1 else 445.0)
		if projectile != null:
			projectile.scale *= 0.92

func _spawn_radial_projectiles_from(origin: Vector2, projectile_count: int, projectile_damage: float, color: Color, projectile_speed: float, angle_offset: float = 0.0) -> void:
	for i in range(projectile_count):
		var angle = TAU * float(i) / float(projectile_count) + angle_offset
		var direction = Vector2(cos(angle), sin(angle))
		_spawn_enemy_projectile(origin + direction * 34.0, direction, projectile_damage, color, projectile_speed)

func _spawn_pride_radial_fire_telegraphs(origin: Vector2, projectile_count: int, angle_offset: float, duration: float) -> void:
	for i in range(projectile_count):
		var angle = TAU * float(i) / float(projectile_count) + angle_offset
		var direction = Vector2(cos(angle), sin(angle))
		_spawn_line_telegraph(origin, origin + direction * 180.0, PRIDE_FIRE_COLOR, duration, 1.5)

func _spawn_pride_light_beams(include_diagonals: bool) -> void:
	var center = _get_arena_center()
	var length = 980.0
	var beam_size = Vector2(length, 34.0)
	var rotations = [0.0, PI / 2.0]
	if include_diagonals:
		rotations.append(PI / 4.0)
		rotations.append(-PI / 4.0)
	for rotation_angle in rotations:
		_spawn_rect_telegraph(center, beam_size, rotation_angle, _with_alpha(PRIDE_LIGHT_COLOR, 0.24), 0.75)
	_create_pride_beams_after_delay(center, beam_size, rotations, 0.75)

func _create_pride_beams_after_delay(center: Vector2, beam_size: Vector2, rotations: Array, delay: float) -> void:
	await get_tree().create_timer(delay, false).timeout
	for rotation_angle in rotations:
		_create_damaging_area(center, beam_size, rotation_angle, _get_pride_damage(PRIDE_LIGHT_BEAM_DAMAGE_MULTIPLIER), _with_alpha(PRIDE_LIGHT_COLOR, 0.35), 0.5, "pride_laser")

func _start_pride_judgement() -> void:
	pride_movement_mode = PRIDE_MOVEMENT_LASER
	is_performing_action = true
	is_invulnerable = true
	current_sub_state = BossSubState.SPECIAL
	global_position = _get_arena_center()
	_spawn_attached_aura(100.0, _with_alpha(PRIDE_LIGHT_COLOR, 0.36), 3.2)
	_spawn_burst_particles(global_position, _with_alpha(PRIDE_LIGHT_COLOR, 0.72), 42, 0.42, 160.0)

	var wave_count = 3 if phase == 1 else 5
	for wave in range(wave_count):
		_spawn_pride_judgement_wave(wave)
		await get_tree().create_timer(2.5 if phase == 1 else 2.0, false).timeout

	is_invulnerable = false
	_finish_action(2.0 if phase == 1 else 1.35)

func _spawn_pride_judgement_wave(wave_index: int) -> void:
	var arena_rect = _get_arena_rect()
	var vertical = wave_index % 2 == 0
	var lane_count = 7
	var safe_lane = randi() % lane_count
	for i in range(lane_count):
		if i == safe_lane:
			continue
		var t = (float(i) + 0.5) / float(lane_count)
		if vertical:
			var x = lerp(arena_rect.position.x, arena_rect.end.x, t)
			var pos = Vector2(x, arena_rect.get_center().y)
			var size = Vector2(28.0, arena_rect.size.y + 100.0)
			_spawn_pride_judgement_beam(pos, size)
		else:
			var y = lerp(arena_rect.position.y, arena_rect.end.y, t)
			var pos = Vector2(arena_rect.get_center().x, y)
			var size = Vector2(arena_rect.size.x + 100.0, 28.0)
			_spawn_pride_judgement_beam(pos, size)

func _spawn_pride_judgement_beam(beam_position: Vector2, beam_size: Vector2) -> void:
	_spawn_rect_telegraph(beam_position, beam_size, 0.0, _with_alpha(PRIDE_LIGHT_COLOR, 0.23), 0.75)
	_create_damaging_area_after_delay(beam_position, beam_size, 0.0, _get_pride_damage(PRIDE_JUDGEMENT_BEAM_DAMAGE_MULTIPLIER), _with_alpha(PRIDE_LIGHT_COLOR, 0.38), 0.75, 0.5, "pride_laser")

func _on_projectile_hit_special_area(area, projectile) -> void:
	if not is_instance_valid(area):
		return

	var special_type = str(area.get_meta("special_type", ""))
	match special_type:
		"wrath_bomb":
			var push_direction = projectile.direction.normalized()
			if push_direction == Vector2.ZERO:
				push_direction = projectile.global_position.direction_to(area.global_position)
			area.set_meta("velocity", push_direction * WRATH_BOMB_PUSH_SPEED)
			area.set_meta("pushed", true)
			area.set_meta("fuse", min(float(area.get_meta("fuse", 1.0)), 1.75 if phase == 1 else 1.0))
			_spawn_burst_particles(area.global_position, _with_alpha(WRATH_COLOR, 0.82), 8, 0.14, 70.0)
			projectile.queue_free()
		"lust_wall":
			var wall = area.get_meta("wall", null)
			if is_instance_valid(wall):
				_damage_lust_wall(wall, _get_projectile_damage(projectile, 35.0), projectile.global_position)
			projectile.queue_free()
		"envy_clone":
			_damage_envy_clone(_get_projectile_damage(projectile, 35.0), projectile.global_position)
			projectile.queue_free()

func _get_projectile_damage(projectile: Node, fallback_damage: float) -> float:
	if projectile.get("damage") != null:
		return float(projectile.get("damage"))
	return fallback_damage

func _damage_lust_wall(wall: Node, _amount: float, hit_position: Vector2) -> void:
	if not is_instance_valid(wall) or not bool(wall.get_meta("breakable", false)):
		return
	var hits_remaining = int(wall.get_meta("hits_remaining", LUST_BREAKABLE_WALL_MAX_HITS)) - 1
	wall.set_meta("hits_remaining", hits_remaining)
	wall.set_meta("health", float(max(hits_remaining, 0)))
	_update_embedded_health_bar(wall)
	_spawn_burst_particles(hit_position, Color(1.0, 1.0, 1.0, 0.72), 8, 0.16, 65.0)
	if hits_remaining <= 0:
		active_lust_walls.erase(wall)
		_spawn_burst_particles(wall.global_position, _with_alpha(LUST_COLOR, 0.82), 24, 0.28, 130.0)
		wall.queue_free()

func _on_lust_serpent_lash_body_entered(body: Node, area) -> void:
	if body.is_in_group(Global.GROUP_PLAYER):
		_damage_lust_lash_player(body, area)

func _damage_lust_lash_player(target: Node, area) -> void:
	if not is_instance_valid(target) or not is_instance_valid(area):
		return

	var lash_id = str(area.get_meta("lash_id", ""))
	if str(target.get_meta(LUST_SERPENT_LASH_HIT_META, "")) == lash_id:
		return

	target.set_meta(LUST_SERPENT_LASH_HIT_META, lash_id)
	if target.has_method("take_damage"):
		target.take_damage(float(area.get_meta("damage", damage)), area.global_position)

func _damage_envy_clone(amount: float, hit_position: Vector2) -> void:
	if not is_instance_valid(envy_clone):
		return
	var health = float(envy_clone.get_meta("health", 0.0)) - amount
	envy_clone.set_meta("health", health)
	_update_embedded_health_bar(envy_clone)
	_spawn_burst_particles(hit_position, _with_alpha(ENVY_COLOR, 0.75), 8, 0.16, 65.0)
	if health <= 0.0:
		_spawn_burst_particles(envy_clone.global_position, _with_alpha(ENVY_COLOR, 0.9), 26, 0.28, 140.0)
		envy_clone.queue_free()
		envy_clone = null
		envy_boss_buff_remaining = 6.0 if phase == 1 else 9.0

func take_damage(amount: float) -> void:
	if is_dead:
		return
	if current_state == BossState.GREED and greed_shield_remaining > 0.0:
		greed_shield_remaining = 0.0
		_spawn_burst_particles(global_position, _with_alpha(GREED_COLOR, 0.95), 26, 0.28, 150.0)
		return
	if is_invulnerable:
		_spawn_burst_particles(global_position, _with_alpha(_get_boss_color(), 0.55), 10, 0.16, 70.0)
		return

	var final_amount = amount * _get_damage_taken_multiplier()
	current_health -= int(round(final_amount))
	_update_health_bar()
	_flash_damage()
	if current_health <= 0:
		die()
		return

	_try_activate_enrage()

func take_self_damage(amount: float) -> void:
	if is_dead:
		return
	current_health -= int(round(amount))
	_update_health_bar()
	_flash_damage()
	if current_health <= 0:
		die()

func _get_damage_taken_multiplier() -> float:
	if current_state == BossState.GLUTTONY:
		return 1.0 + float(gluttony_stress_timers.size()) * (0.1 if phase == 1 else 0.15)
	return 1.0

func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return

	var previous_health = current_health
	current_health = int(min(current_health + amount, max_health))
	_update_health_bar()
	if current_health > previous_health:
		_flash_heal()

func _try_activate_enrage() -> void:
	if is_enraged:
		return
	if current_health > max_health * ENRAGE_HEALTH_RATIO:
		return
	is_enraged = true
	if has_meta("base_speed"):
		set_meta("base_speed", float(get_meta("base_speed")) * ENRAGE_STAT_MULTIPLIER)

func _flash_damage() -> void:
	_play_health_feedback(DAMAGE_FEEDBACK_COLOR)

func _flash_heal() -> void:
	_play_health_feedback(HEAL_FEEDBACK_COLOR)

func _play_health_feedback(color: Color) -> void:
	if not aparencia:
		return
	if health_feedback_tween != null:
		health_feedback_tween.kill()
		health_feedback_tween = null

	aparencia.modulate = health_feedback_base_modulate
	health_feedback_tween = create_tween().bind_node(aparencia)
	health_feedback_tween.tween_property(aparencia, "modulate", color, 0.08)
	health_feedback_tween.tween_property(aparencia, "modulate", health_feedback_base_modulate, 0.12)
	health_feedback_tween.tween_callback(Callable(self, "_clear_health_feedback_tween").bind(health_feedback_tween))

func _clear_health_feedback_tween(tween) -> void:
	if health_feedback_tween == tween:
		health_feedback_tween = null

func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_cleaning_up = true
	current_sub_state = BossSubState.DEAD
	current_health = 0
	_update_health_bar()
	set_physics_process(false)
	_stop_footstep_sfx()
	_set_boss_edge_indicator_visible(false)
	_cleanup_boss_objects()

	var should_grant_rewards = grants_progression_reward and (Global.is_endless_mode() or sin_id < 7)
	if should_grant_rewards and player and player.has_method("gain_xp"):
		player.gain_xp(xp_drop)
	if should_grant_rewards and player and player.has_method("on_enemy_killed"):
		player.on_enemy_killed(self)

	if advances_story_progress and Global.is_story_mode():
		Global.pecado += 1
	boss_defeated.emit()
	queue_free()

func _cleanup_boss_objects() -> void:
	for collection in [active_bombs, active_slow_zones, active_lust_walls, active_treasures, boss_summons]:
		for node in collection.duplicate():
			if is_instance_valid(node):
				node.queue_free()
		collection.clear()
	if is_instance_valid(envy_clone):
		envy_clone.queue_free()
		envy_clone = null
	if player and player.has_method("_clear_dash_speed_modifier"):
		player.call("_clear_dash_speed_modifier", "sloth_boss_zone")
	_restore_sloth_zone_enemy_speeds()

func _restore_sloth_zone_enemy_speeds() -> void:
	for enemy in get_tree().get_nodes_in_group(Global.GROUP_ENEMY):
		if not is_instance_valid(enemy):
			continue
		if enemy.has_meta("sloth_boss_zone_base_speed"):
			enemy.set("speed", float(enemy.get_meta("sloth_boss_zone_base_speed")))
			enemy.remove_meta("sloth_boss_zone_base_speed")
		if enemy.has_meta("sloth_boss_zone_active"):
			enemy.remove_meta("sloth_boss_zone_active")

func _register_boss_summon(enemy: Node) -> void:
	if enemy == null:
		return
	enemy.set_meta("boss_summon", true)
	enemy.set_meta("skip_xp", true)
	if enemy.get("xp_drop") != null:
		enemy.set("xp_drop", 0)
	boss_summons.append(enemy)
	var tree = get_tree()
	var scene = tree.current_scene if tree != null else null
	if scene != null and scene.has_method("apply_contract_to_boss_summon"):
		scene.call("apply_contract_to_boss_summon", enemy)

func _setup_boss_edge_indicator() -> void:
	if boss_indicator_layer != null:
		return

	boss_indicator_layer = CanvasLayer.new()
	boss_indicator_layer.name = "BossEdgeIndicatorLayer"
	boss_indicator_layer.layer = BOSS_INDICATOR_LAYER
	add_child(boss_indicator_layer)

	boss_indicator_node = Node2D.new()
	boss_indicator_node.name = "BossEdgeIndicator"
	boss_indicator_node.visible = false
	boss_indicator_layer.add_child(boss_indicator_node)

	var arrow_points = PackedVector2Array([
		Vector2(16.0, 0.0),
		Vector2(-10.0, -9.0),
		Vector2(-5.0, 0.0),
		Vector2(-10.0, 9.0)
	])

	var shadow = Polygon2D.new()
	shadow.name = "Shadow"
	shadow.position = Vector2(1.5, 1.5)
	shadow.polygon = arrow_points
	shadow.color = Color(0.0, 0.0, 0.0, 0.58)
	boss_indicator_node.add_child(shadow)

	var arrow = Polygon2D.new()
	arrow.name = "Arrow"
	arrow.polygon = arrow_points
	arrow.color = _with_alpha(_get_boss_color(), 0.95)
	boss_indicator_node.add_child(arrow)

	var outline = Line2D.new()
	outline.name = "Outline"
	outline.width = 1.2
	outline.default_color = Color(0.0, 0.0, 0.0, 0.82)
	outline.points = PackedVector2Array([
		Vector2(16.0, 0.0),
		Vector2(-10.0, -9.0),
		Vector2(-5.0, 0.0),
		Vector2(-10.0, 9.0),
		Vector2(16.0, 0.0)
	])
	boss_indicator_node.add_child(outline)

func _update_boss_edge_indicator() -> void:
	if boss_indicator_node == null:
		return

	var viewport = get_viewport()
	if viewport == null or viewport.get_camera_2d() == null:
		_set_boss_edge_indicator_visible(false)
		return

	var viewport_size = viewport.get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		_set_boss_edge_indicator_visible(false)
		return

	var screen_position = viewport.get_canvas_transform() * global_position
	var visible_rect = Rect2(
		Vector2(BOSS_INDICATOR_PADDING, BOSS_INDICATOR_PADDING),
		viewport_size - Vector2(BOSS_INDICATOR_PADDING * 2.0, BOSS_INDICATOR_PADDING * 2.0)
	)
	if visible_rect.has_point(screen_position):
		_set_boss_edge_indicator_visible(false)
		return

	var screen_center = viewport_size * 0.5
	var direction = screen_position - screen_center
	if direction.length_squared() <= 0.01:
		_set_boss_edge_indicator_visible(false)
		return

	direction = direction.normalized()
	var half_extents = screen_center - Vector2(BOSS_INDICATOR_PADDING, BOSS_INDICATOR_PADDING)
	var edge_distance = 1000000.0
	if abs(direction.x) > 0.001:
		edge_distance = min(edge_distance, half_extents.x / abs(direction.x))
	if abs(direction.y) > 0.001:
		edge_distance = min(edge_distance, half_extents.y / abs(direction.y))

	boss_indicator_node.position = screen_center + direction * edge_distance
	boss_indicator_node.rotation = direction.angle()
	_set_boss_edge_indicator_visible(true)

func _set_boss_edge_indicator_visible(is_visible: bool) -> void:
	if boss_indicator_node != null:
		boss_indicator_node.visible = is_visible

func _finish_action(cooldown: float) -> void:
	current_sub_state = BossSubState.RECOVERY
	action_cooldown = cooldown * clampf(endless_action_cooldown_multiplier, 0.45, 1.0)
	is_performing_action = false
	if current_state == BossState.PRIDE:
		pride_movement_mode = PRIDE_MOVEMENT_DEFAULT
	current_sub_state = BossSubState.DECIDE

func _spawn_enemy_projectile(spawn_position: Vector2, projectile_direction: Vector2, projectile_damage: float, color: Color, projectile_speed: float = 500.0) -> Area2D:
	var projectile = PROJECTILE_SCENE.instantiate()
	projectile.direction = projectile_direction.normalized()
	projectile.damage = projectile_damage
	projectile.set_meta("damage_source", self)
	projectile.set_meta("vfx_color", _get_active_attack_color(color))
	if not _add_child_at_global(_get_vfx_parent(), projectile, spawn_position):
		return null
	projectile.speed = projectile_speed
	return projectile

func _create_damaging_area_after_delay(area_position: Vector2, size: Vector2, area_rotation: float, area_damage: float, color: Color, delay: float, duration: float, achievement_damage_type: String = "", outline_color: Color = Color.TRANSPARENT, outline_width: float = 0.0) -> void:
	await get_tree().create_timer(delay, false).timeout
	if is_dead or not is_inside_tree():
		return
	_create_damaging_area(area_position, size, area_rotation, area_damage, color, duration, achievement_damage_type, outline_color, outline_width)

func _create_damaging_area(area_position: Vector2, size: Vector2, area_rotation: float, area_damage: float, color: Color, duration: float, achievement_damage_type: String = "", outline_color: Color = Color.TRANSPARENT, outline_width: float = 0.0) -> void:
	var area = Area2D.new()
	area.name = "BossDamagingArea"
	area.collision_layer = 0
	area.collision_mask = Global.PLAYER_LAYER_MASK
	area.set_meta("damage", area_damage)
	area.set_meta("achievement_damage_type", achievement_damage_type)
	_add_rect_collision(area, size)
	_add_rect_visual(area, size, _get_active_attack_color(color), 0)
	if outline_width > 0.0 and outline_color.a > 0.0:
		_add_rect_outline(area, size, outline_color, outline_width, 1)

	area.body_entered.connect(Callable(self, "_on_damaging_area_body_entered").bind(area))
	if not _add_child_at_global(_get_ground_area_vfx_parent(), area, area_position, area_rotation):
		return
	if player and _is_point_inside_rotated_rect(player.global_position, area_position, size, area_rotation):
		player.take_damage(area_damage, area_position, 1.0, self, achievement_damage_type)
	var tree = get_tree()
	if tree == null:
		return
	var cleanup_timer = tree.create_timer(duration, false)
	cleanup_timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(area))

func _on_damaging_area_body_entered(body: Node, area) -> void:
	if body.is_in_group(Global.GROUP_PLAYER):
		body.take_damage(float(area.get_meta("damage", damage)), area.global_position, 1.0, self, str(area.get_meta("achievement_damage_type", "")))

func _setup_health_bar() -> void:
	if health_bar:
		return

	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(64, 6)
	health_bar.size = Vector2(64, 6)
	health_bar.position = Vector2(-32, _get_health_bar_y_offset())
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.z_index = 20
	health_bar.add_theme_stylebox_override("background", _make_stylebox(Color(0.08, 0.06, 0.06, 0.9)))
	health_bar.add_theme_stylebox_override("fill", _make_stylebox(Color(0.95, 0.03, 0.03, 0.96)))
	add_child(health_bar)
	_update_health_bar()

func _update_health_bar() -> void:
	if not health_bar:
		return
	health_bar.max_value = max(max_health, 1)
	health_bar.value = clamp(current_health, 0, max_health)

func _add_small_health_bar(parent: Node, width: float, bar_position: Vector2) -> void:
	var bar = ProgressBar.new()
	bar.name = "HealthBar"
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(width, 5.0)
	bar.size = Vector2(width, 5.0)
	bar.position = bar_position
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.z_index = 30
	bar.add_theme_stylebox_override("background", _make_stylebox(Color(0.07, 0.06, 0.07, 0.88)))
	bar.add_theme_stylebox_override("fill", _make_stylebox(Color(1.0, 1.0, 1.0, 0.92)))
	parent.add_child(bar)
	_update_embedded_health_bar(parent)

func _update_embedded_health_bar(parent: Node) -> void:
	var bar = parent.get_node_or_null("HealthBar")
	if bar == null:
		return
	var max_value = float(parent.get_meta("max_health", 1.0))
	var value = float(parent.get_meta("health", max_value))
	bar.max_value = max(max_value, 1.0)
	bar.value = clamp(value, 0.0, max_value)

func _make_stylebox(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(1)
	return style

func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)

func _get_pride_damage(multiplier: float) -> float:
	return max(float(roundi(float(damage) * multiplier / 5.0) * 5), 5.0)

func _get_active_attack_color(color: Color) -> Color:
	var multiplier = 1.0 - Global.ENEMY_ATTACK_ACTIVE_COLOR_DARKENING
	return Color(color.r * multiplier, color.g * multiplier, color.b * multiplier, color.a)

func _get_area_aura_vfx_color(color: Color) -> Color:
	var multiplier = 1.0 - Global.AREA_AURA_VFX_DARKENING
	return Color(color.r * multiplier, color.g * multiplier, color.b * multiplier, color.a)

func _get_boss_color() -> Color:
	match current_state:
		BossState.SLOTH:
			return SLOTH_COLOR
		BossState.GLUTTONY:
			return GLUTTONY_COLOR
		BossState.ENVY:
			return ENVY_COLOR
		BossState.WRATH:
			return WRATH_COLOR
		BossState.LUST:
			return LUST_COLOR
		BossState.GREED:
			return GREED_COLOR
		BossState.PRIDE:
			return PRIDE_LIGHT_COLOR
	return Color.WHITE

func _setup_footstep_sfx() -> void:
	if not _should_use_footstep_sfx():
		return

	footstep_sfx_player = get_node_or_null("FootstepSFX") as AudioStreamPlayer
	if footstep_sfx_player == null:
		footstep_sfx_player = AudioStreamPlayer.new()
		footstep_sfx_player.name = "FootstepSFX"
		add_child(footstep_sfx_player)

	footstep_sfx_player.stream = Global.make_looping_audio_stream(FOOTSTEP_SFX_STREAM)
	Global.register_audio_player(footstep_sfx_player, Global.GROUP_SFX, -15.0)

func _should_use_footstep_sfx() -> bool:
	if Global.is_web_build():
		return false
	return current_state != BossState.SLOTH and current_state != BossState.GLUTTONY

func _update_footstep_sfx() -> void:
	if footstep_sfx_player == null:
		return

	if is_dead or velocity.length() < 18.0:
		_stop_footstep_sfx()
		return
	if player != null and global_position.distance_to(player.global_position) > BOSS_FOOTSTEP_SFX_PLAY_DISTANCE:
		_stop_footstep_sfx()
		return

	if not footstep_sfx_player.playing:
		if not has_footstep_sfx_voice and not Global.try_acquire_limited_sfx_voice(BOSS_FOOTSTEP_SFX_VOICE_KEY, BOSS_FOOTSTEP_SFX_MAX_VOICES):
			return
		has_footstep_sfx_voice = true
		footstep_sfx_player.pitch_scale = randf_range(0.92, 1.04)
		footstep_sfx_player.play()

func _stop_footstep_sfx() -> void:
	if footstep_sfx_player != null and footstep_sfx_player.playing:
		footstep_sfx_player.stop()
	if has_footstep_sfx_voice:
		Global.release_limited_sfx_voice(BOSS_FOOTSTEP_SFX_VOICE_KEY)
		has_footstep_sfx_voice = false

func _add_circle_collision(parent: Node, radius: float) -> CollisionPolygon2D:
	var collision = CollisionPolygon2D.new()
	collision.polygon = _build_iso_ellipse_points(radius, false)
	parent.add_child(collision)
	return collision

func _add_rect_collision(parent: Node, size: Vector2) -> CollisionShape2D:
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	parent.add_child(collision)
	return collision

func _add_circle_visual(parent: Node, radius: float, color: Color, visual_z_index: int) -> Polygon2D:
	var visual = Polygon2D.new()
	radius = min(radius, MAX_BOSS_CIRCLE_VFX_RADIUS)
	visual.polygon = _build_iso_ellipse_points(radius, false)
	visual.color = _get_area_aura_vfx_color(color)
	visual.z_index = visual_z_index
	parent.add_child(visual)
	return visual

func _add_rect_visual(parent: Node, size: Vector2, color: Color, visual_z_index: int) -> Polygon2D:
	var visual = Polygon2D.new()
	visual.polygon = _build_rect_points(size)
	visual.color = _get_area_aura_vfx_color(color)
	visual.z_index = visual_z_index
	parent.add_child(visual)
	return visual

func _add_rect_outline(parent: Node, size: Vector2, color: Color, width: float, visual_z_index: int) -> Line2D:
	var outline = Line2D.new()
	var points = _build_rect_points(size)
	points.append(points[0])
	outline.points = points
	outline.width = width
	outline.default_color = _get_area_aura_vfx_color(color)
	outline.joint_mode = Line2D.LINE_JOINT_SHARP
	outline.z_index = visual_z_index
	parent.add_child(outline)
	return outline

func _add_ring_visual(parent: Node, radius: float, color: Color, width: float, visual_z_index: int) -> Line2D:
	var ring = Line2D.new()
	radius = min(radius, MAX_BOSS_CIRCLE_VFX_RADIUS)
	ring.width = width
	ring.default_color = _get_area_aura_vfx_color(color)
	ring.points = _build_iso_ellipse_points(radius, true)
	ring.z_index = visual_z_index
	parent.add_child(ring)
	return ring

func _get_health_bar_y_offset() -> float:
	if boss_health_bar_y_offset < -1.0:
		return boss_health_bar_y_offset

	var collision = get_node_or_null("CollisionShape2D")
	if collision and collision.shape:
		if collision.shape is CapsuleShape2D:
			return -(collision.shape.height * 0.5) - 12.0
		if collision.shape is CircleShape2D:
			return -collision.shape.radius - 12.0
		if collision.shape is RectangleShape2D:
			return -(collision.shape.size.y * 0.5) - 12.0
	return -36.0

func _play_boss_animation(animation_name: String) -> void:
	if aparencia:
		aparencia.play(animation_name)

func _get_vfx_parent() -> Node:
	var tree = get_tree()
	if tree == null:
		return null
	if is_instance_valid(tree.current_scene):
		return tree.current_scene
	if is_instance_valid(tree.root):
		return tree.root
	return null

func _add_child_at_global(parent: Node, child: Node2D, child_position: Vector2, child_rotation = null) -> bool:
	if parent == null or not is_instance_valid(parent):
		if is_instance_valid(child):
			child.queue_free()
		return false

	parent.add_child(child)
	child.global_position = child_position
	if child_rotation != null:
		child.global_rotation = float(child_rotation)
	return true

func _get_ground_area_vfx_parent() -> Node:
	var tree = get_tree()
	if tree == null:
		return null

	var scene = tree.current_scene
	if scene == null:
		return _get_vfx_parent()

	var layer = scene.get_node_or_null(Global.GROUND_AREA_VFX_LAYER_NAME)
	if layer == null:
		layer = Node2D.new()
		layer.name = Global.GROUND_AREA_VFX_LAYER_NAME
		scene.add_child(layer)

	layer.z_index = Global.GROUND_AREA_VFX_Z_INDEX
	layer.z_as_relative = false
	var player_node = scene.get_node_or_null("Player")
	if player_node != null and layer.get_parent() == scene and layer.get_index() > player_node.get_index():
		scene.move_child(layer, player_node.get_index())

	return layer

func _get_arena_center() -> Vector2:
	var tree = get_tree()
	var scene = tree.current_scene if tree != null else null
	if scene and scene.has_method("_get_current_arena_center"):
		return scene.call("_get_current_arena_center")
	return global_position

func _get_arena_rect() -> Rect2:
	var tree = get_tree()
	var scene = tree.current_scene if tree != null else null
	if scene and scene.has_method("_get_current_arena_bounds"):
		var arena_bounds = scene.call("_get_current_arena_bounds")
		if arena_bounds is Rect2:
			return arena_bounds

	if scene and scene.has_method("_get_current_arena_collision_polygon"):
		var collision_polygon = scene.call("_get_current_arena_collision_polygon")
		if collision_polygon:
			var points = []
			for point in collision_polygon.polygon:
				points.append(collision_polygon.to_global(point))
			var arena_rect = Rect2(points[0], Vector2.ZERO)
			for point in points:
				arena_rect = arena_rect.expand(point)
			return arena_rect
	return Rect2(_get_arena_center() - Vector2(420.0, 260.0), Vector2(840.0, 520.0))

func _is_inside_current_arena(point: Vector2, margin: float = 0.0) -> bool:
	var tree = get_tree()
	var scene = tree.current_scene if tree != null else null
	if scene and scene.has_method("_is_position_safe_in_current_arena"):
		return scene.call("_is_position_safe_in_current_arena", point, margin)
	return _get_arena_rect().grow(-margin).has_point(point)

func _is_point_inside_iso_aoe(point: Vector2, center: Vector2, radius: float) -> bool:
	var safe_radius = max(radius, 0.001)
	var y_radius = max(safe_radius * ISO_AOE_VISUAL_Y_SCALE, 0.001)
	var local_position = point - center
	var normalized_x = local_position.x / safe_radius
	var normalized_y = local_position.y / y_radius
	return normalized_x * normalized_x + normalized_y * normalized_y <= 1.0

func _clamp_to_current_arena(point: Vector2, margin: float = 0.0) -> Vector2:
	var tree = get_tree()
	var scene = tree.current_scene if tree != null else null
	if scene and scene.has_method("clamp_position_to_current_arena"):
		return scene.call("clamp_position_to_current_arena", point, margin)
	var rect = _get_arena_rect().grow(-margin)
	return Vector2(
		clamp(point.x, rect.position.x, rect.end.x),
		clamp(point.y, rect.position.y, rect.end.y)
	)

func _get_random_arena_position_near_player(min_distance: float, max_distance: float) -> Vector2:
	if player == null:
		return _get_arena_center()
	for i in range(30):
		var candidate = player.global_position + Vector2.RIGHT.rotated(randf_range(-PI, PI)) * randf_range(min_distance, max_distance)
		if _is_inside_current_arena(candidate, 28.0):
			return candidate
	return _get_random_arena_edge_position()

func _get_random_arena_position(margin: float = 0.0) -> Vector2:
	var tree = get_tree()
	var scene = tree.current_scene if tree != null else null
	if scene and scene.has_method("get_random_arena_position"):
		var arena_position = scene.call("get_random_arena_position", margin)
		if arena_position is Vector2:
			return arena_position

	return _get_arena_center()

func _get_random_arena_position_anywhere(margin: float = 0.0) -> Vector2:
	var tree = get_tree()
	var scene = tree.current_scene if tree != null else null
	if scene and scene.has_method("get_random_arena_position_anywhere"):
		var arena_position = scene.call("get_random_arena_position_anywhere", margin)
		if arena_position is Vector2:
			return arena_position

	return _get_random_arena_position(margin)

func _get_random_arena_edge_position() -> Vector2:
	var tree = get_tree()
	var scene = tree.current_scene if tree != null else null
	if scene and scene.has_method("get_random_arena_edge_position"):
		var arena_position = scene.call("get_random_arena_edge_position", 32.0)
		if arena_position is Vector2:
			return arena_position

	var rect = _get_arena_rect()
	for i in range(30):
		var side = randi() % 4
		var candidate = Vector2.ZERO
		match side:
			0:
				candidate = Vector2(randf_range(rect.position.x, rect.end.x), rect.position.y + 32.0)
			1:
				candidate = Vector2(randf_range(rect.position.x, rect.end.x), rect.end.y - 32.0)
			2:
				candidate = Vector2(rect.position.x + 32.0, randf_range(rect.position.y, rect.end.y))
			3:
				candidate = Vector2(rect.end.x - 32.0, randf_range(rect.position.y, rect.end.y))
		if _is_inside_current_arena(candidate, 30.0):
			return candidate
	return _get_arena_center()

func _spawn_action_charge_vfx(center: Vector2, radius: float, color: Color, duration: float, particle_amount: int = 24) -> void:
	radius = min(radius, MAX_BOSS_CIRCLE_VFX_RADIUS)
	_spawn_circle_telegraph(center, radius, _with_alpha(color, 0.18), duration)
	_spawn_burst_particles(center, _with_alpha(color, 0.62), particle_amount, min(duration, 0.45), radius * 1.35)

func _spawn_line_telegraph(from_position: Vector2, to_position: Vector2, color: Color, duration: float, width: float = 3.0) -> Node2D:
	var telegraph = Node2D.new()
	var line = Line2D.new()
	line.width = width
	line.default_color = _with_alpha(color, 0.45)
	line.points = PackedVector2Array([Vector2.ZERO, to_position - from_position])
	telegraph.add_child(line)
	if not _add_child_at_global(_get_ground_area_vfx_parent(), telegraph, from_position):
		return telegraph

	var tree = get_tree()
	if tree == null:
		return telegraph
	var timer = tree.create_timer(duration, false)
	timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(telegraph))
	return telegraph

func _spawn_wrath_line_telegraph(from_position: Vector2, to_position: Vector2, duration: float) -> void:
	_spawn_line_telegraph(from_position, to_position, WRATH_OUTLINE_COLOR, duration, 6.0)
	_spawn_line_telegraph(from_position, to_position, WRATH_TELEGRAPH_COLOR, duration, 2.6)

func _get_top_screen_warning_position(fall_start_position: Vector2) -> Vector2:
	var viewport = get_viewport()
	var camera = viewport.get_camera_2d() if viewport != null else null
	if camera == null:
		var arena_rect = _get_arena_rect()
		return Vector2(
			clamp(fall_start_position.x, arena_rect.position.x + 28.0, arena_rect.end.x - 28.0),
			arena_rect.position.y + 28.0
		)

	var visible_size = viewport.get_visible_rect().size / camera.zoom
	var visible_rect = Rect2(camera.global_position - visible_size * 0.5, visible_size)
	var margin = GREED_COIN_RAIN_WARNING_RADIUS + 10.0
	return Vector2(
		clamp(fall_start_position.x, visible_rect.position.x + margin, visible_rect.end.x - margin),
		visible_rect.position.y + margin
	)

func _spawn_falling_warning(landing_position: Vector2, color: Color, duration: float, radius: float = 11.0, fall_start_position = null) -> Node2D:
	var warning = Node2D.new()
	var line = Line2D.new()
	var warning_position = _get_top_screen_warning_position(fall_start_position) if fall_start_position is Vector2 else landing_position
	line.width = 3.5
	line.default_color = _with_alpha(color, 0.72)
	line.points = PackedVector2Array([Vector2.ZERO, landing_position - warning_position])
	warning.add_child(line)
	_add_circle_visual(warning, radius, _with_alpha(color, 0.18), 0)
	_add_ring_visual(warning, radius, _with_alpha(color, 0.9), 2.6, 1)
	if not _add_child_at_global(_get_ground_area_vfx_parent(), warning, warning_position):
		return warning

	var tree = get_tree()
	if tree == null:
		return warning
	var timer = tree.create_timer(duration, false)
	timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(warning))
	return warning

func _add_loop_particles(parent: Node, particle_name: String, color: Color, amount: int, lifetime: float, min_velocity: float, max_velocity: float, visual_z_index: int) -> CPUParticles2D:
	var particles = CPUParticles2D.new()
	particles.name = particle_name
	particles.amount = Global.get_web_particle_amount(amount)
	particles.lifetime = lifetime
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = min_velocity
	particles.initial_velocity_max = max_velocity
	particles.color = _get_area_aura_vfx_color(color)
	particles.z_index = visual_z_index
	parent.add_child(particles)
	particles.emitting = true
	return particles

func _spawn_marker_on_node(target: Node2D, radius: float, color: Color, duration: float) -> void:
	if not is_instance_valid(target):
		return
	var marker = Node2D.new()
	marker.z_index = Global.GROUND_AREA_VFX_Z_INDEX
	marker.z_as_relative = false
	marker.show_behind_parent = true
	target.add_child(marker)
	target.move_child(marker, 0)
	_add_circle_visual(marker, radius, _with_alpha(color, 0.1), 0)
	_add_ring_visual(marker, radius, _with_alpha(color, 0.62), 2.0, 0)
	_add_loop_particles(marker, "MarkerParticles", _with_alpha(color, 0.42), 28, 0.55, 12.0, 48.0, 0)
	var tween = create_tween().bind_node(marker)
	tween.tween_property(marker, "modulate:a", 0.55, duration * 0.5)
	tween.tween_property(marker, "modulate:a", 0.0, duration * 0.5)
	tween.tween_callback(Callable(self, "_queue_free_if_valid").bind(marker))

func _spawn_circle_telegraph(center: Vector2, radius: float, color: Color, duration: float) -> Node2D:
	radius = min(radius, MAX_BOSS_CIRCLE_VFX_RADIUS)
	var vfx_color = _get_area_aura_vfx_color(color)
	var telegraph = Node2D.new()
	var fill = Polygon2D.new()
	fill.polygon = _build_iso_ellipse_points(radius, false)
	fill.color = vfx_color
	telegraph.add_child(fill)
	var ring = Line2D.new()
	ring.width = 2.0
	ring.default_color = Color(vfx_color.r, vfx_color.g, vfx_color.b, min(vfx_color.a + 0.24, 1.0))
	ring.points = _build_iso_ellipse_points(radius, true)
	telegraph.add_child(ring)
	if not _add_child_at_global(_get_ground_area_vfx_parent(), telegraph, center):
		return telegraph

	var tree = get_tree()
	if tree == null:
		return telegraph
	var timer = tree.create_timer(duration, false)
	timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(telegraph))
	return telegraph

func _spawn_rect_telegraph(center: Vector2, size: Vector2, rect_rotation: float, color: Color, duration: float, outline_color: Color = Color.TRANSPARENT, outline_width: float = 0.0) -> Node2D:
	var telegraph = Node2D.new()
	var fill = Polygon2D.new()
	fill.polygon = _build_rect_points(size)
	fill.color = _get_area_aura_vfx_color(color)
	telegraph.add_child(fill)
	if outline_width > 0.0 and outline_color.a > 0.0:
		_add_rect_outline(telegraph, size, outline_color, outline_width, 1)
	if not _add_child_at_global(_get_ground_area_vfx_parent(), telegraph, center, rect_rotation):
		return telegraph

	var tree = get_tree()
	if tree == null:
		return telegraph
	var timer = tree.create_timer(duration, false)
	timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(telegraph))
	return telegraph

func _spawn_ring_vfx(center: Vector2, radius: float, color: Color, duration: float) -> Node2D:
	radius = min(radius, MAX_BOSS_CIRCLE_VFX_RADIUS)
	var vfx_color = _get_area_aura_vfx_color(color)
	var node = Node2D.new()
	var ring = Line2D.new()
	ring.width = 3.0
	ring.default_color = vfx_color
	ring.points = _build_iso_ellipse_points(radius, true)
	node.add_child(ring)
	if not _add_child_at_global(_get_ground_area_vfx_parent(), node, center):
		return node

	var tween = create_tween().bind_node(node)
	tween.tween_property(node, "modulate:a", 0.0, duration)
	tween.tween_callback(Callable(self, "_queue_free_if_valid").bind(node))
	return node

func _spawn_attached_aura(radius: float, color: Color, duration: float) -> void:
	radius = min(radius, MAX_BOSS_CIRCLE_VFX_RADIUS)
	var vfx_color = _get_area_aura_vfx_color(color)
	var aura = Node2D.new()
	aura.z_index = Global.GROUND_AREA_VFX_Z_INDEX
	aura.z_as_relative = false
	aura.show_behind_parent = true
	add_child(aura)
	move_child(aura, 0)
	var fill = Polygon2D.new()
	fill.polygon = _build_iso_ellipse_points(radius, false)
	var fill_color = vfx_color
	fill_color.a *= 0.16
	fill.color = fill_color
	aura.add_child(fill)
	var ring = Line2D.new()
	ring.width = 2.0
	ring.default_color = vfx_color
	ring.points = _build_iso_ellipse_points(radius, true)
	aura.add_child(ring)
	var tree = get_tree()
	if tree == null:
		return
	var timer = tree.create_timer(duration, false)
	timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(aura))

func _spawn_burst_particles(spawn_position: Vector2, color: Color, amount: int = 22, lifetime: float = 0.28, velocity_amount: float = 120.0) -> void:
	var particles = CPUParticles2D.new()
	particles.amount = Global.get_web_particle_amount(amount)
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.lifetime = lifetime
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = velocity_amount * 0.25
	particles.initial_velocity_max = velocity_amount
	particles.color = color
	particles.z_index = 35
	if not _add_child_at_global(_get_vfx_parent(), particles, spawn_position):
		return

	particles.emitting = true
	var tree = get_tree()
	if tree == null:
		return
	var timer = tree.create_timer(lifetime + 0.2, false)
	timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(particles))

func _spawn_heal_particles(spawn_position: Vector2) -> void:
	_spawn_burst_particles(spawn_position, _with_alpha(GLUTTONY_COLOR, 0.9), 24, 0.35, 130.0)
	_spawn_burst_particles(global_position, _with_alpha(GLUTTONY_COLOR, 0.8), 12, 0.22, 80.0)

func _build_circle_points(radius: float, closed: bool) -> PackedVector2Array:
	var points = PackedVector2Array()
	var segment_count = 48
	var point_count = segment_count + (1 if closed else 0)
	for i in range(point_count):
		var angle = TAU * float(i % segment_count) / float(segment_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _build_iso_ellipse_points(radius: float, closed: bool) -> PackedVector2Array:
	var points = PackedVector2Array()
	var segment_count = 48
	var point_count = segment_count + (1 if closed else 0)
	for i in range(point_count):
		var angle = TAU * float(i % segment_count) / float(segment_count)
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius * ISO_AOE_VISUAL_Y_SCALE))
	return points

func _build_rect_points(size: Vector2) -> PackedVector2Array:
	var half_size = size * 0.5
	return PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])

func _is_point_inside_rotated_rect(point: Vector2, rect_center: Vector2, size: Vector2, rect_rotation: float) -> bool:
	var local_point = (point - rect_center).rotated(-rect_rotation)
	return abs(local_point.x) <= size.x * 0.5 and abs(local_point.y) <= size.y * 0.5

func _trim_node_array(nodes: Array, max_count: int) -> void:
	while nodes.size() > max_count:
		var node = nodes.pop_front()
		if is_instance_valid(node):
			node.queue_free()

func _queue_free_if_valid(node) -> void:
	if is_instance_valid(node):
		node.queue_free()
