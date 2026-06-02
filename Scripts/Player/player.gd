extends CharacterBody2D

# --- Status melhoráveis via Level Ups ---
@export var max_health: int = 1000
@export var current_health: int = 1000
@export var attack_damage: float = 40.0
@export var fire_rate: float = 1.1
const STARTING_FIRE_RATE: float = 1.1
const DEFAULT_MIN_FIRE_RATE: float = 0.25
var min_fire_rate: float = DEFAULT_MIN_FIRE_RATE
var base_fire_rate: float = 1.1
var attack_speed_bonus: float = 0.0
@export var recoil_force: float = 460.0
const MAX_RECOIL_FORCE: float = 800.0
var base_recoil_force: float = 460.0
var recoil_force_bonus: float = 0.0
@export var friction: float = 760.0
var is_invulnerable: bool = false
const MOVEMENT_FORCE_COMBO_LOCK_DURATION: float = 0.2
const MOVEMENT_FORCE_CAP_BUFFER: float = 100.0
const WALL_COLLISION_LAYER: int = 1
const WALL_BOUNCE_MIN_SPEED: float = 75.0
const WALL_BOUNCE_MULTIPLIER: float = 0.75
const WALL_BOUNCE_PUSH_OUT: float = 4.0
const ISO_AOE_VISUAL_Y_SCALE: float = 0.65
const GROUND_AREA_VFX_LAYER_NAME: String = "GroundAreaVFX"
const GROUND_AREA_VFX_Z_INDEX: int = 1
const CHARACTER_RENDER_Z_INDEX: int = 10

# --- DASH ---
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 5.0
var base_dash_speed: float = 600.0
var dash_speed_modifiers: Dictionary = {}
const MAX_ABILITY_AREA_RADIUS: float = 180.0
const DEVOUR_RADIUS: float = MAX_ABILITY_AREA_RADIUS
const SLOW_AURA_RADIUS: float = MAX_ABILITY_AREA_RADIUS
const SHOCKWAVE_RADIUS: float = MAX_ABILITY_AREA_RADIUS
const SHOCKWAVE_DAMAGE_MULTIPLIER: float = 0.35
const SHOCKWAVE_DASH_DAMAGE_MULTIPLIER: float = 0.75
const WRATH_OVERHEAT_SHOT_INTERVAL: int = 4
const MIRROR_SHOT_DAMAGE_MULTIPLIER: float = 0.5
const MAX_PROJECTILE_SIZE_MULTIPLIER: float = 2.0
const MIN_PROJECTILE_SIZE_MULTIPLIER: float = 0.5
const MAX_HEAL_AFTER_WAVE_BONUS: float = 0.18

# --- TIRO ---
@export var pistol_bullet_scene: PackedScene
var shot_count = 1
var spread_angle = 15.0 
var projectile_size_bonus: float = 0.0
var heal_after_wave_bonus: float = 0.0
var current_arm_id: String = ""
var arm_attack_speed_upgrade_multiplier: float = 1.0
var unstable_arm_projectiles_enabled: bool = false

const STARTING_ARM_DATA = {
	"fast": {
		"name": "Braco rapido",
		"description": "Tiros fracos, cadencia alta e recuo curto para controlar melhor o medico.",
		"attack_damage": 30.0,
		"base_fire_rate": 0.5,
		"min_fire_rate": 0.3,
		"base_recoil_force": 400.0,
		"friction": 900.0,
		"attack_speed_upgrade_multiplier": 0.35,
		"unstable_projectiles": false
	},
	"heavy": {
		"name": "Braco pesado",
		"description": "Tiros lentos com dano alto e recuo forte para reposicionamentos grandes.",
		"attack_damage": 65.0,
		"base_fire_rate": 1.5,
		"min_fire_rate": 1.25,
		"base_recoil_force": 750.0,
		"friction": 600.0,
		"attack_speed_upgrade_multiplier": 0.5,
		"unstable_projectiles": false
	},
	"unstable": {
		"name": "Braco instavel",
		"description": "Projeteis atravessam um alvo e ricocheteiam uma vez, mas voltam perigosos.",
		"attack_damage": 30.0,
		"base_fire_rate": 1.15,
		"min_fire_rate": 0.65,
		"base_recoil_force": 550.0,
		"friction": 750.0,
		"attack_speed_upgrade_multiplier": 0.7,
		"unstable_projectiles": true
	}
}

const ACTIVE_ABILITY_DATA = {
	"sloth_field": {
		"name": "Sloth Field",
		"description": "Create a 180px field for 5 seconds. Enemies inside drop to 35% speed, but your dash speed drops to 75% during the field.",
		"cooldown": 15.0,
		"method": "activate_sloth_field"
	},
	"gluttony_devour": {
		"name": "Devour",
		"description": "Consume up to two enemies within 180px. Green motes fly back and heal up to 12.5% max health when they arrive, but your dash speed is halved for 5 seconds.",
		"cooldown": 25.0,
		"method": "activate_gluttony_devour"
	},
	"envy_mirror_clone": {
		"name": "Mirror Clone",
		"description": "Summon a mirror clone that fires random risky shots with you for a short time. Clone bullets can hit anything, including you.",
		"cooldown": 20.0,
		"method": "activate_envy_mirror_clone"
	},
	"wrath_burst": {
		"name": "Wrath Burst",
		"description": "Fire 16 radial bullets for 120% attack damage each, then take 20 damage.",
		"cooldown": 25.0,
		"method": "activate_wrath_burst"
	},
	"lust_for_perfection": {
		"name": "Perfection",
		"description": "Become invulnerable for 3 seconds, then take double damage for 5 seconds.",
		"cooldown": 25.0,
		"method": "activate_lust_for_perfection"
	},
	"greed_treasure_rain": {
		"name": "Treasure Rain",
		"description": "Rain golden projectiles from above. Each projectile deals 120% attack damage only when it collides, including with you.",
		"cooldown": 30.0,
		"method": "activate_greed_treasure_rain"
	},
}

const PASSIVE_STATUS_DATA = {
	"Shield_Protection": {
		"name": "One-hit Shield",
		"description": "Blocks the next damage instance, then refreshes after 12 seconds."
	},
	"Recoil_Explosion": {
		"name": "Recoil Explosion",
		"description": "Every shot creates a 180px shockwave that deals 35% of your attack damage."
	},
	"Double_Dash": {
		"name": "Double Dash",
		"description": "Gain two dash charges. Each spent charge recharges one at a time."
	},
	"Offensive_Dash": {
		"name": "Offensive Dash",
		"description": "Dashing blocks damage and releases a 180px shockwave for 75% attack damage."
	},
	"sloth_slow_aura": {
		"name": "Slow Aura",
		"description": "Enemies within 180px move at 75% speed."
	},
	"gluttony_heal_kill": {
		"name": "Blood Feast",
		"description": "Killing an enemy releases green motes that heal 1% max health when they return."
	},
	"envy_mirror_shot": {
		"name": "Mirror Shot",
		"description": "Every shot fires a mirrored bullet for 50% damage."
	},
	"wrath_overheat": {
		"name": "Overheat",
		"description": "Every 4th shot deals double damage."
	},
	"lust_for_vengeance": {
		"name": "Vengeance",
		"description": "At full HP, deal 75% more damage."
	},
	"greed_cursed_level": {
		"name": "Cursed Level",
		"description": "Gain 1 bonus level per wave. Enemies move 25% faster."
	},
}

const SIN_PASSIVE_IDS = [
	"sloth_slow_aura",
	"gluttony_heal_kill",
	"envy_mirror_shot",
	"wrath_overheat",
	"lust_for_vengeance",
	"greed_cursed_level"
]

