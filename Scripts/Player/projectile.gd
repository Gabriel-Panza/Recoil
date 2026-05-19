extends Area2D

# Configurações do tiro
var speed: float = 700.0
var direction: Vector2 = Vector2.RIGHT
var damage
@onready var aparencia = get_node_or_null("AnimatedProjectile") if get_node_or_null("AnimatedProjectile") else get_node_or_null("Sprite2D") # aqui tbm
@onready var particles: CPUParticles2D = get_node_or_null("CPUParticles2D")

# Player
var player_path: NodePath = "/root/GameScene/Player"
var player

# Lista de espera de colisões deste frame
var hit_queue: Array = []

func _ready():
	player = get_node_or_null(player_path)
	rotation = direction.angle()
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	if aparencia and aparencia is AnimatedSprite2D:
		aparencia.play("default")
	
	
	if self.is_in_group("EnemyProjectile"):
		speed = 500.0
		collision_layer = 0
		collision_mask = 6 if self.is_in_group("Projectile") else 2

	_configure_projectile_vfx()
	
func _process(delta):
	position += direction * speed * delta
	process_hit_queue()

func _on_area_entered(area):
	var parent = area.get_parent()
	
	if self.is_in_group("Projectile") and parent.is_in_group("Enemy"):
		_queue_hit(parent)
	
	elif self.is_in_group("EnemyProjectile") and parent.is_in_group("Player"):
		_queue_hit(parent)

func _on_body_entered(body: Node) -> void:
	if self.is_in_group("EnemyProjectile") and body.is_in_group("Player"):
		_queue_hit(body)

func _queue_hit(target: Node) -> void:
	if target not in hit_queue:
		hit_queue.append(target)

func process_hit_queue():
	if hit_queue.is_empty():
		return
	
	hit_queue.sort_custom(func(a, b): 
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)
	
	for target in hit_queue:
		if not is_instance_valid(target):
			continue

		if target.is_in_group("Enemy") and target.has_method("take_damage"):
			var enemy_damage = damage if damage != null else player.attack_damage
			target.take_damage(enemy_damage)
		elif target.is_in_group("Player") and target.has_method("take_damage"):
			var player_damage = damage if damage != null else 20.0
			target.take_damage(player_damage)

		_spawn_hit_particles(global_position)
			
		# Destrói o projétil e interrompe o loop imediatamente
		queue_free()
		return
		
	# Limpa a lista para o próximo frame se não tiver achado alvos válidos
	hit_queue.clear()

func _on_screen_exited():
	await get_tree().create_timer(1).timeout
	queue_free()

func _configure_projectile_vfx() -> void:
	if not particles:
		return

	if self.is_in_group("EnemyProjectile") and self.is_in_group("Projectile"):
		particles.amount = 72
		particles.lifetime = 0.42
		particles.initial_velocity_min = 18.0
		particles.initial_velocity_max = 70.0

	if self.has_meta("vfx_color"):
		particles.color = self.get_meta("vfx_color")
	elif self.is_in_group("EnemyProjectile") and self.is_in_group("Projectile"):
		particles.color = Color(1.0, 0.78, 0.08, 0.95)
	elif self.is_in_group("Projectile"):
		particles.color = Color(1.0, 0.52, 0.16, 0.85)

	particles.emitting = true

func _spawn_hit_particles(hit_position: Vector2) -> void:
	var burst = CPUParticles2D.new()
	burst.global_position = hit_position
	burst.amount = 18
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.lifetime = 0.22
	burst.direction = Vector2.UP
	burst.spread = 180.0
	burst.gravity = Vector2.ZERO
	burst.initial_velocity_min = 35.0
	burst.initial_velocity_max = 120.0
	burst.color = _get_vfx_color()
	burst.z_index = 35

	var vfx_parent = get_tree().current_scene if get_tree().current_scene else get_tree().root
	vfx_parent.add_child(burst)
	burst.emitting = true

	var cleanup_timer = get_tree().create_timer(burst.lifetime + 0.2)
	cleanup_timer.timeout.connect(Callable(burst, "queue_free"))

func _get_vfx_color() -> Color:
	if self.has_meta("vfx_color"):
		return self.get_meta("vfx_color")
	if self.is_in_group("EnemyProjectile") and self.is_in_group("Projectile"):
		return Color(1.0, 0.78, 0.08, 0.95)
	if self.is_in_group("EnemyProjectile"):
		return Color(1.0, 0.18, 0.1, 0.9)
	return Color(1.0, 0.36, 0.12, 0.9)
