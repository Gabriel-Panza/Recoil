extends CharacterBody2D
class_name Boss

enum BossState { SLOTH, GLUTTONY, ENVY, WRATH, LUST, GREED, PRIDE }
enum BossSubState { INTRO, DECIDE, TELEGRAPH, ATTACK, RECOVERY, PHASE_CHANGE, SPECIAL, DEAD }

signal boss_defeated

@export var max_health: int = 500
@export var speed: float = 85.0
@export var damage: int = 50
@export var xp_drop: int = 1

const ENEMY_COLLISION_MASK: int = 4
const ENEMY_BODY_COLLISION_SCALE: float = 0.7
const ENRAGE_HEALTH_RATIO: float = 0.5
const ENRAGE_STAT_MULTIPLIER: float = 1.25
const PLAYER_LAYER_MASK: int = 2
const ENEMY_LAYER_MASK: int = 4
const WALL_LAYER_MASK: int = 1
const PROJECTILE_SCENE = preload("res://Cenas/Inimigos/enemyProjectile.tscn")
const MELEE_ENEMY_SCENE = preload("res://Cenas/Inimigos/melee_enemy.tscn")
const RANGED_ENEMY_SCENE = preload("res://Cenas/Inimigos/ranged_enemy.tscn")

const WRATH_BOMB_RADIUS: float = 18.0
const WRATH_BOMB_EXPLOSION_RADIUS: float = 110.0
const WRATH_BOMB_PUSH_SPEED: float = 560.0
const WRATH_BOMB_DAMAGE: float = 38.0
const LUST_WALL_THICKNESS: float = 24.0
const LUST_WALL_LENGTH: float = 260.0
const LUST_BREAKABLE_WALL_HP: float = 110.0
const SLOTH_SLOW_ZONE_RADIUS: float = 95.0
const GLUTTONY_STRESS_DURATION_PHASE_1: float = 7.5
const GLUTTONY_STRESS_DURATION_PHASE_2: float = 10.0
const ENVY_CLONE_MAX_HEALTH: float = 180.0
const GREED_TREASURE_RADIUS: float = 16.0
const MAX_BOSS_CIRCLE_VFX_RADIUS: float = 180.0
const DEFAULT_BOSS_VISUAL_SCALE: Vector2 = Vector2(1.5, 1.5)

const SLOTH_COLOR: Color = Color(0.25, 0.95, 1.0, 1.0)
const GLUTTONY_COLOR: Color = Color(0.96, 0.92, 0.18, 1.0)
const ENVY_COLOR: Color = Color(0.25, 0.95, 1.0, 1.0)
const WRATH_COLOR: Color = Color(1.0, 0.25, 0.05, 1.0)
const LUST_COLOR: Color = Color(1.0, 0.16, 0.36, 1.0)
const GREED_COLOR: Color = Color(1.0, 0.78, 0.08, 1.0)
const PRIDE_LIGHT_COLOR: Color = Color(1.0, 0.96, 0.62, 1.0)
const PRIDE_FIRE_COLOR: Color = Color(1.0, 0.46, 0.14, 1.0)
const BOSS_INDICATOR_LAYER: int = 75
const BOSS_INDICATOR_PADDING: float = 34.0

const BOSS_CONFIG = {
	1: { "max_health": 500, "speed": 0.0, "damage": 35, "state": BossState.SLOTH, "animation": "pecado1" },
	2: { "max_health": 600, "speed": 75.0, "damage": 45, "state": BossState.GLUTTONY, "animation": "pecado2", "visual_scale": Vector2(2.15, 2.15) },
	3: { "max_health": 700, "speed": 82.5, "damage": 40, "state": BossState.ENVY, "animation": "pecado3" },
	4: { "max_health": 800, "speed": 90.0, "damage": 50, "state": BossState.WRATH, "animation": "pecado4" },
	5: { "max_health": 1000, "speed": 75.0, "damage": 40, "state": BossState.LUST, "animation": "pecado5" },
	6: { "max_health": 1250, "speed": 71.25, "damage": 45, "state": BossState.GREED, "animation": "pecado6" },
	7: { "max_health": 1500, "speed": 67.5, "damage": 50, "state": BossState.PRIDE, "animation": "pecado7" },
}

var current_health: int
var player: Node2D
var aparencia
var health_bar: ProgressBar
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
var boss_summons: Array = []
var gluttony_foods: Array = []
var gluttony_stress_timers: Array = []
var active_lust_walls: Array = []
var lust_invulnerability_cooldown: float = 4.0
var lust_invulnerability_active: bool = false
var envy_clone: Area2D
var envy_clone_fire_cooldown: float = 0.8
var envy_boss_buff_remaining: float = 0.0
var active_treasures: Array = []
var greed_money_stacks: int = 0
var greed_shield_remaining: float = 0.0
var greed_tax_active: bool = false
var greed_tax_timer: float = 0.0
var greed_tax_meter: float = 0.0
var greed_previous_player_position: Vector2 = Vector2.ZERO
var greed_previous_can_shoot: bool = true
var boss_indicator_layer: CanvasLayer
var boss_indicator_node: Node2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	add_to_group("Boss")
	add_to_group("Enemy")
	_setup_enemy_body_collision()
	aparencia = $AparenciaAnimada
	aparencia.scale *= 2.5
	_configure_boss_for_current_sin()
	_setup_boss_edge_indicator()
	current_health = max_health
	base_speed = speed
	base_damage = damage
	if player:
		greed_previous_player_position = player.global_position
		greed_previous_can_shoot = player.can_shoot
	call_deferred("_setup_health_bar")
	call_deferred("_begin_intro")

