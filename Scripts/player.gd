extends CharacterBody2D

# --- Status melhoráveis via Level Ups ---
@export var max_health: int = 300
@export var current_health: int = 300
@export var attack_damage: float = 20.0
@export var fire_rate: float = 1.0
@export var recoil_force: float = 500.0
@export var friction: float = 900.0

# --- DASH ---
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 3.0

# --- TIRO ---
@export var pistol_bullet_scene: PackedScene
var shot_count = 1
var spread_angle = 15.0 

# --- SISTEMA DE DANO CONTÍNUO ---
var enemies_in_contact: Array = []
var contact_damage_timer: Timer

# --- Sprites ---
var aparencia

# --- ESTADOS DO JOGADOR ---
var can_shoot: bool = true
var can_dash: bool = true
var is_dashing: bool = false

# --- TIMERS ---
var shoot_timer: Timer
var dash_cd_timer: Timer

func _ready() -> void:
	aparencia = get_node_or_null("Aparencia")

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
	var mouse_pos = get_global_mouse_position()
	var look_direction = global_position.direction_to(mouse_pos)

	# Dash na direção do mouse
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		perform_dash(look_direction)

	# Atirar / Movimentação por Recuo
	if Input.is_action_pressed("shoot") and can_shoot and not is_dashing:
		shoot(look_direction)

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
	if mouse_pos.x < global_position.x:
		aparencia.flip_h = true  # Olha para esquerda
	else:
		aparencia.flip_h = false # Olha para direita
	
	var base_direction = (mouse_pos - global_position).normalized()
	var base_angle = base_direction.angle()
	
	for i in range(shot_count):
		var bullet = pistol_bullet_scene.instantiate()
			
		# Calcula o deslocamento do ângulo dado que podemos ter multiplos tiros
		var angle_offset = deg_to_rad((i - (shot_count - 1) / 2.0) * spread_angle)
		var final_angle = base_angle + angle_offset
		
		bullet.global_position = global_position
		bullet.direction = Vector2(cos(final_angle), sin(final_angle))
		bullet.damage = attack_damage 
		get_tree().root.add_child(bullet)

	velocity += -direction * recoil_force

func perform_dash(direction: Vector2) -> void:
	can_dash = false
	is_dashing = true
	
	velocity = direction * dash_speed
	await get_tree().create_timer(dash_duration).timeout
	
	is_dashing = false
	dash_cd_timer.start(dash_cooldown)

func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		print("Morreu! Game Over")

func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func _on_dash_cd_timer_timeout() -> void:
	can_dash = true

func _on_hitbox_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent.is_in_group("Inimigo"): 
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