const SIN_PASSIVE_FLAGS = {
	"sloth_slow_aura": "sloth_slow_aura_enabled",
	"gluttony_heal_kill": "gluttony_heal_kill_enabled",
	"envy_mirror_shot": "envy_mirror_shot_enabled",
	"wrath_overheat": "wrath_overheat_enabled",
	"lust_for_vengeance": "lust_for_vengeance_enabled",
	"greed_cursed_level": "greed_cursed_level_enabled"
}

var active_abilities = {
	"E": "",
	"R": ""
}

var active_ability_cooldown_remaining = {
	"E": 0.0,
	"R": 0.0
}

var level_up_context: String = "normal"
var level_up_boss_pecado: int = 0
var current_rare_option: String = ""
var current_rare_options: Array = []
const MAX_RARE_PASSIVE_OPTIONS: int = 2
const SHIELD_COOLDOWN: float = 12.0
const SHIELD_VISUAL_RADIUS: float = 24.0
var shield_protection_enabled: bool = false
var has_shield: bool = false
var shield_cooldown_remaining: float = 0.0
var shield_vfx: Node2D
var recoil_explosion_enabled: bool = false
var offensive_dash_enabled: bool = false
var max_dash_charges: int = 1
var double_dash_charges: int = 1
var sloth_slow_aura_enabled: bool = false
var gluttony_heal_kill_enabled: bool = false
var envy_mirror_shot_enabled: bool = false
var envy_clone_active: bool = false
var wrath_overheat_enabled: bool = false
var wrath_shot_count: int = 0
var lust_for_vengeance_enabled: bool = false
var greed_cursed_level_enabled: bool = false
var damage_taken_multiplier: float = 1.0
var temporary_attack_multiplier: float = 1.0
var sloth_aura_vfx: Node2D
var envy_clone_vfx: Node2D
var passive_status_vfx: Dictionary = {}

# --- SISTEMA DE DANO CONTÍNUO ---
var enemies_in_contact: Array = []
var contact_damage_timer: Timer

# --- Sprites ---
var aparencia

# Variáveis de XP e Nível
@export var level: int = 1
@export var current_xp: int = 0
@export var xp_to_next_level: int = 100
var upando = false

# Sinais para comunicação entre códigos
signal xp_updated(current_xp, xp_to_next_level)
signal level_updated(level, current_xp, xp_to_next_level)
signal hp_updated(health, maxHealth)
signal stats_updated()

# --- ESTADOS DO JOGADOR ---
var can_shoot: bool = true
var can_dash: bool = true
var is_dashing: bool = false
var movement_force_combo_lock_remaining: float = 0.0

# --- TIMERS ---
var shoot_timer: Timer
var dash_cd_timer: Timer

# --- Paths ---
var pause_control_path: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/PauseControl"
var pause_control: Control
var game_over_path: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/PauseControl/GameOver"
var game_over: Panel
var game_win_path: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/PauseControl/GameWin"
var game_win: Panel

var type_animation = "walk_down"

func _ready() -> void:
	z_index = CHARACTER_RENDER_Z_INDEX
	z_as_relative = false
	base_fire_rate = STARTING_FIRE_RATE
	fire_rate = STARTING_FIRE_RATE
	_recalculate_fire_rate()
	base_recoil_force = recoil_force
	_recalculate_recoil_force()
	base_dash_speed = dash_speed
	aparencia = get_node_or_null("Aparencia")
	pause_control = get_node_or_null(pause_control_path)
	game_over = get_node_or_null(game_over_path)
	game_win = get_node_or_null(game_win_path)

	shoot_timer = Timer.new()
	shoot_timer.one_shot = true
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	add_child(shoot_timer)
	
	dash_cd_timer = Timer.new()
	dash_cd_timer.one_shot = true
	dash_cd_timer.timeout.connect(_on_dash_cd_timer_timeout)
	add_child(dash_cd_timer)

	contact_damage_timer = Timer.new()
	contact_damage_timer.wait_time = 0.4
	contact_damage_timer.one_shot = false
	contact_damage_timer.timeout.connect(_on_contact_damage_timer_timeout)
	add_child(contact_damage_timer)

func apply_starting_arm(arm_id: String) -> void:
	if not STARTING_ARM_DATA.has(arm_id):
		return

	var arm_data: Dictionary = STARTING_ARM_DATA[arm_id]
	current_arm_id = arm_id
	attack_damage = float(arm_data["attack_damage"])
	base_fire_rate = float(arm_data["base_fire_rate"])
	min_fire_rate = float(arm_data["min_fire_rate"])
	attack_speed_bonus = 0.0
	base_recoil_force = float(arm_data["base_recoil_force"])
	recoil_force_bonus = 0.0
	friction = float(arm_data["friction"])
	arm_attack_speed_upgrade_multiplier = float(arm_data["attack_speed_upgrade_multiplier"])
	unstable_arm_projectiles_enabled = bool(arm_data["unstable_projectiles"])
	_recalculate_fire_rate()
	_recalculate_recoil_force()
	emit_signal("stats_updated")

func get_starting_arm_name() -> String:
	if current_arm_id == "" or not STARTING_ARM_DATA.has(current_arm_id):
		return "Nenhum braco"

	return str(STARTING_ARM_DATA[current_arm_id]["name"])

func add_attack_speed_bonus(amount: float) -> void:
	if not can_upgrade_attack_speed():
		return

	attack_speed_bonus += amount * arm_attack_speed_upgrade_multiplier
	_recalculate_fire_rate()
	emit_signal("stats_updated")

func get_attack_speed_percent() -> float:
	var effective_fire_rate = max(max(fire_rate, min_fire_rate), 0.001)
	return (base_fire_rate / effective_fire_rate) * 100.0

func get_max_attack_speed_percent() -> float:
	return (base_fire_rate / max(min_fire_rate, 0.001)) * 100.0

func get_attack_speed_upgrade_scale_percent() -> float:
	return arm_attack_speed_upgrade_multiplier * 100.0

func get_current_arm_name() -> String:
	if STARTING_ARM_DATA.has(current_arm_id):
		return str(STARTING_ARM_DATA[current_arm_id].get("name", current_arm_id))
	return "Base"

func get_shot_cooldown() -> float:
	return fire_rate

func get_base_shot_cooldown() -> float:
	return base_fire_rate

func can_upgrade_attack_speed() -> bool:
	return fire_rate > min_fire_rate + 0.0001

func can_roll_attack_speed_upgrade() -> bool:
	return current_arm_id != "fast" and can_upgrade_attack_speed()

func _recalculate_fire_rate() -> void:
	fire_rate = max(base_fire_rate / max(1.0 + attack_speed_bonus, 0.001), min_fire_rate)

func add_recoil_force_bonus(amount: float) -> void:
	if not can_upgrade_recoil_force():
		return

	recoil_force_bonus += amount
	_recalculate_recoil_force()

func can_upgrade_recoil_force() -> bool:
	return recoil_force < MAX_RECOIL_FORCE - 0.0001

func can_roll_recoil_force_upgrade() -> bool:
	return current_arm_id != "heavy" and can_upgrade_recoil_force()

func get_max_recoil_force() -> float:
	return MAX_RECOIL_FORCE

func multiply_base_recoil_force(multiplier: float) -> void:
	base_recoil_force *= max(multiplier, 0.0)
	_recalculate_recoil_force()

func _recalculate_recoil_force() -> void:
	recoil_force = min(base_recoil_force * max(1.0 + recoil_force_bonus, 0.0), MAX_RECOIL_FORCE)

func add_projectile_size_bonus(amount: float) -> void:
	if amount > 0.0 and not can_upgrade_projectile_size():
		return

	projectile_size_bonus = clamp(
		projectile_size_bonus + amount,
		MIN_PROJECTILE_SIZE_MULTIPLIER - 1.0,
		MAX_PROJECTILE_SIZE_MULTIPLIER - 1.0
	)