func _configure_boss_for_current_sin() -> void:
	var config = BOSS_CONFIG.get(Global.pecado, BOSS_CONFIG[7])
	max_health = int(config["max_health"])
	speed = float(config["speed"])
	damage = int(config["damage"])
	current_state = config["state"]
	if aparencia:
		aparencia.scale = config.get("visual_scale", DEFAULT_BOSS_VISUAL_SCALE)
	_play_boss_animation(str(config["animation"]))

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
	_move_toward_player(delta, 0.82)
	if not _can_start_action():
		return

	if randf() < 0.65:
		_start_gluttony_food_wave(2 if phase == 1 else 4)
	else:
		_start_gluttony_body_slam()

func handle_envy(delta: float) -> void:
	if phase == 1:
		_keep_distance_from_player(delta, 180.0)
	else:
		_move_toward_player(delta, 1.0 + (0.22 if envy_boss_buff_remaining > 0.0 else 0.0))
		if _can_start_action() and randf() < 0.45:
			_start_envy_boss_shot()

	if not is_instance_valid(envy_clone) and not is_performing_action:
		_start_envy_clone()

func handle_wrath(delta: float) -> void:
	_move_toward_player(delta, 1.05)
	if not _can_start_action():
		return

	if phase == 1:
		_start_wrath_bomb_volley(3, 4.0)
	else:
		_start_wrath_bomb_volley(5, 2.75)

func handle_lust(delta: float) -> void:
	_move_toward_player(delta, 0.7)
	if not lust_invulnerability_active:
		lust_invulnerability_cooldown = max(lust_invulnerability_cooldown - delta, 0.0)
		if lust_invulnerability_cooldown <= 0.0:
			_start_lust_invulnerability()

	if not _can_start_action():
		return

	_start_lust_wall_pattern()

func handle_greed(delta: float) -> void:
	_move_toward_player(delta, 0.85)
	if not _can_start_action():
		return

	var roll = randf()
	if roll < 0.45:
		_start_greed_treasure_drop(3 if phase == 1 else 5)
	elif roll < 0.75:
		_start_greed_coin_rain()
	else:
		_start_greed_tax_mark()

func handle_pride(delta: float) -> void:
	if is_invulnerable:
		velocity = Vector2.ZERO
		move_and_slide()
	else:
		_keep_distance_from_player(delta, 220.0)

	if not _can_start_action():
		return

	if phase == 1:
		var roll = randf()
		if roll < 0.45:
			_start_pride_fire_orbs(false)
		elif roll < 0.75:
			_start_pride_light_cross(false)
		else:
			_start_pride_judgement()
	else:
		var roll = randf()
		if roll < 0.40:
			_start_pride_fire_orbs(true)
		elif roll < 0.75:
			_start_pride_light_cross(true)
		else:
			_start_pride_judgement()

func _move_toward_player(_delta: float, speed_multiplier: float = 1.0) -> void:
	if player == null:
		return

	var direction = global_position.direction_to(player.global_position)
	velocity = direction * _get_current_speed(speed_multiplier)
	move_and_slide()

func _keep_distance_from_player(_delta: float, desired_distance: float) -> void:
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

	velocity = direction.normalized() * _get_current_speed(0.72)
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
		multiplier *= 1.0 + float(gluttony_stress_timers.size()) * (0.13 if phase == 1 else 0.2)
	if current_state == BossState.GREED:
		multiplier *= 1.0 + float(greed_money_stacks) * 0.04
	if envy_boss_buff_remaining > 0.0:
		multiplier *= 1.25
	damage = int(round(float(base_damage) * multiplier))

func _setup_enemy_body_collision() -> void:
	collision_mask = collision_mask | ENEMY_COLLISION_MASK
	_shrink_body_collision_shape()

func _shrink_body_collision_shape() -> void:
	var collision = get_node_or_null("CollisionShape2D")
	if collision == null or collision.shape == null:
		return

	var shape = collision.shape.duplicate()
	if shape is CapsuleShape2D:
		shape.radius = max(shape.radius * ENEMY_BODY_COLLISION_SCALE, 4.0)
		shape.height = max(shape.height * ENEMY_BODY_COLLISION_SCALE, shape.radius * 2.0)
	elif shape is CircleShape2D:
		shape.radius = max(shape.radius * ENEMY_BODY_COLLISION_SCALE, 4.0)
	elif shape is RectangleShape2D:
		shape.size *= ENEMY_BODY_COLLISION_SCALE
	collision.shape = shape

func _start_sloth_summon(amount: int) -> void:
	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	_spawn_action_charge_vfx(global_position, 90.0, SLOTH_COLOR, 0.5, 30)
	await get_tree().create_timer(0.5, false).timeout

	current_sub_state = BossSubState.ATTACK
	for i in range(amount):
		var scene = MELEE_ENEMY_SCENE if i % 2 == 0 else RANGED_ENEMY_SCENE
		var enemy = scene.instantiate()
		_get_vfx_parent().add_child(enemy)
		enemy.global_position = _get_random_arena_position_near_player(160.0, 300.0)
		_register_boss_summon(enemy)
		await get_tree().create_timer(2.0, false).timeout

	_finish_action(1.7 if phase == 1 else 1.2)

func _start_sloth_slow_zones(amount: int) -> void:
	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	for i in range(amount):
		var zone_position = _get_random_arena_position_near_player(80.0, 280.0)
		_spawn_circle_telegraph(zone_position, SLOTH_SLOW_ZONE_RADIUS, _with_alpha(SLOTH_COLOR, 0.24), 0.55)
		await get_tree().create_timer(2.5, false).timeout
		_create_sloth_slow_zone(zone_position)

	_trim_node_array(active_slow_zones, 4 if phase == 1 else 7)
	_finish_action(2.0 if phase == 1 else 1.5)

