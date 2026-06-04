extends Panel

const PLAYER_PATH: NodePath = "/root/GameScene/Player"
const GAME_SCENE_PATH: NodePath = "/root/GameScene"
const HEAL_AFTER_WAVE_COMMON_ROLL_CHANCE: float = 0.3
const DEFAULT_VIEWPORT_SIZE: Vector2 = Vector2(1152.0, 648.0)
const OPTION_BUTTON_COUNT: int = 3
const SLOT_ROLL_BASE_TICKS: int = 14
const SLOT_ROLL_STOP_TICK_STEP: int = 6
const SLOT_ROLL_INTERVAL: float = 0.075

var player
var game_scene

var current_options: Array = []
var saved_level_options: Array = []
var slot_roll_pools: Array = []
var blocked_level_option_ids: Array = []
var current_mode: String = "level_up"
var is_rolling_options: bool = false
var slot_roll_generation: int = 0
var pending_active_option: String = ""
var pending_old_rare_option: String = ""
var pending_rare_options: Array = []
var pending_new_rare_option: String = ""
var title_label: Label
var skip_button: Button

signal option_selected(option)
signal active_discard_selected(discarded_slot, new_option)
signal rare_discard_selected(discarded_option, old_option, new_option)

func _ready() -> void:
	randomize()
	game_scene = get_node_or_null(GAME_SCENE_PATH)
	player = get_node_or_null(PLAYER_PATH)
	_setup_title_label()
	_setup_skip_button()
	_connect_buttons()
	visible = false

func _setup_title_label() -> void:
	title_label = get_node_or_null("TitleLabel")
	if title_label == null:
		title_label = Label.new()
		title_label.name = "TitleLabel"
		title_label.offset_left = 4
		title_label.offset_top = -48
		title_label.offset_right = 644
		title_label.offset_bottom = -10
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_font_size_override("font_size", 20)
		add_child(title_label)
	title_label.visible = false

func _setup_skip_button() -> void:
	skip_button = get_node_or_null("SkipButton")
	if skip_button == null:
		skip_button = Button.new()
		skip_button.name = "SkipButton"
		skip_button.offset_left = 260
		skip_button.offset_top = 214
		skip_button.offset_right = 388
		skip_button.offset_bottom = 252
		skip_button.text = "Skip"
		skip_button.add_theme_font_size_override("font_size", 16)
		add_child(skip_button)

	skip_button.tooltip_text = "Skip this level up"
	var skip_callable = Callable(self, "_on_skip_button_pressed")
	if not skip_button.pressed.is_connected(skip_callable):
		skip_button.pressed.connect(skip_callable)

func _connect_buttons() -> void:
	var container = get_node_or_null("VBoxContainer")
	if container == null:
		return

	for i in range(container.get_child_count()):
		var button = container.get_child(i)
		var callable = Callable(self, "_on_option_button_pressed").bind(i)
		if not button.pressed.is_connected(callable):
			button.pressed.connect(callable)
		if button.get_child_count() > 0 and button.get_child(0) is Control:
			button.get_child(0).mouse_filter = Control.MOUSE_FILTER_IGNORE

## Shows the correct level-up option set for a normal, pre-boss, or boss reward.
func show_popup(context: String = "normal", boss_pecado: int = 0) -> void:
	get_tree().paused = true
	await get_tree().create_timer(0.25, true).timeout

	current_mode = "level_up"
	pending_active_option = ""
	pending_old_rare_option = ""
	pending_rare_options = []
	pending_new_rare_option = ""
	blocked_level_option_ids = []
	title_label.visible = false
	var roll_data = _build_level_up_roll_data(context, boss_pecado)
	saved_level_options = roll_data.get("final_options", []).duplicate(true)
	slot_roll_pools = roll_data.get("roll_pools_by_slot", []).duplicate(true)
	is_rolling_options = saved_level_options.size() > 0
	_render_options(saved_level_options, true)
	await _play_level_up_slot_roll(saved_level_options, slot_roll_pools)

