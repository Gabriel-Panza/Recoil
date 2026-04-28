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
	
	if self.is_in_group("EnemyProjectile"):
		speed = 500.0
	
func _process(delta):
	position += direction * speed * delta
	process_hit_queue()

func _on_area_entered(area):
	var parent = area.get_parent()
	
	if self.is_in_group("Projectile") and parent.is_in_group("Enemy"):
		if parent not in hit_queue:
			hit_queue.append(parent)
	
	elif self.is_in_group("EnemyProjectile") and parent.is_in_group("Player"):
		if parent not in hit_queue:
			hit_queue.append(parent)

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
			target.take_damage(player.attack_damage)
		elif target.is_in_group("Player") and target.has_method("take_damage"):
			target.take_damage(damage)
			
		# Destrói o projétil e interrompe o loop imediatamente
		queue_free()
		return
		
	# Limpa a lista para o próximo frame se não tiver achado alvos válidos
	hit_queue.clear()

func _on_screen_exited():
	queue_free()
