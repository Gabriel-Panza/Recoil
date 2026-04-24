extends CharacterBody2D
class_name BaseEnemy 

@export var max_health: int = 100
@export var speed: float = 150.0
@export var damage: int = 20
@export var xp_drop: int = 10

var current_health: int
var player: Node2D

func _ready() -> void:
	current_health = max_health
	# Busca o player na cena dinamicamente
	player = get_tree().get_first_node_in_group("Player")
	add_to_group("Enemy") # Garante que está no grupo para o tiro reconhecer

func _physics_process(delta: float) -> void:
	if player and not get_tree().paused:
		mover(delta)

# Função virtual que pode ser reescrita pelos filhos
func mover(_delta: float) -> void:
	var distance = global_position.distance_to(player.global_position)
	
	# Só se move se estiver a mais de 45 pixels (distância segura para não "entrar")
	if distance > 45.0:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * speed
		move_and_slide()
	else:
		# Para na sua frente e tenta te dar dano
		velocity = Vector2.ZERO

# O seu projectile.gd já chama essa função "take_damage"
func take_damage(amount: int) -> void:
	current_health -= amount
	# Feedback visual rápido de dano
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	if current_health <= 0:
		die()

func die() -> void:
	if player and player.has_method("gain_xp"):
		player.gain_xp(xp_drop)
	queue_free()