func _create_sloth_slow_zone(zone_position: Vector2) -> void:
	var zone = Area2D.new()
	zone.name = "SlothSlowZone"
	zone.global_position = zone_position
	zone.collision_layer = 0
	zone.collision_mask = PLAYER_LAYER_MASK
	zone.set_meta("radius", SLOTH_SLOW_ZONE_RADIUS)
	zone.set_meta("lifetime", 15.0)

	_add_circle_collision(zone, SLOTH_SLOW_ZONE_RADIUS)
	_add_circle_visual(zone, SLOTH_SLOW_ZONE_RADIUS, _with_alpha(SLOTH_COLOR, 0.12), 5)
	_add_ring_visual(zone, SLOTH_SLOW_ZONE_RADIUS, _with_alpha(SLOTH_COLOR, 0.42), 2.0, 6)
	_add_loop_particles(zone, "SlothZoneParticles", _with_alpha(SLOTH_COLOR, 0.28), 42, 1.0, 18.0, 72.0, 7)

	_get_vfx_parent().add_child(zone)
	active_slow_zones.append(zone)

func _update_sloth_slow_zones(delta: float) -> void:
	if player == null:
		return

	var is_inside_any_zone = false
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
		if player.global_position.distance_to(zone.global_position) <= float(zone.get_meta("radius", SLOTH_SLOW_ZONE_RADIUS)):
			is_inside_any_zone = true

	if is_inside_any_zone:
		if player.has_method("_set_dash_speed_modifier"):
			player.call("_set_dash_speed_modifier", "sloth_boss_zone", 0.62)
		player.velocity *= 0.95
	elif player.has_method("_clear_dash_speed_modifier"):
		player.call("_clear_dash_speed_modifier", "sloth_boss_zone")

func _start_gluttony_food_wave(amount: int) -> void:
	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	_spawn_action_charge_vfx(global_position, 120.0, GLUTTONY_COLOR, 0.5, 34)
	await get_tree().create_timer(0.5, false).timeout

	current_sub_state = BossSubState.ATTACK
	for i in range(amount):
		_spawn_gluttony_food()
		await get_tree().create_timer(2.0, false).timeout
	_finish_action(2.0 if phase == 1 else 1.25)

func _spawn_gluttony_food() -> void:
	var food = MELEE_ENEMY_SCENE.instantiate()
	_get_vfx_parent().add_child(food)
	food.global_position = _get_random_arena_edge_position()
	food.player = self
	food.speed = 135.0 if phase == 1 else 165.0
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
			var heal_amount = max_health * (0.09 if phase == 1 else 0.055)
			current_health = int(min(current_health + heal_amount, max_health))
			_update_health_bar()
			_spawn_heal_particles(food.global_position)
			food.queue_free()

func _on_gluttony_food_exited(food: Node) -> void:
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
	_spawn_circle_telegraph(player.global_position, 90.0, _with_alpha(GLUTTONY_COLOR, 0.24), 0.75)
	await get_tree().create_timer(0.75, false).timeout

	current_sub_state = BossSubState.ATTACK
	var slam_position = player.global_position
	global_position = _clamp_to_current_arena(slam_position, 32.0)
	_spawn_ring_vfx(global_position, 115.0, _with_alpha(GLUTTONY_COLOR, 0.44), 0.32)
	_spawn_burst_particles(global_position, _with_alpha(GLUTTONY_COLOR, 0.88), 34, 0.3, 160.0)
	if player.global_position.distance_to(global_position) <= 115.0:
		player.take_damage(float(damage) * 1.25, global_position)
	_finish_action(1.75 if phase == 1 else 1.25)

func _start_envy_clone() -> void:
	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	_spawn_action_charge_vfx(global_position, 70.0, ENVY_COLOR, 0.5, 28)
	await get_tree().create_timer(0.5, false).timeout
	_create_envy_clone()
	_finish_action(1.25)

func _create_envy_clone() -> void:
	if is_instance_valid(envy_clone):
		envy_clone.queue_free()

	envy_clone = Area2D.new()
	envy_clone.name = "EnvyMirrorClone"
	envy_clone.global_position = _clamp_to_current_arena(global_position * 2.0 - player.global_position, 26.0)
	envy_clone.collision_layer = ENEMY_LAYER_MASK
	envy_clone.collision_mask = 0
	envy_clone.set_meta("projectile_special_owner", self)
	envy_clone.set_meta("special_type", "envy_clone")
	envy_clone.set_meta("health", ENVY_CLONE_MAX_HEALTH)
	envy_clone.set_meta("max_health", ENVY_CLONE_MAX_HEALTH)

	_add_circle_collision(envy_clone, 22.0)
	_add_circle_visual(envy_clone, 22.0, _with_alpha(ENVY_COLOR, 0.32), 12)
	_add_ring_visual(envy_clone, 24.0, _with_alpha(ENVY_COLOR, 0.78), 2.0, 13)
	_add_loop_particles(envy_clone, "EnvyCloneParticles", _with_alpha(ENVY_COLOR, 0.42), 30, 0.65, 12.0, 62.0, 14)
	_add_small_health_bar(envy_clone, 42.0, Vector2(-21.0, -34.0))

	_get_vfx_parent().add_child(envy_clone)

