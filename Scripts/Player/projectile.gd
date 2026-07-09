extends Area2D

const PLAYER_PATH: NodePath = "/root/GameScene/Player"

var speed: float = 700.0
var direction: Vector2 = Vector2.RIGHT
var damage = null
var player
var hit_queue: Array = []
var pierced_targets: Array = []

@onready var aparencia = get_node_or_null("AnimatedProjectile") if get_node_or_null("AnimatedProjectile") else get_node_or_null("Sprite2D")
@onready var particles: CPUParticles2D = get_node_or_null("CPUParticles2D")

func _ready() -> void:
	player = get_node_or_null(PLAYER_PATH)
	rotation = direction.angle()
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	if aparencia and aparencia is AnimatedSprite2D:
		aparencia.play("default")

	if self.is_in_group(Global.GROUP_ENEMY_PROJECTILE):
		speed = 500.0
		collision_layer = 0
		collision_mask = (Global.ENEMY_LAYER_MASK | Global.PLAYER_LAYER_MASK) if self.is_in_group(Global.GROUP_PROJECTILE) else Global.PLAYER_LAYER_MASK

	if has_meta("projectile_speed_multiplier"):
		speed *= float(get_meta("projectile_speed_multiplier"))

	_configure_projectile_vfx()

func _process(delta: float) -> void:
	_apply_projectile_mutations(delta)
	position += direction * speed * delta
	_process_hit_queue()

func _on_area_entered(area: Area2D) -> void:
	if self.is_in_group(Global.GROUP_PROJECTILE) and area.has_meta("projectile_special_owner"):
		var special_owner = area.get_meta("projectile_special_owner")
		if is_instance_valid(special_owner) and special_owner.has_method("_on_projectile_hit_special_area"):
			special_owner.call("_on_projectile_hit_special_area", area, self)
			return

	var parent = area.get_parent()
	if parent == null:
		return

	if self.is_in_group(Global.GROUP_PROJECTILE) and parent.is_in_group(Global.GROUP_ENEMY):
		_queue_hit(parent)
	elif self.is_in_group(Global.GROUP_ENEMY_PROJECTILE) and parent.is_in_group(Global.GROUP_PLAYER):
		_queue_hit(parent)

func _on_body_entered(body: Node) -> void:
	if (self.is_in_group(Global.GROUP_PROJECTILE) or bool(get_meta("enemy_ricochet_enabled", false))) and _try_ricochet_from_body(body):
		return

	if self.is_in_group(Global.GROUP_ENEMY_PROJECTILE) and body.is_in_group(Global.GROUP_PLAYER):
		_queue_hit(body)

func _queue_hit(target: Node) -> void:
	if target not in hit_queue:
		hit_queue.append(target)

func _process_hit_queue() -> void:
	if hit_queue.is_empty():
		return

	hit_queue = hit_queue.filter(func(target): return _is_valid_hit_target(target))
	if hit_queue.is_empty():
		return

	hit_queue.sort_custom(func(a, b): 
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)

	for target in hit_queue:
		if not _is_valid_hit_target(target):
			continue

		if target.is_in_group(Global.GROUP_ENEMY) and target.has_method("take_damage"):
			if target in pierced_targets:
				continue

			var enemy_damage = _get_enemy_hit_damage()
			if enemy_damage <= 0.0:
				queue_free()
				return
			target.take_damage(enemy_damage)
			_notify_player_projectile_enemy_hit(target, enemy_damage)
			pierced_targets.append(target)
		elif target.is_in_group(Global.GROUP_PLAYER) and target.has_method("take_damage"):
			var player_damage = damage if damage != null else 20.0
			var damage_source = get_meta("damage_source", null)
			if is_instance_valid(damage_source):
				target.take_damage(player_damage, global_position, 1.0, damage_source)
			else:
				target.take_damage(player_damage, global_position)

		_spawn_hit_particles(global_position)

		if target.is_in_group(Global.GROUP_ENEMY) and _consume_pierce():
			hit_queue.clear()
			return

		queue_free()
		return

	hit_queue.clear()

func _is_valid_hit_target(target) -> bool:
	return target != null and is_instance_valid(target) and target is Node2D

func _get_enemy_hit_damage() -> float:
	if damage != null:
		return float(damage)
	if is_instance_valid(player) and player.get("attack_damage") != null:
		return float(player.get("attack_damage"))
	return 0.0

func _consume_pierce() -> bool:
	var remaining = int(get_meta("pierce_remaining", 0))
	if remaining <= 0:
		return false

	set_meta("pierce_remaining", remaining - 1)
	return true

func _try_ricochet_from_body(body: Node) -> bool:
	var remaining = int(get_meta("ricochet_remaining", 0))
	if remaining <= 0 or not _is_wall_body(body):
		return false

	set_meta("ricochet_remaining", remaining - 1)
	var incoming_direction = direction
	var bounce_normal = _get_arena_bounce_normal()
	direction = direction.bounce(bounce_normal).normalized()
	rotation = direction.angle()
	global_position += direction * 8.0

	if bool(get_meta("risk_after_ricochet", false)):
		add_to_group(Global.GROUP_ENEMY_PROJECTILE)
		collision_mask = Global.ENEMY_LAYER_MASK | Global.PLAYER_LAYER_MASK
		damage = max(float(damage) * 0.5, 12.0)
		set_meta("vfx_color", Color(1.0, 0.78, 0.08, 0.95))
		_configure_projectile_vfx()

	_notify_player_projectile_ricochet(incoming_direction, direction)
	return true

