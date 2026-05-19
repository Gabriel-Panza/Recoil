extends CharacterBody2D

# --- Status melhoráveis via Level Ups ---
@export var max_health: int = 1000
@export var current_health: int = 1000
@export var attack_damage: float = 30.0
@export var fire_rate: float = 1.0
const MIN_FIRE_RATE: float = 0.25
var base_fire_rate: float = 1.0
var attack_speed_bonus: float = 0.0
@export var recoil_force: float = 480.0
@export var friction: float = 725.0
var is_invulnerable: bool = false

# --- DASH ---
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 5.0
const MAX_ABILITY_AREA_RADIUS: float = 180.0
const DEVOUR_RADIUS: float = MAX_ABILITY_AREA_RADIUS
const SLOW_AURA_RADIUS: float = MAX_ABILITY_AREA_RADIUS
const SHOCKWAVE_RADIUS: float = MAX_ABILITY_AREA_RADIUS
const SHOCKWAVE_DAMAGE_MULTIPLIER: float = 0.35
const SHOCKWAVE_DASH_DAMAGE_MULTIPLIER: float = 0.75

# --- TIRO ---
@export var pistol_bullet_scene: PackedScene
var shot_count = 1
var spread_angle = 15.0 

const ACTIVE_ABILITY_IDS = [
	"sloth_field",
	"gluttony_devour",
	"envy_mirror_clone",
	"wrath_burst",
	"lust_for_perfection",
	"greed_treasure_rain"
]