func _update_envy_clone(delta: float) -> void:
	if not is_instance_valid(envy_clone) or player == null:
		return

	var mirror_target = global_position * 2.0 - player.global_position
	envy_clone.global_position = envy_clone.global_position.lerp(_clamp_to_current_arena(mirror_target, 28.0), 0.07)
	envy_clone_fire_cooldown = max(envy_clone_fire_cooldown - delta, 0.0)
	if envy_clone_fire_cooldown <= 0.0:
		envy_clone_fire_cooldown = 1.0 if phase == 1 else 0.75
		var direction = envy_clone.global_position.direction_to(player.global_position)
		if randf() < 0.65:
			direction = Vector2(direction.x, -direction.y).normalized()
		_spawn_line_telegraph(envy_clone.global_position, envy_clone.global_position + direction * 150.0, ENVY_COLOR, 0.12, 1.6)
		_spawn_enemy_projectile(envy_clone.global_position, direction, float(damage) * 0.7, _with_alpha(ENVY_COLOR, 0.9), 440.0)

func _start_envy_boss_shot() -> void:
	is_performing_action = true
	current_sub_state = BossSubState.ATTACK
	for i in range(3):
		var direction = global_position.direction_to(player.global_position).rotated(deg_to_rad((i - 1) * 14.0))
		_spawn_line_telegraph(global_position, global_position + direction * 180.0, ENVY_COLOR, 0.25, 2.0)
	await get_tree().create_timer(0.25, false).timeout
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
	_spawn_action_charge_vfx(global_position, 80.0, WRATH_COLOR, 0.75, 34)
	await get_tree().create_timer(0.75, false).timeout

	current_sub_state = BossSubState.ATTACK
	for i in range(amount):
		var target = player.global_position + Vector2(randf_range(-90.0, 90.0), randf_range(-70.0, 70.0))
		var bomb_position = global_position + Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0))
		_spawn_line_telegraph(bomb_position, target, WRATH_COLOR, 0.18, 2.0)
		_create_wrath_bomb(bomb_position, target, fuse_time)
		await get_tree().create_timer(1.75 if phase == 1 else 1.35, false).timeout

	_finish_action(1.25 if phase == 1 else 0.85)

func _create_wrath_bomb(from_position: Vector2, target_position: Vector2, fuse_time: float) -> void:
	var bomb = Area2D.new()
	bomb.name = "WrathBomb"
	bomb.global_position = from_position
	bomb.collision_layer = ENEMY_LAYER_MASK
	bomb.collision_mask = WALL_LAYER_MASK | PLAYER_LAYER_MASK
	bomb.set_meta("projectile_special_owner", self)
	bomb.set_meta("special_type", "wrath_bomb")
	bomb.set_meta("velocity", from_position.direction_to(target_position) * 165.0)
	bomb.set_meta("fuse", fuse_time)
	bomb.set_meta("pushed", false)

	_add_circle_collision(bomb, WRATH_BOMB_RADIUS)
	_add_circle_visual(bomb, WRATH_BOMB_RADIUS, _with_alpha(WRATH_COLOR, 0.78), 12)
	_add_ring_visual(bomb, WRATH_BOMB_RADIUS + 3.0, _with_alpha(WRATH_COLOR, 0.92), 2.0, 13)
	_add_loop_particles(bomb, "WrathBombFuse", _with_alpha(WRATH_COLOR, 0.65), 18, 0.38, 12.0, 56.0, 14)

	bomb.body_entered.connect(Callable(self, "_on_wrath_bomb_body_entered").bind(bomb))
	_get_vfx_parent().add_child(bomb)
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

		if bool(bomb.get_meta("pushed", false)) and bomb.global_position.distance_to(global_position) <= 38.0:
			_explode_wrath_bomb(bomb, true)
			continue

		if not _is_inside_current_arena(bomb.global_position, WRATH_BOMB_RADIUS):
			_explode_wrath_bomb(bomb, false)
			continue

		if fuse <= 0.0:
			_explode_wrath_bomb(bomb, false)

func _on_wrath_bomb_body_entered(body: Node, bomb: Area2D) -> void:
	if not is_instance_valid(bomb):
		return
	if body.is_in_group("Player"):
		_explode_wrath_bomb(bomb, false)
	elif body != self:
		_explode_wrath_bomb(bomb, false)

func _explode_wrath_bomb(bomb: Area2D, force_boss_damage: bool) -> void:
	if not is_instance_valid(bomb):
		return

	var explosion_position = bomb.global_position
	var was_pushed = bool(bomb.get_meta("pushed", false))
	active_bombs.erase(bomb)
	bomb.queue_free()
	_spawn_burst_particles(explosion_position, _with_alpha(WRATH_COLOR, 0.92), 46, 0.38, 220.0)
	_spawn_circle_telegraph(explosion_position, WRATH_BOMB_EXPLOSION_RADIUS, _with_alpha(WRATH_COLOR, 0.18), 0.16)
	_spawn_ring_vfx(explosion_position, WRATH_BOMB_EXPLOSION_RADIUS, _with_alpha(WRATH_COLOR, 0.44), 0.28)

	if player and player.global_position.distance_to(explosion_position) <= WRATH_BOMB_EXPLOSION_RADIUS:
		player.take_damage(WRATH_BOMB_DAMAGE, explosion_position)

	if (force_boss_damage or was_pushed) and global_position.distance_to(explosion_position) <= WRATH_BOMB_EXPLOSION_RADIUS:
		take_self_damage(max_health * (0.055 if phase == 1 else 0.04))

