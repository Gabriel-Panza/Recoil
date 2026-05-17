extends CharacterBody2D
class_name BaseEnemy 

@export var max_health: int = 100
@export var speed: float = 7500.0 # 75 m/s * 100fps
@export var damage: int = 20
@export var xp_drop: int = 1

var current_health: int
var player: Node2D
var health_bar: ProgressBar
@onready var aparencia = get_node_or_null("Aparencia")

func _ready() -> void:
	current_health = max_health
	player = get_tree().get_first_node_in_group("Player")
	add_to_group("Enemy")
	call_deferred("_setup_health_bar")

func _physics_process(delta: float) -> void:
	if player:
		mover(delta)

func mover(_delta: float) -> void:
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed * _delta
	move_and_slide()

func take_damage(amount: float) -> void:
	current_health -= int(round(amount))
	_update_health_bar()
	if current_health <= 0:
		die()
		return

	# Tween para demonstrar que tomou dano
	var tween = create_tween()
	tween.tween_property(aparencia, "modulate", Color.RED, 0.1)
	tween.tween_property(aparencia, "modulate", Color.WHITE, 0.1)

func die() -> void:
	if player and player.has_method("gain_xp"):
		player.gain_xp(xp_drop)
	if player and player.has_method("on_enemy_killed"):
		player.on_enemy_killed(self)
	queue_free()

func _setup_health_bar() -> void:
	if health_bar:
		return

	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(42, 5)
	health_bar.size = Vector2(42, 5)
	health_bar.position = Vector2(-21, _get_health_bar_y_offset())
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.z_index = 20

	var background = StyleBoxFlat.new()
	background.bg_color = Color(0.08, 0.06, 0.06, 0.88)
	background.set_corner_radius_all(1)

	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.9, 0.05, 0.05, 0.95)
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
			return -(collision.shape.height * 0.5) - 10.0
		if collision.shape is CircleShape2D:
			return -collision.shape.radius - 10.0
		if collision.shape is RectangleShape2D:
			return -(collision.shape.size.y * 0.5) - 10.0

	return -32.0
