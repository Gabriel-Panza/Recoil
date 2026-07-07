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
const MAX_RECOIL_FORCE: float = 650.0
var base_recoil_force: float = 460.0
var recoil_force_bonus: float = 0.0
@export var friction: float = 760.0
var is_invulnerable: bool = false
const MOVEMENT_FORCE_COMBO_LOCK_DURATION: float = 0.2
const MOVEMENT_FORCE_CAP_BUFFER: float = 100.0
const WALL_BOUNCE_MIN_SPEED: float = 75.0
const WALL_BOUNCE_MULTIPLIER: float = 0.75
const WALL_BOUNCE_PUSH_OUT: float = 4.0
const ARENA_FORCE_CLAMP_PADDING: float = 2.0
const ARENA_FORCE_CLAMP_MIN_MARGIN: float = 6.0
const ISO_AOE_VISUAL_Y_SCALE: float = 0.65

# --- DASH ---
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 5.0
var base_dash_speed: float = 600.0
var base_dash_cooldown: float = 5.0
var dash_cooldown_reduction_bonus: float = 0.0
var dash_speed_modifiers: Dictionary = {}
const MAX_ABILITY_AREA_RADIUS: float = 180.0
const DEVOUR_RADIUS: float = MAX_ABILITY_AREA_RADIUS + 30
const SLOW_AURA_RADIUS: float = MAX_ABILITY_AREA_RADIUS
const SHOCKWAVE_RADIUS: float = MAX_ABILITY_AREA_RADIUS - 30
const SHOCKWAVE_DAMAGE_MULTIPLIER: float = 0.35
const SHOCKWAVE_DASH_DAMAGE_MULTIPLIER: float = 0.75
const EXPLOSIVE_KNOCKBACK_IMMUNITY_DURATION: float = 0.35
const EXPLOSIVE_SHOCKWAVE_COLOR: Color = Color(0.62, 0.39, 0.16, 0.72)
const EXPLOSIVE_SHOCKWAVE_PARTICLE_COLOR: Color = Color(0.76, 0.48, 0.18, 1.0)
const PASSIVE_RING_Z_INDEX: int = 10
const PASSIVE_RING_COLOR: Color = Color(0.78, 0.54, 0.18, 0.58)
const PASSIVE_RING_SOFT_COLOR: Color = Color(0.78, 0.54, 0.18, 0.42)
const PASSIVE_RING_DOT_COLOR: Color = Color(0.95, 0.7, 0.24, 0.95)
const DASH_CHARGE_RING_RADIUS: float = 24.0
const DASH_CHARGE_RING_WIDTH: float = 1.2
const DASH_CHARGE_PROGRESS_RING_WIDTH: float = 2.0
const DASH_CHARGE_ORB_RADIUS: float = 4.5
const DASH_CHARGE_ORB_ORBIT_RADIUS: float = 27.0
const AREA_FILL_ALPHA_MULTIPLIER: float = 0.2
const SHOT_COOLDOWN_BAR_SIZE: Vector2 = Vector2(28.0, 4.0)
const SHOT_COOLDOWN_BAR_OFFSET: Vector2 = Vector2(-14.0, -36.0)
const SHOT_COOLDOWN_BAR_Z_INDEX: int = 35
const SLOTH_AURA_DPS: float = 2.0
const SLOTH_FIELD_DPS: float = 5.0
const SLOTH_FIELD_TICK_INTERVAL: float = 0.1
const SLOTH_PLAYER_DOT_META: String = "player_sloth_dot_accumulator"
const DASH_COOLDOWN_REDUCTION_STEP: float = 0.05
const MAX_DASH_COOLDOWN_REDUCTION: float = 0.4
const KINETIC_RELOAD_REMAINING_COOLDOWN_REDUCTION: float = 0.35
const KINETIC_RELOAD_INTERNAL_COOLDOWN: float = 0.35
const SPLINTERED_CHAMBER_SHOT_INTERVAL: int = 8
const SPLINTERED_CHAMBER_DAMAGE_MULTIPLIER: float = 0.35
const SPLINTERED_CHAMBER_FRAGMENT_ANGLE: float = 18.0
const DAMAGE_FEEDBACK_COLOR: Color = Color(1.0, 0.1, 0.1, 1.0)
const HEAL_FEEDBACK_COLOR: Color = Color(0.1, 1.0, 0.1, 1.0)
const WRATH_OVERHEAT_SHOT_INTERVAL: int = 4
const MIRROR_SHOT_DAMAGE_MULTIPLIER: float = 0.5
const ENVY_CLONE_OFFSET: Vector2 = Vector2(58.0, 0.0)
const ENVY_CLONE_DAMAGE_MULTIPLIER: float = 0.75
const ENVY_CLONE_PLAYER_TARGET_CHANCE: float = 0.1
const ENVY_CLONE_PLAYER_DAMAGE_MULTIPLIER: float = 0.5
const ENVY_CLONE_VISUAL_MODULATE: Color = Color(0.55, 0.95, 1.0, 0.56)
const ENVY_CLONE_SHOT_COLOR: Color = Color(0.25, 0.95, 1.0, 0.9)
const GOLDEN_DEBT_ATTACK_MULTIPLIER: float = 1.2
const GOLDEN_DEBT_ATTACK_SPEED_BONUS: float = 0.1
const GOLDEN_DEBT_WAVE_HEALTH_RATIO: float = 0.05
const MAX_PROJECTILE_SIZE_MULTIPLIER: float = 2.0
const MIN_PROJECTILE_SIZE_MULTIPLIER: float = 0.5
const MAX_HEAL_AFTER_WAVE_BONUS: float = 0.15
const ARM_MUTATION_DATA = {
	"fast": {
		1: {
			"name": "Nervous Aim",
			"description": "Shots mark enemies for a few seconds. Nearby projectiles curve slightly toward marked targets."
		},
		2: {
			"name": "Rhythm Pierce",
			"description": "Every 6 shots in sequence, the next shot pierces one additional target."
		},
		3: {
			"name": "Split Trigger",
			"description": "Shots have a 40% chance to split into two angled projectiles at 75% damage each."
		}
	},
	"heavy": {
		1: {
			"name": "Impact Shard",
			"description": "The first impact of each heavy shot releases cone fragments backward."
		},
		2: {
			"name": "Execution Kick",
			"description": "Heavy-shot kills create a short wave that pushes and damages nearby enemies."
		},
		3: {
			"name": "Penitence Cannon",
			"description": "Shooting right as the cooldown ends creates a large shot that pierces and drags enemies."
		}
	},
	"unstable": {
		1: {
			"name": "Ballistic Memory",
			"description": "Ricochets leave a delayed echo that repeats part of the trajectory with low damage."
		},
		2: {
			"name": "Unstable Resonance",
			"description": "Hitting a target after a ricochet leaves a resonance. Another shot on that target detonates a short explosion."
		},
		3: {
			"name": "Errant Seeker",
			"description": "After ricocheting off a wall, shots bend slightly toward nearby enemies without perfect tracking."
		}
	}
}
const FAST_MARK_META: String = "fast_nervous_mark_until_msec"
const FAST_MARK_DURATION_MSEC: int = 3000
const FAST_HOMING_RANGE: float = 420.0
const FAST_HOMING_TURN_RATE: float = 5.4
const FAST_RHYTHM_SHOT_WINDOW_MSEC: int = 1000
const FAST_RHYTHM_SHOTS_REQUIRED: int = 6
const FAST_RHYTHM_PIERCE_BONUS: int = 1
const FAST_SPLIT_TRIGGER_CHANCE: float = 0.40
const FAST_SPLIT_TRIGGER_ANGLE: float = 15.0
const FAST_SPLIT_TRIGGER_DAMAGE_MULTIPLIER: float = 0.75
const HEAVY_IMPACT_SHARD_COUNT: int = 3
const HEAVY_IMPACT_SHARD_DAMAGE_MULTIPLIER: float = 0.3
const HEAVY_IMPACT_SHARD_ANGLE_SPREAD: float = 45.0
const HEAVY_EXECUTION_RADIUS: float = 128.0
const HEAVY_EXECUTION_DAMAGE_MULTIPLIER: float = 0.22
const HEAVY_EXECUTION_KNOCKBACK_FORCE: float = 340.0
const HEAVY_PENITENCE_READY_WINDOW: float = 0.34
const HEAVY_PENITENCE_DAMAGE_MULTIPLIER: float = 1.1
const HEAVY_PENITENCE_PIERCE_BONUS: int = 2
const HEAVY_PENITENCE_DRAG_RADIUS: float = 145.0
const HEAVY_PENITENCE_DRAG_DAMAGE_MULTIPLIER: float = 0.18
const HEAVY_PENITENCE_DRAG_FORCE: float = 260.0
const UNSTABLE_RESONANCE_META: String = "unstable_resonance_until_msec"
const UNSTABLE_MEMORY_ECHO_DELAY: float = 0.12
const UNSTABLE_MEMORY_ECHO_DAMAGE_MULTIPLIER: float = 0.35
const UNSTABLE_MEMORY_ECHO_SPEED_MULTIPLIER: float = 0.72
const UNSTABLE_RESONANCE_DURATION_MSEC: int = 2500
const UNSTABLE_RESONANCE_RADIUS: float = 105.0
const UNSTABLE_RESONANCE_DAMAGE_MULTIPLIER: float = 0.55
const UNSTABLE_RICOCHET_HOMING_RANGE: float = 520.0
const UNSTABLE_RICOCHET_HOMING_TURN_RATE: float = 2.2
const UNSTABLE_RICOCHET_HOMING_MAX_TURN: float = 0.1

# --- TIRO ---
@export var pistol_bullet_scene: PackedScene
var shot_count = 1
var spread_angle = 15.0 
var projectile_size_bonus: float = 0.0
var heal_after_wave_bonus: float = 0.0
var current_arm_id: String = ""
var arm_attack_speed_upgrade_multiplier: float = 1.0
var unstable_arm_projectiles_enabled: bool = false
var arm_mutation_tier: int = 0
var fast_rhythm_combo: int = 0
var fast_last_shot_msec: int = -1
var heavy_perfect_window_remaining: float = 0.0

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
var current_boss_passive_options: Array = []
const MAX_BOSS_PASSIVE_OPTIONS: int = 2
const SHIELD_COOLDOWN: float = 12.0
const SHIELD_VISUAL_RADIUS: float = 24.0
var shield_protection_enabled: bool = false
var has_shield: bool = false
var shield_cooldown_remaining: float = 0.0
var shield_vfx: Node2D
var recoil_explosion_enabled: bool = false
var offensive_dash_enabled: bool = false
var kinetic_reload_enabled: bool = false
var kinetic_reload_cooldown_remaining: float = 0.0
var splintered_chamber_enabled: bool = false
var splintered_chamber_shot_count: int = 0
var max_dash_charges: int = 1
var double_dash_charges: int = 1
var reroll_tokens: int = 1
var sloth_slow_aura_enabled: bool = false
var gluttony_heal_kill_enabled: bool = false
var envy_mirror_shot_enabled: bool = false
var envy_clone_active: bool = false
var wrath_overheat_enabled: bool = false
var wrath_shot_count: int = 0
var lust_for_vengeance_enabled: bool = false
var greed_cursed_level_enabled: bool = false
var healing_received_multiplier: float = 1.0
var damage_taken_base_multiplier: float = 1.0
var temporary_damage_taken_multiplier: float = 1.0
var damage_taken_multiplier: float = 1.0
var temporary_attack_multiplier: float = 1.0
var special_level_up_chance_bonus: float = 0.0
var sloth_aura_vfx: Node2D
var envy_clone_vfx: Node2D
var envy_clone_fire_timer: float = 0.0
var passive_status_vfx: Dictionary = {}
var debug_invincible_enabled: bool = false
var run_upgrade_history: Array = []
var run_contract_history: Array = []
var run_damage_taken_total: int = 0
var run_damage_taken_by_source: Dictionary = {}
var run_kills_total: int = 0
var run_elite_kills_total: int = 0
var run_lucky_upgrade_count: int = 0
var run_cursed_upgrade_count: int = 0
var run_end_elapsed_seconds: float = 0.0
var run_end_reason: String = ""
var last_damage_source_name: String = "None"
var last_damage_source_amount: int = 0

# --- SISTEMA DE DANO CONTÍNUO ---
var enemies_in_contact: Array = []
var contact_damage_timer: Timer