func can_upgrade_projectile_size() -> bool:
	return get_projectile_size_multiplier() < MAX_PROJECTILE_SIZE_MULTIPLIER - 0.0001

func get_projectile_size_multiplier() -> float:
	return clamp(1.0 + projectile_size_bonus, MIN_PROJECTILE_SIZE_MULTIPLIER, MAX_PROJECTILE_SIZE_MULTIPLIER)

func get_projectile_size_percent() -> float:
	return get_projectile_size_multiplier() * 100.0

func add_heal_after_wave_bonus(amount: float) -> void:
	if not can_upgrade_heal_after_wave():
		return

	heal_after_wave_bonus = min(heal_after_wave_bonus + amount, MAX_HEAL_AFTER_WAVE_BONUS)
	emit_signal("stats_updated")

func can_upgrade_heal_after_wave() -> bool:
	return heal_after_wave_bonus < MAX_HEAL_AFTER_WAVE_BONUS - 0.0001

func get_heal_after_wave_percent() -> float:
	return heal_after_wave_bonus * 100.0

func get_max_heal_after_wave_percent() -> float:
	return MAX_HEAL_AFTER_WAVE_BONUS * 100.0

func apply_heal_after_wave() -> void:
	if heal_after_wave_bonus <= 0.0 or current_health >= max_health:
		return

	var heal_amount = max_health * heal_after_wave_bonus
	heal(heal_amount)
	_spawn_burst_particles(global_position, Color(0.25, 1.0, 0.45, 0.9), 18, 0.24, 90.0)

func enable_shield_protection() -> void:
	shield_protection_enabled = true
	shield_cooldown_remaining = 0.0
	has_shield = true
	_ensure_shield_vfx()
	emit_signal("stats_updated")

func disable_shield_protection() -> void:
	shield_protection_enabled = false
	shield_cooldown_remaining = 0.0
	has_shield = false
	_destroy_shield_vfx(false)
	emit_signal("stats_updated")

func is_shield_protection_enabled() -> bool:
	return shield_protection_enabled

func is_shield_ready() -> bool:
	return shield_protection_enabled and has_shield

func get_shield_cooldown_remaining() -> float:
	return shield_cooldown_remaining

func _update_shield_protection(delta: float) -> void:
	if not shield_protection_enabled:
		_destroy_shield_vfx(false)
		return

	if has_shield:
		_ensure_shield_vfx()
		return

	if shield_cooldown_remaining > 0.0:
		shield_cooldown_remaining = max(shield_cooldown_remaining - delta, 0.0)
		if shield_cooldown_remaining == 0.0:
			has_shield = true
			_ensure_shield_vfx()
			emit_signal("stats_updated")

func _break_shield() -> void:
	has_shield = false
	shield_cooldown_remaining = SHIELD_COOLDOWN if shield_protection_enabled else 0.0
	_destroy_shield_vfx(true)
	emit_signal("stats_updated")