func _apply_projectile_mutations(delta: float) -> void:
	if not self.is_in_group(Global.GROUP_PROJECTILE):
		return
	if not is_instance_valid(player):
		return

	if bool(get_meta("fast_homing_enabled", false)) and player.has_method("get_fast_mutation_homing_direction"):
		var fast_direction = player.call("get_fast_mutation_homing_direction", global_position, direction, delta)
		if fast_direction is Vector2 and fast_direction != Vector2.ZERO:
			direction = fast_direction.normalized()
			rotation = direction.angle()

	if bool(get_meta("unstable_ricochet_homing_enabled", false)) and bool(get_meta("unstable_has_ricocheted", false)) and player.has_method("get_unstable_ricochet_homing_direction"):
		var unstable_direction = player.call("get_unstable_ricochet_homing_direction", global_position, direction, delta)
		if unstable_direction is Vector2 and unstable_direction != Vector2.ZERO:
			direction = unstable_direction.normalized()
			rotation = direction.angle()

func _notify_player_projectile_enemy_hit(target: Node, enemy_damage: float) -> void:
	if not is_instance_valid(player) or not player.has_method("on_player_projectile_hit_enemy"):
		return

	player.call("on_player_projectile_hit_enemy", target, self, enemy_damage)

func _notify_player_projectile_ricochet(incoming_direction: Vector2, outgoing_direction: Vector2) -> void:
	if not is_instance_valid(player) or not player.has_method("on_player_projectile_ricochet"):
		return

	player.call("on_player_projectile_ricochet", self, global_position, incoming_direction, outgoing_direction)

func _is_wall_body(body: Node) -> bool:
	if body == null:
		return false

	var collision_layer = body.get("collision_layer")
	return collision_layer != null and (int(collision_layer) & Global.WALL_LAYER_MASK) != 0

func _get_arena_bounce_normal() -> Vector2:
	var tree = get_tree()
	var scene = tree.current_scene if tree != null else null
	if scene != null and scene.has_method("_get_current_arena_edge_normal"):
		var edge_normal = scene.call("_get_current_arena_edge_normal", global_position)
		if edge_normal is Vector2 and edge_normal != Vector2.ZERO:
			return edge_normal

	if scene != null and scene.has_method("_get_current_arena_bounds"):
		var arena_bounds: Rect2 = scene.call("_get_current_arena_bounds")
		if arena_bounds.size != Vector2.ZERO:
			var distances = [
				{ "normal": Vector2.RIGHT, "distance": abs(global_position.x - arena_bounds.position.x) },
				{ "normal": Vector2.LEFT, "distance": abs(global_position.x - arena_bounds.end.x) },
				{ "normal": Vector2.DOWN, "distance": abs(global_position.y - arena_bounds.position.y) },
				{ "normal": Vector2.UP, "distance": abs(global_position.y - arena_bounds.end.y) }
			]
			distances.sort_custom(func(a, b): return float(a["distance"]) < float(b["distance"]))
			return distances[0]["normal"]

	if abs(direction.x) > abs(direction.y):
		return Vector2.LEFT if direction.x > 0.0 else Vector2.RIGHT
	return Vector2.UP if direction.y > 0.0 else Vector2.DOWN

func _on_screen_exited() -> void:
	var tree = get_tree()
	if tree == null:
		queue_free()
		return

	await tree.create_timer(0.5, false).timeout
	queue_free()

func _configure_projectile_vfx() -> void:
	if not particles:
		return

	if self.is_in_group(Global.GROUP_ENEMY_PROJECTILE) and self.is_in_group(Global.GROUP_PROJECTILE):
		particles.amount = 72
		particles.lifetime = 0.42
		particles.initial_velocity_min = 18.0
		particles.initial_velocity_max = 70.0

	if self.has_meta("vfx_color"):
		particles.color = self.get_meta("vfx_color")
	elif self.is_in_group(Global.GROUP_ENEMY_PROJECTILE) and self.is_in_group(Global.GROUP_PROJECTILE):
		particles.color = _get_active_attack_color(Color(1.0, 0.78, 0.08, 0.95))
	elif self.is_in_group(Global.GROUP_PROJECTILE):
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

	var tree = get_tree()
	if tree == null:
		burst.queue_free()
		return

	var vfx_parent = tree.current_scene if tree.current_scene else tree.root
	if vfx_parent == null:
		burst.queue_free()
		return

	vfx_parent.add_child(burst)
	burst.emitting = true

	var cleanup_timer = tree.create_timer(burst.lifetime + 0.2, false)
	cleanup_timer.timeout.connect(Callable(burst, "queue_free"))

func _get_vfx_color() -> Color:
	if self.has_meta("vfx_color"):
		return self.get_meta("vfx_color")
	if self.is_in_group(Global.GROUP_ENEMY_PROJECTILE) and self.is_in_group(Global.GROUP_PROJECTILE):
		return _get_active_attack_color(Color(1.0, 0.78, 0.08, 0.95))
	if self.is_in_group(Global.GROUP_ENEMY_PROJECTILE):
		return _get_active_attack_color(Color(1.0, 0.18, 0.1, 0.9))
	return Color(1.0, 0.36, 0.12, 0.9)

func _get_active_attack_color(color: Color) -> Color:
	var multiplier = 1.0 - Global.ENEMY_ATTACK_ACTIVE_COLOR_DARKENING
	return Color(color.r * multiplier, color.g * multiplier, color.b * multiplier, color.a)