# --- Sprites ---
var aparencia
var health_feedback_tween: Tween
var health_feedback_base_modulate: Color = Color.WHITE

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
signal rerolls_updated(reroll_tokens)

# --- ESTADOS DO JOGADOR ---
var can_shoot: bool = true
var can_dash: bool = true
var is_dashing: bool = false
var movement_force_combo_lock_remaining: float = 0.0
var knockback_immunity_remaining: float = 0.0

# --- TIMERS ---
var shoot_timer: Timer
var dash_cd_timer: Timer
var shot_cooldown_bar: ProgressBar

# --- Paths ---
const PAUSE_CONTROL_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/PauseControl"
const GAME_OVER_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/PauseControl/GameOver"
const GAME_WIN_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/PauseControl/GameWin"

var pause_control: Control
var game_over: Panel
var game_win: Panel

var type_animation = "walk_down"

func _ready() -> void:
	z_index = Global.CHARACTER_RENDER_Z_INDEX
	z_as_relative = false
	base_fire_rate = STARTING_FIRE_RATE
	fire_rate = STARTING_FIRE_RATE
	_recalculate_fire_rate()
	base_recoil_force = recoil_force
	_recalculate_recoil_force()
	base_dash_speed = dash_speed
	base_dash_cooldown = dash_cooldown
	_recalculate_dash_cooldown()
	aparencia = get_node_or_null("Aparencia")
	if aparencia:
		health_feedback_base_modulate = aparencia.modulate
	pause_control = get_node_or_null(PAUSE_CONTROL_PATH)
	game_over = get_node_or_null(GAME_OVER_PATH)
	game_win = get_node_or_null(GAME_WIN_PATH)

	shoot_timer = Timer.new()
	shoot_timer.one_shot = true
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	add_child(shoot_timer)
	_setup_shot_cooldown_bar()
	
	dash_cd_timer = Timer.new()
	dash_cd_timer.one_shot = true
	dash_cd_timer.timeout.connect(_on_dash_cd_timer_timeout)
	add_child(dash_cd_timer)

	contact_damage_timer = Timer.new()
	contact_damage_timer.wait_time = 0.4
	contact_damage_timer.one_shot = false
	contact_damage_timer.timeout.connect(_on_contact_damage_timer_timeout)
	add_child(contact_damage_timer)

## Applies the selected starting arm and resets arm-dependent upgrade scaling.
func apply_starting_arm(arm_id: String) -> void:
	if not Global.STARTING_ARM_DATA.has(arm_id):
		return

	var arm_data: Dictionary = Global.STARTING_ARM_DATA[arm_id]
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
	arm_mutation_tier = 0
	_reset_arm_mutation_runtime_state()
	_recalculate_fire_rate()
	_recalculate_recoil_force()
	emit_signal("stats_updated")

## Returns the display name of the arm selected at the start of the run.
func get_starting_arm_name() -> String:
	if current_arm_id == "" or not Global.STARTING_ARM_DATA.has(current_arm_id):
		return I18n.t("arm.none")

	return I18n.arm_name(current_arm_id, str(Global.STARTING_ARM_DATA[current_arm_id]["name"]))

func add_attack_speed_bonus(amount: float) -> void:
	if amount > 0.0 and not can_upgrade_attack_speed():
		return

	attack_speed_bonus += amount * arm_attack_speed_upgrade_multiplier
	_recalculate_fire_rate()
	emit_signal("stats_updated")

func add_raw_attack_speed_bonus(amount: float) -> void:
	attack_speed_bonus = max(attack_speed_bonus + amount, -0.95)
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
	if Global.STARTING_ARM_DATA.has(current_arm_id):
		return I18n.arm_name(current_arm_id, str(Global.STARTING_ARM_DATA[current_arm_id].get("name", current_arm_id)))
	return I18n.t("common.base")

func apply_arm_mutation(target_tier: int) -> bool:
	if current_arm_id == "" or not ARM_MUTATION_DATA.has(current_arm_id):
		return false

	var clamped_tier = clampi(target_tier, 1, 3)
	if clamped_tier <= arm_mutation_tier:
		return false

	for tier in range(arm_mutation_tier + 1, clamped_tier + 1):
		arm_mutation_tier = tier
		_record_arm_mutation_unlock(tier)

	_reset_arm_mutation_runtime_state()
	_spawn_burst_particles(global_position, _get_arm_mutation_color(current_arm_id), 34, 0.38, 170.0)
	emit_signal("stats_updated")
	return true

func get_arm_mutation_summaries() -> Array:
	var summaries: Array = []
	if current_arm_id == "" or not ARM_MUTATION_DATA.has(current_arm_id):
		return summaries

	for tier in range(1, arm_mutation_tier + 1):
		var mutation_data = _get_arm_mutation_data(current_arm_id, tier)
		if mutation_data.is_empty():
			continue
		summaries.append({
			"id": "arm_mutation_%s_%d" % [current_arm_id, tier],
			"name": I18n.mutation_name(current_arm_id, tier, str(mutation_data.get("name", "Mutation"))),
			"description": I18n.mutation_description(current_arm_id, tier, str(mutation_data.get("description", "")))
		})
	return summaries

func _record_arm_mutation_unlock(tier: int) -> void:
	var mutation_data = _get_arm_mutation_data(current_arm_id, tier)
	if mutation_data.is_empty():
		return

	record_upgrade({
		"id": "arm_mutation_%s_%d" % [current_arm_id, tier],
		"text": "Arm Mutation %d: %s" % [tier, I18n.mutation_name(current_arm_id, tier, str(mutation_data.get("name", "Mutation")))],
		"description": I18n.mutation_description(current_arm_id, tier, str(mutation_data.get("description", ""))),
		"rarity": "arm_mutation"
	})

func _get_arm_mutation_data(arm_id: String, tier: int) -> Dictionary:
	if not ARM_MUTATION_DATA.has(arm_id):
		return {}

	var arm_data = ARM_MUTATION_DATA[arm_id]
	if not arm_data.has(tier):
		return {}
	return arm_data[tier]

func _reset_arm_mutation_runtime_state() -> void:
	fast_rhythm_combo = 0
	fast_last_shot_msec = -1
	heavy_perfect_window_remaining = 0.0

func _get_arm_mutation_color(arm_id: String) -> Color:
	match arm_id:
		"fast":
			return Color(0.92, 0.95, 0.22, 0.9)
		"heavy":
			return Color(0.95, 0.5, 0.2, 0.9)
		"unstable":
			return Color(0.72, 0.28, 1.0, 0.92)
	return Color(1.0, 0.75, 0.3, 0.9)

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

func add_dash_cooldown_reduction_bonus(amount: float = DASH_COOLDOWN_REDUCTION_STEP) -> void:
	if not can_upgrade_dash_cooldown_reduction():
		return

	dash_cooldown_reduction_bonus = min(dash_cooldown_reduction_bonus + amount, MAX_DASH_COOLDOWN_REDUCTION)
	_recalculate_dash_cooldown()
	emit_signal("stats_updated")

func can_upgrade_dash_cooldown_reduction() -> bool:
	return dash_cooldown_reduction_bonus < MAX_DASH_COOLDOWN_REDUCTION - 0.0001

func get_dash_cooldown_reduction_percent() -> float:
	return dash_cooldown_reduction_bonus * 100.0

func get_max_dash_cooldown_reduction_percent() -> float:
	return MAX_DASH_COOLDOWN_REDUCTION * 100.0

func get_dash_cooldown() -> float:
	return dash_cooldown

func get_base_dash_cooldown() -> float:
	return base_dash_cooldown

func _recalculate_dash_cooldown() -> void:
	var previous_dash_cooldown = dash_cooldown
	var reduction = clamp(dash_cooldown_reduction_bonus, 0.0, MAX_DASH_COOLDOWN_REDUCTION)
	dash_cooldown = max(base_dash_cooldown * (1.0 - reduction), 0.05)
	if is_instance_valid(dash_cd_timer) and not dash_cd_timer.is_stopped() and previous_dash_cooldown > 0.0:
		var recharge_progress = clamp(1.0 - dash_cd_timer.time_left / previous_dash_cooldown, 0.0, 1.0)
		dash_cd_timer.start(max(dash_cooldown * (1.0 - recharge_progress), 0.01))

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

func add_healing_received_multiplier_bonus(amount: float) -> void:
	healing_received_multiplier *= max(1.0 + amount, 0.0)
	emit_signal("stats_updated")

func get_healing_received_percent() -> float:
	return healing_received_multiplier * 100.0

func add_damage_taken_multiplier_bonus(amount: float) -> void:
	damage_taken_base_multiplier *= max(1.0 + amount, 0.01)
	_recalculate_damage_taken_multiplier()
	emit_signal("stats_updated")

func _set_temporary_damage_taken_multiplier(multiplier: float) -> void:
	temporary_damage_taken_multiplier = max(multiplier, 0.0)
	_recalculate_damage_taken_multiplier()

func _recalculate_damage_taken_multiplier() -> void:
	damage_taken_multiplier = damage_taken_base_multiplier * temporary_damage_taken_multiplier

func add_special_level_up_chance_bonus(amount: float) -> void:
	special_level_up_chance_bonus += max(amount, 0.0)
	emit_signal("stats_updated")

func get_special_level_up_roll_chance(base_chance: float) -> float:
	return clamp(base_chance * max(1.0 + special_level_up_chance_bonus, 0.0), 0.0, 1.0)

func get_reroll_tokens() -> int:
	return reroll_tokens

func add_reroll_tokens(amount: int) -> void:
	if amount <= 0:
		return

	reroll_tokens += amount
	emit_signal("rerolls_updated", reroll_tokens)
	emit_signal("stats_updated")

func consume_reroll_token() -> bool:
	if reroll_tokens <= 0:
		return false

	reroll_tokens -= 1
	emit_signal("rerolls_updated", reroll_tokens)
	emit_signal("stats_updated")
	return true

func grant_bonus_level_up(context: String = "normal", boss_pecado: int = 0) -> void:
	if upando:
		return

	xp_to_next_level = max(xp_to_next_level, 1)
	current_xp = xp_to_next_level
	level_up_context = context
	level_up_boss_pecado = boss_pecado
	upando = true
	level_up()

func get_available_contract_stat_ids() -> Array:
	var stat_ids = ["health", "attack"]
	if can_roll_attack_speed_upgrade():
		stat_ids.append("attack_speed")
	if can_roll_recoil_force_upgrade():
		stat_ids.append("recoil")
	return stat_ids

func apply_contract_stat_reward(stat_id: String) -> Dictionary:
	var reward_data = {
		"id": "contract_stat_%s" % stat_id,
		"text": I18n.option_text("contract_stat_%s" % stat_id, "Contract Stat"),
		"description": I18n.t("contract.stat_description"),
		"rarity": "contract_reward"
	}

	match stat_id:
		"health":
			var health_bonus = 0.08
			var health_gain = current_health * health_bonus
			max_health = int(round(float(max_health) * (1.0 + health_bonus)))
			heal(health_gain)
			reward_data["text"] = I18n.option_text("contract_stat_health")
		"attack":
			attack_damage += attack_damage * 0.10
			reward_data["text"] = I18n.option_text("contract_stat_attack")
		"attack_speed":
			add_attack_speed_bonus(0.08)
			reward_data["text"] = I18n.option_text("contract_stat_attack_speed")
		"recoil":
			add_recoil_force_bonus(0.08)
			reward_data["text"] = I18n.option_text("contract_stat_recoil")
		_:
			return {}

	record_upgrade(reward_data)
	emit_signal("hp_updated", current_health, max_health)
	emit_signal("stats_updated")
	return reward_data

func set_debug_invincible_enabled(is_enabled: bool) -> void:
	debug_invincible_enabled = is_enabled
	emit_signal("stats_updated")

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

func enable_kinetic_reload() -> void:
	kinetic_reload_enabled = true
	kinetic_reload_cooldown_remaining = 0.0
	emit_signal("stats_updated")

func disable_kinetic_reload() -> void:
	kinetic_reload_enabled = false
	kinetic_reload_cooldown_remaining = 0.0
	emit_signal("stats_updated")

func enable_splintered_chamber() -> void:
	splintered_chamber_enabled = true
	splintered_chamber_shot_count = 0
	emit_signal("stats_updated")

func disable_splintered_chamber() -> void:
	splintered_chamber_enabled = false
	splintered_chamber_shot_count = 0
	emit_signal("stats_updated")