func _ensure_shield_vfx() -> void:
	if not shield_protection_enabled or not has_shield:
		return
	if is_instance_valid(shield_vfx):
		return

	shield_vfx = Node2D.new()
	shield_vfx.name = "OneHitShieldVFX"
	shield_vfx.z_index = 35
	add_child(shield_vfx)

	var ring = Line2D.new()
	ring.width = 2.0
	ring.default_color = Color(0.35, 0.85, 1.0, 0.95)
	ring.z_index = 35
	_build_ring_points(ring, SHIELD_VISUAL_RADIUS)
	shield_vfx.add_child(ring)

	var pulse = create_tween().bind_node(shield_vfx)
	pulse.set_loops()
	pulse.tween_property(shield_vfx, "scale", Vector2(1.08, 1.08), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(shield_vfx, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _destroy_shield_vfx(with_particles: bool) -> void:
	if with_particles:
		_spawn_burst_particles(global_position, Color(0.35, 0.9, 1.0, 0.95), 34, 0.35, 150.0)

	if not is_instance_valid(shield_vfx):
		shield_vfx = null
		return

	var old_vfx = shield_vfx
	shield_vfx = null
	if not with_particles:
		old_vfx.queue_free()
		return

	var tween = create_tween().bind_node(old_vfx)
	tween.tween_property(old_vfx, "scale", Vector2(1.35, 1.35), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(old_vfx, "modulate:a", 0.0, 0.12)
	tween.tween_callback(Callable(self, "_queue_free_if_valid").bind(old_vfx))

func _update_movement_force_combo_lock(delta: float) -> void:
	if movement_force_combo_lock_remaining > 0.0:
		movement_force_combo_lock_remaining = max(movement_force_combo_lock_remaining - delta, 0.0)

func _apply_recoil_impulse(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	var recoil_velocity = -direction.normalized() * recoil_force
	if movement_force_combo_lock_remaining > 0.0:
		velocity = recoil_velocity
		movement_force_combo_lock_remaining = 0.0
	else:
		velocity += recoil_velocity

	velocity = velocity.limit_length(_get_movement_force_speed_cap())

func _apply_knockback(attacker_position: Vector2, force_multiplier: float = 1.0) -> void:
	if is_dashing:
		return

	var knockback_direction = attacker_position.direction_to(global_position)
	var knockback_force = 275.0 * clampf(force_multiplier, 0.0, 1.0)
	velocity = (knockback_direction * knockback_force).limit_length(_get_movement_force_speed_cap())
	movement_force_combo_lock_remaining = MOVEMENT_FORCE_COMBO_LOCK_DURATION

func _get_movement_force_speed_cap() -> float:
	return max(dash_speed, recoil_force) + MOVEMENT_FORCE_CAP_BUFFER

func _set_dash_speed_modifier(source: String, multiplier: float) -> void:
	dash_speed_modifiers[source] = max(multiplier, 0.0)
	_recalculate_dash_speed()

func _clear_dash_speed_modifier(source: String) -> void:
	if dash_speed_modifiers.has(source):
		dash_speed_modifiers.erase(source)
		_recalculate_dash_speed()

func _recalculate_dash_speed() -> void:
	var final_multiplier = 1.0
	for multiplier in dash_speed_modifiers.values():
		final_multiplier *= float(multiplier)

	dash_speed = base_dash_speed * final_multiplier

func _apply_wall_bounce(incoming_velocity: Vector2) -> void:
	if incoming_velocity.length() < WALL_BOUNCE_MIN_SPEED:
		return

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision == null or not _is_wall_collision(collision):
			continue

		var normal = collision.get_normal()
		if incoming_velocity.dot(normal) >= 0.0:
			continue

		var bounced_velocity = incoming_velocity.bounce(normal) * WALL_BOUNCE_MULTIPLIER
		if bounced_velocity.length() < WALL_BOUNCE_MIN_SPEED:
			velocity = Vector2.ZERO
		else:
			velocity = bounced_velocity.limit_length(_get_movement_force_speed_cap())
		global_position += normal * WALL_BOUNCE_PUSH_OUT
		return

func _is_wall_collision(collision: KinematicCollision2D) -> bool:
	var collider = collision.get_collider()
	if collider == null:
		return false
	var collision_layer = collider.get("collision_layer")
	if collision_layer == null:
		return false

	return (int(collision_layer) & WALL_COLLISION_LAYER) != 0

func _take_direct_damage(amount: float) -> void:
	current_health -= int(round(amount))
	emit_signal("hp_updated", current_health, max_health)
	if current_health <= 0:
		die()

func _physics_process(delta: float) -> void:
	_update_active_ability_cooldowns(delta)
	_update_shield_protection(delta)
	_update_movement_force_combo_lock(delta)

	var mouse_pos = get_global_mouse_position()
	var look_direction = global_position.direction_to(mouse_pos)
	_update_direction_animation(look_direction)
	
	if pause_control.canMove:
		# Dash na direção do mouse
		if Input.is_action_just_pressed("dash") and _can_perform_dash():
			perform_dash(look_direction)

		# Atirar / Movimentação por Recuo
		if Input.is_action_just_pressed("shoot") and can_shoot and not is_dashing:
			shoot(look_direction)

		if Input.is_action_just_pressed("active_e"):
			use_active_ability("E")

		if Input.is_action_just_pressed("active_r"):
			use_active_ability("R")

	if sloth_slow_aura_enabled:
		_ensure_sloth_slow_aura_vfx()
		_apply_sloth_slow_aura()

	_update_passive_status_vfx(delta)

	# Aplicar Atrito se não estiver no meio de um dash
	if not is_dashing:
		if velocity.length() > 0:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	var velocity_before_slide = velocity
	move_and_slide()
	_apply_wall_bounce(velocity_before_slide)

func shoot(direction: Vector2) -> void:
	if not pistol_bullet_scene:
		return
	
	can_shoot = false
	shoot_timer.start(fire_rate)
	
	var mouse_pos = get_global_mouse_position()
	var base_direction = (mouse_pos - global_position).normalized()
	type_animation = _get_animation_for_direction(base_direction)
	var base_angle = base_direction.angle()
	var shot_damage = _get_current_shot_damage()
	
	for i in range(shot_count):
		# Calcula o deslocamento do ângulo dado que podemos ter multiplos tiros
		var angle_offset = deg_to_rad((i - (shot_count - 1) / 2.0) * spread_angle)
		var final_angle = base_angle + angle_offset
		_spawn_projectile(global_position, final_angle, shot_damage)

		if envy_mirror_shot_enabled:
			_spawn_mirror_shot(global_position, final_angle, shot_damage)

		if envy_clone_active:
			var clone_position = global_position + Vector2(48, 0)
			_spawn_projectile(clone_position, _get_clone_random_shot_angle(clone_position), shot_damage * 0.75, true, Color(0.25, 0.95, 1.0, 0.9))

	_apply_recoil_impulse(direction)
	if recoil_explosion_enabled:
		_trigger_recoil_explosion()

func _update_direction_animation(direction: Vector2) -> void:
	if not aparencia:
		return

	type_animation = _get_animation_for_direction(direction)
	if aparencia.animation != type_animation:
		aparencia.play(type_animation)
	elif not aparencia.is_playing():
		aparencia.play()

func _get_animation_for_direction(direction: Vector2) -> String:
	if direction == Vector2.ZERO:
		return type_animation

	var angle = rad_to_deg(direction.angle())
	if angle >= -135.0 and angle < -45.0:
		return "walk_up"
	if angle >= -45.0 and angle < 22.5:
		return "walk_right"
	if angle >= 22.5 and angle < 67.5:
		return "walk_down_right"
	if angle >= 67.5 and angle < 112.5:
		return "walk_down"
	if angle >= 112.5 and angle < 157.5:
		return "walk_down_left"
	return "walk_left"

func _get_current_shot_damage() -> float:
	var damage = attack_damage * temporary_attack_multiplier
	if lust_for_vengeance_enabled and current_health >= max_health:
		damage *= 1.75

	if wrath_overheat_enabled:
		wrath_shot_count += 1
		if wrath_shot_count >= WRATH_OVERHEAT_SHOT_INTERVAL:
			wrath_shot_count = 0
			damage *= 2.0
			_spawn_burst_particles(global_position, Color(1.0, 0.18, 0.04, 0.85), 14, 0.18, 110.0)

	return damage

func _get_mirrored_shot_angle(source_angle: float) -> float:
	var source_direction = Vector2(cos(source_angle), sin(source_angle))
	if abs(source_direction.y) >= abs(source_direction.x):
		source_direction.x *= -1.0
	else:
		source_direction.y *= -1.0

	return source_direction.normalized().angle()

func _spawn_mirror_shot(spawn_position: Vector2, source_angle: float, shot_damage: float) -> void:
	_spawn_projectile(spawn_position, _get_mirrored_shot_angle(source_angle), shot_damage * MIRROR_SHOT_DAMAGE_MULTIPLIER, false, Color(0.25, 0.95, 1.0, 0.9))

func _get_clone_random_shot_angle(clone_position: Vector2) -> float:
	var direction_to_player = clone_position.direction_to(global_position)
	var angle_to_player = direction_to_player.angle()
	if randf() < 0.18:
		return angle_to_player + randf_range(-PI / 6.0, PI / 6.0)

	for i in range(10):
		var random_angle = randf_range(-PI, PI)
		var angle_diff = abs(wrapf(random_angle - angle_to_player, -PI, PI))
		if angle_diff > PI / 4.0:
			return random_angle

	return angle_to_player + PI

func _spawn_projectile(spawn_position: Vector2, angle: float, projectile_damage: float, can_hit_player: bool = false, projectile_vfx_color: Color = Color(0.0, 0.0, 0.0, 0.0)) -> Node:
	if not pistol_bullet_scene:
		return null

	var bullet = pistol_bullet_scene.instantiate()
	bullet.global_position = spawn_position
	bullet.direction = Vector2(cos(angle), sin(angle))
	bullet.damage = projectile_damage
	if not can_hit_player:
		bullet.scale *= get_projectile_size_multiplier()
	if projectile_vfx_color.a > 0.0:
		bullet.set_meta("vfx_color", projectile_vfx_color)
	if can_hit_player:
		bullet.add_to_group("EnemyProjectile")
	elif unstable_arm_projectiles_enabled:
		_configure_unstable_projectile(bullet)
	get_tree().root.add_child(bullet)
	return bullet

func _configure_unstable_projectile(bullet: Node) -> void:
	bullet.set_meta("pierce_remaining", 1)
	bullet.set_meta("ricochet_remaining", 1)
	bullet.set_meta("risk_after_ricochet", true)
	bullet.set_meta("vfx_color", Color(0.6, 0.2, 1.0, 0.95))

func _can_perform_dash() -> bool:
	return can_dash and double_dash_charges > 0 and not is_dashing

func perform_dash(direction: Vector2) -> void:
	if not _consume_dash_charge():
		return

	is_dashing = true
	if max_dash_charges > 1:
		_spawn_burst_particles(global_position, Color(0.35, 0.7, 1.0, 0.9), 22, 0.28, 160.0)
	
	velocity = direction.normalized() * dash_speed
	await get_tree().create_timer(dash_duration, false).timeout
	
	is_dashing = false
	movement_force_combo_lock_remaining = MOVEMENT_FORCE_COMBO_LOCK_DURATION
	if offensive_dash_enabled:
		_trigger_offensive_dash_explosion()

	can_dash = double_dash_charges > 0

func enable_double_dash() -> void:
	max_dash_charges = 2
	_refill_dash_charges()
	emit_signal("stats_updated")

func disable_double_dash() -> void:
	max_dash_charges = 1
	double_dash_charges = min(double_dash_charges, max_dash_charges)
	can_dash = double_dash_charges > 0
	if double_dash_charges >= max_dash_charges and not dash_cd_timer.is_stopped():
		dash_cd_timer.stop()
	elif double_dash_charges < max_dash_charges and dash_cd_timer.is_stopped():
		dash_cd_timer.start(dash_cooldown)
	emit_signal("stats_updated")

func _refill_dash_charges() -> void:
	double_dash_charges = max_dash_charges
	can_dash = true
	if not dash_cd_timer.is_stopped():
		dash_cd_timer.stop()

func _consume_dash_charge() -> bool:
	if double_dash_charges <= 0:
		can_dash = false
		return false

	double_dash_charges -= 1
	can_dash = double_dash_charges > 0
	if double_dash_charges < max_dash_charges and dash_cd_timer.is_stopped():
		dash_cd_timer.start(dash_cooldown)

	emit_signal("stats_updated")
	return true

func take_damage(amount: float, attacker_position: Vector2 = Vector2.ZERO, knockback_multiplier: float = 1.0) -> void:
	if is_invulnerable: 
		return

	if offensive_dash_enabled and is_dashing:
		_spawn_burst_particles(global_position, Color(0.25, 0.95, 1.0, 0.85), 18, 0.22, 110.0)
		return

	if has_shield:
		_break_shield()
		return

	if attacker_position != Vector2.ZERO:
		_apply_knockback(attacker_position, knockback_multiplier)

	current_health -= int(round(amount * damage_taken_multiplier))
	emit_signal("hp_updated", current_health, max_health)
	
	if current_health <= 0:
		die()
		return

	is_invulnerable = true
	
	# Tween para demonstrar que tomou dano
	var tween = create_tween()
	tween.tween_property(aparencia, "modulate", Color.RED, 0.1)
	tween.tween_property(aparencia, "modulate", Color.WHITE, 0.1)
	
	await get_tree().create_timer(0.2, false).timeout
	is_invulnerable = false

func die():
	_finish_current_run()
	# aparencia.play("death")
	for musica in get_tree().get_nodes_in_group("Music"):
		musica.stop()
	get_tree().paused = true
	# $Lose.play()
	await get_tree().create_timer(0.25, true).timeout
	if game_over:
		game_over.visible = true

func win():
	_finish_current_run()
	for musica in get_tree().get_nodes_in_group("Music"):
		musica.stop()
	get_tree().paused = true
	# $Win.play()
	if game_win:
		game_win.visible = true

func _finish_current_run() -> void:
	var game_scene = get_tree().current_scene
	if game_scene and game_scene.has_method("finish_run"):
		game_scene.finish_run()

func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func _on_dash_cd_timer_timeout() -> void:
	if double_dash_charges < max_dash_charges:
		double_dash_charges += 1

	can_dash = double_dash_charges > 0
	if double_dash_charges < max_dash_charges:
		dash_cd_timer.start(dash_cooldown)

	emit_signal("stats_updated")

func _on_hitbox_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent == null:
		return

	if parent.is_in_group("Enemy"): 
		if not enemies_in_contact.has(parent):
			enemies_in_contact.append(parent)
		
		if contact_damage_timer.is_stopped():
			take_damage(_get_contact_damage(parent), parent.global_position, _get_contact_knockback_multiplier(parent))
			contact_damage_timer.start()

func _on_hitbox_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent == null:
		return

	if parent in enemies_in_contact:
		enemies_in_contact.erase(parent)
	
	if enemies_in_contact.is_empty():
		contact_damage_timer.stop()

func _on_contact_damage_timer_timeout() -> void:
	enemies_in_contact = enemies_in_contact.filter(func(e): return is_instance_valid(e))
	
	if not enemies_in_contact.is_empty():
		var prime_enemy = enemies_in_contact[0]
		take_damage(_get_contact_damage(prime_enemy), prime_enemy.global_position, _get_contact_knockback_multiplier(prime_enemy))
	else:
		contact_damage_timer.stop()

func _get_contact_damage(enemy: Node) -> float:
	if enemy and enemy.get("damage") != null:
		return float(enemy.get("damage"))

	return 20.0

func _get_contact_knockback_multiplier(enemy: Node) -> float:
	if enemy and enemy.has_meta("contact_knockback_multiplier"):
		return float(enemy.get_meta("contact_knockback_multiplier"))

	return 1.0

func is_active_ability_id(option_id: String) -> bool:
	return ACTIVE_ABILITY_DATA.has(option_id)

func learn_active_ability(option_id: String) -> bool:
	if not is_active_ability_id(option_id):
		return true

	if active_abilities["E"] == "":
		active_abilities["E"] = option_id
		active_ability_cooldown_remaining["E"] = 0.0
		emit_signal("stats_updated")
		return true

	if active_abilities["R"] == "":
		active_abilities["R"] = option_id
		active_ability_cooldown_remaining["R"] = 0.0
		emit_signal("stats_updated")
		return true

	return false

func replace_active_ability(slot: String, option_id: String) -> void:
	if slot == "E" or slot == "R":
		active_abilities[slot] = option_id
		active_ability_cooldown_remaining[slot] = 0.0
		emit_signal("stats_updated")

func get_active_ability_slots() -> Dictionary:
	return active_abilities.duplicate()

func get_active_slot_cooldown(slot: String) -> float:
	return float(active_ability_cooldown_remaining.get(slot, 0.0))

func get_active_ability_cooldown(option_id: String) -> float:
	var data = ACTIVE_ABILITY_DATA.get(option_id, {})
	return float(data.get("cooldown", 0.0))

func get_active_ability_name(option_id: String) -> String:
	var data = ACTIVE_ABILITY_DATA.get(option_id, {})
	return str(data.get("name", option_id))

func get_active_ability_description(option_id: String) -> String:
	var data = ACTIVE_ABILITY_DATA.get(option_id, {})
	return str(data.get("description", option_id))

func get_equipped_passive_summaries() -> Array:
	var passive_ids: Array = []
	for passive_id in get_rare_passive_options():
		passive_ids.append(passive_id)

	for passive_id in SIN_PASSIVE_IDS:
		if _is_passive_enabled(passive_id):
			passive_ids.append(passive_id)

	var summaries: Array = []
	if current_arm_id != "" and STARTING_ARM_DATA.has(current_arm_id):
		var arm_data: Dictionary = STARTING_ARM_DATA[current_arm_id]
		summaries.append({
			"id": current_arm_id,
			"name": str(arm_data["name"]),
			"description": str(arm_data["description"])
		})

	for passive_id in passive_ids:
		summaries.append({
			"id": passive_id,
			"name": get_passive_effect_name(passive_id),
			"description": get_passive_effect_description(passive_id)
		})

	return summaries

func get_passive_effect_name(passive_id: String) -> String:
	var data = PASSIVE_STATUS_DATA.get(passive_id, {})
	return str(data.get("name", passive_id))

func get_passive_effect_description(passive_id: String) -> String:
	var data = PASSIVE_STATUS_DATA.get(passive_id, {})
	return str(data.get("description", passive_id))

func _is_passive_enabled(passive_id: String) -> bool:
	if SIN_PASSIVE_FLAGS.has(passive_id):
		return bool(get(SIN_PASSIVE_FLAGS[passive_id]))

	return has_rare_passive(passive_id)

func get_rare_passive_options() -> Array:
	_sync_rare_passive_options()
	return current_rare_options.duplicate()

func has_rare_passive(option_id: String) -> bool:
	_sync_rare_passive_options()
	return option_id in current_rare_options

func can_equip_rare_passive(option_id: String) -> bool:
	_sync_rare_passive_options()
	return option_id in current_rare_options or current_rare_options.size() < MAX_RARE_PASSIVE_OPTIONS

func equip_rare_passive_id(option_id: String) -> void:
	if option_id == "":
		return

	_sync_rare_passive_options()
	if option_id not in current_rare_options and current_rare_options.size() < MAX_RARE_PASSIVE_OPTIONS:
		current_rare_options.append(option_id)
	_sync_current_rare_option_alias()

func replace_rare_passive_id(old_option: String, new_option: String) -> void:
	if new_option == "":
		return

	_sync_rare_passive_options()
	var old_index = current_rare_options.find(old_option)
	if old_index >= 0:
		current_rare_options[old_index] = new_option
	elif new_option not in current_rare_options and current_rare_options.size() < MAX_RARE_PASSIVE_OPTIONS:
		current_rare_options.append(new_option)
	_dedupe_rare_passive_options()
	_sync_current_rare_option_alias()

func remove_rare_passive_id(option_id: String) -> void:
	_sync_rare_passive_options()
	current_rare_options.erase(option_id)
	_sync_current_rare_option_alias()

func _sync_rare_passive_options() -> void:
	if current_rare_option != "" and current_rare_option not in current_rare_options:
		current_rare_options.insert(0, current_rare_option)
	_dedupe_rare_passive_options()
	while current_rare_options.size() > MAX_RARE_PASSIVE_OPTIONS:
		current_rare_options.pop_back()
	_sync_current_rare_option_alias()

func _dedupe_rare_passive_options() -> void:
	var unique_options: Array = []
	for option_id in current_rare_options:
		if option_id != "" and option_id not in unique_options:
			unique_options.append(option_id)
	current_rare_options = unique_options

func _sync_current_rare_option_alias() -> void:
	current_rare_option = str(current_rare_options[0]) if current_rare_options.size() > 0 else ""

func use_active_ability(slot: String) -> void:
	if not active_abilities.has(slot):
		return

	var ability_id = active_abilities[slot]
	if ability_id == "" or get_active_slot_cooldown(slot) > 0.0:
		return

	_activate_active_ability(ability_id)

	active_ability_cooldown_remaining[slot] = get_active_ability_cooldown(ability_id)
	emit_signal("stats_updated")

func _activate_active_ability(ability_id: String) -> void:
	var method_name = str(ACTIVE_ABILITY_DATA.get(ability_id, {}).get("method", ""))
	if method_name != "" and has_method(method_name):
		call(method_name)

func _update_active_ability_cooldowns(delta: float) -> void:
	for slot in active_ability_cooldown_remaining.keys():
		if active_ability_cooldown_remaining[slot] > 0.0:
			active_ability_cooldown_remaining[slot] = max(active_ability_cooldown_remaining[slot] - delta, 0.0)

func heal(amount: float) -> void:
	current_health = int(min(current_health + amount, max_health))
	emit_signal("hp_updated", current_health, max_health)

func on_enemy_killed(_enemy: Node) -> void:
	if gluttony_heal_kill_enabled and is_instance_valid(_enemy):
		_spawn_heal_motes(_enemy.global_position, max_health * 0.01, 5)

func grant_bonus_level_up(context: String = "normal", boss_pecado: int = 0) -> void:
	if upando:
		return

	level_up_context = context
	level_up_boss_pecado = boss_pecado
	upando = true
	level += 1
	emit_signal("level_updated", level, current_xp, xp_to_next_level)
	emit_signal("xp_updated", current_xp, xp_to_next_level)

func activate_sloth_field() -> void:
	var field_position = global_position
	var field_radius = MAX_ABILITY_AREA_RADIUS
	_spawn_field_vfx(field_position, field_radius, Color(0.25, 0.95, 1.0, 0.42), 5.0)

	var slowed_enemies: Array = []
	var elapsed = 0.0
	_set_dash_speed_modifier("sloth_field", 0.75)

	while elapsed < 5.0:
		for enemy in get_tree().get_nodes_in_group("Enemy"):
			if not is_instance_valid(enemy) or enemy.get("speed") == null:
				continue

			_remember_enemy_base_speed(enemy)
			var base_speed = enemy.get_meta("base_speed")
			var is_inside_field = _is_position_inside_iso_aoe(enemy.global_position, field_position, field_radius)
			if is_inside_field:
				enemy.set_meta("sloth_field_active", true)
				enemy.set("speed", base_speed * 0.35)
				if enemy not in slowed_enemies:
					slowed_enemies.append(enemy)
			elif enemy in slowed_enemies:
				enemy.set("speed", base_speed)
				enemy.remove_meta("sloth_field_active")
				slowed_enemies.erase(enemy)

		await get_tree().create_timer(0.1, false).timeout
		elapsed += 0.1

	_clear_dash_speed_modifier("sloth_field")
	for enemy in slowed_enemies:
		if is_instance_valid(enemy) and enemy.has_meta("base_speed"):
			enemy.set("speed", enemy.get_meta("base_speed"))
			enemy.remove_meta("sloth_field_active")

func activate_gluttony_devour() -> void:
	var nearby_enemies = get_tree().get_nodes_in_group("Enemy")
	nearby_enemies = nearby_enemies.filter(func(enemy): return is_instance_valid(enemy) and not enemy.is_in_group("Boss") and _is_position_inside_iso_aoe(enemy.global_position, global_position, DEVOUR_RADIUS))
	nearby_enemies.sort_custom(func(a, b): return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))

	var devoured_count = min(2, nearby_enemies.size())
	var heal_per_enemy = (max_health * 0.125) / max(devoured_count, 1)
	for i in range(devoured_count):
		var enemy = nearby_enemies[i]
		var enemy_position = enemy.global_position
		_spawn_burst_particles(enemy_position, Color(0.2, 1.0, 0.45, 0.95), 30, 0.4, 130.0)
		_spawn_heal_motes(enemy_position, heal_per_enemy, 3)
		if enemy.has_method("die"):
			enemy.die()

	_set_dash_speed_modifier("gluttony_devour", 0.5)
	await get_tree().create_timer(5.0, false).timeout
	_clear_dash_speed_modifier("gluttony_devour")

func activate_envy_mirror_clone() -> void:
	envy_clone_active = true
	_spawn_clone_vfx(8.0)
	await get_tree().create_timer(8.0, false).timeout
	envy_clone_active = false
	if is_instance_valid(envy_clone_vfx):
		envy_clone_vfx.queue_free()

func activate_wrath_burst() -> void:
	_spawn_burst_particles(global_position, Color(1.0, 0.25, 0.05, 0.95), 48, 0.4, 230.0)
	_spawn_ring_vfx(global_position, 150.0, Color(1.0, 0.28, 0.08, 0.46), 0.35)
	var burst_damage = attack_damage * 1.2
	for i in range(16):
		var angle = TAU * float(i) / 16.0
		_spawn_projectile(global_position, angle, burst_damage, false, Color(1.0, 0.25, 0.05, 0.95))
	_take_direct_damage(20)

func activate_lust_for_perfection() -> void:
	is_invulnerable = true
	_spawn_attached_aura(110.0, Color(1.0, 0.82, 0.98, 0.42), 3.0)
	await get_tree().create_timer(3.0, false).timeout
	is_invulnerable = false
	damage_taken_multiplier = 2.0
	_spawn_attached_aura(130.0, Color(1.0, 0.16, 0.36, 0.38), 5.0)
	await get_tree().create_timer(5.0, false).timeout
	damage_taken_multiplier = 1.0

func activate_greed_treasure_rain() -> void:
	_spawn_burst_particles(global_position, Color(1.0, 0.78, 0.08, 0.95), 42, 0.45, 180.0)
	for i in range(20):
		var spawn_position = global_position + Vector2(randf_range(-420.0, 420.0), -360.0 - randf_range(0.0, 180.0))
		_spawn_projectile(spawn_position, PI / 2.0, attack_damage * 1.2, true, Color(1.0, 0.78, 0.08, 0.95))
		await get_tree().create_timer(0.06, false).timeout

func _trigger_recoil_explosion() -> void:
	_spawn_burst_particles(global_position, Color(1.0, 0.52, 0.12, 0.95), 34, 0.3, 210.0)
	_spawn_ring_vfx(global_position, SHOCKWAVE_RADIUS, Color(1.0, 0.55, 0.12, 0.44), 0.28)
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if is_instance_valid(enemy) and enemy.has_method("take_damage") and _is_position_inside_iso_aoe(enemy.global_position, global_position, SHOCKWAVE_RADIUS):
			enemy.take_damage(_get_shockwave_damage())

func _trigger_offensive_dash_explosion() -> void:
	_spawn_burst_particles(global_position, Color(0.25, 0.95, 1.0, 0.9), 36, 0.32, 190.0)
	_spawn_ring_vfx(global_position, SHOCKWAVE_RADIUS, Color(0.42, 0.95, 1.0, 0.44), 0.3)
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if is_instance_valid(enemy) and enemy.has_method("take_damage") and _is_position_inside_iso_aoe(enemy.global_position, global_position, SHOCKWAVE_RADIUS):
			enemy.take_damage(_get_shockwave_dash_damage())

func _get_shockwave_damage() -> float:
	return attack_damage * SHOCKWAVE_DAMAGE_MULTIPLIER
func _get_shockwave_dash_damage() -> float:
	return attack_damage * SHOCKWAVE_DASH_DAMAGE_MULTIPLIER

func _apply_sloth_slow_aura() -> void:
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if not is_instance_valid(enemy) or enemy.get("speed") == null:
			continue

		if enemy.has_meta("sloth_field_active"):
			continue

		_remember_enemy_base_speed(enemy)
		var base_speed = enemy.get_meta("base_speed")
		if _is_position_inside_iso_aoe(enemy.global_position, global_position, SLOW_AURA_RADIUS):
			enemy.set("speed", base_speed * 0.7)
		else:
			enemy.set("speed", base_speed)

func _remember_enemy_base_speed(enemy: Node) -> void:
	if not enemy.has_meta("base_speed"):
		enemy.set_meta("base_speed", enemy.get("speed"))

func _is_position_inside_iso_aoe(point: Vector2, center: Vector2, radius: float) -> bool:
	var safe_radius = max(radius, 0.001)
	var y_radius = max(safe_radius * ISO_AOE_VISUAL_Y_SCALE, 0.001)
	var local_position = point - center
	var normalized_x = local_position.x / safe_radius
	var normalized_y = local_position.y / y_radius
	return normalized_x * normalized_x + normalized_y * normalized_y <= 1.0

func _get_vfx_parent() -> Node:
	if get_tree().current_scene:
		return get_tree().current_scene
	return get_tree().root

func _get_ground_area_vfx_parent() -> Node:
	var scene = get_tree().current_scene
	if scene == null:
		return _get_vfx_parent()

	var layer = scene.get_node_or_null(GROUND_AREA_VFX_LAYER_NAME)
	if layer == null:
		layer = Node2D.new()
		layer.name = GROUND_AREA_VFX_LAYER_NAME
		scene.add_child(layer)

	layer.z_index = GROUND_AREA_VFX_Z_INDEX
	layer.z_as_relative = false
	var player_node = scene.get_node_or_null("Player")
	if player_node != null and layer.get_parent() == scene and layer.get_index() > player_node.get_index():
		scene.move_child(layer, player_node.get_index())

	return layer

func _spawn_burst_particles(spawn_position: Vector2, color: Color, amount: int = 24, lifetime: float = 0.35, velocity: float = 120.0) -> void:
	var particles = CPUParticles2D.new()
	particles.global_position = spawn_position
	particles.amount = amount
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.lifetime = lifetime
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = velocity * 0.25
	particles.initial_velocity_max = velocity
	particles.color = color
	particles.z_index = 30
	_get_vfx_parent().add_child(particles)
	particles.emitting = true

	var cleanup_timer = get_tree().create_timer(lifetime + 0.25, false)
	cleanup_timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(particles))

func _spawn_field_vfx(center: Vector2, radius: float, color: Color, duration: float) -> void:
	radius = min(radius, MAX_ABILITY_AREA_RADIUS)
	_spawn_ring_vfx(center, radius, color, duration)

	var particles = CPUParticles2D.new()
	particles.amount = 80
	particles.lifetime = 1.0
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = radius * 0.05
	particles.initial_velocity_max = radius * 0.24
	particles.color = color
	_get_ground_area_vfx_parent().add_child(particles)
	particles.global_position = center
	particles.emitting = true

	var cleanup_timer = get_tree().create_timer(duration, false)
	cleanup_timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(particles))

func _spawn_attached_aura(radius: float, color: Color, duration: float) -> void:
	radius = min(radius, MAX_ABILITY_AREA_RADIUS)
	var aura = Node2D.new()
	aura.name = "TimedAuraVFX"
	add_child(aura)
	move_child(aura, 0)

	_add_ring_to_node(aura, radius, color, 2.0)
	var particles = CPUParticles2D.new()
	particles.amount = 64
	particles.lifetime = 0.85
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = radius * 0.1
	particles.initial_velocity_max = radius * 0.45
	particles.color = color
	aura.add_child(particles)
	particles.emitting = true

	var cleanup_timer = get_tree().create_timer(duration, false)
	cleanup_timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(aura))

