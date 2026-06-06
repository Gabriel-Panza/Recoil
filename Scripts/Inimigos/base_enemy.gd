extends CharacterBody2D
class_name BaseEnemy 

@export var max_health: int = 100
@export var speed: float = 130.0
@export var damage: int = 15
@export var xp_drop: int = 1

const PECADO_SPRITE_ROW_BY_ID = {
	1: 6,
	2: 4,
	3: 5,
	4: 2,
	5: 3,
	6: 1,
	7: 0,
}
const DAMAGE_FEEDBACK_COLOR: Color = Color(1.0, 0.08, 0.08, 1.0)
const HEAL_FEEDBACK_COLOR: Color = Color(0.18, 1.0, 0.32, 1.0)
const OBSTACLE_AVOIDANCE_LOOK_AHEAD: float = 82.0
const OBSTACLE_AVOIDANCE_PADDING: float = 8.0
const OBSTACLE_AVOIDANCE_FORCE: float = 0.95
const OBSTACLE_AVOIDANCE_MEMORY_TIME: float = 0.32
const SOFT_SEPARATION_PADDING: float = 10.0
const SOFT_SEPARATION_FORCE: float = 0.48
const SOFT_SEPARATION_IDLE_SPEED_MULTIPLIER: float = 0.35
const BODY_RADIUS_FALLBACK: float = 18.0

var current_health: int
var player: Node2D
var health_bar: ProgressBar
var is_dead: bool = false
var health_feedback_tween: Tween
var health_feedback_base_modulate: Color = Color.WHITE
var avoidance_side: int = 1
var avoidance_memory_timer: float = 0.0
@onready var aparencia = get_node_or_null("AnimatedAppearence")

func _ready() -> void:
	z_index = Global.CHARACTER_RENDER_Z_INDEX
	z_as_relative = false
	current_health = max_health
	if aparencia:
		health_feedback_base_modulate = aparencia.modulate
	player = get_tree().get_first_node_in_group(Global.GROUP_PLAYER)
	var player_arm_id = str(player.get("current_arm_id")) if player != null and player.get("current_arm_id") != null else ""
	match player_arm_id:
		"fast":
			speed = 140
		"heavy":
			speed = 127
		"unstable":
			speed = 132
	add_to_group(Global.GROUP_ENEMY)
	_setup_enemy_body_collision()
	call_deferred("_setup_health_bar")

func _physics_process(delta: float) -> void:
	if player:
		mover(delta)

func mover(_delta: float) -> void:
	var direction = global_position.direction_to(player.global_position)
	_move_with_obstacle_avoidance(direction, speed, _delta)

func _move_with_obstacle_avoidance(desired_direction: Vector2, move_speed: float, delta: float, include_soft_separation: bool = true) -> void:
	velocity = _get_obstacle_aware_velocity(desired_direction, move_speed, delta, include_soft_separation)
	move_and_slide()

func _get_obstacle_aware_velocity(desired_direction: Vector2, move_speed: float, delta: float, include_soft_separation: bool = true) -> Vector2:
	var desired_velocity = Vector2.ZERO
	if desired_direction != Vector2.ZERO and move_speed > 0.0:
		desired_velocity = _get_obstacle_aware_direction(desired_direction.normalized(), delta) * move_speed

	if not include_soft_separation:
		return desired_velocity

	var separation_velocity = _get_soft_separation_velocity(move_speed)
	if desired_velocity == Vector2.ZERO:
		return separation_velocity

	return (desired_velocity + separation_velocity).limit_length(move_speed)

func _get_soft_separation_velocity(move_speed: float) -> Vector2:
	var separation = _get_soft_separation_vector()
	if separation == Vector2.ZERO:
		return Vector2.ZERO

	return separation.limit_length(1.0) * move_speed * SOFT_SEPARATION_FORCE