func _start_lust_wall_pattern() -> void:
	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	var wall_count = 3 if phase == 1 else 5
	var wall_lifetime = 5.5 if phase == 1 else 8.0
	for i in range(wall_count):
		var horizontal = (i % 2 == 0)
		var size = Vector2(LUST_WALL_LENGTH, LUST_WALL_THICKNESS) if horizontal else Vector2(LUST_WALL_THICKNESS, LUST_WALL_LENGTH)
		var position = _get_lust_wall_position(i, wall_count)
		var breakable = randf() < (0.52 if phase == 1 else 0.42)
		_spawn_rect_telegraph(position, size, 0.0, _with_alpha(LUST_COLOR, 0.24), 0.65)
		await get_tree().create_timer(0.25, false).timeout
		_create_lust_wall(position, size, breakable, wall_lifetime)

	await get_tree().create_timer(0.55, false).timeout
	_finish_action(2.0 if phase == 1 else 1.35)

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
	wall.global_position = wall_position
	wall.collision_layer = WALL_LAYER_MASK
	wall.collision_mask = 0
	wall.set_meta("breakable", breakable)
	wall.set_meta("lifetime", lifetime)
	wall.set_meta("size", size)

	_add_rect_collision(wall, size)
	_add_rect_visual(wall, size, _with_alpha(LUST_COLOR, 0.82) if breakable else Color(0.24, 0.03, 0.12, 0.92), 14)

	if breakable:
		var wall_health = LUST_BREAKABLE_WALL_HP * (1.0 if phase == 1 else 1.35)
		wall.set_meta("health", wall_health)
		wall.set_meta("max_health", wall_health)
		var hurtbox = Area2D.new()
		hurtbox.name = "BreakableHurtbox"
		hurtbox.collision_layer = ENEMY_LAYER_MASK
		hurtbox.collision_mask = 0
		hurtbox.set_meta("projectile_special_owner", self)
		hurtbox.set_meta("special_type", "lust_wall")
		hurtbox.set_meta("wall", wall)
		_add_rect_collision(hurtbox, size + Vector2(8.0, 8.0))
		wall.add_child(hurtbox)
		var bar_width = 72.0 if size.x < size.y else min(size.x, 90.0)
		_add_small_health_bar(wall, bar_width, Vector2(-bar_width * 0.5, -size.y * 0.5 - 14.0))
		_add_breakable_wall_particles(wall, size)

	_get_vfx_parent().add_child(wall)
	active_lust_walls.append(wall)
	_trim_node_array(active_lust_walls, 7 if phase == 1 else 10)

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
	await get_tree().create_timer(1.75 if phase == 1 else 1.35, false).timeout
	is_invulnerable = false
	lust_invulnerability_active = false
	lust_invulnerability_cooldown = 6.5 if phase == 1 else 4.25

func _start_greed_treasure_drop(amount: int) -> void:
	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	for i in range(amount):
		var pos = _get_random_arena_position_near_player(80.0, 300.0)
		_spawn_circle_telegraph(pos, GREED_TREASURE_RADIUS + 14.0, _with_alpha(GREED_COLOR, 0.24), 0.45)
		await get_tree().create_timer(1.1, false).timeout
		_create_greed_treasure(pos)
	_finish_action(1.35 if phase == 1 else 0.9)

func _create_greed_treasure(treasure_position: Vector2) -> void:
	var treasure = Area2D.new()
	treasure.name = "GreedTreasure"
	treasure.global_position = treasure_position
	treasure.collision_layer = 0
	treasure.collision_mask = PLAYER_LAYER_MASK
	treasure.set_meta("lifetime", 6.6)

	_add_circle_collision(treasure, GREED_TREASURE_RADIUS)
	_add_circle_visual(treasure, GREED_TREASURE_RADIUS, _with_alpha(GREED_COLOR, 0.88), 14)
	_add_ring_visual(treasure, GREED_TREASURE_RADIUS + 4.0, _with_alpha(GREED_COLOR, 0.72), 1.6, 15)
	_add_loop_particles(treasure, "GreedTreasureSparkles", _with_alpha(GREED_COLOR, 0.55), 20, 0.7, 8.0, 38.0, 16)
	treasure.body_entered.connect(Callable(self, "_on_greed_treasure_body_entered").bind(treasure))
	_get_vfx_parent().add_child(treasure)
	active_treasures.append(treasure)

func _update_greed_treasures(delta: float) -> void:
	for treasure in active_treasures.duplicate():
		if not is_instance_valid(treasure):
			active_treasures.erase(treasure)
			continue
		var lifetime = float(treasure.get_meta("lifetime", 0.0)) - delta
		treasure.set_meta("lifetime", lifetime)
		treasure.rotation += delta * 2.8
		if global_position.distance_to(treasure.global_position) <= GREED_TREASURE_RADIUS + 26.0:
			_collect_greed_treasure_for_boss(treasure)
		elif lifetime <= 0.0:
			active_treasures.erase(treasure)
			treasure.queue_free()

func _on_greed_treasure_body_entered(body: Node, treasure: Area2D) -> void:
	if body.is_in_group("Player"):
		_collect_greed_treasure_for_player(treasure)

func _collect_greed_treasure_for_player(treasure: Area2D) -> void:
	if not is_instance_valid(treasure):
		return
	active_treasures.erase(treasure)
	treasure.queue_free()
	_spawn_burst_particles(player.global_position, _with_alpha(GREED_COLOR, 0.9), 18, 0.28, 110.0)
	_apply_temporary_player_attack_boost(1.25, 5.0)

func _collect_greed_treasure_for_boss(treasure: Area2D) -> void:
	if not is_instance_valid(treasure):
		return
	active_treasures.erase(treasure)
	treasure.queue_free()
	greed_money_stacks += 1 if phase == 1 else 2
	greed_shield_remaining = max(greed_shield_remaining, 3.0)
	_spawn_marker_on_node(self, 54.0, GREED_COLOR, greed_shield_remaining)
	_spawn_burst_particles(global_position, _with_alpha(GREED_COLOR, 0.9), 24, 0.32, 130.0)