func _spawn_ring_vfx(center: Vector2, radius: float, color: Color, duration: float) -> void:
	radius = min(radius, MAX_ABILITY_AREA_RADIUS)
	var ring_vfx = Node2D.new()
	ring_vfx.name = "FilledRingVFX"
	_get_ground_area_vfx_parent().add_child(ring_vfx)
	ring_vfx.global_position = center
	_add_ring_to_node(ring_vfx, radius, color, 3.0)

	var tween = create_tween()
	tween.tween_property(ring_vfx, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(Callable(self, "_queue_free_if_valid").bind(ring_vfx))

func _add_ring_to_node(parent: Node, radius: float, color: Color, width: float) -> Line2D:
	radius = min(radius, MAX_ABILITY_AREA_RADIUS)
	_add_circle_fill_to_node(parent, radius, color)

	var ring = Line2D.new()
	ring.width = width
	ring.default_color = color
	ring.points = _build_iso_ellipse_points(radius, true)
	parent.add_child(ring)
	return ring

func _add_circle_fill_to_node(parent: Node, radius: float, color: Color) -> Polygon2D:
	radius = min(radius, MAX_ABILITY_AREA_RADIUS)
	var fill = Polygon2D.new()
	var fill_color = color
	fill_color.a *= 0.1
	fill.color = fill_color
	fill.polygon = _build_iso_ellipse_points(radius, false)
	parent.add_child(fill)
	return fill

func _update_passive_status_vfx(delta: float) -> void:
	_set_passive_ring_vfx_enabled("recoil_explosion", recoil_explosion_enabled, 28.0, Color(1.0, 0.55, 0.14, 0.36), 1.5)
	_set_passive_ring_vfx_enabled("offensive_dash", offensive_dash_enabled, 31.0, Color(0.38, 0.95, 1.0, 0.34), 1.5)

	var dash_charge_vfx = _ensure_double_dash_vfx()
	if is_instance_valid(dash_charge_vfx):
		_update_double_dash_vfx(dash_charge_vfx)
		dash_charge_vfx.rotation += delta * 1.7

	_set_passive_ring_vfx_enabled("vengeance", lust_for_vengeance_enabled and current_health >= max_health, 34.0, Color(1.0, 0.24, 0.46, 0.34), 1.6)

func _set_passive_ring_vfx_enabled(vfx_id: String, enabled: bool, radius: float, color: Color, width: float) -> void:
	if enabled:
		_ensure_passive_ring_vfx(vfx_id, radius, color, width)
	else:
		_remove_passive_status_vfx(vfx_id)

func _ensure_passive_ring_vfx(vfx_id: String, radius: float, color: Color, width: float) -> Node2D:
	var existing_vfx = passive_status_vfx.get(vfx_id, null)
	if is_instance_valid(existing_vfx):
		return existing_vfx

	var vfx = Node2D.new()
	vfx.name = "%sPassiveVFX" % vfx_id.capitalize().replace("_", "")
	add_child(vfx)
	move_child(vfx, 0)
	_add_ring_to_node(vfx, radius, color, width)
	passive_status_vfx[vfx_id] = vfx

	var pulse = create_tween().bind_node(vfx)
	pulse.set_loops()
	pulse.tween_property(vfx, "scale", Vector2(1.08, 1.08), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(vfx, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	return vfx

func _ensure_double_dash_vfx() -> Node2D:
	var existing_vfx = passive_status_vfx.get("double_dash", null)
	if is_instance_valid(existing_vfx):
		return existing_vfx

	var vfx = Node2D.new()
	vfx.name = "DoubleDashPassiveVFX"
	add_child(vfx)
	move_child(vfx, 0)
	_add_circular_ring_to_node(vfx, 25.0, Color(0.36, 0.72, 1.0, 0.24), 1.2)

	for i in range(2):
		var dot = Polygon2D.new()
		dot.name = "DashChargeDot%d" % i
		dot.polygon = _build_circle_points(3.6, false)
		dot.color = Color(0.38, 0.78, 1.0, 0.82)
		dot.position = Vector2(28.0, 0.0).rotated(PI * float(i))
		vfx.add_child(dot)

	passive_status_vfx["double_dash"] = vfx
	_update_double_dash_vfx(vfx)
	return vfx

func _update_double_dash_vfx(vfx: Node2D) -> void:
	var visible_charges = clamp(double_dash_charges, 0, max_dash_charges)
	for i in range(2):
		var dot = vfx.get_node_or_null("DashChargeDot%d" % i)
		if dot is CanvasItem:
			dot.visible = i < visible_charges

func _remove_passive_status_vfx(vfx_id: String) -> void:
	var vfx = passive_status_vfx.get(vfx_id, null)
	if is_instance_valid(vfx):
		vfx.queue_free()
	passive_status_vfx.erase(vfx_id)

func _build_ring_points(ring: Line2D, radius: float) -> void:
	ring.points = _build_circle_points(radius, true)

func _add_circular_ring_to_node(parent: Node, radius: float, color: Color, width: float) -> Line2D:
	radius = min(radius, MAX_ABILITY_AREA_RADIUS)
	var fill = Polygon2D.new()
	var fill_color = color
	fill_color.a *= 0.1
	fill.color = fill_color
	fill.polygon = _build_circle_points(radius, false)
	parent.add_child(fill)

	var ring = Line2D.new()
	ring.width = width
	ring.default_color = color
	ring.points = _build_circle_points(radius, true)
	parent.add_child(ring)
	return ring

func _build_circle_points(radius: float, closed: bool) -> PackedVector2Array:
	var points = PackedVector2Array()
	var segment_count = 48
	var point_count = segment_count
	if closed:
		point_count += 1

	for i in range(point_count):
		var angle = TAU * float(i % segment_count) / float(segment_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _build_iso_ellipse_points(radius: float, closed: bool) -> PackedVector2Array:
	var points = PackedVector2Array()
	var segment_count = 48
	var point_count = segment_count
	if closed:
		point_count += 1

	for i in range(point_count):
		var angle = TAU * float(i % segment_count) / float(segment_count)
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius * ISO_AOE_VISUAL_Y_SCALE))
	return points

func _spawn_heal_motes(from_position: Vector2, total_heal: float, mote_count: int) -> void:
	if total_heal <= 0.0:
		return

	var pieces = max(mote_count, 1)
	var heal_per_mote = total_heal / pieces
	for i in range(pieces):
		var start_offset = Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0))
		var curve_offset = Vector2(randf_range(-45.0, 45.0), randf_range(-60.0, -24.0))
		var duration = randf_range(0.42, 0.72)
		_spawn_heal_mote(from_position + start_offset, heal_per_mote, curve_offset, duration)