const ACTIVE_ABILITY_DATA = {
	"sloth_field": {
		"name": "Sloth Field",
		"description": "Create a 180px field for 5 seconds. Enemies inside drop to 35% speed, but your dash speed drops to 75% during the field.",
		"cooldown": 15.0
	},
	"gluttony_devour": {
		"name": "Devour",
		"description": "Consume up to two enemies within 180px. Green motes fly back and heal up to 12.5% max health when they arrive, but your dash speed is halved for 5 seconds.",
		"cooldown": 20.0
	},
	"envy_mirror_clone": {
		"name": "Mirror Clone",
		"description": "Summon a mirror clone that fires random risky shots with you for a short time. Clone bullets can hit anything, including you.",
		"cooldown": 15.0
	},
	"wrath_burst": {
		"name": "Wrath Burst",
		"description": "Fire 16 radial bullets for 110% attack damage each, then take 20 damage.",
		"cooldown": 20.0
	},
	"lust_for_perfection": {
		"name": "Perfection",
		"description": "Become invulnerable for 3 seconds, then take double damage for 5 seconds.",
		"cooldown": 25.0
	},
	"greed_treasure_rain": {
		"name": "Treasure Rain",
		"description": "Rain golden projectiles from above. Each projectile deals 120% attack damage only when it collides, including with you.",
		"cooldown": 20.0
	},
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
var has_shield: bool = false
var recoil_explosion_enabled: bool = false
var offensive_dash_enabled: bool = false
var double_dash_charges: int = 0
var max_dash_charges: int = 1
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
	base_fire_rate = fire_rate
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

func add_attack_speed_bonus(amount: float) -> void:
	if not can_upgrade_attack_speed():
		return

	attack_speed_bonus += amount
	_recalculate_fire_rate()

func get_attack_speed_percent() -> float:
	return (base_fire_rate / max(fire_rate, MIN_FIRE_RATE)) * 100.0

func can_upgrade_attack_speed() -> bool:
	return fire_rate > MIN_FIRE_RATE + 0.0001

func _recalculate_fire_rate() -> void:
	fire_rate = max(base_fire_rate / max(1.0 + attack_speed_bonus, 0.001), MIN_FIRE_RATE)

func _physics_process(delta: float) -> void:
	_update_active_ability_cooldowns(delta)

	var mouse_pos = get_global_mouse_position()
	var look_direction = global_position.direction_to(mouse_pos)
	_update_direction_animation(look_direction)
	
	if pause_control.canMove:
		# Dash na direção do mouse
		if Input.is_action_just_pressed("dash") and (can_dash or double_dash_charges > 0) and not is_dashing:
			var uses_extra_dash_charge = max_dash_charges > 1 and double_dash_charges > 0
			perform_dash(look_direction, uses_extra_dash_charge)

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

	# Aplicar Atrito se não estiver no meio de um dash
	if not is_dashing:
		if velocity.length() > 0:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()

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
		var bullet = pistol_bullet_scene.instantiate()
			
		# Calcula o deslocamento do ângulo dado que podemos ter multiplos tiros
		var angle_offset = deg_to_rad((i - (shot_count - 1) / 2.0) * spread_angle)
		var final_angle = base_angle + angle_offset
		
		bullet.global_position = global_position
		bullet.direction = Vector2(cos(final_angle), sin(final_angle))
		bullet.damage = shot_damage
		get_tree().root.add_child(bullet)

		if envy_mirror_shot_enabled and randf() < 0.25:
			_spawn_projectile(global_position, _get_mirrored_shot_angle(final_angle), shot_damage * 0.75, false, Color(0.25, 0.95, 1.0, 0.9))

		if envy_clone_active:
			var clone_position = global_position + Vector2(48, 0)
			_spawn_projectile(clone_position, _get_clone_random_shot_angle(clone_position), shot_damage * 0.75, true, Color(0.25, 0.95, 1.0, 0.9))

	velocity += -direction * recoil_force
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
		if wrath_shot_count >= 3:
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
	if projectile_vfx_color.a > 0.0:
		bullet.set_meta("vfx_color", projectile_vfx_color)
	if can_hit_player:
		bullet.add_to_group("EnemyProjectile")
	get_tree().root.add_child(bullet)
	return bullet

func perform_dash(direction: Vector2, uses_double_dash_charge: bool = false) -> void:
	can_dash = false
	is_dashing = true
	if uses_double_dash_charge:
		_spawn_burst_particles(global_position, Color(0.35, 0.7, 1.0, 0.9), 22, 0.28, 160.0)
	
	velocity = direction * dash_speed
	await get_tree().create_timer(dash_duration).timeout
	
	is_dashing = false
	if offensive_dash_enabled:
		_trigger_offensive_dash_explosion()

	if uses_double_dash_charge:
		double_dash_charges = max(double_dash_charges - 1, 0)
		if double_dash_charges > 0:
			can_dash = true
		else:
			dash_cd_timer.start(dash_cooldown)
	else:
		double_dash_charges = max(max_dash_charges - 1, 0)
		dash_cd_timer.start(dash_cooldown)

func take_damage(amount: float) -> void:
	if is_invulnerable: 
		return

	if offensive_dash_enabled and is_dashing:
		_spawn_burst_particles(global_position, Color(0.25, 0.95, 1.0, 0.85), 18, 0.22, 110.0)
		return

	if has_shield:
		has_shield = false
		_spawn_burst_particles(global_position, Color(0.35, 0.9, 1.0, 0.95), 34, 0.35, 150.0)
		emit_signal("stats_updated")
		return

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
	
	await get_tree().create_timer(0.2).timeout
	is_invulnerable = false

func die():
	# aparencia.play("death")
	if pause_control:
		pause_control.freeze()
	for musica in get_tree().get_nodes_in_group("Music"):
		musica.stop()
	# $Lose.play()
	await get_tree().create_timer(1.0).timeout
	game_over.visible = true

func win():
	for musica in get_tree().get_nodes_in_group("Music"):
		musica.stop()
	get_tree().paused = true
	# $Win.play()
	game_win.visible = true

func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func _on_dash_cd_timer_timeout() -> void:
	can_dash = true
	double_dash_charges = max(max_dash_charges - 1, 0)

func _on_hitbox_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent.is_in_group("Enemy"): 
		if not enemies_in_contact.has(parent):
			enemies_in_contact.append(parent)
		
		if contact_damage_timer.is_stopped():
			take_damage(20)
			contact_damage_timer.start()

func _on_hitbox_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent in enemies_in_contact:
		enemies_in_contact.erase(parent)
	
	if enemies_in_contact.is_empty():
		contact_damage_timer.stop()

func _on_contact_damage_timer_timeout() -> void:
	enemies_in_contact = enemies_in_contact.filter(func(e): return is_instance_valid(e))
	
	if not enemies_in_contact.is_empty():
		take_damage(20)
	else:
		contact_damage_timer.stop()

func is_active_ability_id(option_id: String) -> bool:
	return option_id in ACTIVE_ABILITY_IDS

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

func use_active_ability(slot: String) -> void:
	if not active_abilities.has(slot):
		return

	var ability_id = active_abilities[slot]
	if ability_id == "" or get_active_slot_cooldown(slot) > 0.0:
		return

	match ability_id:
		"sloth_field":
			activate_sloth_field()
		"gluttony_devour":
			activate_gluttony_devour()
		"envy_mirror_clone":
			activate_envy_mirror_clone()
		"wrath_burst":
			activate_wrath_burst()
		"lust_for_perfection":
			activate_lust_for_perfection()
		"greed_treasure_rain":
			activate_greed_treasure_rain()

	active_ability_cooldown_remaining[slot] = get_active_ability_cooldown(ability_id)
	emit_signal("stats_updated")

func _update_active_ability_cooldowns(delta: float) -> void:
	for slot in active_ability_cooldown_remaining.keys():
		if active_ability_cooldown_remaining[slot] > 0.0:
			active_ability_cooldown_remaining[slot] = max(active_ability_cooldown_remaining[slot] - delta, 0.0)

func heal(amount: float) -> void:
	current_health = int(min(current_health + amount, max_health))
	emit_signal("hp_updated", current_health, max_health)

func on_enemy_killed(_enemy: Node) -> void:
	if gluttony_heal_kill_enabled and is_instance_valid(_enemy):
		_spawn_heal_motes(_enemy.global_position, max_health * 0.01, 4)

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
	_spawn_field_vfx(field_position, field_radius, Color(0.55, 0.28, 1.0, 0.72), 5.0)

	var old_dash_speed = dash_speed
	var slowed_enemies: Array = []
	var elapsed = 0.0
	dash_speed *= 0.75

	while elapsed < 5.0:
		for enemy in get_tree().get_nodes_in_group("Enemy"):
			if not is_instance_valid(enemy) or enemy.get("speed") == null:
				continue

			_remember_enemy_base_speed(enemy)
			var base_speed = enemy.get_meta("base_speed")
			var is_inside_field = enemy.global_position.distance_to(field_position) <= field_radius
			if is_inside_field:
				enemy.set_meta("sloth_field_active", true)
				enemy.set("speed", base_speed * 0.3)
				if enemy not in slowed_enemies:
					slowed_enemies.append(enemy)
			elif enemy in slowed_enemies:
				enemy.set("speed", base_speed)
				enemy.remove_meta("sloth_field_active")
				slowed_enemies.erase(enemy)

		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1

	dash_speed = old_dash_speed
	for enemy in slowed_enemies:
		if is_instance_valid(enemy) and enemy.has_meta("base_speed"):
			enemy.set("speed", enemy.get_meta("base_speed"))
			enemy.remove_meta("sloth_field_active")

func activate_gluttony_devour() -> void:
	var nearby_enemies = get_tree().get_nodes_in_group("Enemy")
	nearby_enemies = nearby_enemies.filter(func(enemy): return is_instance_valid(enemy) and not enemy.is_in_group("Boss") and enemy.global_position.distance_to(global_position) <= DEVOUR_RADIUS)
	nearby_enemies.sort_custom(func(a, b): return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))

	var devoured_count = min(2, nearby_enemies.size())
	for i in range(devoured_count):
		var enemy = nearby_enemies[i]
		var enemy_position = enemy.global_position
		_spawn_burst_particles(enemy_position, Color(0.2, 1.0, 0.45, 0.95), 30, 0.4, 130.0)
		_spawn_heal_motes(enemy_position, (max_health * 0.125) / max(devoured_count, 1), 7)
		if enemy.has_method("die"):
			enemy.die()

	var old_dash_speed = dash_speed
	dash_speed *= 0.5
	await get_tree().create_timer(5.0).timeout
	dash_speed = old_dash_speed