func show_active_discard_popup(new_option: String, active_slots: Dictionary) -> void:
	get_tree().paused = true
	current_mode = "discard_active"
	pending_active_option = new_option
	pending_old_rare_option = ""
	pending_rare_options = []
	pending_new_rare_option = ""
	title_label.text = "Escolha 1 habilidade para descartar"
	title_label.visible = true

	var discard_options = []
	for slot in ["E", "R"]:
		var option_id = active_slots.get(slot, "")
		if option_id != "":
			var option_data = _get_option_by_id(option_id).duplicate()
			option_data["slot"] = slot
			option_data["text"] = "%s - %s" % [slot, _get_option_button_text(option_data)]
			discard_options.append(option_data)

	var new_option_data = _get_option_by_id(new_option).duplicate()
	new_option_data["slot"] = "new"
	new_option_data["text"] = "Nova - %s" % _get_option_button_text(new_option_data)
	discard_options.append(new_option_data)
	_render_options(discard_options, false)

func show_rare_discard_popup(old_options, new_option: String) -> void:
	get_tree().paused = true
	current_mode = "discard_rare"
	pending_active_option = ""
	pending_rare_options = old_options.duplicate() if old_options is Array else [old_options]
	pending_rare_options = pending_rare_options.filter(func(option_id): return str(option_id) != "")
	pending_old_rare_option = str(pending_rare_options[0]) if pending_rare_options.size() > 0 else ""
	pending_new_rare_option = new_option
	title_label.text = "Escolha 1 rara para substituir"
	title_label.visible = true

	var discard_options = []
	for old_option in pending_rare_options:
		var old_option_data = _get_option_by_id(str(old_option)).duplicate()
		old_option_data["discard_target"] = "equipped"
		old_option_data["discard_option"] = str(old_option)
		old_option_data["text"] = "Descartar - %s" % _get_option_button_text(old_option_data)
		discard_options.append(old_option_data)

	var new_option_data = _get_option_by_id(new_option).duplicate()
	new_option_data["discard_target"] = "new"
	new_option_data["text"] = "Manter atuais - %s" % _get_option_button_text(new_option_data)
	discard_options.append(new_option_data)

	_render_options(discard_options, false)

func _build_options(context: String, boss_pecado: int) -> Array:
	return _build_level_up_roll_data(context, boss_pecado).get("final_options", [])

## Builds final rewards and the visual pools used by the level-up slot animation.
func _build_level_up_roll_data(context: String, boss_pecado: int) -> Dictionary:
	if context == "pre_boss":
		return _build_pre_boss_roll_data()
	if context == "boss":
		return _build_boss_roll_data(boss_pecado)
	return _build_normal_roll_data()

func _build_normal_roll_data() -> Dictionary:
	var passive_pool = _get_available_passive_options()
	var final_options = _select_normal_options(passive_pool)
	var pools = []
	for _i in range(final_options.size()):
		pools.append(passive_pool)
	return _make_level_up_roll_data(final_options, pools)

func _build_pre_boss_roll_data() -> Dictionary:
	var rare_pool = _get_available_rare_options()
	var passive_pool = _get_available_passive_options()
	var final_options = _select_pre_boss_options(rare_pool, passive_pool)
	var pools = []
	for option in final_options:
		pools.append(_get_level_up_roll_pool_for_option(option, passive_pool, rare_pool, [], []))
	return _make_level_up_roll_data(final_options, pools)

func _build_boss_roll_data(boss_pecado: int) -> Dictionary:
	var boss_pool = _get_boss_reward_options(boss_pecado)
	var cursed_pool = _get_cursed_passive_options()
	var final_options = _select_boss_options(boss_pool, cursed_pool)
	var pools = []
	for option in final_options:
		pools.append(_get_level_up_roll_pool_for_option(option, [], [], boss_pool, cursed_pool))
	return _make_level_up_roll_data(final_options, pools)

func _build_normal_options() -> Array:
	return _select_normal_options(_get_available_passive_options())

func _build_pre_boss_options() -> Array:
	return _select_pre_boss_options(_get_available_rare_options(), _get_available_passive_options())