func _get_idle_soft_separation_velocity(move_speed: float) -> Vector2:
	var separation = _get_soft_separation_vector()
	if separation == Vector2.ZERO:
		return Vector2.ZERO

	return separation.limit_length(1.0) * move_speed * SOFT_SEPARATION_IDLE_SPEED_MULTIPLIER

func _get_obstacle_aware_direction(move_dir: Vector2, delta: float) -> Vector2:
	if avoidance_memory_timer > 0.0:
		avoidance_memory_timer = max(avoidance_memory_timer - delta, 0.0)

	var blocking_side = _get_blocking_enemy_side(move_dir)
	if blocking_side != 0:
		avoidance_side = blocking_side
		avoidance_memory_timer = OBSTACLE_AVOIDANCE_MEMORY_TIME
	elif _has_blocking_slide_collision(move_dir):
		avoidance_side = _get_slide_collision_avoidance_side(move_dir)
		avoidance_memory_timer = OBSTACLE_AVOIDANCE_MEMORY_TIME

	if avoidance_memory_timer <= 0.0:
		return move_dir

	var side_dir = move_dir.rotated(PI * 0.5 * avoidance_side)
	return (move_dir + side_dir * OBSTACLE_AVOIDANCE_FORCE).normalized()

func _get_blocking_enemy_side(move_dir: Vector2) -> int:
	var right_dir = move_dir.rotated(PI * 0.5)
	var closest_forward = INF
	var chosen_side = 0
	var self_radius = _get_body_collision_radius(self)

	for enemy in get_tree().get_nodes_in_group(Global.GROUP_ENEMY):
		if enemy == self or not is_instance_valid(enemy) or not (enemy is Node2D):
			continue

		var enemy_node = enemy as Node2D
		var offset = enemy_node.global_position - global_position
		var forward_distance = offset.dot(move_dir)
		if forward_distance <= 0.0 or forward_distance > OBSTACLE_AVOIDANCE_LOOK_AHEAD:
			continue

		var side_distance = offset.dot(right_dir)
		var corridor_half_width = self_radius + _get_body_collision_radius(enemy_node) + OBSTACLE_AVOIDANCE_PADDING
		if abs(side_distance) > corridor_half_width:
			continue

		if forward_distance < closest_forward:
			closest_forward = forward_distance
			chosen_side = _side_away_from_lateral_position(side_distance, enemy_node)

	return chosen_side

func _has_blocking_slide_collision(move_dir: Vector2) -> bool:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision == null:
			continue

		var collider = collision.get_collider()
		if collider == null or collider == self:
			continue

		if move_dir.dot(collision.get_normal()) < -0.35:
			return true

	return false

func _get_slide_collision_avoidance_side(move_dir: Vector2) -> int:
	var right_dir = move_dir.rotated(PI * 0.5)

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision == null:
			continue

		var collider = collision.get_collider()
		if collider == null or collider == self:
			continue

		if collider is Node2D:
			var collider_node = collider as Node2D
			var side_distance = (collider_node.global_position - global_position).dot(right_dir)
			return _side_away_from_lateral_position(side_distance, collider_node)

	return avoidance_side

func _side_away_from_lateral_position(side_distance: float, other: Node) -> int:
	if abs(side_distance) > 1.0:
		return -1 if side_distance > 0.0 else 1

	return _get_stable_avoidance_side(other)

func _get_stable_avoidance_side(other: Node) -> int:
	if other == null:
		return avoidance_side

	var combined_id = int(get_instance_id() + other.get_instance_id())
	return 1 if combined_id % 2 == 0 else -1