func activate_envy_mirror_clone() -> void:
	envy_clone_active = true
	_spawn_clone_vfx(8.0)
	await get_tree().create_timer(8.0).timeout
	envy_clone_active = false
	if is_instance_valid(envy_clone_vfx):
		envy_clone_vfx.queue_free()

func activate_wrath_burst() -> void:
	_spawn_burst_particles(global_position, Color(1.0, 0.25, 0.05, 0.95), 48, 0.4, 230.0)
	_spawn_ring_vfx(global_position, 150.0, Color(1.0, 0.18, 0.04, 0.75), 0.35)
	var burst_damage = attack_damage * 1.1
	for i in range(16):
		var angle = TAU * float(i) / 16.0
		_spawn_projectile(global_position, angle, burst_damage, false, Color(1.0, 0.25, 0.05, 0.95))
	take_damage(20)

func activate_lust_for_perfection() -> void:
	is_invulnerable = true
	_spawn_attached_aura(110.0, Color(1.0, 0.72, 0.95, 0.65), 3.0)
	await get_tree().create_timer(3.0).timeout
	is_invulnerable = false
	damage_taken_multiplier = 2.0
	_spawn_attached_aura(130.0, Color(1.0, 0.08, 0.28, 0.6), 5.0)
	await get_tree().create_timer(5.0).timeout
	damage_taken_multiplier = 1.0

func activate_greed_treasure_rain() -> void:
	_spawn_burst_particles(global_position, Color(1.0, 0.78, 0.08, 0.95), 42, 0.45, 180.0)
	for i in range(20):
		var spawn_position = global_position + Vector2(randf_range(-420.0, 420.0), -360.0 - randf_range(0.0, 180.0))
		_spawn_projectile(spawn_position, PI / 2.0, attack_damage * 1.2, true, Color(1.0, 0.78, 0.08, 0.95))
		await get_tree().create_timer(0.06).timeout

