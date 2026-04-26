extends CharacterBody2D
class_name BaseEnemy 

@export var max_health: int = 100
@export var speed: float = 9000.0 # 75 m/s * 120fps
@export var damage: int = 20
@export var xp_drop: int = 10

var current_health: int
var player: Node2D
@onready var aparencia = $Aparencia

func _ready() -> void:
	current_health = max_health
	player = get_tree().get_first_node_in_group("Player")
	add_to_group("Enemy")

func _physics_process(delta: float) -> void:
	if player:
		mover(delta)

func mover(_delta: float) -> void:
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed * _delta
	move_and_slide()

func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		die()

	# Tween para demonstrar que tomou dano
	var tween = create_tween()
	tween.tween_property(aparencia, "modulate", Color.RED, 0.1)
	tween.tween_property(aparencia, "modulate", Color.WHITE, 0.1)

func die() -> void:
	if player and player.has_method("gain_xp"):
		player.gain_xp(xp_drop)
	queue_free()