func _apply_temporary_player_attack_boost(multiplier: float, duration: float) -> void:
	if player == null:
		return
	player.temporary_attack_multiplier = max(player.temporary_attack_multiplier, multiplier)
	await get_tree().create_timer(duration, false).timeout
	if is_instance_valid(player) and player.temporary_attack_multiplier <= multiplier + 0.01:
		player.temporary_attack_multiplier = 1.0

func _update_greed_shield(delta: float) -> void:
	if greed_shield_remaining > 0.0:
		greed_shield_remaining = max(greed_shield_remaining - delta, 0.0)

func _start_greed_coin_rain() -> void:
	is_performing_action = true
	current_sub_state = BossSubState.TELEGRAPH
	var projectile_count = 8 + greed_money_stacks * 2
	projectile_count = min(projectile_count, 26)
	for i in range(projectile_count):
		var spawn_position = _get_arena_center() + Vector2(randf_range(-360.0, 360.0), -340.0 - randf_range(0.0, 120.0))
		_spawn_falling_warning(Vector2(spawn_position.x, _get_arena_rect().position.y + 8.0), GREED_COLOR, 0.25)
		await get_tree().create_timer(0.25, false).timeout
		_spawn_enemy_projectile(spawn_position, Vector2.DOWN, float(damage) * 0.72, _with_alpha(GREED_COLOR, 0.95), 520.0)
		await get_tree().create_timer(0.3 if phase == 2 else 0.5, false).timeout
	_finish_action(1.25 if phase == 1 else 0.75)

func _start_greed_tax_mark() -> void:
	is_performing_action = true
	greed_tax_active = true
	greed_tax_timer = 5.0 if phase == 1 else 3.5
	greed_tax_meter = 0.0
	greed_previous_player_position = player.global_position
	greed_previous_can_shoot = player.can_shoot
	_spawn_marker_on_node(player, 42.0, GREED_COLOR, greed_tax_timer)
	_spawn_action_charge_vfx(global_position, 70.0, GREED_COLOR, 0.8, 26)
	_finish_action(1.0)

func _update_greed_tax(delta: float) -> void:
	if not greed_tax_active or player == null:
		return

	greed_tax_timer -= delta
	greed_tax_meter += player.global_position.distance_to(greed_previous_player_position) * 0.01
	if greed_previous_can_shoot and not player.can_shoot:
		greed_tax_meter += 3.0
	greed_previous_can_shoot = player.can_shoot
	greed_previous_player_position = player.global_position
	if greed_tax_timer <= 0.0:
		greed_tax_active = false
		if greed_tax_meter > 12.0:
			player.take_damage((greed_tax_meter - 12.0) * 2.0 + 12.0, global_position)
			_spawn_burst_particles(player.global_position, _with_alpha(GREED_COLOR, 0.9), 28, 0.3, 150.0)

func _start_pride_fire_orbs(overlap: bool) -> void:
	is_performing_action = true
	current_sub_state = BossSubState.ATTACK
	var waves = 2 if not overlap else 3
	for wave in range(waves):
		var projectile_count = 10 if phase == 1 else 16
		_spawn_action_charge_vfx(global_position, 64.0, PRIDE_FIRE_COLOR, 0.16, 14)
		_spawn_radial_projectiles(projectile_count, float(damage) * 0.55, _with_alpha(PRIDE_FIRE_COLOR, 0.92), 390.0, float(wave) * 0.18)
		await get_tree().create_timer(2.0, false).timeout
	if overlap:
		_spawn_pride_light_beams(true)
	_finish_action(1.5 if phase == 1 else 1.0)

func _start_pride_light_cross(overlap: bool) -> void:
	is_performing_action = true
	_spawn_pride_light_beams(overlap)
	if overlap:
		await get_tree().create_timer(0.55, false).timeout
		_spawn_radial_projectiles(10, float(damage) * 0.45, _with_alpha(PRIDE_FIRE_COLOR, 0.9), 360.0)
	_finish_action(1.5 if phase == 1 else 0.9)

func _spawn_radial_projectiles(projectile_count: int, projectile_damage: float, color: Color, projectile_speed: float, angle_offset: float = 0.0) -> void:
	for i in range(projectile_count):
		var angle = TAU * float(i) / float(projectile_count) + angle_offset
		_spawn_enemy_projectile(global_position, Vector2(cos(angle), sin(angle)), projectile_damage, color, projectile_speed)

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
		_create_damaging_area(center, beam_size, rotation_angle, float(damage) * 0.8, _with_alpha(PRIDE_LIGHT_COLOR, 0.35), 0.5)

func _start_pride_judgement() -> void:
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
	_create_damaging_area_after_delay(beam_position, beam_size, 0.0, float(damage) * 0.72, _with_alpha(PRIDE_LIGHT_COLOR, 0.38), 0.75, 0.5)

func _on_projectile_hit_special_area(area: Area2D, projectile: Area2D) -> void:
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

func _damage_lust_wall(wall: Node, amount: float, hit_position: Vector2) -> void:
	if not is_instance_valid(wall) or not bool(wall.get_meta("breakable", false)):
		return
	var health = float(wall.get_meta("health", 0.0)) - amount
	wall.set_meta("health", health)
	_update_embedded_health_bar(wall)
	_spawn_burst_particles(hit_position, Color(1.0, 1.0, 1.0, 0.72), 8, 0.16, 65.0)
	if health <= 0.0:
		active_lust_walls.erase(wall)
		_spawn_burst_particles(wall.global_position, _with_alpha(LUST_COLOR, 0.82), 24, 0.28, 130.0)
		wall.queue_free()

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
	if current_health <= 0:
		die()
		return

	_try_activate_enrage()
	_flash_damage()

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
		return 1.0 + float(gluttony_stress_timers.size()) * (0.11 if phase == 1 else 0.17)
	return 1.0