func _trigger_recoil_explosion() -> void:
	_spawn_burst_particles(global_position, Color(1.0, 0.52, 0.12, 0.95), 34, 0.3, 210.0)
	_spawn_ring_vfx(global_position, 80.0, Color(1.0, 0.45, 0.08, 0.72), 0.28)
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if is_instance_valid(enemy) and enemy.has_method("take_damage") and enemy.global_position.distance_to(global_position) <= SHOCKWAVE_RADIUS:
			enemy.take_damage(_get_shockwave_damage())

func _trigger_offensive_dash_explosion() -> void:
	_spawn_burst_particles(global_position, Color(0.25, 0.95, 1.0, 0.9), 36, 0.32, 190.0)
	_spawn_ring_vfx(global_position, 120.0, Color(0.25, 0.95, 1.0, 0.68), 0.3)
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if is_instance_valid(enemy) and enemy.has_method("take_damage") and enemy.global_position.distance_to(global_position) <= SHOCKWAVE_RADIUS:
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
		if enemy.global_position.distance_to(global_position) <= SLOW_AURA_RADIUS:
			enemy.set("speed", base_speed * 0.7)
		else:
			enemy.set("speed", base_speed)

func _remember_enemy_base_speed(enemy: Node) -> void:
	if not enemy.has_meta("base_speed"):
		enemy.set_meta("base_speed", enemy.get("speed"))

func _get_vfx_parent() -> Node:
	if get_tree().current_scene:
		return get_tree().current_scene
	return get_tree().root

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

	var cleanup_timer = get_tree().create_timer(lifetime + 0.25)
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
	particles.z_index = 25
	_get_vfx_parent().add_child(particles)
	particles.global_position = center
	particles.emitting = true

	var cleanup_timer = get_tree().create_timer(duration)
	cleanup_timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(particles))

func _spawn_attached_aura(radius: float, color: Color, duration: float) -> void:
	radius = min(radius, MAX_ABILITY_AREA_RADIUS)
	var aura = Node2D.new()
	aura.name = "TimedAuraVFX"
	aura.z_index = 25
	add_child(aura)

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
	particles.z_index = 25
	aura.add_child(particles)
	particles.emitting = true

	var cleanup_timer = get_tree().create_timer(duration)
	cleanup_timer.timeout.connect(Callable(self, "_queue_free_if_valid").bind(aura))

func _spawn_ring_vfx(center: Vector2, radius: float, color: Color, duration: float) -> void:
	radius = min(radius, MAX_ABILITY_AREA_RADIUS)
	var ring_vfx = Node2D.new()
	ring_vfx.name = "FilledRingVFX"
	ring_vfx.z_index = 24
	_get_vfx_parent().add_child(ring_vfx)
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
	ring.z_index = 24
	_build_ring_points(ring, radius)
	parent.add_child(ring)
	return ring

func _add_circle_fill_to_node(parent: Node, radius: float, color: Color) -> Polygon2D:
	radius = min(radius, MAX_ABILITY_AREA_RADIUS)
	var fill = Polygon2D.new()
	var fill_color = color
	fill_color.a *= 0.18
	fill.color = fill_color
	fill.polygon = _build_circle_points(radius, false)
	fill.z_index = 23
	parent.add_child(fill)
	return fill

func _build_ring_points(ring: Line2D, radius: float) -> void:
	ring.points = _build_circle_points(radius, true)

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
	sloth_aura_vfx.z_index = 20
	add_child(sloth_aura_vfx)

	_add_ring_to_node(sloth_aura_vfx, SLOW_AURA_RADIUS-45, Color(0.42, 0.18, 0.95, 0.38), 2.0)

	var particles = CPUParticles2D.new()
	particles.amount = 64
	particles.lifetime = 1.1
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 45.0
	particles.initial_velocity_max = 120.0
	particles.color = Color(0.55, 0.28, 1.0, 0.48)
	particles.z_index = 20
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

	_add_ring_to_node(envy_clone_vfx, 36.0, Color(0.25, 0.95, 1.0, 0.7), 2.0)
	var particles = CPUParticles2D.new()
	particles.amount = 36
	particles.lifetime = 0.7
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 25.0
	particles.initial_velocity_max = 80.0
	particles.color = Color(0.28, 0.92, 1.0, 0.82)
	particles.z_index = 26
	envy_clone_vfx.add_child(particles)
	particles.emitting = true

	var cleanup_timer = get_tree().create_timer(duration)
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
