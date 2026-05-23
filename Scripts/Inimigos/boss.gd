extends CharacterBody2D
class_name Boss

enum BossState { SLOTH, GLUTTONY, ENVY, WRATH, LUST, GREED, PRIDE }
enum SlothSubState { IDLE, PREPARE, ATTACK, SPECIAL }
enum GluttonySubState { IDLE, PREPARE, ATTACK, SPECIAL }
enum EnvySubState { IDLE, PREPARE, ATTACK, SPECIAL }
enum WrathSubState { IDLE, PREPARE, ATTACK, SPECIAL }
enum LustSubState { IDLE, PREPARE, ATTACK, SPECIAL }
enum GreedSubState { IDLE, PREPARE, ATTACK, SPECIAL }
enum PrideSubState { IDLE, PREPARE, ATTACK, SPECIAL }

signal boss_defeated

@export var max_health: int = 500
@export var speed: float = 85.0
@export var damage: int = 50
@export var xp_drop: int = 1

const ENEMY_COLLISION_MASK: int = 4
const ENEMY_BODY_COLLISION_SCALE: float = 0.7

var current_health: int
var player: Node2D
var aparencia
var health_bar: ProgressBar
var is_dead: bool = false

var current_state: BossState
var current_sub_state = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	add_to_group("Boss")
	add_to_group("Enemy")
	_setup_enemy_body_collision()
	aparencia = $AparenciaAnimada

	# Define o estado baseado no pecado atual
	match Global.pecado:
		7:
			max_health = 1250
			current_state = BossState.PRIDE
			current_sub_state = PrideSubState.IDLE
		6:
			max_health = 1100
			current_state = BossState.GREED
			current_sub_state = GreedSubState.IDLE
		5:
			max_health = 950
			current_state = BossState.LUST
			current_sub_state = LustSubState.IDLE
		4:
			max_health = 800
			current_state = BossState.WRATH
			current_sub_state = WrathSubState.IDLE
		3:
			max_health = 700
			current_state = BossState.ENVY
			current_sub_state = EnvySubState.IDLE
		2:
			max_health = 600
			current_state = BossState.GLUTTONY
			current_sub_state = GluttonySubState.IDLE
		1:
			max_health = 500
			current_state = BossState.SLOTH
			current_sub_state = SlothSubState.IDLE
		_:
			max_health = 1250
			current_state = BossState.PRIDE
			current_sub_state = PrideSubState.IDLE
	current_health = max_health
	call_deferred("_setup_health_bar")

func _physics_process(delta: float) -> void:
	if player:
		match current_state:
			BossState.PRIDE:
				aparencia.play("pecado7")
				handle_pride(delta)
			BossState.GREED:
				aparencia.play("pecado6")
				handle_greed(delta)
			BossState.LUST:
				aparencia.play("pecado5")
				handle_lust(delta)
			BossState.WRATH:
				aparencia.play("pecado4")
				handle_wrath(delta)
			BossState.ENVY:
				aparencia.play("pecado3")
				handle_envy(delta)
			BossState.GLUTTONY:
				aparencia.play("pecado2")
				handle_gluttony(delta)
			BossState.SLOTH:
				aparencia.play("pecado1")
				handle_sloth(delta)

func handle_pride(delta: float):
	match current_sub_state:
		PrideSubState.IDLE:
			# Lógica para Pride idle
			pass
		PrideSubState.PREPARE:
			# Lógica para Pride prepare
			pass
		PrideSubState.ATTACK:
			# Lógica para Pride attack
			pass
		PrideSubState.SPECIAL:
			# Lógica para Pride special
			pass
	
	# Movimento básico
	_move_toward_player()

func _move_toward_player() -> void:
	if player == null:
		return

	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()

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

func handle_greed(delta: float):
	_move_toward_player()
	# Implemente lógica específica para Greed
	pass

func handle_wrath(delta: float):
	_move_toward_player()
	# Implemente lógica específica para Wrath
	pass

func handle_envy(delta: float):
	_move_toward_player()
	# Implemente lógica específica para Envy
	pass

func handle_lust(delta: float):
	_move_toward_player()
	# Implemente lógica específica para Lust
	pass

func handle_gluttony(delta: float):
	_move_toward_player()
	# Implemente lógica específica para Gluttony
	pass

func handle_sloth(delta: float):
	_move_toward_player()
	# Implemente lógica específica para Sloth
	pass

func take_damage(amount: float) -> void:
	if is_dead:
		return

	current_health -= int(round(amount))
	_update_health_bar()
	if current_health <= 0:
		die()
		return
	
	# Tween para dano
	var tween = create_tween()
	tween.tween_property(aparencia, "modulate", Color.RED, 0.1)
	tween.tween_property(aparencia, "modulate", Color.WHITE, 0.1)

func die() -> void:
	if is_dead:
		return

	is_dead = true
	current_health = 0
	_update_health_bar()
	set_physics_process(false)

	var should_grant_rewards = Global.pecado < 7
	if should_grant_rewards and player and player.has_method("gain_xp"):
		player.gain_xp(xp_drop)
	if should_grant_rewards and player and player.has_method("on_enemy_killed"):
		player.on_enemy_killed(self)
	
	Global.pecado += 1
	boss_defeated.emit()
	
	queue_free()

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

	var background = StyleBoxFlat.new()
	background.bg_color = Color(0.08, 0.06, 0.06, 0.9)
	background.set_corner_radius_all(1)

	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.95, 0.03, 0.03, 0.96)
	fill.set_corner_radius_all(1)

	health_bar.add_theme_stylebox_override("background", background)
	health_bar.add_theme_stylebox_override("fill", fill)
	add_child(health_bar)
	_update_health_bar()

func _update_health_bar() -> void:
	if not health_bar:
		return

	health_bar.max_value = max(max_health, 1)
	health_bar.value = clamp(current_health, 0, max_health)

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