func _try_activate_enrage() -> void:
	if is_enraged:
		return
	if current_health > max_health * ENRAGE_HEALTH_RATIO:
		return
	is_enraged = true
	if has_meta("base_speed"):
		set_meta("base_speed", float(get_meta("base_speed")) * ENRAGE_STAT_MULTIPLIER)

func _flash_damage() -> void:
	if not aparencia:
		return
	var tween = create_tween()
	tween.tween_property(aparencia, "modulate", Color.RED, 0.1)
	tween.tween_property(aparencia, "modulate", Color.WHITE, 0.1)

func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_cleaning_up = true
	current_sub_state = BossSubState.DEAD
	current_health = 0
	_update_health_bar()
	set_physics_process(false)
	_set_boss_edge_indicator_visible(false)
	_cleanup_boss_objects()

	var should_grant_rewards = Global.pecado < 7
	if should_grant_rewards and player and player.has_method("gain_xp"):
		player.gain_xp(xp_drop)
	if should_grant_rewards and player and player.has_method("on_enemy_killed"):
		player.on_enemy_killed(self)

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

func _register_boss_summon(enemy: Node) -> void:
	if enemy == null:
		return
	enemy.set_meta("boss_summon", true)
	enemy.set_meta("skip_xp", true)
	if enemy.get("xp_drop") != null:
		enemy.set("xp_drop", 0)
	boss_summons.append(enemy)

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
	action_cooldown = cooldown
	is_performing_action = false
	current_sub_state = BossSubState.DECIDE

func _spawn_enemy_projectile(spawn_position: Vector2, projectile_direction: Vector2, projectile_damage: float, color: Color, projectile_speed: float = 500.0) -> Area2D:
	var projectile = PROJECTILE_SCENE.instantiate()
	projectile.global_position = spawn_position
	projectile.direction = projectile_direction.normalized()
	projectile.damage = projectile_damage
	projectile.set_meta("vfx_color", color)
	_get_vfx_parent().add_child(projectile)
	projectile.speed = projectile_speed
	return projectile

func _create_damaging_area_after_delay(area_position: Vector2, size: Vector2, area_rotation: float, area_damage: float, color: Color, delay: float, duration: float) -> void:
	await get_tree().create_timer(delay, false).timeout
	_create_damaging_area(area_position, size, area_rotation, area_damage, color, duration)

func _create_damaging_area(area_position: Vector2, size: Vector2, area_rotation: float, area_damage: float, color: Color, duration: float) -> void:
	var area = Area2D.new()
	area.name = "BossDamagingArea"
	area.global_position = area_position
	area.rotation = area_rotation
	area.collision_layer = 0
	area.collision_mask = PLAYER_LAYER_MASK
	area.set_meta("damage", area_damage)
	_add_rect_collision(area, size)
	_add_rect_visual(area, size, color, 20)

	area.body_entered.connect(Callable(self, "_on_damaging_area_body_entered").bind(area))
	_get_vfx_parent().add_child(area)
	if player and _is_point_inside_rotated_rect(player.global_position, area_position, size, area_rotation):
		player.take_damage(area_damage, area_position)
	var cleanup_timer = get_tree().create_timer(duration, false)
	cleanup_timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(area))

func _on_damaging_area_body_entered(body: Node, area: Area2D) -> void:
	if body.is_in_group("Player"):
		body.take_damage(float(area.get_meta("damage", damage)), area.global_position)

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

func _add_circle_collision(parent: Node, radius: float) -> CollisionShape2D:
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
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
	visual.polygon = _build_circle_points(radius, false)
	visual.color = color
	visual.z_index = visual_z_index
	parent.add_child(visual)
	return visual

func _add_rect_visual(parent: Node, size: Vector2, color: Color, visual_z_index: int) -> Polygon2D:
	var visual = Polygon2D.new()
	visual.polygon = _build_rect_points(size)
	visual.color = color
	visual.z_index = visual_z_index
	parent.add_child(visual)
	return visual

func _add_ring_visual(parent: Node, radius: float, color: Color, width: float, visual_z_index: int) -> Line2D:
	var ring = Line2D.new()
	radius = min(radius, MAX_BOSS_CIRCLE_VFX_RADIUS)
	ring.width = width
	ring.default_color = color
	ring.points = _build_circle_points(radius, true)
	ring.z_index = visual_z_index
	parent.add_child(ring)
	return ring

func _get_health_bar_y_offset() -> float:
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
	if get_tree().current_scene:
		return get_tree().current_scene
	return get_tree().root

func _get_arena_center() -> Vector2:
	var scene = get_tree().current_scene
	if scene and scene.has_method("_get_current_arena_center"):
		return scene.call("_get_current_arena_center")
	return global_position

func _get_arena_rect() -> Rect2:
	var scene = get_tree().current_scene
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
	var scene = get_tree().current_scene
	if scene and scene.has_method("_is_position_safe_in_current_arena"):
		return scene.call("_is_position_safe_in_current_arena", point, margin)
	return _get_arena_rect().grow(-margin).has_point(point)

func _clamp_to_current_arena(point: Vector2, margin: float = 0.0) -> Vector2:
	var scene = get_tree().current_scene
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

func _get_random_arena_edge_position() -> Vector2:
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