func reset_periodic_shot_counters() -> void:
	wrath_shot_count = 0
	splintered_chamber_shot_count = 0
	_reset_arm_mutation_runtime_state()

func enable_golden_debt() -> void:
	if greed_cursed_level_enabled:
		return

	greed_cursed_level_enabled = true
	attack_damage *= GOLDEN_DEBT_ATTACK_MULTIPLIER
	add_raw_attack_speed_bonus(GOLDEN_DEBT_ATTACK_SPEED_BONUS)
	_spawn_burst_particles(global_position, Color(1.0, 0.72, 0.12, 0.92), 22, 0.28, 115.0)
	emit_signal("stats_updated")

func disable_golden_debt() -> void:
	if not greed_cursed_level_enabled:
		return

	greed_cursed_level_enabled = false
	attack_damage /= GOLDEN_DEBT_ATTACK_MULTIPLIER
	add_raw_attack_speed_bonus(-GOLDEN_DEBT_ATTACK_SPEED_BONUS)
	emit_signal("stats_updated")

func apply_golden_debt_wave_cost() -> void:
	if not greed_cursed_level_enabled or current_health <= 0:
		return

	var debt_damage = max(1.0, float(current_health) * GOLDEN_DEBT_WAVE_HEALTH_RATIO)
	_take_direct_damage(debt_damage)
	if current_health > 0:
		_spawn_burst_particles(global_position, Color(1.0, 0.72, 0.12, 0.82), 18, 0.24, 95.0)

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

func _update_knockback_immunity(delta: float) -> void:
	if knockback_immunity_remaining > 0.0:
		knockback_immunity_remaining = max(knockback_immunity_remaining - delta, 0.0)

func _update_kinetic_reload(delta: float) -> void:
	if kinetic_reload_cooldown_remaining > 0.0:
		kinetic_reload_cooldown_remaining = max(kinetic_reload_cooldown_remaining - delta, 0.0)

func _grant_knockback_immunity(duration: float) -> void:
	knockback_immunity_remaining = max(knockback_immunity_remaining, duration)

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
	if is_dashing or knockback_immunity_remaining > 0.0:
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
		_try_trigger_kinetic_reload()
		return

func _is_wall_collision(collision: KinematicCollision2D) -> bool:
	var collider = collision.get_collider()
	if collider == null:
		return false
	var collision_layer = collider.get("collision_layer")
	if collision_layer == null:
		return false

	return (int(collision_layer) & Global.WALL_LAYER_MASK) != 0

func _take_direct_damage(amount: float) -> void:
	var damage_taken = int(round(amount))
	current_health -= damage_taken
	_record_damage_taken(damage_taken, null)
	emit_signal("hp_updated", current_health, max_health)
	_play_damage_feedback()
	if current_health <= 0:
		capture_run_end("Defeat")
		die()

func _physics_process(delta: float) -> void:
	_update_active_ability_cooldowns(delta)
	_update_shield_protection(delta)
	_update_movement_force_combo_lock(delta)
	_update_knockback_immunity(delta)
	_update_kinetic_reload(delta)
	if heavy_perfect_window_remaining > 0.0:
		heavy_perfect_window_remaining = max(heavy_perfect_window_remaining - delta, 0.0)
	_update_shot_cooldown_bar()

	var mouse_pos = get_global_mouse_position()
	var look_direction = global_position.direction_to(mouse_pos)
	_update_direction_animation(look_direction)
	
	if pause_control.can_move:
		# Dash na direção do mouse
		if Input.is_action_just_pressed("dash") and _can_perform_dash():
			perform_dash(look_direction)

		# Atirar / Movimentação por Recuo
		if Input.is_action_pressed("shoot") and can_shoot and not is_dashing:
			shoot(look_direction)

		if Input.is_action_just_pressed("active_e"):
			use_active_ability("E")

		if Input.is_action_just_pressed("active_r"):
			use_active_ability("R")

	if sloth_slow_aura_enabled:
		_ensure_sloth_slow_aura_vfx()
		_apply_sloth_slow_aura(delta)

	if envy_clone_active:
		_update_envy_clone_active(delta)

	_update_passive_status_vfx(delta)

	# Aplicar Atrito se não estiver no meio de um dash
	if not is_dashing:
		if velocity.length() > 0:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	var velocity_before_slide = velocity
	move_and_slide()
	_apply_wall_bounce(velocity_before_slide)
	_force_clamp_to_current_arena()

func shoot(direction: Vector2) -> void:
	if not pistol_bullet_scene:
		return
	
	can_shoot = false
	shoot_timer.start(fire_rate)
	_update_shot_cooldown_bar()
	
	var mouse_pos = get_global_mouse_position()
	var base_direction = (mouse_pos - global_position).normalized()
	type_animation = _get_animation_for_direction(base_direction)
	var base_angle = base_direction.angle()
	var shot_damage = _get_current_shot_damage()
	var mutation_shot = _prepare_arm_mutation_shot(base_angle, shot_damage)
	shot_damage = float(mutation_shot.get("damage", shot_damage))
	var projectile_flags: Dictionary = mutation_shot.get("projectile_flags", {})
	var skip_base_projectiles = bool(mutation_shot.get("skip_base_projectiles", false))
	var base_shot_count = shot_count if not skip_base_projectiles else 0
	
	for i in range(base_shot_count):
		# Calcula o deslocamento do ângulo dado que podemos ter multiplos tiros
		var angle_offset = deg_to_rad((i - (shot_count - 1) / 2.0) * spread_angle)
		var final_angle = base_angle + angle_offset
		_spawn_projectile(global_position, final_angle, shot_damage, false, Color(0.0, 0.0, 0.0, 0.0), projectile_flags.duplicate())

		if envy_mirror_shot_enabled:
			_spawn_mirror_shot(global_position, final_angle, shot_damage)

	for extra_projectile in mutation_shot.get("extra_projectiles", []):
		if not (extra_projectile is Dictionary):
			continue
		var extra_flags: Dictionary = extra_projectile.get("projectile_flags", {})
		_spawn_projectile(
			global_position,
			float(extra_projectile.get("angle", base_angle)),
			shot_damage * float(extra_projectile.get("damage_multiplier", 1.0)),
			false,
			extra_projectile.get("color", Color(0.0, 0.0, 0.0, 0.0)),
			extra_flags.duplicate()
		)

	_try_trigger_splintered_chamber(base_angle, shot_damage)
	_apply_recoil_impulse(direction)
	if recoil_explosion_enabled:
		_trigger_recoil_explosion()

func _prepare_arm_mutation_shot(base_angle: float, shot_damage: float) -> Dictionary:
	var result = {
		"damage": shot_damage,
		"projectile_flags": {},
		"extra_projectiles": [],
		"skip_base_projectiles": false
	}

	match current_arm_id:
		"fast":
			_prepare_fast_mutation_shot(result, base_angle)
		"heavy":
			_prepare_heavy_mutation_shot(result)
	return result

func _prepare_fast_mutation_shot(result: Dictionary, base_angle: float) -> void:
	if arm_mutation_tier < 2:
		return

	var projectile_flags: Dictionary = result["projectile_flags"]
	var now_msec = Time.get_ticks_msec()
	if fast_last_shot_msec >= 0 and now_msec - fast_last_shot_msec <= FAST_RHYTHM_SHOT_WINDOW_MSEC:
		fast_rhythm_combo += 1
	else:
		fast_rhythm_combo = 1
	fast_last_shot_msec = now_msec

	if fast_rhythm_combo >= FAST_RHYTHM_SHOTS_REQUIRED:
		fast_rhythm_combo = 0
		projectile_flags["pierce_remaining_bonus"] = int(projectile_flags.get("pierce_remaining_bonus", 0)) + FAST_RHYTHM_PIERCE_BONUS
		projectile_flags["vfx_color"] = Color(0.95, 1.0, 0.24, 0.95)
		_spawn_burst_particles(global_position, Color(0.92, 1.0, 0.28, 0.72), 10, 0.16, 70.0)

	if arm_mutation_tier < 3:
		return

	if randf() > FAST_SPLIT_TRIGGER_CHANCE:
		return

	result["skip_base_projectiles"] = true
	var split_angle = deg_to_rad(FAST_SPLIT_TRIGGER_ANGLE)
	for angle_offset in [-split_angle, split_angle]:
		var split_flags = projectile_flags.duplicate()
		split_flags["split_trigger"] = true
		split_flags["projectile_speed_multiplier"] = float(split_flags.get("projectile_speed_multiplier", 1.0)) * 1.06
		result["extra_projectiles"].append({
			"angle": base_angle + angle_offset,
			"damage_multiplier": FAST_SPLIT_TRIGGER_DAMAGE_MULTIPLIER,
			"color": Color(0.25, 0.95, 1.0, 0.92),
			"projectile_flags": split_flags
		})
	_spawn_burst_particles(global_position, Color(0.25, 0.95, 1.0, 0.72), 8, 0.14, 64.0)

func _prepare_heavy_mutation_shot(result: Dictionary) -> void:
	if arm_mutation_tier < 3 or heavy_perfect_window_remaining <= 0.0:
		return

	heavy_perfect_window_remaining = 0.0
	result["damage"] = float(result.get("damage", attack_damage)) * HEAVY_PENITENCE_DAMAGE_MULTIPLIER
	var projectile_flags: Dictionary = result["projectile_flags"]
	projectile_flags["heavy_penitence"] = true
	projectile_flags["pierce_remaining_bonus"] = int(projectile_flags.get("pierce_remaining_bonus", 0)) + HEAVY_PENITENCE_PIERCE_BONUS
	projectile_flags["scale_multiplier"] = float(projectile_flags.get("scale_multiplier", 1.0)) * 1.35
	projectile_flags["projectile_speed_multiplier"] = float(projectile_flags.get("projectile_speed_multiplier", 1.0)) * 0.92
	projectile_flags["vfx_color"] = Color(1.0, 0.82, 0.34, 0.96)
	_spawn_burst_particles(global_position, Color(1.0, 0.78, 0.28, 0.9), 18, 0.22, 120.0)

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

func _try_trigger_splintered_chamber(base_angle: float, shot_damage: float) -> void:
	if not splintered_chamber_enabled:
		return

	splintered_chamber_shot_count += 1
	if splintered_chamber_shot_count < SPLINTERED_CHAMBER_SHOT_INTERVAL:
		return

	splintered_chamber_shot_count = 0
	var fragment_damage = shot_damage * SPLINTERED_CHAMBER_DAMAGE_MULTIPLIER
	var fragment_angle = deg_to_rad(SPLINTERED_CHAMBER_FRAGMENT_ANGLE)
	_spawn_projectile(global_position, base_angle - fragment_angle, fragment_damage, false, Color(0.95, 0.55, 0.18, 0.9))
	_spawn_projectile(global_position, base_angle + fragment_angle, fragment_damage, false, Color(0.95, 0.55, 0.18, 0.9))
	_spawn_burst_particles(global_position, Color(0.95, 0.55, 0.18, 0.82), 12, 0.18, 85.0)

func _update_envy_clone_active(delta: float) -> void:
	if not is_instance_valid(envy_clone_vfx):
		return

	_sync_player_mirror_visual(envy_clone_vfx)
	envy_clone_fire_timer = max(envy_clone_fire_timer - delta, 0.0)
	if envy_clone_fire_timer > 0.0:
		return

	_fire_envy_clone_auto_shot()
	envy_clone_fire_timer = max(fire_rate, min_fire_rate)

func _fire_envy_clone_auto_shot() -> void:
	var clone_position = envy_clone_vfx.global_position if is_instance_valid(envy_clone_vfx) else global_position + ENVY_CLONE_OFFSET
	var target_data = _get_envy_clone_auto_target(clone_position)
	if target_data.is_empty():
		return

	var aim_direction = target_data["direction"] as Vector2
	if aim_direction == Vector2.ZERO:
		return

	_aim_player_mirror_visual(envy_clone_vfx, aim_direction)
	var base_angle = aim_direction.angle()
	var shot_damage = _get_envy_clone_shot_damage() * float(target_data["damage_multiplier"])
	var can_hit_player = bool(target_data["can_hit_player"])
	for i in range(shot_count):
		var angle_offset = deg_to_rad((i - (shot_count - 1) / 2.0) * spread_angle)
		_spawn_projectile(clone_position, base_angle + angle_offset, shot_damage, can_hit_player, ENVY_CLONE_SHOT_COLOR)