func _select_normal_options(passive_pool: Array) -> Array:
	var options = passive_pool.duplicate(true)
	options.shuffle()
	return options.slice(0, OPTION_BUTTON_COUNT)

func _select_pre_boss_options(rare_pool: Array, passive_pool: Array) -> Array:
	var rare_options = rare_pool.duplicate(true)
	var passive_options = passive_pool.duplicate(true)
	rare_options.shuffle()
	passive_options.shuffle()

	var options = []
	if rare_options.size() > 0:
		options.append(rare_options[0])
	options.append_array(passive_options.slice(0, OPTION_BUTTON_COUNT - options.size()))
	options.shuffle()
	return options

func _get_available_rare_options() -> Array:
	var available_options = []
	var current_rare_options: Array = []
	if player:
		if player.has_method("get_rare_passive_options"):
			current_rare_options = player.get_rare_passive_options()
		elif player.current_rare_option != "":
			current_rare_options = [player.current_rare_option]

	for option in Global.RARE_PASSIVE_OPTIONS:
		if option["id"] in current_rare_options:
			continue
		available_options.append(option.duplicate())

	return available_options

func _get_available_passive_options() -> Array:
	var available_options = []
	for option in Global.PASSIVE_UPGRADE_OPTIONS:
		if option["id"] == "option_1" and player and player.has_method("can_roll_recoil_force_upgrade") and not player.can_roll_recoil_force_upgrade():
			continue
		if option["id"] == "option_1" and player and player.has_method("can_upgrade_recoil_force") and not player.can_upgrade_recoil_force():
			continue
		if option["id"] == "option_4" and player and player.has_method("can_roll_attack_speed_upgrade") and not player.can_roll_attack_speed_upgrade():
			continue
		if option["id"] == "option_4" and player and player.has_method("can_upgrade_attack_speed") and not player.can_upgrade_attack_speed():
			continue
		if option["id"] == "option_5" and player and player.has_method("can_upgrade_projectile_size") and not player.can_upgrade_projectile_size():
			continue
		if option["id"] == "option_6":
			if player and player.has_method("can_upgrade_heal_after_wave") and not player.can_upgrade_heal_after_wave():
				continue
			if randf() > HEAL_AFTER_WAVE_COMMON_ROLL_CHANCE:
				continue
		available_options.append(option.duplicate())

	return available_options

func _build_boss_options(boss_pecado: int) -> Array:
	return _select_boss_options(_get_boss_reward_options(boss_pecado), _get_cursed_passive_options())

func _get_boss_reward_options(boss_pecado: int) -> Array:
	var options = []
	for option_id in Global.BOSS_OPTION_IDS_BY_PECADO.get(boss_pecado, []):
		options.append(_get_option_by_id(option_id))
	return options

func _get_cursed_passive_options() -> Array:
	return Global.CURSED_PASSIVE_OPTIONS.duplicate(true)

func _select_boss_options(boss_pool: Array, cursed_pool: Array) -> Array:
	var options = boss_pool.duplicate(true)
	var cursed_options = cursed_pool.duplicate(true)
	cursed_options.shuffle()
	if cursed_options.size() > 0:
		options.append(cursed_options[0])
	return options

func _get_level_up_roll_pool_for_option(
	option: Dictionary,
	passive_pool: Array,
	rare_pool: Array,
	boss_pool: Array,
	cursed_pool: Array
) -> Array:
	var rarity = str(option.get("rarity", ""))
	match rarity:
		"passive_rare":
			return rare_pool.duplicate(true)
		"passive_cursed":
			return cursed_pool.duplicate(true)
		"active_sin", "passive_sin":
			return boss_pool.duplicate(true)
		_:
			return passive_pool.duplicate(true)

func _make_level_up_roll_data(final_options: Array, pools: Array) -> Dictionary:
	var normalized_pools = []
	for i in range(final_options.size()):
		var pool = []
		if i < pools.size() and pools[i] is Array:
			pool = pools[i].duplicate(true)
		if pool.is_empty():
			pool = final_options.duplicate(true)
		pool.shuffle()
		normalized_pools.append(pool)

	return {
		"final_options": final_options.duplicate(true),
		"roll_pools_by_slot": normalized_pools,
	}

