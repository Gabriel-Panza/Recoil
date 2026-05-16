extends Area2D

# Configurações do tiro
var speed: float = 700.0
var direction: Vector2 = Vector2.RIGHT
var damage
@onready var aparencia = $Sprite2D

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
	
	if self.is_in_group("EnemyProjectile"):
		speed = 500.0
		collision_layer = 0
		collision_mask = 6 if self.is_in_group("Projectile") else 2
	
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
			
		# Destrói o projétil e interrompe o loop imediatamente
		queue_free()
		return
		
	# Limpa a lista para o próximo frame se não tiver achado alvos válidos
	hit_queue.clear()

func _on_screen_exited():
	await get_tree().create_timer(1).timeout
	queue_free()