func _get_envy_clone_auto_target(clone_position: Vector2) -> Dictionary:
	if randf() < ENVY_CLONE_PLAYER_TARGET_CHANCE:
		var player_direction = clone_position.direction_to(global_position)
		if player_direction != Vector2.ZERO:
			return {
				"direction": player_direction,
				"can_hit_player": true,
				"damage_multiplier": ENVY_CLONE_PLAYER_DAMAGE_MULTIPLIER
			}

	var enemy = _get_nearest_envy_clone_enemy_target(clone_position)
	if enemy != null:
		var enemy_direction = clone_position.direction_to(enemy.global_position)
		if enemy_direction != Vector2.ZERO:
			return {
				"direction": enemy_direction,
				"can_hit_player": false,
				"damage_multiplier": ENVY_CLONE_DAMAGE_MULTIPLIER
			}

	return {}

func _get_nearest_envy_clone_enemy_target(clone_position: Vector2) -> Node2D:
	var closest_enemy: Node2D = null
	var closest_distance = INF
	for enemy in get_tree().get_nodes_in_group(Global.GROUP_ENEMY):
		if not is_instance_valid(enemy) or not (enemy is Node2D):
			continue
		if enemy.get("is_dead") != null and bool(enemy.get("is_dead")):
			continue

		var enemy_node = enemy as Node2D
		var distance = clone_position.distance_squared_to(enemy_node.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy_node

	return closest_enemy

func _get_envy_clone_shot_damage() -> float:
	var damage = attack_damage * temporary_attack_multiplier
	if lust_for_vengeance_enabled and current_health >= max_health:
		damage *= 1.75
	return damage

func _spawn_projectile(spawn_position: Vector2, angle: float, projectile_damage: float, can_hit_player: bool = false, projectile_vfx_color: Color = Color(0.0, 0.0, 0.0, 0.0), projectile_flags: Dictionary = {}) -> Node:
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
		bullet.add_to_group(Global.GROUP_ENEMY_PROJECTILE)
	elif not bool(projectile_flags.get("skip_arm_mutations", false)):
		_configure_current_arm_projectile(bullet)
	_apply_projectile_flags(bullet, projectile_flags)

	var projectile_parent = _get_vfx_parent()
	if projectile_parent == null:
		bullet.queue_free()
		return null

	projectile_parent.add_child(bullet)
	return bullet

func _configure_current_arm_projectile(bullet: Node) -> void:
	match current_arm_id:
		"fast":
			_configure_fast_projectile(bullet)
		"heavy":
			_configure_heavy_projectile(bullet)
		"unstable":
			if unstable_arm_projectiles_enabled:
				_configure_unstable_projectile(bullet)

func _configure_fast_projectile(bullet: Node) -> void:
	if arm_mutation_tier < 1:
		return

	bullet.set_meta("fast_mark_on_hit", true)
	bullet.set_meta("fast_homing_enabled", true)
	bullet.set_meta("vfx_color", Color(0.95, 0.95, 0.24, 0.92))

func _configure_heavy_projectile(bullet: Node) -> void:
	if arm_mutation_tier >= 1:
		bullet.set_meta("heavy_impact_shards_enabled", true)
	if arm_mutation_tier >= 2:
		bullet.set_meta("heavy_execution_blast_enabled", true)

func _configure_unstable_projectile(bullet: Node) -> void:
	bullet.set_meta("pierce_remaining", 1)
	bullet.set_meta("ricochet_remaining", 1)
	bullet.set_meta("risk_after_ricochet", true)
	bullet.set_meta("vfx_color", Color(0.6, 0.2, 1.0, 0.95))
	if arm_mutation_tier >= 1:
		bullet.set_meta("unstable_memory_echo", true)
	if arm_mutation_tier >= 2:
		bullet.set_meta("unstable_resonance_enabled", true)
	if arm_mutation_tier >= 3:
		bullet.set_meta("unstable_ricochet_homing_enabled", true)

func _apply_projectile_flags(bullet: Node, projectile_flags: Dictionary) -> void:
	if projectile_flags.is_empty():
		return

	if projectile_flags.has("pierce_remaining_bonus"):
		var pierce_bonus = int(projectile_flags.get("pierce_remaining_bonus", 0))
		if pierce_bonus != 0:
			bullet.set_meta("pierce_remaining", int(bullet.get_meta("pierce_remaining", 0)) + pierce_bonus)

	if projectile_flags.has("scale_multiplier"):
		bullet.scale *= float(projectile_flags.get("scale_multiplier", 1.0))

	if projectile_flags.has("projectile_speed_multiplier"):
		bullet.set_meta("projectile_speed_multiplier", float(projectile_flags.get("projectile_speed_multiplier", 1.0)))

	for key in projectile_flags.keys():
		var key_name = str(key)
		if key_name in ["skip_arm_mutations", "pierce_remaining_bonus", "scale_multiplier", "projectile_speed_multiplier"]:
			continue
		bullet.set_meta(key_name, projectile_flags[key])

func get_fast_mutation_homing_direction(projectile_position: Vector2, current_direction: Vector2, delta: float) -> Vector2:
	if current_arm_id != "fast" or arm_mutation_tier < 1 or current_direction == Vector2.ZERO:
		return current_direction

	var target = _get_best_fast_marked_target(projectile_position, current_direction)
	if target == null:
		return current_direction

	var target_direction = projectile_position.direction_to(target.global_position)
	if target_direction == Vector2.ZERO:
		return current_direction

	var turn_amount = clampf(FAST_HOMING_TURN_RATE * delta, 0.0, 0.24)
	return current_direction.lerp(target_direction, turn_amount).normalized()

func get_unstable_ricochet_homing_direction(projectile_position: Vector2, current_direction: Vector2, delta: float) -> Vector2:
	if current_arm_id != "unstable" or arm_mutation_tier < 3 or current_direction == Vector2.ZERO:
		return current_direction

	var target = _get_best_unstable_ricochet_target(projectile_position, current_direction)
	if target == null:
		return current_direction

	var target_direction = projectile_position.direction_to(target.global_position)
	if target_direction == Vector2.ZERO:
		return current_direction

	var turn_amount = clampf(UNSTABLE_RICOCHET_HOMING_TURN_RATE * delta, 0.0, UNSTABLE_RICOCHET_HOMING_MAX_TURN)
	return current_direction.lerp(target_direction, turn_amount).normalized()

func _get_best_fast_marked_target(projectile_position: Vector2, current_direction: Vector2) -> Node2D:
	var now_msec = Time.get_ticks_msec()
	var best_target: Node2D = null
	var best_score = INF
	var max_distance_sq = FAST_HOMING_RANGE * FAST_HOMING_RANGE

	for enemy in get_tree().get_nodes_in_group(Global.GROUP_ENEMY):
		if not is_instance_valid(enemy) or not (enemy is Node2D):
			continue
		if enemy.get("is_dead") != null and bool(enemy.get("is_dead")):
			continue

		var mark_until = int(enemy.get_meta(FAST_MARK_META, 0))
		if mark_until <= now_msec:
			if enemy.has_meta(FAST_MARK_META):
				enemy.remove_meta(FAST_MARK_META)
			continue

		var enemy_node = enemy as Node2D
		var to_enemy = projectile_position.direction_to(enemy_node.global_position)
		if to_enemy == Vector2.ZERO:
			continue

		var distance_sq = projectile_position.distance_squared_to(enemy_node.global_position)
		if distance_sq > max_distance_sq:
			continue

		var alignment = current_direction.normalized().dot(to_enemy)
		if alignment < -0.2:
			continue

		var score = distance_sq / max(alignment + 1.1, 0.1)
		if score < best_score:
			best_score = score
			best_target = enemy_node

	return best_target

func _get_best_unstable_ricochet_target(projectile_position: Vector2, current_direction: Vector2) -> Node2D:
	var best_target: Node2D = null
	var best_score = INF
	var max_distance_sq = UNSTABLE_RICOCHET_HOMING_RANGE * UNSTABLE_RICOCHET_HOMING_RANGE
	var normalized_direction = current_direction.normalized()

	for enemy in get_tree().get_nodes_in_group(Global.GROUP_ENEMY):
		if not is_instance_valid(enemy) or not (enemy is Node2D):
			continue
		if enemy.get("is_dead") != null and bool(enemy.get("is_dead")):
			continue

		var enemy_node = enemy as Node2D
		var to_enemy = projectile_position.direction_to(enemy_node.global_position)
		if to_enemy == Vector2.ZERO:
			continue

		var distance_sq = projectile_position.distance_squared_to(enemy_node.global_position)
		if distance_sq > max_distance_sq:
			continue

		var alignment = normalized_direction.dot(to_enemy)
		if alignment < -0.1:
			continue

		var score = distance_sq / max(alignment + 1.05, 0.1)
		if score < best_score:
			best_score = score
			best_target = enemy_node

	return best_target

func on_player_projectile_hit_enemy(enemy: Node, projectile: Node, dealt_damage: float) -> void:
	if not is_instance_valid(enemy) or not is_instance_valid(projectile):
		return

	var hit_position = _get_node_global_position(enemy, global_position)
	if bool(projectile.get_meta("fast_mark_on_hit", false)):
		_apply_fast_nervous_mark(enemy)

	if bool(projectile.get_meta("heavy_impact_shards_enabled", false)):
		_try_spawn_heavy_impact_shards(projectile, hit_position, dealt_damage)

	if bool(projectile.get_meta("heavy_execution_blast_enabled", false)) and _is_enemy_dead(enemy):
		_trigger_heavy_execution_blast(hit_position, dealt_damage)

	if bool(projectile.get_meta("heavy_penitence", false)):
		_trigger_heavy_penitence_drag(hit_position, _get_projectile_direction(projectile), dealt_damage)

	if bool(projectile.get_meta("unstable_resonance_enabled", false)):
		_handle_unstable_resonance_hit(enemy, projectile, dealt_damage)

func on_player_projectile_ricochet(projectile: Node, ricochet_position: Vector2, incoming_direction: Vector2, outgoing_direction: Vector2) -> void:
	if not is_instance_valid(projectile):
		return

	projectile.set_meta("unstable_has_ricocheted", true)
	if bool(projectile.get_meta("unstable_memory_echo", false)):
		spawn_unstable_memory_echo(ricochet_position, incoming_direction, projectile.get("damage"))

func _apply_fast_nervous_mark(enemy: Node) -> void:
	enemy.set_meta(FAST_MARK_META, Time.get_ticks_msec() + FAST_MARK_DURATION_MSEC)
	if enemy.has_meta("fast_nervous_mark_feedback_msec"):
		var next_feedback = int(enemy.get_meta("fast_nervous_mark_feedback_msec", 0))
		if next_feedback > Time.get_ticks_msec():
			return

	enemy.set_meta("fast_nervous_mark_feedback_msec", Time.get_ticks_msec() + 280)
	if enemy is Node2D:
		_spawn_burst_particles((enemy as Node2D).global_position, Color(0.95, 1.0, 0.24, 0.78), 6, 0.14, 55.0)

func _try_spawn_heavy_impact_shards(projectile: Node, hit_position: Vector2, dealt_damage: float) -> void:
	if bool(projectile.get_meta("heavy_impact_shards_spent", false)):
		return

	projectile.set_meta("heavy_impact_shards_spent", true)
	var projectile_direction = _get_projectile_direction(projectile)
	var base_angle = (-projectile_direction.normalized()).angle()
	var spread = deg_to_rad(HEAVY_IMPACT_SHARD_ANGLE_SPREAD)
	var shard_damage = max(dealt_damage * HEAVY_IMPACT_SHARD_DAMAGE_MULTIPLIER, 1.0)

	for i in range(HEAVY_IMPACT_SHARD_COUNT):
		var t = 0.0 if HEAVY_IMPACT_SHARD_COUNT <= 1 else float(i) / float(HEAVY_IMPACT_SHARD_COUNT - 1) - 0.5
		var shard_angle = base_angle + spread * t
		var shard_direction = Vector2(cos(shard_angle), sin(shard_angle))
		_spawn_projectile(
			hit_position + shard_direction * 10.0,
			shard_angle,
			shard_damage,
			false,
			Color(1.0, 0.55, 0.24, 0.92),
			{
				"skip_arm_mutations": true,
				"projectile_speed_multiplier": 0.78,
				"scale_multiplier": 0.65
			}
		)
	_spawn_burst_particles(hit_position, Color(1.0, 0.5, 0.2, 0.78), 12, 0.18, 90.0)

func _trigger_heavy_execution_blast(center: Vector2, dealt_damage: float) -> void:
	var blast_damage = max(dealt_damage * HEAVY_EXECUTION_DAMAGE_MULTIPLIER, attack_damage * 0.12)
	_spawn_ring_vfx(center, HEAVY_EXECUTION_RADIUS, Color(1.0, 0.46, 0.18, 0.44), 0.24)
	_spawn_burst_particles(center, Color(1.0, 0.45, 0.18, 0.86), 22, 0.24, 150.0)

	for enemy in get_tree().get_nodes_in_group(Global.GROUP_ENEMY):
		if not _can_mutation_affect_enemy(enemy):
			continue
		if (enemy as Node2D).global_position.distance_to(center) > HEAVY_EXECUTION_RADIUS:
			continue
		enemy.take_damage(blast_damage)
		var push_direction = center.direction_to((enemy as Node2D).global_position)
		_apply_enemy_impulse(enemy, push_direction * HEAVY_EXECUTION_KNOCKBACK_FORCE)

func _trigger_heavy_penitence_drag(center: Vector2, projectile_direction: Vector2, dealt_damage: float) -> void:
	if projectile_direction == Vector2.ZERO:
		return

	var drag_direction = projectile_direction.normalized()
	var drag_damage = max(dealt_damage * HEAVY_PENITENCE_DRAG_DAMAGE_MULTIPLIER, attack_damage * 0.08)
	_spawn_ring_vfx(center, HEAVY_PENITENCE_DRAG_RADIUS, Color(1.0, 0.78, 0.3, 0.34), 0.18)

	for enemy in get_tree().get_nodes_in_group(Global.GROUP_ENEMY):
		if not _can_mutation_affect_enemy(enemy):
			continue
		if (enemy as Node2D).global_position.distance_to(center) > HEAVY_PENITENCE_DRAG_RADIUS:
			continue
		enemy.take_damage(drag_damage)
		_apply_enemy_impulse(enemy, drag_direction * HEAVY_PENITENCE_DRAG_FORCE)

func _handle_unstable_resonance_hit(enemy: Node, projectile: Node, dealt_damage: float) -> void:
	if not is_instance_valid(enemy):
		return

	var now_msec = Time.get_ticks_msec()
	var resonance_until = int(enemy.get_meta(UNSTABLE_RESONANCE_META, 0))
	if resonance_until > now_msec:
		enemy.remove_meta(UNSTABLE_RESONANCE_META)
		_trigger_unstable_resonance(_get_node_global_position(enemy, global_position), dealt_damage)
		return

	if bool(projectile.get_meta("unstable_has_ricocheted", false)):
		enemy.set_meta(UNSTABLE_RESONANCE_META, now_msec + UNSTABLE_RESONANCE_DURATION_MSEC)
		_spawn_burst_particles(_get_node_global_position(enemy, global_position), Color(0.72, 0.28, 1.0, 0.82), 10, 0.18, 75.0)

func _trigger_unstable_resonance(center: Vector2, dealt_damage: float) -> void:
	var resonance_damage = max(dealt_damage * UNSTABLE_RESONANCE_DAMAGE_MULTIPLIER, attack_damage * 0.35)
	_spawn_ring_vfx(center, UNSTABLE_RESONANCE_RADIUS, Color(0.72, 0.28, 1.0, 0.46), 0.26)
	_spawn_burst_particles(center, Color(0.72, 0.28, 1.0, 0.9), 28, 0.28, 160.0)

	for enemy in get_tree().get_nodes_in_group(Global.GROUP_ENEMY):
		if not _can_mutation_affect_enemy(enemy):
			continue
		if (enemy as Node2D).global_position.distance_to(center) <= UNSTABLE_RESONANCE_RADIUS:
			enemy.take_damage(resonance_damage)

func spawn_unstable_memory_echo(source_position: Vector2, echo_direction: Vector2, source_damage) -> void:
	if current_arm_id != "unstable" or arm_mutation_tier < 1 or echo_direction == Vector2.ZERO:
		return

	var tree = get_tree()
	if tree == null:
		return
	await tree.create_timer(UNSTABLE_MEMORY_ECHO_DELAY, false).timeout
	if not is_inside_tree():
		return

	var damage_value = float(source_damage) if source_damage != null else attack_damage
	var direction = echo_direction.normalized()
	_spawn_projectile(
		source_position + direction * 12.0,
		direction.angle(),
		max(damage_value * UNSTABLE_MEMORY_ECHO_DAMAGE_MULTIPLIER, 4.0),
		false,
		Color(0.55, 0.45, 1.0, 0.64),
		{
			"skip_arm_mutations": true,
			"projectile_speed_multiplier": UNSTABLE_MEMORY_ECHO_SPEED_MULTIPLIER,
			"scale_multiplier": 0.78
		}
	)

func _can_mutation_affect_enemy(enemy: Node) -> bool:
	if not is_instance_valid(enemy) or not enemy.has_method("take_damage") or not (enemy is Node2D):
		return false
	if enemy.get("is_dead") != null and bool(enemy.get("is_dead")):
		return false
	return true

func _is_enemy_dead(enemy: Node) -> bool:
	if not is_instance_valid(enemy):
		return true
	if enemy.get("is_dead") != null and bool(enemy.get("is_dead")):
		return true
	if enemy.get("current_health") != null and float(enemy.get("current_health")) <= 0.0:
		return true
	return false

func _apply_enemy_impulse(enemy: Node, impulse: Vector2) -> void:
	if not is_instance_valid(enemy) or impulse == Vector2.ZERO or enemy.get("velocity") == null:
		return

	var current_velocity = enemy.get("velocity")
	if current_velocity is Vector2:
		var velocity_vector: Vector2 = current_velocity
		enemy.set("velocity", velocity_vector + impulse)

func _get_node_global_position(node: Node, fallback: Vector2) -> Vector2:
	if node is Node2D:
		return (node as Node2D).global_position
	return fallback

func _get_projectile_direction(projectile: Node) -> Vector2:
	if not is_instance_valid(projectile):
		return Vector2.RIGHT

	var projectile_direction = projectile.get("direction")
	if projectile_direction is Vector2 and projectile_direction != Vector2.ZERO:
		return projectile_direction.normalized()
	return Vector2.RIGHT


func _can_perform_dash() -> bool:
	return can_dash and double_dash_charges > 0 and not is_dashing

func perform_dash(direction: Vector2) -> void:
	if not _consume_dash_charge():
		return

	is_dashing = true
	if offensive_dash_enabled:
		_grant_knockback_immunity(EXPLOSIVE_KNOCKBACK_IMMUNITY_DURATION)
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

func take_damage(amount: float, attacker_position: Vector2 = Vector2.ZERO, knockback_multiplier: float = 1.0, contact_source: Node = null) -> void:
	if debug_invincible_enabled or is_invulnerable:
		return

	if offensive_dash_enabled and is_dashing:
		_spawn_burst_particles(global_position, Color(0.25, 0.95, 1.0, 0.85), 18, 0.22, 110.0)
		return

	if has_shield:
		_break_shield()
		return

	if attacker_position != Vector2.ZERO:
		_apply_knockback(attacker_position, knockback_multiplier)

	var damage_taken = int(round(amount * damage_taken_multiplier))
	current_health -= damage_taken
	_record_damage_taken(damage_taken, contact_source)
	emit_signal("hp_updated", current_health, max_health)
	if is_instance_valid(contact_source) and contact_source.has_method("on_player_damage_dealt"):
		contact_source.call("on_player_damage_dealt", float(damage_taken), self)
	_play_damage_feedback()
	
	if current_health <= 0:
		capture_run_end("Defeat")
		die()
		return

	is_invulnerable = true
	
	await get_tree().create_timer(0.2, false).timeout
	is_invulnerable = false

func die() -> void:
	capture_run_end("Defeat")
	_finish_current_run()
	# aparencia.play("death")
	for musica in get_tree().get_nodes_in_group(Global.GROUP_MUSIC):
		musica.stop()
	get_tree().paused = true
	# $Lose.play()
	await get_tree().create_timer(0.25, true).timeout
	if game_over:
		game_over.visible = true

func win() -> void:
	capture_run_end("Victory")
	_finish_current_run()
	for musica in get_tree().get_nodes_in_group(Global.GROUP_MUSIC):
		musica.stop()
	get_tree().paused = true
	# $Win.play()
	if game_win:
		game_win.visible = true

func _finish_current_run() -> void:
	var tree = get_tree()
	if tree == null:
		return

	var game_scene = tree.current_scene
	if game_scene and game_scene.has_method("finish_run"):
		if game_scene.finish_run():
			return

	Global.finish_current_run()

func _on_shoot_timer_timeout() -> void:
	can_shoot = true
	if current_arm_id == "heavy" and arm_mutation_tier >= 3:
		heavy_perfect_window_remaining = HEAVY_PENITENCE_READY_WINDOW
	_update_shot_cooldown_bar()

func _setup_shot_cooldown_bar() -> void:
	if is_instance_valid(shot_cooldown_bar):
		return

	shot_cooldown_bar = ProgressBar.new()
	shot_cooldown_bar.name = "ShotCooldownBar"
	shot_cooldown_bar.show_percentage = false
	shot_cooldown_bar.custom_minimum_size = SHOT_COOLDOWN_BAR_SIZE
	shot_cooldown_bar.size = SHOT_COOLDOWN_BAR_SIZE
	shot_cooldown_bar.position = SHOT_COOLDOWN_BAR_OFFSET
	shot_cooldown_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shot_cooldown_bar.z_index = SHOT_COOLDOWN_BAR_Z_INDEX
	shot_cooldown_bar.max_value = 1.0
	shot_cooldown_bar.value = 1.0
	shot_cooldown_bar.visible = false
	shot_cooldown_bar.add_theme_stylebox_override("background", _make_shot_cooldown_stylebox(Color(0.08, 0.06, 0.04, 0.72)))
	shot_cooldown_bar.add_theme_stylebox_override("fill", _make_shot_cooldown_stylebox(Color(0.95, 0.66, 0.22, 0.96)))
	add_child(shot_cooldown_bar)

func _update_shot_cooldown_bar() -> void:
	if not is_instance_valid(shot_cooldown_bar):
		return

	if can_shoot or shoot_timer == null or shoot_timer.is_stopped():
		shot_cooldown_bar.visible = false
		shot_cooldown_bar.value = shot_cooldown_bar.max_value
		return

	var cooldown = max(fire_rate, 0.001)
	shot_cooldown_bar.visible = true
	shot_cooldown_bar.value = clamp(1.0 - shoot_timer.time_left / cooldown, 0.0, 1.0)

func _make_shot_cooldown_stylebox(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(1)
	return style

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

	if parent.is_in_group(Global.GROUP_ENEMY):
		if not enemies_in_contact.has(parent):
			enemies_in_contact.append(parent)
		
		if contact_damage_timer.is_stopped():
			take_damage(_get_contact_damage(parent), parent.global_position, _get_contact_knockback_multiplier(parent), parent)
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
		take_damage(_get_contact_damage(prime_enemy), prime_enemy.global_position, _get_contact_knockback_multiplier(prime_enemy), prime_enemy)
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
	return Global.ACTIVE_ABILITY_DATA.has(option_id)

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
	var data = Global.ACTIVE_ABILITY_DATA.get(option_id, {})
	return float(data.get("cooldown", 0.0))

func get_active_ability_name(option_id: String) -> String:
	var data = Global.ACTIVE_ABILITY_DATA.get(option_id, {})
	return I18n.option_name(option_id, str(data.get("name", option_id)))

func get_active_ability_description(option_id: String) -> String:
	var data = Global.ACTIVE_ABILITY_DATA.get(option_id, {})
	return I18n.option_description(option_id, str(data.get("description", option_id)))

func get_equipped_passive_summaries() -> Array:
	var summaries: Array = []
	if current_arm_id != "" and Global.STARTING_ARM_DATA.has(current_arm_id):
		var arm_data: Dictionary = Global.STARTING_ARM_DATA[current_arm_id]
		summaries.append({
			"id": current_arm_id,
			"name": I18n.arm_name(current_arm_id, str(arm_data["name"])),
			"description": I18n.arm_description(current_arm_id, str(arm_data["description"]))
		})
	for summary in get_arm_mutation_summaries():
		summaries.append(summary)

	for summary in get_equipped_boss_passive_summaries():
		summaries.append(summary)
	for summary in get_equipped_rare_passive_summaries():
		summaries.append(summary)

	return summaries

func get_equipped_boss_passive_summaries() -> Array:
	var summaries: Array = []
	for passive_id in get_boss_passive_options():
		summaries.append(_get_passive_summary(passive_id))
	return summaries

func get_equipped_rare_passive_summaries() -> Array:
	var summaries: Array = []
	for passive_id in get_rare_passive_options():
		summaries.append(_get_passive_summary(passive_id))
	return summaries

func _get_passive_summary(passive_id: String) -> Dictionary:
	return {
		"id": passive_id,
		"name": get_passive_effect_name(passive_id),
		"description": get_passive_effect_description(passive_id)
	}

func get_passive_effect_name(passive_id: String) -> String:
	var data = Global.PASSIVE_STATUS_DATA.get(passive_id, {})
	return I18n.option_name(passive_id, str(data.get("name", passive_id)))

func get_passive_effect_description(passive_id: String) -> String:
	var data = Global.PASSIVE_STATUS_DATA.get(passive_id, {})
	return I18n.option_description(passive_id, str(data.get("description", passive_id)))

func _is_passive_enabled(passive_id: String) -> bool:
	if Global.SIN_PASSIVE_FLAGS.has(passive_id):
		return bool(get(Global.SIN_PASSIVE_FLAGS[passive_id]))

	return has_rare_passive(passive_id)

func get_boss_passive_options() -> Array:
	_sync_boss_passive_options()
	return current_boss_passive_options.duplicate()

func has_boss_passive(option_id: String) -> bool:
	_sync_boss_passive_options()
	return option_id in current_boss_passive_options

func can_equip_boss_passive(option_id: String) -> bool:
	_sync_boss_passive_options()
	return option_id in current_boss_passive_options or current_boss_passive_options.size() < MAX_BOSS_PASSIVE_OPTIONS

func equip_boss_passive_id(option_id: String) -> void:
	if option_id == "":
		return

	_sync_boss_passive_options()
	if option_id not in current_boss_passive_options and current_boss_passive_options.size() < MAX_BOSS_PASSIVE_OPTIONS:
		current_boss_passive_options.append(option_id)

func replace_boss_passive_id(old_option: String, new_option: String) -> void:
	if new_option == "":
		return

	_sync_boss_passive_options()
	var old_index = current_boss_passive_options.find(old_option)
	if old_index >= 0:
		current_boss_passive_options[old_index] = new_option
	elif new_option not in current_boss_passive_options and current_boss_passive_options.size() < MAX_BOSS_PASSIVE_OPTIONS:
		current_boss_passive_options.append(new_option)
	_dedupe_boss_passive_options()

func remove_boss_passive_id(option_id: String) -> void:
	_sync_boss_passive_options()
	current_boss_passive_options.erase(option_id)

func _sync_boss_passive_options() -> void:
	for passive_id in Global.SIN_PASSIVE_IDS:
		if _is_passive_enabled(passive_id) and passive_id not in current_boss_passive_options:
			current_boss_passive_options.append(passive_id)
	_dedupe_boss_passive_options()
	while current_boss_passive_options.size() > MAX_BOSS_PASSIVE_OPTIONS:
		current_boss_passive_options.pop_back()

func _dedupe_boss_passive_options() -> void:
	var unique_options: Array = []
	for option_id in current_boss_passive_options:
		if option_id != "" and option_id not in unique_options:
			unique_options.append(option_id)
	current_boss_passive_options = unique_options

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
	var method_name = str(Global.ACTIVE_ABILITY_DATA.get(ability_id, {}).get("method", ""))
	if method_name != "" and has_method(method_name):
		call(method_name)

func _update_active_ability_cooldowns(delta: float) -> void:
	for slot in active_ability_cooldown_remaining.keys():
		if active_ability_cooldown_remaining[slot] > 0.0:
			active_ability_cooldown_remaining[slot] = max(active_ability_cooldown_remaining[slot] - delta, 0.0)

func heal(amount: float) -> void:
	var final_heal = max(amount, 0.0) * healing_received_multiplier
	if final_heal <= 0.0:
		return

	var previous_health = current_health
	current_health = int(min(current_health + final_heal, max_health))
	emit_signal("hp_updated", current_health, max_health)
	if current_health > previous_health:
		_play_heal_feedback()

func _play_damage_feedback() -> void:
	_play_health_feedback(DAMAGE_FEEDBACK_COLOR)

func _play_heal_feedback() -> void:
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

func _clear_health_feedback_tween(tween: Tween) -> void:
	if health_feedback_tween == tween:
		health_feedback_tween = null

func on_enemy_killed(_enemy: Node) -> void:
	run_kills_total += 1
	if is_instance_valid(_enemy) and _enemy.has_meta("elite_variant") and str(_enemy.get_meta("elite_variant")) != "":
		run_elite_kills_total += 1
	if gluttony_heal_kill_enabled and is_instance_valid(_enemy):
		_spawn_heal_motes(_enemy.global_position, max_health * 0.01, 5)

func record_upgrade(option_data: Dictionary) -> void:
	if option_data.is_empty():
		return

	var rarity = str(option_data.get("rarity", ""))
	var upgrade_record = {
		"id": str(option_data.get("id", "")),
		"name": str(option_data.get("text", option_data.get("name", option_data.get("id", "Upgrade")))),
		"rarity": rarity,
		"lucky": bool(option_data.get("special_level_up", false)),
		"lucky_tier": str(option_data.get("special_level_up_tier", "")),
		"stat_multiplier": float(option_data.get("stat_multiplier", 1.0))
	}
	run_upgrade_history.append(upgrade_record)

	if bool(upgrade_record["lucky"]):
		run_lucky_upgrade_count += 1
	if rarity == "passive_cursed":
		run_cursed_upgrade_count += 1

func record_contract_decision(contract_data: Dictionary, accepted: bool) -> void:
	if contract_data.is_empty():
		return

	run_contract_history.append({
		"name": str(contract_data.get("name", I18n.t("contract.fallback_name"))),
		"pecado_id": int(contract_data.get("pecado_id", 0)),
		"accepted": accepted,
		"modifiers": contract_data.get("modifiers", {}).duplicate(true),
		"reward_type": str(contract_data.get("reward_type", "")),
		"buff_summary": str(contract_data.get("buff_summary", "")),
		"reward_summary": str(contract_data.get("reward_summary", ""))
	})

func capture_run_end(reason: String) -> void:
	if run_end_reason != "":
		return

	run_end_reason = reason
	if Global.run_start_msec >= 0:
		run_end_elapsed_seconds = float(Time.get_ticks_msec() - Global.run_start_msec) / 1000.0

func get_death_recap_text() -> String:
	var lines = PackedStringArray()
	lines.append(I18n.t("recap.title"))
	lines.append(I18n.t("recap.result", [_format_run_result(run_end_reason)]))
	lines.append(I18n.t("recap.time", [Global.format_run_time(run_end_elapsed_seconds)]))
	lines.append(I18n.t("recap.sins", [Global.format_pecados_derrotados(clampi(Global.pecado - 1, 0, 7))]))
	lines.append(I18n.t("recap.kills", [run_kills_total, run_elite_kills_total]))
	lines.append(I18n.t("recap.damage_taken", [run_damage_taken_total]))
	var final_blow_name = I18n.t("common.none") if last_damage_source_name == "None" else last_damage_source_name
	lines.append(I18n.t("recap.final_blow", [final_blow_name, last_damage_source_amount]))
	lines.append("")
	lines.append(I18n.t("recap.final_stats"))
	lines.append(I18n.t("recap.health", [current_health, max_health]))
	lines.append(I18n.t("recap.attack", [attack_damage]))
	lines.append(I18n.t("recap.atk_speed", [get_attack_speed_percent()]))
	lines.append(I18n.t("recap.recoil", [recoil_force / 100.0]))
	lines.append(I18n.t("recap.rerolls_left", [reroll_tokens]))
	lines.append("")
	lines.append(I18n.t("recap.build"))
	lines.append(I18n.t("recap.lucky_upgrades", [run_lucky_upgrade_count]))
	lines.append(I18n.t("recap.cursed_passives", [run_cursed_upgrade_count]))
	if run_upgrade_history.is_empty():
		lines.append(I18n.t("recap.no_upgrades"))
	else:
		for upgrade in run_upgrade_history:
			var lucky_suffix = ""
			if bool(upgrade.get("lucky", false)):
				lucky_suffix = " [%s x%.1f]" % [str(upgrade.get("lucky_tier", "lucky")).capitalize(), float(upgrade.get("stat_multiplier", 1.0))]
			lines.append("- %s (%s)%s" % [_get_recap_upgrade_name(upgrade), _format_recap_rarity(str(upgrade.get("rarity", ""))), lucky_suffix])
	lines.append("")
	lines.append(I18n.t("recap.contracts"))
	if run_contract_history.is_empty():
		lines.append(I18n.t("recap.no_contracts"))
	else:
		for contract in run_contract_history:
			var status = I18n.t("recap.accepted") if bool(contract.get("accepted", false)) else I18n.t("recap.declined")
			lines.append(I18n.t("recap.contract_status", [status, _get_recap_contract_name(contract)]))
			var buff_summary = _get_recap_contract_buff_summary(contract)
			var reward_summary = _get_recap_contract_reward_summary(contract)
			if buff_summary != "":
				lines.append(I18n.t("recap.boss_buff", [buff_summary]))
			if reward_summary != "":
				lines.append(I18n.t("recap.reward", [reward_summary]))
	lines.append("")
	lines.append(I18n.t("recap.damage_sources"))
	if run_damage_taken_by_source.is_empty():
		lines.append("- %s" % I18n.t("common.none"))
	else:
		for source_name in run_damage_taken_by_source.keys():
			lines.append("- %s: %d" % [str(source_name), int(run_damage_taken_by_source[source_name])])
	return "\n".join(lines)

func _format_run_result(reason: String) -> String:
	match reason:
		"Victory", "recap.victory":
			return I18n.t("recap.victory")
		"Defeat", "recap.defeat", "":
			return I18n.t("recap.defeat")
	return reason

func _get_recap_upgrade_name(upgrade: Dictionary) -> String:
	var upgrade_id = str(upgrade.get("id", ""))
	if upgrade_id == "contract_rerolls":
		return I18n.t("contract.record_rerolls", [5])
	if upgrade_id.begins_with("arm_mutation_"):
		var parts = upgrade_id.split("_")
		if parts.size() >= 4:
			var tier = int(parts[3])
			var mutation_name = I18n.mutation_name(str(parts[2]), tier, str(upgrade.get("name", "Upgrade")))
			return I18n.t("recap.arm_mutation_upgrade", [tier, mutation_name])
	return I18n.option_text(upgrade_id, str(upgrade.get("name", "Upgrade")))

func _get_recap_contract_name(contract: Dictionary) -> String:
	var pecado_id = int(contract.get("pecado_id", 0))
	if pecado_id > 0:
		return I18n.t("contract.name", [pecado_id])
	return str(contract.get("name", I18n.t("contract.fallback_name")))

func _get_recap_contract_buff_summary(contract: Dictionary) -> String:
	var modifiers = contract.get("modifiers", {})
	if not (modifiers is Dictionary) or modifiers.is_empty():
		return str(contract.get("buff_summary", ""))

	var parts = PackedStringArray()
	for key in modifiers.keys():
		var label_key = "contract.buff.%s" % str(key)
		var label = I18n.t(label_key) if I18n.has_key(label_key) else str(key).replace("_", " ").capitalize()
		parts.append("%s +%d%%" % [label, int(round((float(modifiers[key]) - 1.0) * 100.0))])
	return ", ".join(parts)

func _get_recap_contract_reward_summary(contract: Dictionary) -> String:
	match str(contract.get("reward_type", "")):
		"extra_level":
			return I18n.t("contract.reward.extra_level")
		"rerolls":
			return I18n.t("contract.reward.rerolls", [5])
		"stat":
			return I18n.t("contract.reward.stat")
	return str(contract.get("reward_summary", ""))

func _format_recap_rarity(rarity: String) -> String:
	match rarity:
		"passive_common":
			return I18n.t("rarity.passive_common")
		"passive_rare":
			return I18n.t("rarity.passive_rare")
		"passive_cursed":
			return I18n.t("rarity.passive_cursed")
		"passive_sin":
			return I18n.t("rarity.passive_sin")
		"active_sin":
			return I18n.t("rarity.active_sin")
		"contract_reward":
			return I18n.t("rarity.contract_reward")
		"arm_mutation":
			return I18n.t("rarity.arm_mutation")
	return rarity if rarity != "" else I18n.t("common.unknown")

func _record_damage_taken(amount: int, contact_source: Node) -> void:
	if amount <= 0:
		return

	var source_name = _get_damage_source_name(contact_source)
	run_damage_taken_total += amount
	run_damage_taken_by_source[source_name] = int(run_damage_taken_by_source.get(source_name, 0)) + amount
	last_damage_source_name = source_name
	last_damage_source_amount = amount

func _get_damage_source_name(contact_source: Node) -> String:
	if not is_instance_valid(contact_source):
		return I18n.t("common.direct_damage")

	if contact_source.is_in_group(Global.GROUP_BOSS):
		return I18n.t("common.boss")

	var source_name = str(contact_source.name)
	if contact_source.has_method("get_elite_display_name"):
		var elite_name = str(contact_source.call("get_elite_display_name"))
		if elite_name != "":
			return "%s %s" % [elite_name, source_name]

	return source_name

func activate_sloth_field() -> void:
	var field_position = global_position
	var field_radius = MAX_ABILITY_AREA_RADIUS
	_spawn_field_vfx(field_position, field_radius, Color(0.25, 0.95, 1.0, 0.54), 5.0)

	var slowed_enemies: Array = []
	var elapsed = 0.0
	_set_dash_speed_modifier("sloth_field", 0.75)

	while elapsed < 5.0:
		for enemy in get_tree().get_nodes_in_group(Global.GROUP_ENEMY):
			if not is_instance_valid(enemy) or enemy.get("speed") == null:
				continue

			_remember_enemy_base_speed(enemy)
			var base_speed = enemy.get_meta("base_speed")
			var is_inside_field = _is_position_inside_iso_aoe(enemy.global_position, field_position, field_radius)
			if is_inside_field:
				enemy.set_meta("sloth_field_active", true)
				enemy.set("speed", base_speed * 0.35)
				_apply_enemy_sloth_dot(enemy, SLOTH_FIELD_DPS * SLOTH_FIELD_TICK_INTERVAL)
				if enemy not in slowed_enemies:
					slowed_enemies.append(enemy)
			elif enemy in slowed_enemies:
				enemy.set("speed", base_speed)
				enemy.remove_meta("sloth_field_active")
				slowed_enemies.erase(enemy)

		await get_tree().create_timer(SLOTH_FIELD_TICK_INTERVAL, false).timeout
		elapsed += SLOTH_FIELD_TICK_INTERVAL

	_clear_dash_speed_modifier("sloth_field")
	for enemy in slowed_enemies:
		if is_instance_valid(enemy) and enemy.has_meta("base_speed"):
			enemy.set("speed", enemy.get_meta("base_speed"))
			enemy.remove_meta("sloth_field_active")

func activate_gluttony_devour() -> void:
	var nearby_enemies = get_tree().get_nodes_in_group(Global.GROUP_ENEMY)
	nearby_enemies = nearby_enemies.filter(func(enemy): return is_instance_valid(enemy) and not enemy.is_in_group(Global.GROUP_BOSS) and _is_position_inside_iso_aoe(enemy.global_position, global_position, DEVOUR_RADIUS))
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
	envy_clone_fire_timer = min(max(fire_rate * 0.45, 0.15), 0.45)
	_spawn_clone_vfx(8.0)
	await get_tree().create_timer(8.0, false).timeout
	envy_clone_active = false
	envy_clone_fire_timer = 0.0
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
	_set_temporary_damage_taken_multiplier(2.0)
	_spawn_attached_aura(130.0, Color(1.0, 0.16, 0.36, 0.38), 5.0)
	await get_tree().create_timer(5.0, false).timeout
	_set_temporary_damage_taken_multiplier(1.0)

func activate_greed_treasure_rain() -> void:
	_spawn_burst_particles(global_position, Color(1.0, 0.78, 0.08, 0.95), 42, 0.45, 180.0)
	for i in range(20):
		var spawn_position = global_position + Vector2(randf_range(-420.0, 420.0), -360.0 - randf_range(0.0, 180.0))
		_spawn_projectile(spawn_position, PI / 2.0, attack_damage * 1.2, true, Color(1.0, 0.78, 0.08, 0.95))
		await get_tree().create_timer(0.06, false).timeout

func _trigger_recoil_explosion() -> void:
	_grant_knockback_immunity(EXPLOSIVE_KNOCKBACK_IMMUNITY_DURATION)
	_spawn_burst_particles(global_position, EXPLOSIVE_SHOCKWAVE_PARTICLE_COLOR, 34, 0.3, 210.0)
	_spawn_ring_vfx(global_position, SHOCKWAVE_RADIUS, EXPLOSIVE_SHOCKWAVE_COLOR, 0.28)
	for enemy in get_tree().get_nodes_in_group(Global.GROUP_ENEMY):
		if is_instance_valid(enemy) and enemy.has_method("take_damage") and _is_position_inside_iso_aoe(enemy.global_position, global_position, SHOCKWAVE_RADIUS):
			enemy.take_damage(_get_shockwave_damage())

func _trigger_offensive_dash_explosion() -> void:
	_spawn_burst_particles(global_position, EXPLOSIVE_SHOCKWAVE_PARTICLE_COLOR, 36, 0.32, 190.0)
	_spawn_ring_vfx(global_position, SHOCKWAVE_RADIUS, EXPLOSIVE_SHOCKWAVE_COLOR, 0.3)
	for enemy in get_tree().get_nodes_in_group(Global.GROUP_ENEMY):
		if is_instance_valid(enemy) and enemy.has_method("take_damage") and _is_position_inside_iso_aoe(enemy.global_position, global_position, SHOCKWAVE_RADIUS):
			enemy.take_damage(_get_shockwave_dash_damage())

func _get_shockwave_damage() -> float:
	return attack_damage * SHOCKWAVE_DAMAGE_MULTIPLIER
func _get_shockwave_dash_damage() -> float:
	return attack_damage * SHOCKWAVE_DASH_DAMAGE_MULTIPLIER

func _apply_sloth_slow_aura(delta: float) -> void:
	for enemy in get_tree().get_nodes_in_group(Global.GROUP_ENEMY):
		if not is_instance_valid(enemy) or enemy.get("speed") == null:
			continue

		if enemy.has_meta("sloth_field_active"):
			continue

		_remember_enemy_base_speed(enemy)
		var base_speed = enemy.get_meta("base_speed")
		if _is_position_inside_iso_aoe(enemy.global_position, global_position, SLOW_AURA_RADIUS):
			enemy.set("speed", base_speed * 0.65)
			_apply_enemy_sloth_dot(enemy, SLOTH_AURA_DPS * delta)
		else:
			enemy.set("speed", base_speed)

func _apply_enemy_sloth_dot(enemy: Node, damage_amount: float) -> void:
	if not is_instance_valid(enemy) or not enemy.has_method("take_damage") or damage_amount <= 0.0:
		return

	var accumulated_damage = float(enemy.get_meta(SLOTH_PLAYER_DOT_META, 0.0)) + damage_amount
	var whole_damage = floori(accumulated_damage)
	if whole_damage <= 0:
		enemy.set_meta(SLOTH_PLAYER_DOT_META, accumulated_damage)
		return

	enemy.take_damage(float(whole_damage))
	if is_instance_valid(enemy):
		enemy.set_meta(SLOTH_PLAYER_DOT_META, accumulated_damage - float(whole_damage))

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

func _force_clamp_to_current_arena() -> void:
	var scene = _get_current_game_scene()
	if scene == null or not scene.has_method("clamp_position_to_current_arena"):
		return

	var previous_position = global_position
	var clamp_margin = _get_arena_force_clamp_margin()
	var clamped_position: Vector2 = scene.call("clamp_position_to_current_arena", previous_position, clamp_margin)
	if previous_position.distance_squared_to(clamped_position) <= 0.01:
		return

	global_position = clamped_position
	_apply_arena_clamp_bounce(previous_position, clamped_position)

func _get_current_game_scene() -> Node:
	var tree = get_tree()
	if tree == null or not is_instance_valid(tree.current_scene):
		return null
	return tree.current_scene

func _get_arena_force_clamp_margin() -> float:
	var collision = get_node_or_null("CollisionShape2D")
	if collision == null or not (collision is CollisionShape2D) or collision.shape == null:
		return ARENA_FORCE_CLAMP_MIN_MARGIN

	var shape = collision.shape
	var radius = ARENA_FORCE_CLAMP_MIN_MARGIN
	if shape is CapsuleShape2D:
		radius = max(shape.radius, shape.height * 0.5)
	elif shape is CircleShape2D:
		radius = shape.radius
	elif shape is RectangleShape2D:
		radius = shape.size.length() * 0.5

	return max(radius + ARENA_FORCE_CLAMP_PADDING, ARENA_FORCE_CLAMP_MIN_MARGIN)

func _remove_outward_arena_velocity(previous_position: Vector2, clamped_position: Vector2) -> void:
	var correction = previous_position - clamped_position
	if correction.length_squared() <= 0.001:
		return

	var outward_direction = correction.normalized()
	var outward_speed = velocity.dot(outward_direction)
	if outward_speed > 0.0:
		velocity -= outward_direction * outward_speed

func _apply_arena_clamp_bounce(previous_position: Vector2, clamped_position: Vector2) -> void:
	var inward_normal = _get_current_arena_edge_normal(clamped_position)
	if inward_normal == Vector2.ZERO:
		inward_normal = previous_position.direction_to(clamped_position)

	if inward_normal != Vector2.ZERO and velocity.length() >= WALL_BOUNCE_MIN_SPEED and velocity.dot(inward_normal) < 0.0:
		var bounced_velocity = velocity.bounce(inward_normal.normalized()) * WALL_BOUNCE_MULTIPLIER
		if bounced_velocity.length() < WALL_BOUNCE_MIN_SPEED:
			velocity = Vector2.ZERO
		else:
			velocity = bounced_velocity.limit_length(_get_movement_force_speed_cap())
		global_position += inward_normal.normalized() * WALL_BOUNCE_PUSH_OUT
		_try_trigger_kinetic_reload()
		return

	_remove_outward_arena_velocity(previous_position, clamped_position)

func _try_trigger_kinetic_reload() -> void:
	if not kinetic_reload_enabled or kinetic_reload_cooldown_remaining > 0.0 or is_dashing:
		return
	if shoot_timer == null or shoot_timer.is_stopped() or can_shoot:
		return

	var remaining_cooldown = shoot_timer.time_left
	if remaining_cooldown <= 0.01:
		return

	var new_remaining_cooldown = max(remaining_cooldown * (1.0 - KINETIC_RELOAD_REMAINING_COOLDOWN_REDUCTION), 0.01)
	shoot_timer.start(new_remaining_cooldown)
	kinetic_reload_cooldown_remaining = KINETIC_RELOAD_INTERNAL_COOLDOWN
	_update_shot_cooldown_bar()
	_spawn_burst_particles(global_position, Color(0.42, 0.95, 1.0, 0.78), 10, 0.16, 75.0)

func _get_current_arena_edge_normal(point: Vector2) -> Vector2:
	var scene = _get_current_game_scene()
	if scene == null or not scene.has_method("_get_current_arena_edge_normal"):
		return Vector2.ZERO

	var edge_normal = scene.call("_get_current_arena_edge_normal", point)
	if edge_normal is Vector2:
		return edge_normal

	return Vector2.ZERO

func _get_vfx_parent() -> Node:
	var tree = get_tree()
	if tree == null:
		return null
	if is_instance_valid(tree.current_scene):
		return tree.current_scene
	if is_instance_valid(tree.root):
		return tree.root
	return null

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
	var parent = _get_vfx_parent()
	if parent == null:
		particles.queue_free()
		return

	parent.add_child(particles)
	particles.emitting = true

	var tree = get_tree()
	if tree == null:
		return
	var cleanup_timer = tree.create_timer(lifetime + 0.25, false)
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
	particles.color = _get_area_aura_vfx_color(color)
	var parent = _get_ground_area_vfx_parent()
	if parent == null:
		particles.queue_free()
		return

	parent.add_child(particles)
	particles.z_index = PASSIVE_RING_Z_INDEX
	particles.z_as_relative = false
	particles.global_position = center
	particles.emitting = true

	var tree = get_tree()
	if tree == null:
		return
	var cleanup_timer = tree.create_timer(duration, false)
	cleanup_timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(particles))

func _spawn_attached_aura(radius: float, color: Color, duration: float) -> void:
	radius = min(radius, MAX_ABILITY_AREA_RADIUS)
	var aura = Node2D.new()
	aura.name = "TimedAuraVFX"
	aura.z_index = PASSIVE_RING_Z_INDEX
	aura.z_as_relative = false
	aura.show_behind_parent = true
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
	particles.color = _get_area_aura_vfx_color(color)
	aura.add_child(particles)
	particles.emitting = true

	var tree = get_tree()
	if tree == null:
		return
	var cleanup_timer = tree.create_timer(duration, false)
	cleanup_timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(aura))