func _spawn_line_telegraph(from_position: Vector2, to_position: Vector2, color: Color, duration: float, width: float = 3.0) -> void:
	var telegraph = Node2D.new()
	telegraph.global_position = from_position
	telegraph.z_index = 18
	var line = Line2D.new()
	line.width = width
	line.default_color = _with_alpha(color, 0.45)
	line.points = PackedVector2Array([Vector2.ZERO, to_position - from_position])
	telegraph.add_child(line)
	_get_vfx_parent().add_child(telegraph)
	var timer = get_tree().create_timer(duration, false)
	timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(telegraph))

func _spawn_falling_warning(spawn_position: Vector2, color: Color, duration: float) -> void:
	var warning = Node2D.new()
	warning.global_position = spawn_position
	warning.z_index = 18
	var line = Line2D.new()
	line.width = 2.5
	line.default_color = _with_alpha(color, 0.55)
	line.points = PackedVector2Array([Vector2.ZERO, Vector2(0.0, MAX_BOSS_CIRCLE_VFX_RADIUS)])
	warning.add_child(line)
	_add_ring_visual(warning, 11.0, _with_alpha(color, 0.72), 2.0, 19)
	_get_vfx_parent().add_child(warning)
	var timer = get_tree().create_timer(duration, false)
	timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(warning))

func _add_loop_particles(parent: Node, particle_name: String, color: Color, amount: int, lifetime: float, min_velocity: float, max_velocity: float, visual_z_index: int) -> CPUParticles2D:
	var particles = CPUParticles2D.new()
	particles.name = particle_name
	particles.amount = amount
	particles.lifetime = lifetime
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = min_velocity
	particles.initial_velocity_max = max_velocity
	particles.color = color
	particles.z_index = visual_z_index
	parent.add_child(particles)
	particles.emitting = true
	return particles

func _spawn_marker_on_node(target: Node2D, radius: float, color: Color, duration: float) -> void:
	if not is_instance_valid(target):
		return
	var marker = Node2D.new()
	marker.z_index = 28
	target.add_child(marker)
	_add_circle_visual(marker, radius, _with_alpha(color, 0.1), 28)
	_add_ring_visual(marker, radius, _with_alpha(color, 0.62), 2.0, 29)
	_add_loop_particles(marker, "MarkerParticles", _with_alpha(color, 0.42), 28, 0.55, 12.0, 48.0, 30)
	var tween = create_tween().bind_node(marker)
	tween.tween_property(marker, "modulate:a", 0.55, duration * 0.5)
	tween.tween_property(marker, "modulate:a", 0.0, duration * 0.5)
	tween.tween_callback(Callable(self, "_queue_free_if_valid").bind(marker))

func _spawn_circle_telegraph(center: Vector2, radius: float, color: Color, duration: float) -> void:
	radius = min(radius, MAX_BOSS_CIRCLE_VFX_RADIUS)
	var telegraph = Node2D.new()
	telegraph.global_position = center
	telegraph.z_index = 18
	var fill = Polygon2D.new()
	fill.polygon = _build_circle_points(radius, false)
	fill.color = color
	telegraph.add_child(fill)
	var ring = Line2D.new()
	ring.width = 2.0
	ring.default_color = Color(color.r, color.g, color.b, min(color.a + 0.24, 1.0))
	ring.points = _build_circle_points(radius, true)
	telegraph.add_child(ring)
	_get_vfx_parent().add_child(telegraph)
	var timer = get_tree().create_timer(duration, false)
	timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(telegraph))

func _spawn_rect_telegraph(center: Vector2, size: Vector2, rect_rotation: float, color: Color, duration: float) -> void:
	var telegraph = Node2D.new()
	telegraph.global_position = center
	telegraph.rotation = rect_rotation
	telegraph.z_index = 18
	var fill = Polygon2D.new()
	fill.polygon = _build_rect_points(size)
	fill.color = color
	telegraph.add_child(fill)
	_get_vfx_parent().add_child(telegraph)
	var timer = get_tree().create_timer(duration, false)
	timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(telegraph))

func _spawn_ring_vfx(center: Vector2, radius: float, color: Color, duration: float) -> void:
	radius = min(radius, MAX_BOSS_CIRCLE_VFX_RADIUS)
	var node = Node2D.new()
	node.global_position = center
	node.z_index = 22
	var ring = Line2D.new()
	ring.width = 3.0
	ring.default_color = color
	ring.points = _build_circle_points(radius, true)
	node.add_child(ring)
	_get_vfx_parent().add_child(node)
	var tween = create_tween().bind_node(node)
	tween.tween_property(node, "modulate:a", 0.0, duration)
	tween.tween_callback(Callable(self, "_queue_free_if_valid").bind(node))

func _spawn_attached_aura(radius: float, color: Color, duration: float) -> void:
	radius = min(radius, MAX_BOSS_CIRCLE_VFX_RADIUS)
	var aura = Node2D.new()
	aura.z_index = 22
	add_child(aura)
	var fill = Polygon2D.new()
	fill.polygon = _build_circle_points(radius, false)
	var fill_color = color
	fill_color.a *= 0.16
	fill.color = fill_color
	aura.add_child(fill)
	var ring = Line2D.new()
	ring.width = 2.0
	ring.default_color = color
	ring.points = _build_circle_points(radius, true)
	aura.add_child(ring)
	var timer = get_tree().create_timer(duration, false)
	timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(aura))

func _spawn_burst_particles(spawn_position: Vector2, color: Color, amount: int = 22, lifetime: float = 0.28, velocity_amount: float = 120.0) -> void:
	var particles = CPUParticles2D.new()
	particles.global_position = spawn_position
	particles.amount = amount
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
	_get_vfx_parent().add_child(particles)
	particles.emitting = true
	var timer = get_tree().create_timer(lifetime + 0.2, false)
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

func _queue_free_if_valid(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
