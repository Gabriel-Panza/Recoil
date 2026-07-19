class_name TutorialAnimation
extends Control

const MODE_MOVEMENT: String = "movement"
const MODE_RECOIL: String = "recoil"
const MODE_DASH: String = "dash"
const MODE_ELITES: String = "elites"
const MODE_ENDLESS: String = "endless"

var mode: String = MODE_MOVEMENT

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.045, 0.025, 0.03, 0.98), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.88, 0.24, 0.12, 0.75), false, 3.0)
	_draw_floor_grid()

	match mode:
		MODE_ELITES:
			_draw_elite_demo()
		MODE_ENDLESS:
			_draw_endless_demo()
		MODE_DASH:
			_draw_dash_demo()
		_:
			_draw_recoil_demo()

func _draw_floor_grid() -> void:
	var grid_color = Color(0.7, 0.16, 0.10, 0.22)
	for x in range(0, int(size.x), 32):
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)
	for y in range(0, int(size.y), 32):
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)

func _draw_recoil_demo() -> void:
	var t = fmod(float(Time.get_ticks_msec()) / 1000.0, 2.0)
	var center_y = size.y * 0.52
	var mouse_pos = Vector2(size.x * 0.72, center_y - 38.0)
	var progress = clampf(t / 2.0, 0.0, 1.0)
	var recoil_progress = smoothstep(0.12, 0.9, progress)
	var recoil_distance = min(size.x * 0.24, 88.0)
	var player_pos = Vector2(size.x * 0.48 - recoil_progress * recoil_distance, center_y)
	var bullet_pos = player_pos.lerp(mouse_pos + Vector2(78.0, -10.0), clampf((progress - 0.12) / 0.62, 0.0, 1.0))
	_draw_arrow(player_pos, mouse_pos, Color(1.0, 0.88, 0.38, 0.9), 2.0)
	_draw_arrow(player_pos, player_pos + Vector2(-recoil_distance * 0.95, 24.0), Color(0.36, 0.9, 1.0, 0.86), 4.0)
	_draw_player(player_pos)
	_draw_mouse(mouse_pos)
	draw_circle(bullet_pos, 8.0, Color(1.0, 0.85, 0.46, 0.95))
	draw_arc(player_pos, 28.0 + 14.0 * sin(progress * TAU), 0.0, TAU, 48, Color(0.36, 0.9, 1.0, 0.35), 2.0)

func _draw_dash_demo() -> void:
	var t = fmod(float(Time.get_ticks_msec()) / 1000.0, 2.0)
	var center_y = size.y * 0.52
	var dash_t = clampf(t / 2.0, 0.0, 1.0)
	var dash_progress = smoothstep(0.08, 0.62, dash_t)
	var start_pos = Vector2(size.x * 0.28, center_y + 12.0)
	var end_pos = Vector2(size.x * 0.68, center_y + 12.0)
	var player_pos = start_pos.lerp(end_pos, dash_progress)
	for i in range(4):
		var trail_progress = max(dash_progress - float(i) * 0.08, 0.0)
		var trail_pos = start_pos.lerp(end_pos, trail_progress)
		draw_circle(trail_pos, 17.0 - float(i) * 2.0, Color(0.42, 0.95, 1.0, 0.18 - float(i) * 0.03))
	_draw_arrow(start_pos, end_pos, Color(0.42, 0.95, 1.0, 0.9), 4.0)
	_draw_player(player_pos)
	draw_arc(player_pos, 34.0, 0.0, TAU, 48, Color(0.42, 0.95, 1.0, 0.55), 3.0)

func _draw_elite_demo() -> void:
	var t = fmod(float(Time.get_ticks_msec()) / 1000.0, 3.0)
	var centers = [
		Vector2(size.x * 0.24, size.y * 0.50),
		Vector2(size.x * 0.50, size.y * 0.50),
		Vector2(size.x * 0.76, size.y * 0.50)
	]
	_draw_elite_enemy(centers[0], Color(0.82, 0.86, 0.88, 1.0), Color(0.65, 0.70, 0.72, 0.50), "shield", t)
	_draw_elite_enemy(centers[1], Color(1.0, 0.66, 0.08, 1.0), Color(1.0, 0.62, 0.08, 0.34), "blast", t)
	_draw_elite_enemy(centers[2], Color(0.82, 0.02, 0.06, 1.0), Color(0.92, 0.05, 0.08, 0.35), "drain", t)

