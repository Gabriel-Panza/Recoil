extends CharacterBody2D

# --- Status melhoráveis via Level Ups ---
@export var max_health: int = 1000
@export var current_health: int = 1000
@export var attack_damage: float = 25.0
@export var fire_rate: float = 1.0
@export var recoil_force: float = 550.0
@export var friction: float = 750.0
var is_invulnerable: bool = false

# --- DASH ---
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 5.0

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
		"description": "Create a field that greatly slows all enemies inside it, but you become slightly slower too.",
		"cooldown": 15.0
	},
	"gluttony_devour": {
		"name": "Devour",
		"description": "Consume two nearby enemies to heal yourself for a large amount, but become very slow for 5 seconds.",
		"cooldown": 20.0
	},
	"envy_mirror_clone": {
		"name": "Mirror Clone",
		"description": "Summon a mirror clone that shoots with you for a short time. Clone bullets can hit anything, including you.",
		"cooldown": 15.0
	},
	"wrath_burst": {
		"name": "Wrath Burst",
		"description": "Fire a radial burst of bullets, but take some damage.",
		"cooldown": 20.0
	},
	"lust_for_perfection": {
		"name": "Perfection",
		"description": "Become invulnerable briefly, then take double damage for 5 seconds after the invulnerability ends.",
		"cooldown": 25.0
	},
	"greed_treasure_rain": {
		"name": "Treasure Rain",
		"description": "Rain golden projectiles from above, dealing damage to everything, including you.",
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
			_spawn_projectile(global_position, PI - final_angle, shot_damage * 0.75)

		if envy_clone_active:
			_spawn_projectile(global_position + Vector2(48, 0), PI - final_angle, shot_damage * 0.75, true)

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

	return damage

func _spawn_projectile(spawn_position: Vector2, angle: float, projectile_damage: float, can_hit_player: bool = false) -> void:
	if not pistol_bullet_scene:
		return

	var bullet = pistol_bullet_scene.instantiate()
	bullet.global_position = spawn_position
	bullet.direction = Vector2(cos(angle), sin(angle))
	bullet.damage = projectile_damage
	if can_hit_player:
		bullet.add_to_group("EnemyProjectile")
	get_tree().root.add_child(bullet)

func perform_dash(direction: Vector2, uses_double_dash_charge: bool = false) -> void:
	can_dash = false
	is_dashing = true
	
	velocity = direction * dash_speed
	await get_tree().create_timer(dash_duration).timeout
	
	is_dashing = false
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

	if has_shield:
		has_shield = false
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
	if gluttony_heal_kill_enabled:
		heal(max_health * 0.04)

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
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if is_instance_valid(enemy) and enemy.get("speed") != null:
			_remember_enemy_base_speed(enemy)
			enemy.set("speed", enemy.get("speed") * 0.35)

	var old_dash_speed = dash_speed
	dash_speed *= 0.75
	await get_tree().create_timer(5.0).timeout
	dash_speed = old_dash_speed
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if is_instance_valid(enemy) and enemy.has_meta("base_speed"):
			enemy.set("speed", enemy.get_meta("base_speed"))

func activate_gluttony_devour() -> void:
	var nearby_enemies = get_tree().get_nodes_in_group("Enemy")
	nearby_enemies = nearby_enemies.filter(func(enemy): return is_instance_valid(enemy) and not enemy.is_in_group("Boss") and enemy.global_position.distance_to(global_position) <= 260.0)
	nearby_enemies.sort_custom(func(a, b): return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))

	for i in range(min(2, nearby_enemies.size())):
		if nearby_enemies[i].has_method("die"):
			nearby_enemies[i].die()

	heal(max_health * 0.25)
	var old_dash_speed = dash_speed
	dash_speed *= 0.5
	await get_tree().create_timer(5.0).timeout
	dash_speed = old_dash_speed

func activate_envy_mirror_clone() -> void:
	envy_clone_active = true
	await get_tree().create_timer(8.0).timeout
	envy_clone_active = false

func activate_wrath_burst() -> void:
	var burst_damage = attack_damage * 1.1
	for i in range(16):
		var angle = TAU * float(i) / 16.0
		_spawn_projectile(global_position, angle, burst_damage)
	take_damage(20)

func activate_lust_for_perfection() -> void:
	is_invulnerable = true
	await get_tree().create_timer(3.0).timeout
	is_invulnerable = false
	damage_taken_multiplier = 2.0
	await get_tree().create_timer(5.0).timeout
	damage_taken_multiplier = 1.0

func activate_greed_treasure_rain() -> void:
	for i in range(20):
		var spawn_position = global_position + Vector2(randf_range(-420.0, 420.0), -360.0 - randf_range(0.0, 180.0))
		_spawn_projectile(spawn_position, PI / 2.0, attack_damage * 1.2, true)
		await get_tree().create_timer(0.06).timeout

func _trigger_recoil_explosion() -> void:
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if is_instance_valid(enemy) and enemy.has_method("take_damage") and enemy.global_position.distance_to(global_position) <= 190.0:
			enemy.take_damage(attack_damage * 1.4)

func _apply_sloth_slow_aura() -> void:
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if not is_instance_valid(enemy) or enemy.get("speed") == null:
			continue

		_remember_enemy_base_speed(enemy)
		var base_speed = enemy.get_meta("base_speed")
		if enemy.global_position.distance_to(global_position) <= 260.0:
			enemy.set("speed", base_speed * 0.75)
		else:
			enemy.set("speed", base_speed)

func _remember_enemy_base_speed(enemy: Node) -> void:
	if not enemy.has_meta("base_speed"):
		enemy.set_meta("base_speed", enemy.get("speed"))


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