func _spawn_heal_mote(from_position: Vector2, heal_amount: float, curve_offset: Vector2, duration: float) -> void:
	var mote = Polygon2D.new()
	mote.polygon = PackedVector2Array([
		Vector2(-4.0, -4.0),
		Vector2(4.0, -4.0),
		Vector2(4.0, 4.0),
		Vector2(-4.0, 4.0)
	])
	mote.color = Color(0.25, 1.0, 0.45, 0.95)
	mote.z_index = 40
	_get_vfx_parent().add_child(mote)
	mote.global_position = from_position

	var tween = create_tween()
	tween.tween_method(
		Callable(self, "_update_heal_mote").bind(mote, from_position, curve_offset),
		0.0,
		1.0,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(mote, "scale", Vector2(0.45, 0.45), duration)
	tween.tween_callback(Callable(self, "_finish_heal_mote").bind(mote, heal_amount, mote.color))

func _update_heal_mote(progress: float, mote: Polygon2D, from_position: Vector2, curve_offset: Vector2) -> void:
	if not is_instance_valid(mote):
		return

	var target_position = global_position
	var curve = curve_offset * sin(progress * PI)
	mote.global_position = from_position.lerp(target_position, progress) + curve
	mote.rotation = progress * TAU

func _finish_heal_mote(mote: Polygon2D, heal_amount: float, color: Color) -> void:
	var arrival_position = global_position
	if is_instance_valid(mote):
		arrival_position = mote.global_position
		mote.queue_free()

	heal(heal_amount)
	_spawn_burst_particles(arrival_position, color, 8, 0.18, 55.0)

func _ensure_sloth_slow_aura_vfx() -> void:
	if is_instance_valid(sloth_aura_vfx):
		return

	sloth_aura_vfx = Node2D.new()
	sloth_aura_vfx.name = "SlothSlowAuraVFX"
	add_child(sloth_aura_vfx)
	move_child(sloth_aura_vfx, 0)

	_add_ring_to_node(sloth_aura_vfx, SLOW_AURA_RADIUS, Color(0.25, 0.95, 1.0, 0.26), 2.0)

	var particles = CPUParticles2D.new()
	particles.amount = 64
	particles.lifetime = 1.1
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 45.0
	particles.initial_velocity_max = 120.0
	particles.color = Color(0.25, 0.95, 1.0, 0.3)
	sloth_aura_vfx.add_child(particles)
	particles.emitting = true

func _spawn_clone_vfx(duration: float) -> void:
	if is_instance_valid(envy_clone_vfx):
		envy_clone_vfx.queue_free()

	envy_clone_vfx = Node2D.new()
	envy_clone_vfx.name = "MirrorCloneVFX"
	envy_clone_vfx.position = Vector2(48.0, 0.0)
	envy_clone_vfx.z_index = 25
	add_child(envy_clone_vfx)

	_add_ring_to_node(envy_clone_vfx, 36.0, Color(0.4, 0.95, 1.0, 0.44), 2.0)
	var particles = CPUParticles2D.new()
	particles.amount = 36
	particles.lifetime = 0.7
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 25.0
	particles.initial_velocity_max = 80.0
	particles.color = Color(0.42, 0.95, 1.0, 0.52)
	particles.z_index = 26
	envy_clone_vfx.add_child(particles)
	particles.emitting = true

	var cleanup_timer = get_tree().create_timer(duration, false)
	cleanup_timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(envy_clone_vfx))

func _queue_free_if_valid(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()


func gain_xp(amount: int) -> void:
	current_xp += amount
	emit_signal("xp_updated", current_xp, xp_to_next_level)

	if not upando and current_xp >= xp_to_next_level:
		upando = true
		level_up()

func start_wave_xp_goal(enemy_count: int, context: String = "normal", boss_pecado: int = 0) -> void:
	current_xp = 0
	xp_to_next_level = max(enemy_count, 1)
	level_up_context = context
	level_up_boss_pecado = boss_pecado
	emit_signal("xp_updated", current_xp, xp_to_next_level)

func level_up() -> void:
	level += 1
	current_xp -= xp_to_next_level
	emit_signal("level_updated", level, current_xp, xp_to_next_level)
	emit_signal("xp_updated", current_xp, xp_to_next_level)