func _spawn_ring_vfx(center: Vector2, radius: float, color: Color, duration: float) -> void:
	radius = min(radius, MAX_ABILITY_AREA_RADIUS)
	var ring_vfx = Node2D.new()
	ring_vfx.name = "FilledRingVFX"
	ring_vfx.z_index = PASSIVE_RING_Z_INDEX
	ring_vfx.z_as_relative = false
	var parent = _get_ground_area_vfx_parent()
	if parent == null:
		ring_vfx.queue_free()
		return

	parent.add_child(ring_vfx)
	ring_vfx.global_position = center
	_add_ring_to_node(ring_vfx, radius, color, 3.0)

	var tween = create_tween()
	tween.tween_property(ring_vfx, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(Callable(self, "_queue_free_if_valid").bind(ring_vfx))

func _add_ring_to_node(parent: Node, radius: float, color: Color, width: float) -> Line2D:
	radius = min(radius, MAX_ABILITY_AREA_RADIUS)
	var vfx_color = _get_area_aura_vfx_color(color)
	_add_circle_fill_to_node(parent, radius, vfx_color)

	var ring = Line2D.new()
	ring.width = width
	ring.default_color = vfx_color
	ring.points = _build_iso_ellipse_points(radius, true)
	parent.add_child(ring)
	return ring

func _add_circle_fill_to_node(parent: Node, radius: float, color: Color) -> Polygon2D:
	radius = min(radius, MAX_ABILITY_AREA_RADIUS)
	var fill = Polygon2D.new()
	var fill_color = color
	fill_color.a *= AREA_FILL_ALPHA_MULTIPLIER
	fill.color = fill_color
	fill.polygon = _build_iso_ellipse_points(radius, false)
	parent.add_child(fill)
	return fill

func _update_passive_status_vfx(delta: float) -> void:
	_set_passive_ring_vfx_enabled("recoil_explosion", recoil_explosion_enabled, 28.0, PASSIVE_RING_COLOR, 1.5)
	_set_passive_ring_vfx_enabled("offensive_dash", offensive_dash_enabled, 31.0, PASSIVE_RING_COLOR, 1.5)

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
	vfx.z_index = PASSIVE_RING_Z_INDEX
	vfx.z_as_relative = false
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
	vfx.z_index = PASSIVE_RING_Z_INDEX
	vfx.z_as_relative = false
	add_child(vfx)
	move_child(vfx, 0)
	_add_circular_ring_to_node(vfx, DASH_CHARGE_RING_RADIUS, PASSIVE_RING_SOFT_COLOR, DASH_CHARGE_RING_WIDTH)

	var progress_ring = Line2D.new()
	progress_ring.name = "DashCooldownProgressRing"
	progress_ring.width = DASH_CHARGE_PROGRESS_RING_WIDTH
	progress_ring.default_color = PASSIVE_RING_DOT_COLOR
	progress_ring.points = _build_dash_cooldown_progress_points(1.0)
	vfx.add_child(progress_ring)

	for i in range(2):
		var dot = Polygon2D.new()
		dot.name = "DashChargeDot%d" % i
		dot.polygon = _build_circle_points(DASH_CHARGE_ORB_RADIUS, false)
		dot.color = PASSIVE_RING_DOT_COLOR
		dot.position = Vector2(DASH_CHARGE_ORB_ORBIT_RADIUS, 0.0).rotated(PI * float(i))
		vfx.add_child(dot)

	passive_status_vfx["double_dash"] = vfx
	_update_double_dash_vfx(vfx)
	return vfx

func _update_double_dash_vfx(vfx: Node2D) -> void:
	var visible_charges = clamp(double_dash_charges, 0, max_dash_charges)
	var progress_ring = vfx.get_node_or_null("DashCooldownProgressRing") as Line2D
	if progress_ring:
		progress_ring.points = _build_dash_cooldown_progress_points(_get_dash_recharge_progress())

	for i in range(2):
		var dot = vfx.get_node_or_null("DashChargeDot%d" % i)
		if dot is CanvasItem:
			dot.visible = i < visible_charges

func _get_dash_recharge_progress() -> float:
	if double_dash_charges >= max_dash_charges:
		return 1.0
	if dash_cd_timer == null or dash_cd_timer.is_stopped():
		return 0.0

	var cooldown = max(dash_cooldown, 0.001)
	return clampf(1.0 - dash_cd_timer.time_left / cooldown, 0.0, 1.0)

func _remove_passive_status_vfx(vfx_id: String) -> void:
	var vfx = passive_status_vfx.get(vfx_id, null)
	if is_instance_valid(vfx):
		vfx.queue_free()
	passive_status_vfx.erase(vfx_id)

func _build_ring_points(ring: Line2D, radius: float) -> void:
	ring.points = _build_circle_points(radius, true)

func _add_circular_ring_to_node(parent: Node, radius: float, color: Color, width: float) -> Line2D:
	radius = min(radius, MAX_ABILITY_AREA_RADIUS)
	var vfx_color = _get_area_aura_vfx_color(color)
	var fill = Polygon2D.new()
	var fill_color = vfx_color
	fill_color.a *= AREA_FILL_ALPHA_MULTIPLIER
	fill.color = fill_color
	fill.polygon = _build_circle_points(radius, false)
	parent.add_child(fill)

	var ring = Line2D.new()
	ring.width = width
	ring.default_color = vfx_color
	ring.points = _build_circle_points(radius, true)
	parent.add_child(ring)
	return ring

func _get_area_aura_vfx_color(color: Color) -> Color:
	var multiplier = 1.0 - Global.AREA_AURA_VFX_DARKENING
	return Color(color.r * multiplier, color.g * multiplier, color.b * multiplier, color.a)

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

func _build_dash_cooldown_progress_points(progress: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	var clamped_progress = clampf(progress, 0.0, 1.0)
	if clamped_progress <= 0.0:
		return points

	var segment_count = 48
	var point_count = int(ceil(float(segment_count) * clamped_progress)) + 1
	point_count = min(max(point_count, 2), segment_count + 1)

	for i in range(point_count):
		var progress_at_point = min(float(i) / float(segment_count), clamped_progress)
		var angle = -PI * 0.5 + TAU * progress_at_point
		points.append(Vector2(cos(angle), sin(angle)) * DASH_CHARGE_RING_RADIUS)

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
	var parent = _get_vfx_parent()
	if parent == null:
		mote.queue_free()
		return

	parent.add_child(mote)
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
	sloth_aura_vfx.z_index = PASSIVE_RING_Z_INDEX
	sloth_aura_vfx.z_as_relative = false
	sloth_aura_vfx.show_behind_parent = true
	add_child(sloth_aura_vfx)
	move_child(sloth_aura_vfx, 0)

	_add_ring_to_node(sloth_aura_vfx, SLOW_AURA_RADIUS, Color(0.25, 0.95, 1.0, 0.4), 2.0)

	var particles = CPUParticles2D.new()
	particles.amount = 64
	particles.lifetime = 1.1
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 45.0
	particles.initial_velocity_max = 120.0
	particles.color = _get_area_aura_vfx_color(Color(0.25, 0.95, 1.0, 0.46))
	particles.z_index = PASSIVE_RING_Z_INDEX
	particles.z_as_relative = false
	sloth_aura_vfx.add_child(particles)
	particles.emitting = true

func _spawn_clone_vfx(duration: float) -> void:
	if is_instance_valid(envy_clone_vfx):
		envy_clone_vfx.queue_free()

	envy_clone_vfx = Node2D.new()
	envy_clone_vfx.name = "MirrorCloneVFX"
	envy_clone_vfx.position = ENVY_CLONE_OFFSET
	envy_clone_vfx.z_index = 25
	add_child(envy_clone_vfx)

	var clone_visual = _create_player_mirror_visual()
	if clone_visual != null:
		envy_clone_vfx.add_child(clone_visual)

	_add_ring_to_node(envy_clone_vfx, 36.0, Color(0.4, 0.95, 1.0, 0.44), 2.0)
	var particles = CPUParticles2D.new()
	particles.amount = 36
	particles.lifetime = 0.7
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 25.0
	particles.initial_velocity_max = 80.0
	particles.color = _get_area_aura_vfx_color(Color(0.42, 0.95, 1.0, 0.52))
	particles.z_index = 26
	envy_clone_vfx.add_child(particles)
	particles.emitting = true

	var tree = get_tree()
	if tree == null:
		return
	var cleanup_timer = tree.create_timer(duration, false)
	cleanup_timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(envy_clone_vfx))

func _create_player_mirror_visual() -> Node:
	if aparencia == null or not (aparencia is Node):
		return null

	var visual = (aparencia as Node).duplicate()
	visual.name = "MirroredPlayerCopy"
	if visual is CanvasItem:
		(visual as CanvasItem).modulate = ENVY_CLONE_VISUAL_MODULATE
		(visual as CanvasItem).z_index = 27
	if visual is Node2D and aparencia is Node2D:
		(visual as Node2D).position = (aparencia as Node2D).position
		(visual as Node2D).scale = (aparencia as Node2D).scale
	if visual is AnimatedSprite2D and aparencia is AnimatedSprite2D:
		var animated_visual = visual as AnimatedSprite2D
		var player_visual = aparencia as AnimatedSprite2D
		animated_visual.animation = player_visual.animation
		animated_visual.frame = player_visual.frame
		animated_visual.flip_h = not player_visual.flip_h
		animated_visual.play()

	return visual

func _sync_player_mirror_visual(parent: Node) -> void:
	if parent == null or aparencia == null:
		return

	var visual = parent.get_node_or_null("MirroredPlayerCopy")
	if visual is CanvasItem:
		(visual as CanvasItem).modulate = ENVY_CLONE_VISUAL_MODULATE
	if visual is AnimatedSprite2D and aparencia is AnimatedSprite2D:
		var animated_visual = visual as AnimatedSprite2D
		var player_visual = aparencia as AnimatedSprite2D
		animated_visual.animation = player_visual.animation
		animated_visual.frame = player_visual.frame
		animated_visual.flip_h = not player_visual.flip_h
		if player_visual.is_playing() and not animated_visual.is_playing():
			animated_visual.play()

func _aim_player_mirror_visual(parent: Node, direction: Vector2) -> void:
	if parent == null or direction == Vector2.ZERO:
		return

	var visual = parent.get_node_or_null("MirroredPlayerCopy")
	if visual is AnimatedSprite2D:
		var animated_visual = visual as AnimatedSprite2D
		animated_visual.animation = _get_animation_for_direction(direction)
		animated_visual.flip_h = direction.x < 0.0
		animated_visual.play()

func _queue_free_if_valid(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()


func gain_xp(amount: int) -> void:
	current_xp += amount
	emit_signal("xp_updated", current_xp, xp_to_next_level)

	if not upando and current_xp >= xp_to_next_level:
		upando = true
		level_up()

## Resets XP so the current wave awards exactly one level-up when cleared.
func start_wave_xp_goal(enemy_count: int, context: String = "normal", boss_pecado: int = 0) -> void:
	current_xp = 0
	xp_to_next_level = max(enemy_count, 1)
	level_up_context = context
	level_up_boss_pecado = boss_pecado
	emit_signal("xp_updated", current_xp, xp_to_next_level)

## Emits a level-up event; the HUD popup owns the final upgrade selection.
func level_up() -> void:
	level += 1
	current_xp -= xp_to_next_level
	emit_signal("level_updated", level, current_xp, xp_to_next_level)
	emit_signal("xp_updated", current_xp, xp_to_next_level)