func _draw_endless_demo() -> void:
	var t = float(Time.get_ticks_msec()) / 1000.0
	var center = size * Vector2(0.5, 0.53)
	var pulse = 1.0 + sin(t * 2.2) * 0.035
	for ring_index in range(3, 0, -1):
		var radius = (34.0 + float(ring_index) * 28.0) * pulse
		var ring_color = Color(0.64, 0.42, 0.96, 0.30 + float(3 - ring_index) * 0.16)
		draw_arc(center, radius, 0.0, TAU, 64, ring_color, 5.0)
	var hand_angle = -PI * 0.5 + fmod(t, 4.0) / 4.0 * TAU
	draw_line(center, center + Vector2.RIGHT.rotated(hand_angle) * 58.0, Color(1.0, 0.78, 0.30), 5.0)
	draw_circle(center, 8.0, Color(1.0, 0.78, 0.30))
	for i in range(7):
		var marker_angle = -PI * 0.5 + TAU * float(i) / 7.0
		var marker_pos = center + Vector2.RIGHT.rotated(marker_angle) * 105.0
		draw_circle(marker_pos, 8.0, Color(0.88, 0.18, 0.10, 0.95))

func _draw_elite_enemy(center: Vector2, outline_color: Color, aura_color: Color, icon: String, t: float) -> void:
	var pulse = 1.0 + 0.07 * sin(t * TAU)
	draw_circle(center, 34.0 * pulse, aura_color)
	draw_circle(center, 24.0, outline_color)
	draw_circle(center, 18.0, Color(0.42, 0.09, 0.08, 1.0))
	draw_rect(Rect2(center - Vector2(11.0, 6.0), Vector2(22.0, 15.0)), Color(0.17, 0.05, 0.05, 1.0), true)

	match icon:
		"shield":
			draw_arc(center, 43.0, -PI * 0.78, PI * 0.78, 28, outline_color, 4.0)
			draw_line(center + Vector2(-13.0, 1.0), center + Vector2(13.0, 1.0), outline_color, 3.0)
		"blast":
			for i in range(8):
				var angle = TAU * float(i) / 8.0 + t
				draw_line(center, center + Vector2(cos(angle), sin(angle)) * 48.0, outline_color, 2.0)
			draw_arc(center, 52.0 * pulse, 0.0, TAU, 48, outline_color, 2.0)
		"drain":
			var mote_pos = center + Vector2(cos(t * TAU), sin(t * TAU * 1.3)) * 54.0
			draw_circle(mote_pos, 6.0, outline_color)
			_draw_arrow(mote_pos, center, outline_color, 2.5)

func _draw_player(position: Vector2) -> void:
	draw_circle(position, 24.0, Color(0.12, 0.42, 0.30, 1.0))
	draw_circle(position + Vector2(0.0, -20.0), 15.0, Color(0.92, 0.70, 0.58, 1.0))
	draw_rect(Rect2(position + Vector2(-22.0, -10.0), Vector2(44.0, 28.0)), Color(0.10, 0.32, 0.24, 1.0), true)
	draw_circle(position + Vector2(9.0, -24.0), 3.0, Color(0.05, 0.02, 0.02, 1.0))

func _draw_mouse(position: Vector2) -> void:
	draw_circle(position, 10.0, Color(1.0, 0.95, 0.78, 0.95))
	draw_circle(position, 4.0, Color(0.20, 0.07, 0.04, 1.0))

func _draw_arrow(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var direction = to - from
	if direction.length() < 0.01:
		return
	var normal = direction.normalized()
	var side = normal.orthogonal()
	draw_line(from, to, color, width)
	var head = to - normal * 14.0
	draw_polygon(PackedVector2Array([
		to,
		head + side * 6.0,
		head - side * 6.0
	]), PackedColorArray([color, color, color]))
