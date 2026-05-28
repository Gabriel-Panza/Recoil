extends CharacterBody2D
class_name BaseEnemy 

@export var max_health: int = 100
@export var speed: float = 125.0
@export var damage: int = 15
@export var xp_drop: int = 1

const ENEMY_COLLISION_MASK: int = 4
const ENEMY_BODY_COLLISION_SCALE: float = 0.7
const PECADO_SPRITE_ROW_BY_ID = {
	1: 6,
	2: 4,
	3: 5,
	4: 2,
	5: 3,
	6: 1,
	7: 0,
}

var current_health: int
var player: Node2D
var health_bar: ProgressBar
var is_dead: bool = false
@onready var aparencia = get_node_or_null("AnimatedAppearence")

func _ready() -> void:
	current_health = max_health
	player = get_tree().get_first_node_in_group("Player")
	add_to_group("Enemy")
	_setup_enemy_body_collision()
	call_deferred("_setup_health_bar")

func _physics_process(delta: float) -> void:
	if player:
		mover(delta)

func mover(_delta: float) -> void:
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()

func _configure_enemy_sprite_sheet(
	texture_path: String,
	frame_size: Vector2i,
	frames_per_row: int,
	states: Array,
	pecado_group_rows: Dictionary = {},
	animation_speed: float = 6.0,
	visual_scale: Vector2 = Vector2.ONE
) -> void:
	if aparencia == null:
		return

	var texture = load(texture_path) as Texture2D
	if texture == null:
		return

	var sprite_frames = SpriteFrames.new()
	if sprite_frames.has_animation("default"):
		sprite_frames.remove_animation("default")

	for pecado_id in range(1, 8):
		var group_row = int(pecado_group_rows.get(pecado_id, PECADO_SPRITE_ROW_BY_ID.get(pecado_id, 0)))
		for state_index in range(states.size()):
			var state_name = str(states[state_index])
			var animation_name = _get_pecado_animation_name(pecado_id, state_name if states.size() > 1 else "")
			sprite_frames.add_animation(animation_name)
			sprite_frames.set_animation_speed(animation_name, animation_speed)
			sprite_frames.set_animation_loop(animation_name, true)

			var sheet_row = group_row * states.size() + state_index
			for frame_index in range(frames_per_row):
				var atlas_frame = AtlasTexture.new()
				atlas_frame.atlas = texture
				atlas_frame.region = Rect2(
					Vector2(frame_index * frame_size.x, sheet_row * frame_size.y),
					Vector2(frame_size.x, frame_size.y)
				)
				sprite_frames.add_frame(animation_name, atlas_frame)

	aparencia.sprite_frames = sprite_frames
	aparencia.scale = visual_scale

func _play_pecado_animation(state_name: String = "") -> void:
	if aparencia == null or aparencia.sprite_frames == null:
		return

	var pecado_id = clampi(Global.pecado, 1, 7)
	var animation_name = _get_pecado_animation_name(pecado_id, state_name)
	if not aparencia.sprite_frames.has_animation(animation_name):
		animation_name = _get_pecado_animation_name(2, state_name)
	if not aparencia.sprite_frames.has_animation(animation_name):
		return

	if str(aparencia.animation) != animation_name or not aparencia.is_playing():
		aparencia.play(animation_name)

func _get_pecado_animation_name(pecado_id: int, state_name: String = "") -> String:
	if state_name == "":
		return "pecado%d" % pecado_id
	return "pecado%d_%s" % [pecado_id, state_name]

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

func take_damage(amount: float) -> void:
	if is_dead:
		return

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
	if is_dead:
		return

	is_dead = true
	current_health = 0
	_update_health_bar()
	set_physics_process(false)

	if _should_grant_xp() and player and player.has_method("gain_xp"):
		player.gain_xp(xp_drop)
	if player and player.has_method("on_enemy_killed"):
		player.on_enemy_killed(self)
	queue_free()

func _should_grant_xp() -> bool:
	return xp_drop > 0 and not bool(get_meta("skip_xp", false))

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