func _render_options(options: Array, show_skip: bool) -> void:
	current_options = options.duplicate(true)
	visible = true
	if skip_button:
		skip_button.visible = show_skip
		skip_button.disabled = is_rolling_options
	var container = get_node_or_null("VBoxContainer")
	if container == null:
		return

	for i in range(min(OPTION_BUTTON_COUNT, container.get_child_count())):
		var button = container.get_child(i)
		if i < current_options.size():
			var option = current_options[i]
			var option_id = str(option.get("id", ""))
			var is_blocked = current_mode == "level_up" and option_id in blocked_level_option_ids
			_apply_option_to_button(button, option, is_blocked, is_rolling_options)
		else:
			button.visible = false
			button.disabled = false
			button.tooltip_text = ""

	_center_popup()

## Plays the slot-machine reveal without changing the rewards already selected.
func _play_level_up_slot_roll(final_options: Array, pools: Array) -> void:
	if final_options.is_empty():
		is_rolling_options = false
		_render_options(final_options, true)
		return

	slot_roll_generation += 1
	var generation = slot_roll_generation
	var container = get_node_or_null("VBoxContainer")
	if container == null:
		is_rolling_options = false
		return

	var button_count = min(OPTION_BUTTON_COUNT, min(container.get_child_count(), final_options.size()))
	var max_ticks = SLOT_ROLL_BASE_TICKS + SLOT_ROLL_STOP_TICK_STEP * max(0, button_count - 1) + 1
	for tick in range(max_ticks):
		if generation != slot_roll_generation or not visible or current_mode != "level_up":
			return

		for i in range(button_count):
			var button = container.get_child(i)
			var stop_tick = SLOT_ROLL_BASE_TICKS + i * SLOT_ROLL_STOP_TICK_STEP
			if tick >= stop_tick:
				_apply_option_to_button(button, final_options[i], false, true)
				continue

			var pool = _get_slot_roll_pool(i, final_options, pools)
			if pool.is_empty():
				continue
			var preview_option = pool[(tick + i * 3) % pool.size()]
			_apply_option_to_button(button, preview_option, false, true)

		await get_tree().create_timer(SLOT_ROLL_INTERVAL, true).timeout

	if generation != slot_roll_generation or not visible or current_mode != "level_up":
		return

	is_rolling_options = false
	_render_options(final_options, true)

func _get_slot_roll_pool(slot_index: int, final_options: Array, pools: Array) -> Array:
	if slot_index < pools.size() and pools[slot_index] is Array and not pools[slot_index].is_empty():
		return pools[slot_index]
	if not final_options.is_empty():
		return final_options
	return []

func _apply_option_to_button(button: Button, option: Dictionary, is_blocked: bool, force_disabled: bool = false) -> void:
	var tooltip = _get_option_tooltip(option)
	button.visible = true
	button.disabled = force_disabled or is_blocked
	button.get_child(0).text = _get_option_button_text(option)
	button.tooltip_text = tooltip
	if is_blocked:
		var blocked_tooltip = "Bloqueado neste level up porque voce recusou esta opcao."
		button.tooltip_text = blocked_tooltip if tooltip == "" else "%s\n%s" % [tooltip, blocked_tooltip]
	button.get_child(0).tooltip_text = button.tooltip_text
	button.self_modulate = _get_option_button_color(option, is_blocked)

func _center_popup() -> void:
	var has_bounds := false
	var popup_bounds := Rect2()

	for child in get_children():
		if not (child is Control) or not child.visible:
			continue

		var control := child as Control
		var child_rect := Rect2(control.position, control.size)
		if not has_bounds:
			popup_bounds = child_rect
			has_bounds = true
		else:
			popup_bounds = popup_bounds.merge(child_rect)

	if not has_bounds:
		return

	position = (_get_design_viewport_size() * 0.5 - popup_bounds.get_center()).round()

func _get_design_viewport_size() -> Vector2:
	return Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", DEFAULT_VIEWPORT_SIZE.x)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", DEFAULT_VIEWPORT_SIZE.y))
	)