func _get_soft_separation_vector() -> Vector2:
	var push = Vector2.ZERO
	var self_radius = _get_body_collision_radius(self)

	for enemy in get_tree().get_nodes_in_group(Global.GROUP_ENEMY):
		if enemy == self or not is_instance_valid(enemy) or not (enemy is Node2D):
			continue

		var enemy_node = enemy as Node2D
		var offset = global_position - enemy_node.global_position
		var distance = offset.length()
		var separation_distance = self_radius + _get_body_collision_radius(enemy_node) + SOFT_SEPARATION_PADDING
		if distance >= separation_distance:
			continue

		if distance <= 0.01:
			offset = Vector2.RIGHT.rotated(float(get_instance_id() % 360))
			distance = 1.0

		var strength = (separation_distance - distance) / separation_distance
		push += offset.normalized() * strength

	return push

func _get_body_collision_radius(body: Node2D) -> float:
	var collision = body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null or collision.shape == null:
		return BODY_RADIUS_FALLBACK

	var shape = collision.shape
	if shape is CapsuleShape2D:
		return max(shape.radius * abs(collision.scale.x), shape.height * 0.25 * abs(collision.scale.y))
	if shape is CircleShape2D:
		return shape.radius * max(abs(collision.scale.x), abs(collision.scale.y))
	if shape is RectangleShape2D:
		return min(shape.size.x * abs(collision.scale.x), shape.size.y * abs(collision.scale.y)) * 0.5

	return BODY_RADIUS_FALLBACK

func _configure_enemy_sprite_sheet(
	texture_path: String,
	frame_size: Vector2i,
	frames_per_row: int,
	states: Array,
	pecado_group_rows: Dictionary = {},
	animation_speed: float = 6.0,
	visual_scale: Vector2 = Vector2.ONE,
	frame_spacing: Vector2i = Vector2i.ZERO
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
					Vector2(frame_index * (frame_size.x + frame_spacing.x), sheet_row * (frame_size.y + frame_spacing.y)),
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
	collision_mask = collision_mask | Global.ENEMY_COLLISION_MASK
	_shrink_body_collision_shape()

func _shrink_body_collision_shape() -> void:
	var collision = get_node_or_null("CollisionShape2D")
	if collision == null or collision.shape == null:
		return

	var shape = collision.shape.duplicate()

	if shape is CapsuleShape2D:
		shape.radius = max(shape.radius * Global.ENEMY_BODY_COLLISION_SCALE, 4.0)
		shape.height = max(shape.height * Global.ENEMY_BODY_COLLISION_SCALE, shape.radius * 2.0)
	elif shape is CircleShape2D:
		shape.radius = max(shape.radius * Global.ENEMY_BODY_COLLISION_SCALE, 4.0)
	elif shape is RectangleShape2D:
		shape.size *= Global.ENEMY_BODY_COLLISION_SCALE

	collision.shape = shape

func take_damage(amount: float) -> void:
	if is_dead:
		return

	current_health -= int(round(amount))
	_update_health_bar()
	_play_damage_feedback()
	if current_health <= 0:
		die()
		return

func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return

	var previous_health = current_health
	current_health = int(min(current_health + amount, max_health))
	_update_health_bar()
	if current_health > previous_health:
		_play_heal_feedback()

func _play_damage_feedback() -> void:
	_play_health_feedback(DAMAGE_FEEDBACK_COLOR)

func _play_heal_feedback() -> void:
	_play_health_feedback(HEAL_FEEDBACK_COLOR)

func _play_health_feedback(color: Color) -> void:
	if not aparencia:
		return
	if health_feedback_tween != null:
		health_feedback_tween.kill()
		health_feedback_tween = null

	aparencia.modulate = health_feedback_base_modulate
	health_feedback_tween = create_tween().bind_node(aparencia)
	health_feedback_tween.tween_property(aparencia, "modulate", color, 0.08)
	health_feedback_tween.tween_property(aparencia, "modulate", health_feedback_base_modulate, 0.12)
	health_feedback_tween.tween_callback(Callable(self, "_clear_health_feedback_tween").bind(health_feedback_tween))

func _clear_health_feedback_tween(tween: Tween) -> void:
	if health_feedback_tween == tween:
		health_feedback_tween = null

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