func _get_option_button_text(option: Dictionary) -> String:
	return str(option.get("text", option.get("name", option.get("id", ""))))

func _get_option_tooltip(option: Dictionary) -> String:
	return str(option.get("description", ""))

func _get_color_for_rarity(rarity: String) -> Color:
	match rarity:
		"passive_common":
			return Color(0, 1, 0.1, 1)
		"passive_rare":
			return Color(0.1, 0.0, 1, 1.0)
		"passive_cursed":
			return Color(0.6, 0.0, 0.6, 1.0)
		_:
			return Color(1, 0, 0.1, 1)

func _get_option_button_color(option: Dictionary, is_blocked: bool) -> Color:
	var color = _get_color_for_rarity(str(option.get("rarity", "")))
	if is_blocked:
		return Color(color.r * 0.28, color.g * 0.28, color.b * 0.28, 0.78)

	return color

func _get_option_by_id(option_id: String) -> Dictionary:
	for pool in [Global.PASSIVE_UPGRADE_OPTIONS, Global.CURSED_PASSIVE_OPTIONS, Global.RARE_PASSIVE_OPTIONS, Global.BOSS_REWARD_OPTIONS]:
		for option in pool:
			if option["id"] == option_id:
				return option.duplicate()

	return { "id": option_id, "text": option_id, "description": "Unknown upgrade effect.", "rarity": "passive_common" }

func _on_option_button_pressed(index: int) -> void:
	if is_rolling_options:
		return
	if index >= current_options.size():
		return

	var option = current_options[index]
	if current_mode == "level_up" and str(option.get("id", "")) in blocked_level_option_ids:
		return

	if current_mode == "discard_active":
		var discarded_slot = option.get("slot", "new")
		emit_signal("active_discard_selected", discarded_slot, pending_active_option)
		if discarded_slot == "new":
			_block_level_option(pending_active_option)
			_return_to_saved_level_options()
		else:
			_complete_level_up_choice()
		return

	if current_mode == "discard_rare":
		var discard_target = str(option.get("discard_target", ""))
		var discarded_option = pending_new_rare_option
		if discard_target == "equipped":
			discarded_option = str(option.get("discard_option", option.get("id", pending_new_rare_option)))
		elif discard_target == "old":
			discarded_option = pending_old_rare_option
		elif discard_target == "new":
			discarded_option = pending_new_rare_option
		else:
			discarded_option = option.get("id", pending_new_rare_option)

		emit_signal("rare_discard_selected", discarded_option, pending_old_rare_option, pending_new_rare_option)
		if discarded_option == pending_new_rare_option:
			_block_level_option(pending_new_rare_option)
			_return_to_saved_level_options()
		else:
			_complete_level_up_choice()
		return

	emit_signal("option_selected", option["id"])
	if current_mode == "level_up":
		_complete_level_up_choice()

func _on_skip_button_pressed() -> void:
	if is_rolling_options:
		return
	if current_mode != "level_up":
		return

	_complete_level_up_choice()

func _return_to_saved_level_options() -> void:
	current_mode = "level_up"
	is_rolling_options = false
	pending_active_option = ""
	pending_old_rare_option = ""
	pending_rare_options = []
	pending_new_rare_option = ""
	title_label.visible = false
	_render_options(saved_level_options, true)

func _block_level_option(option_id: String) -> void:
	if option_id == "" or option_id in blocked_level_option_ids:
		return

	blocked_level_option_ids.append(option_id)

func _complete_level_up_choice() -> void:
	_close_popup()
	if player:
		player.upando = false
		if player.current_xp >= player.xp_to_next_level:
			player.level_up()

func _close_popup() -> void:
	slot_roll_generation += 1
	is_rolling_options = false
	hide()
	title_label.visible = false
	pending_active_option = ""
	pending_old_rare_option = ""
	pending_rare_options = []
	pending_new_rare_option = ""
	if skip_button:
		skip_button.visible = false
		skip_button.disabled = false
	get_tree().paused = false
