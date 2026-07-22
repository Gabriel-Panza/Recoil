extends Panel

const PLAYER_PATH: NodePath = "/root/GameScene/Player"
const GAME_SCENE_PATH: NodePath = "/root/GameScene"
const HEAL_AFTER_WAVE_COMMON_ROLL_CHANCE: float = 0.3
const DASH_COOLDOWN_COMMON_ROLL_CHANCE: float = 0.5
const CONTRACT_EXTRA_CURSED_ROLL_CHANCE: float = 0.075
const DEFAULT_VIEWPORT_SIZE: Vector2 = Vector2(1152.0, 648.0)
const OPTION_BUTTON_COUNT: int = 3
const OPTION_LABEL_FONT_SIZE: int = 32
const REROLL_BUTTON_SIZE: Vector2 = Vector2(72.0, 42.0)
const REROLL_BUTTON_RIGHT_MARGIN: float = 8.0
const SLOT_ROLL_BASE_TICKS: int = 14
const SLOT_ROLL_STOP_TICK_STEP: int = 6
const SLOT_ROLL_INTERVAL: float = 0.075
const SPECIAL_LEVEL_UP_ROLL_CHANCE: float = 0.10
const SPECIAL_LEVEL_UP_EPIC_TIER: String = "epic"
const SPECIAL_LEVEL_UP_LEGENDARY_TIER: String = "legendary"
const SPECIAL_LEVEL_UP_LEGENDARY_SHARE: float = 0.4
const SPECIAL_LEVEL_UP_EPIC_MULTIPLIER: float = 1.5
const SPECIAL_LEVEL_UP_LEGENDARY_MULTIPLIER: float = 2.0
const SPECIAL_LEVEL_UP_GLOW_NODE_NAME: String = "SpecialLevelUpGlow"
const SPECIAL_LEVEL_UP_EPIC_GLOW_COLOR: Color = Color(0.68, 0.22, 1.0, 1.0)
const SPECIAL_LEVEL_UP_LEGENDARY_GLOW_COLOR: Color = Color(1.0, 0.8, 0.2, 1.0)
const SPECIAL_LEVEL_UP_CONFETTI_NAME: String = "SpecialLevelUpConfetti"
const CONFETTI_LIFETIME: float = 2.5
const CONFETTI_VIEWPORT_WIDTH_MULTIPLIER: float = 1.15
const CONFETTI_START_Y: float = -36.0
const CONFETTI_AMOUNT: int = 280
const CONFETTI_EXPLOSIVENESS: float = 0.0
const CONFETTI_GRAVITY: float = 280.0
const CONFETTI_MIN_VELOCITY: float = 80.0
const CONFETTI_MAX_VELOCITY: float = 180.0
const CONFETTI_SCALE_MIN: float = 6.0
const CONFETTI_SCALE_MAX: float = 14.0
const STYLED_BACKGROUND_NODE_NAME: String = "StyledPopupBackground"
const POPUP_CENTER_OFFSET: Vector2 = Vector2(8.0, 0.0)
const PAUSE_CONTROL_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/PauseControl"

var player
var game_scene
var pause_control
var level_up_rng := RandomNumberGenerator.new()
var special_percent_regex := RegEx.new()
var special_multiplier_regex := RegEx.new()

var current_options: Array = []
var saved_level_options: Array = []
var slot_roll_pools: Array = []
var blocked_level_option_ids: Array = []
var current_mode: String = "level_up"
var current_popup_context: String = "normal"
var current_popup_boss_pecado: int = 0
var is_rolling_options: bool = false
var slot_roll_generation: int = 0
var pending_active_option: String = ""
var pending_old_rare_option: String = ""
var pending_rare_options: Array = []
var pending_new_rare_option: String = ""
var title_label: Label
var skip_button: Button
var special_level_up_confetti: CPUParticles2D

signal option_selected(option)
signal active_discard_selected(discarded_slot, new_option)
signal rare_discard_selected(discarded_option, old_option, new_option)
signal boss_passive_discard_selected(discarded_option, old_option, new_option)

func _ready() -> void:
	level_up_rng.randomize()
	special_percent_regex.compile("([+-])([0-9]+(?:\\.[0-9]+)?)%")
	special_multiplier_regex.compile("\\bx([0-9]+(?:\\.[0-9]+)?)\\b")
	game_scene = get_node_or_null(GAME_SCENE_PATH)
	player = get_node_or_null(PLAYER_PATH)
	pause_control = get_node_or_null(PAUSE_CONTROL_PATH)
	_setup_title_label()
	_setup_skip_button()
	_connect_buttons()
	_apply_popup_style()
	I18n.language_changed.connect(_on_language_changed)
	visible = false

func _setup_title_label() -> void:
	title_label = get_node_or_null("TitleLabel")
	if title_label == null:
		title_label = Label.new()
		title_label.name = "TitleLabel"
		title_label.offset_left = 16
		title_label.offset_top = -48
		title_label.offset_right = 632
		title_label.offset_bottom = -10
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_font_size_override("font_size", 20)
		add_child(title_label)
	PopupStyle.apply_title(title_label)
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
		skip_button.add_theme_font_size_override("font_size", 16)
		add_child(skip_button)

	PopupStyle.apply_button(skip_button)
	skip_button.text = I18n.t("levelup.skip")
	skip_button.tooltip_text = _wrap_tooltip_text(I18n.t("levelup.skip_tooltip"))
	var skip_callable = Callable(self, "_on_skip_button_pressed")
	if not skip_button.pressed.is_connected(skip_callable):
		skip_button.pressed.connect(skip_callable)

func _on_language_changed(_language: String) -> void:
	_refresh_title_label()
	if skip_button:
		skip_button.text = I18n.t("levelup.skip")
		skip_button.tooltip_text = _wrap_tooltip_text(I18n.t("levelup.skip_tooltip"))
	if visible and not is_rolling_options:
		_render_options(current_options, skip_button != null and skip_button.visible)

func _refresh_title_label() -> void:
	if title_label == null:
		return
	match current_mode:
		"discard_active":
			title_label.text = I18n.t("levelup.discard_active_title")
		"discard_rare":
			title_label.text = I18n.t("levelup.discard_rare_title")
		"discard_boss_passive":
			title_label.text = I18n.t("levelup.discard_boss_title")

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

func _rng_randf() -> float:
	return level_up_rng.randf()

func _shuffle_array(values: Array) -> void:
	if values.size() < 2:
		return

	for i in range(values.size() - 1, 0, -1):
		var swap_index = level_up_rng.randi_range(0, i)
		if swap_index == i:
			continue
		var value = values[i]
		values[i] = values[swap_index]
		values[swap_index] = value

func _apply_popup_style() -> void:
	var frame = get_node_or_null("NinePatchRect")
	if frame is CanvasItem:
		(frame as CanvasItem).visible = false

	var background = get_node_or_null(STYLED_BACKGROUND_NODE_NAME)
	if background == null:
		background = Panel.new()
		background.name = STYLED_BACKGROUND_NODE_NAME
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.z_index = -1
		add_child(background)
		move_child(background, 0)

	if background is Control and frame is Control:
		var background_control = background as Control
		var frame_control = frame as Control
		background_control.position = frame_control.position
		background_control.size = frame_control.size
		background_control.anchor_left = frame_control.anchor_left
		background_control.anchor_top = frame_control.anchor_top
		background_control.anchor_right = frame_control.anchor_right
		background_control.anchor_bottom = frame_control.anchor_bottom
		background_control.offset_left = frame_control.offset_left
		background_control.offset_top = frame_control.offset_top
		background_control.offset_right = frame_control.offset_right
		background_control.offset_bottom = frame_control.offset_bottom
		background_control.grow_horizontal = frame_control.grow_horizontal
		background_control.grow_vertical = frame_control.grow_vertical
		PopupStyle.apply_panel(background_control)

	var container = get_node_or_null("VBoxContainer")
	if container != null:
		for child in container.get_children():
			if child is Button:
				PopupStyle.apply_button(child as Button)
				var label = _get_button_label(child as Button)
				if label != null:
					label.add_theme_font_size_override("font_size", OPTION_LABEL_FONT_SIZE)

## Shows the correct level-up option set for a normal, pre-boss, or boss reward.
func show_popup(context: String = "normal", boss_pecado: int = 0) -> void:
	get_tree().paused = true
	Global.keep_music_playing_during_pause()
	_set_pause_stats_preview_visible(true)
	await get_tree().create_timer(0.25, true).timeout

	current_mode = "level_up"
	current_popup_context = context
	current_popup_boss_pecado = boss_pecado
	pending_active_option = ""
	pending_old_rare_option = ""
	pending_rare_options = []
	pending_new_rare_option = ""
	blocked_level_option_ids = []
	title_label.visible = false
	_clear_special_level_up_confetti()
	var roll_data = _build_level_up_roll_data(context, boss_pecado)
	saved_level_options = roll_data.get("final_options", []).duplicate(true)
	slot_roll_pools = roll_data.get("roll_pools_by_slot", []).duplicate(true)
	is_rolling_options = saved_level_options.size() > 0
	_render_options(saved_level_options, true)
	await _play_level_up_slot_roll(saved_level_options, slot_roll_pools)

func show_active_discard_popup(new_option: String, active_slots: Dictionary) -> void:
	get_tree().paused = true
	Global.keep_music_playing_during_pause()
	current_mode = "discard_active"
	pending_active_option = new_option
	pending_old_rare_option = ""
	pending_rare_options = []
	pending_new_rare_option = ""
	title_label.text = I18n.t("levelup.discard_active_title")
	title_label.visible = true

	var discard_options = []
	for slot in ["E", "R"]:
		var option_id = active_slots.get(slot, "")
		if option_id != "":
			var option_data = _get_option_by_id(option_id).duplicate()
			option_data["slot"] = slot
			discard_options.append(option_data)

	var new_option_data = _get_option_by_id(new_option).duplicate()
	new_option_data["slot"] = "new"
	new_option_data["display_prefix_key"] = "levelup.new_prefix"
	discard_options.append(new_option_data)
	_render_options(discard_options, false)

func show_rare_discard_popup(old_options, new_option: String) -> void:
	get_tree().paused = true
	Global.keep_music_playing_during_pause()
	current_mode = "discard_rare"
	pending_active_option = ""
	pending_rare_options = old_options.duplicate() if old_options is Array else [old_options]
	pending_rare_options = pending_rare_options.filter(func(option_id): return str(option_id) != "")
	pending_old_rare_option = str(pending_rare_options[0]) if pending_rare_options.size() > 0 else ""
	pending_new_rare_option = new_option
	title_label.text = I18n.t("levelup.discard_rare_title")
	title_label.visible = true

	var discard_options = []
	for old_option in pending_rare_options:
		var old_option_data = _get_option_by_id(str(old_option)).duplicate()
		old_option_data["discard_target"] = "equipped"
		old_option_data["discard_option"] = str(old_option)
		old_option_data["display_prefix_key"] = "levelup.discard_prefix"
		discard_options.append(old_option_data)

	var new_option_data = _get_option_by_id(new_option).duplicate()
	new_option_data["discard_target"] = "new"
	new_option_data["display_prefix_key"] = "levelup.keep_current_prefix"
	discard_options.append(new_option_data)

	_render_options(discard_options, false)

func show_boss_passive_discard_popup(old_options, new_option: String) -> void:
	get_tree().paused = true
	Global.keep_music_playing_during_pause()
	current_mode = "discard_boss_passive"
	pending_active_option = ""
	pending_rare_options = old_options.duplicate() if old_options is Array else [old_options]
	pending_rare_options = pending_rare_options.filter(func(option_id): return str(option_id) != "")
	pending_old_rare_option = str(pending_rare_options[0]) if pending_rare_options.size() > 0 else ""
	pending_new_rare_option = new_option
	title_label.text = I18n.t("levelup.discard_boss_title")
	title_label.visible = true

	var discard_options = []
	for old_option in pending_rare_options:
		var old_option_data = _get_option_by_id(str(old_option)).duplicate()
		old_option_data["discard_target"] = "equipped"
		old_option_data["discard_option"] = str(old_option)
		old_option_data["display_prefix_key"] = "levelup.discard_prefix"
		discard_options.append(old_option_data)

	var new_option_data = _get_option_by_id(new_option).duplicate()
	new_option_data["discard_target"] = "new"
	new_option_data["display_prefix_key"] = "levelup.keep_current_prefix"
	discard_options.append(new_option_data)

	_render_options(discard_options, false)

## Builds final rewards and the visual pools used by the level-up slot animation.
func _build_level_up_roll_data(context: String, boss_pecado: int) -> Dictionary:
	if context == "pre_boss":
		return _build_pre_boss_roll_data()
	if context == "boss":
		return _build_boss_roll_data(boss_pecado)
	if context == "contract_extra":
		return _build_contract_extra_roll_data()
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

func _build_contract_extra_roll_data() -> Dictionary:
	var passive_pool = _get_available_passive_options()
	var cursed_pool = _get_cursed_passive_options()
	var passive_options = passive_pool.duplicate(true)
	var cursed_options = cursed_pool.duplicate(true)
	_shuffle_array(passive_options)
	_shuffle_array(cursed_options)

	var final_options = []
	var pools = []
	for _i in range(OPTION_BUTTON_COUNT):
		var should_roll_cursed = not cursed_options.is_empty() and (passive_options.is_empty() or _rng_randf() <= CONTRACT_EXTRA_CURSED_ROLL_CHANCE)
		if should_roll_cursed:
			final_options.append(cursed_options.pop_back())
			pools.append(cursed_pool)
		elif not passive_options.is_empty():
			final_options.append(passive_options.pop_back())
			pools.append(passive_pool)
		elif not cursed_options.is_empty():
			final_options.append(cursed_options.pop_back())
			pools.append(cursed_pool)

	return _make_level_up_roll_data(final_options, pools)

func _select_normal_options(passive_pool: Array) -> Array:
	var options = passive_pool.duplicate(true)
	_shuffle_array(options)
	return options.slice(0, OPTION_BUTTON_COUNT)

func _select_pre_boss_options(rare_pool: Array, passive_pool: Array) -> Array:
	var rare_options = rare_pool.duplicate(true)
	var passive_options = passive_pool.duplicate(true)
	_shuffle_array(rare_options)
	_shuffle_array(passive_options)

	var options = []
	if rare_options.size() > 0:
		options.append(rare_options[0])
	options.append_array(passive_options.slice(0, OPTION_BUTTON_COUNT - options.size()))
	_shuffle_array(options)
	return options

func _get_available_rare_options() -> Array:
	var available_options = []
	var current_rare_options: Array = []
	var current_arm_id = str(player.get("current_arm_id")) if player and player.get("current_arm_id") != null else ""
	if player:
		if player.has_method("get_rare_passive_options"):
			current_rare_options = player.get_rare_passive_options()
		elif player.current_rare_option != "":
			current_rare_options = [player.current_rare_option]

	for option in Global.RARE_PASSIVE_OPTIONS:
		if option["id"] in current_rare_options:
			continue
		if current_arm_id == "fast" and option["id"] == "Kinetic_Reload":
			continue
		if current_arm_id == "heavy" and option["id"] == "Recoil_Explosion":
			continue
		available_options.append(option.duplicate())

	return available_options

func _get_available_passive_options() -> Array:
	var available_options = []
	var reached_any_limit = false
	for option in Global.PASSIVE_UPGRADE_OPTIONS:
		if option["id"] == "option_1" and player and player.has_method("can_roll_recoil_force_upgrade") and not player.can_roll_recoil_force_upgrade():
			reached_any_limit = true
			continue
		if option["id"] == "option_1" and player and player.has_method("can_upgrade_recoil_force") and not player.can_upgrade_recoil_force():
			reached_any_limit = true
			continue
		if option["id"] == "option_4" and player and player.has_method("can_roll_attack_speed_upgrade") and not player.can_roll_attack_speed_upgrade():
			reached_any_limit = true
			continue
		if option["id"] == "option_4" and player and player.has_method("can_upgrade_attack_speed") and not player.can_upgrade_attack_speed():
			reached_any_limit = true
			continue
		if option["id"] == "option_5" and player and player.has_method("can_upgrade_projectile_size") and not player.can_upgrade_projectile_size():
			reached_any_limit = true
			continue
		if option["id"] == "option_6":
			if player and player.has_method("can_upgrade_heal_after_wave") and not player.can_upgrade_heal_after_wave():
				reached_any_limit = true
				continue
			if _rng_randf() > HEAL_AFTER_WAVE_COMMON_ROLL_CHANCE:
				continue
		if option["id"] == "option_7":
			if player and player.has_method("can_upgrade_dash_cooldown_reduction") and not player.can_upgrade_dash_cooldown_reduction():
				reached_any_limit = true
				continue
			if _rng_randf() > DASH_COOLDOWN_COMMON_ROLL_CHANCE:
				continue
		available_options.append(option.duplicate())
	if Global.is_endless_mode() and (reached_any_limit or available_options.size() < OPTION_BUTTON_COUNT):
		available_options.append({"id": "endless_heal_potion", "text": "Health Potion", "description": "Restore 25% max health.", "rarity": "passive_common"})
		available_options.append({"id": "endless_greater_heal_potion", "text": "Greater Health Potion", "description": "Restore 50% max health.", "rarity": "passive_common"})
		available_options.append({"id": "endless_reroll_token", "text": "Infernal Die", "description": "Gain 1 reroll.", "rarity": "passive_common"})

	return available_options

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
	_shuffle_array(cursed_options)
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
	var boosted_final_options = _roll_special_level_up_options(final_options)
	var normalized_pools = []
	for i in range(boosted_final_options.size()):
		var pool = []
		if i < pools.size() and pools[i] is Array:
			pool = pools[i].duplicate(true)
		if pool.is_empty():
			pool = final_options.duplicate(true)
		_shuffle_array(pool)
		normalized_pools.append(pool)

	return {
		"final_options": boosted_final_options,
		"roll_pools_by_slot": normalized_pools,
	}

func _roll_special_level_up_options(options: Array) -> Array:
	var rolled_options = []
	var special_roll_chance = _get_special_level_up_roll_chance()
	for option in options:
		var rolled_option = option.duplicate(true)
		if _can_roll_special_level_up(rolled_option) and _rng_randf() <= special_roll_chance:
			var tier = _roll_special_level_up_tier()
			rolled_option["special_level_up"] = true
			rolled_option["special_level_up_tier"] = tier
			rolled_option["stat_multiplier"] = _get_special_level_up_tier_multiplier(tier)
		rolled_options.append(rolled_option)
	return rolled_options

func _get_special_level_up_roll_chance() -> float:
	if player and player.has_method("get_special_level_up_roll_chance"):
		return player.get_special_level_up_roll_chance(SPECIAL_LEVEL_UP_ROLL_CHANCE)
	return SPECIAL_LEVEL_UP_ROLL_CHANCE

func _roll_special_level_up_tier() -> String:
	return SPECIAL_LEVEL_UP_LEGENDARY_TIER if _rng_randf() <= SPECIAL_LEVEL_UP_LEGENDARY_SHARE else SPECIAL_LEVEL_UP_EPIC_TIER

func _get_special_level_up_tier_multiplier(tier: String) -> float:
	return SPECIAL_LEVEL_UP_LEGENDARY_MULTIPLIER if tier == SPECIAL_LEVEL_UP_LEGENDARY_TIER else SPECIAL_LEVEL_UP_EPIC_MULTIPLIER

func _can_roll_special_level_up(option: Dictionary) -> bool:
	var rarity = str(option.get("rarity", ""))
	return rarity == "passive_common" or rarity == "passive_cursed"

func _render_options(options: Array, show_skip: bool) -> void:
	current_options = options.duplicate(true)
	for option in current_options:
		Global.discover_passive_option(str(option.get("id", "")))
	visible = true
	if skip_button:
		skip_button.visible = show_skip
		skip_button.disabled = is_rolling_options
		skip_button.text = I18n.t("levelup.skip")
		skip_button.tooltip_text = _wrap_tooltip_text(I18n.t("levelup.skip_tooltip"))
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
			_update_reroll_button(button, i, is_blocked, show_skip)
		else:
			button.visible = false
			button.disabled = false
			button.tooltip_text = ""
			_hide_reroll_button(button)
			_clear_special_level_up_button_effect(button)

	_center_popup()
	if not is_rolling_options:
		_focus_first_available_option.call_deferred()

func _focus_first_available_option() -> void:
	var container = get_node_or_null("VBoxContainer")
	if container == null:
		return
	for child in container.get_children():
		if child is Button and child.visible and not child.disabled:
			(child as Button).grab_focus()
			return

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
	if _has_legendary_special_level_up_option(final_options):
		_spawn_special_level_up_confetti()

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
	var label = _get_button_label(button)
	if label:
		label.text = _get_option_button_text(option)
		var rarity_color = _get_option_text_color(option, is_blocked)
		label.add_theme_font_size_override("font_size", OPTION_LABEL_FONT_SIZE)
		label.add_theme_color_override("font_color", PopupStyle.DISABLED_TEXT_COLOR if is_blocked else rarity_color)
		label.add_theme_color_override("font_outline_color", Color(rarity_color.r * 0.35, rarity_color.g * 0.25, rarity_color.b * 0.2, 1.0))
	button.tooltip_text = _wrap_tooltip_text(tooltip)
	if is_blocked:
		var blocked_tooltip = I18n.t("levelup.blocked_tooltip")
		var full_tooltip = blocked_tooltip if tooltip == "" else "%s\n%s" % [tooltip, blocked_tooltip]
		button.tooltip_text = _wrap_tooltip_text(full_tooltip)
	if label:
		label.tooltip_text = button.tooltip_text
	button.self_modulate = Color(0.62, 0.62, 0.62, 1.0) if is_blocked else Color.WHITE
	PopupStyle.apply_button(button)
	_set_special_level_up_button_effect(button, option, is_blocked)
	_layout_option_button_label(button)

func _layout_option_button_label(button: Button) -> void:
	var label = _get_button_label(button)
	if label == null:
		return

	label.anchor_left = 0.0
	label.anchor_top = 0.0
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.offset_left = 0.0
	label.offset_top = 0.0
	label.offset_right = -88.0
	label.offset_bottom = 0.0

func _update_reroll_button(button: Button, option_index: int, is_blocked: bool, show_skip: bool) -> void:
	var reroll_button = _get_or_create_reroll_button(button, option_index)
	var rerolls_left = _get_player_reroll_tokens()
	var can_show = current_mode == "level_up" and show_skip and not is_rolling_options and not is_blocked and rerolls_left > 0
	if can_show and option_index >= 0 and option_index < current_options.size():
		can_show = not _get_same_type_reroll_option_pool(current_options[option_index], option_index).is_empty()
	reroll_button.visible = can_show
	reroll_button.disabled = not can_show
	reroll_button.text = I18n.t("levelup.reroll")
	reroll_button.tooltip_text = _wrap_tooltip_text(I18n.t("levelup.reroll_tooltip", [rerolls_left]))

func _get_or_create_reroll_button(button: Button, option_index: int) -> Button:
	var reroll_button_name = "RerollButton%d" % option_index
	var reroll_button = button.get_node_or_null(reroll_button_name)
	if reroll_button is Button:
		return reroll_button as Button

	reroll_button = Button.new()
	reroll_button.name = reroll_button_name
	reroll_button.text = I18n.t("levelup.reroll")
	reroll_button.focus_mode = Control.FOCUS_ALL
	reroll_button.mouse_filter = Control.MOUSE_FILTER_STOP
	reroll_button.custom_minimum_size = REROLL_BUTTON_SIZE
	reroll_button.size = REROLL_BUTTON_SIZE
	reroll_button.anchor_left = 1.0
	reroll_button.anchor_top = 0.5
	reroll_button.anchor_right = 1.0
	reroll_button.anchor_bottom = 0.5
	reroll_button.offset_left = -REROLL_BUTTON_SIZE.x - REROLL_BUTTON_RIGHT_MARGIN
	reroll_button.offset_top = -REROLL_BUTTON_SIZE.y * 0.5
	reroll_button.offset_right = -REROLL_BUTTON_RIGHT_MARGIN
	reroll_button.offset_bottom = REROLL_BUTTON_SIZE.y * 0.5
	reroll_button.add_theme_font_size_override("font_size", 16)
	PopupStyle.apply_button(reroll_button)
	reroll_button.pressed.connect(Callable(self, "_on_reroll_button_pressed").bind(option_index))
	button.add_child(reroll_button)
	return reroll_button

func _hide_reroll_button(button: Button) -> void:
	for child in button.get_children():
		if child is Button and str(child.name).begins_with("RerollButton"):
			(child as Button).visible = false

func _get_player_reroll_tokens() -> int:
	if player and player.has_method("get_reroll_tokens"):
		return int(player.get_reroll_tokens())
	return 0

func _get_button_label(button: Button) -> Label:
	for child in button.get_children():
		if child is Label:
			return child as Label
	return null

func _set_special_level_up_button_effect(button: Button, option: Dictionary, is_blocked: bool) -> void:
	if is_blocked or not _is_special_level_up_option(option):
		_clear_special_level_up_button_effect(button)
		return

	var glow = button.get_node_or_null(SPECIAL_LEVEL_UP_GLOW_NODE_NAME)
	if glow == null:
		glow = Panel.new()
		glow.name = SPECIAL_LEVEL_UP_GLOW_NODE_NAME
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.set_anchors_preset(Control.PRESET_FULL_RECT)
		glow.offset_left = -4.0
		glow.offset_top = -4.0
		glow.offset_right = 4.0
		glow.offset_bottom = 4.0
		var style = StyleBoxFlat.new()
		style.set_border_width_all(2)
		style.set_corner_radius_all(6)
		glow.add_theme_stylebox_override("panel", style)
		button.add_child(glow)

	var glow_color = _get_special_level_up_color(option)
	var style = glow.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style.bg_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.12)
		style.border_color = glow_color

	glow.visible = true
	var effect_key = "%s:%s:%.2f" % [str(option.get("id", "")), _get_special_level_up_tier(option), _get_option_stat_multiplier(option)]
	if str(button.get_meta("special_level_up_effect_key", "")) == effect_key:
		return

	_kill_special_level_up_tween(button)
	button.set_meta("special_level_up_effect_key", effect_key)
	glow.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if not _is_legendary_special_level_up_option(option):
		return

	var pulse = create_tween().bind_node(glow)
	pulse.set_loops()
	pulse.tween_property(glow, "modulate:a", 0.42, 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(glow, "modulate:a", 1.0, 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	button.set_meta("special_level_up_tween", pulse)

func _clear_special_level_up_button_effect(button: Button) -> void:
	_kill_special_level_up_tween(button)
	if button.has_meta("special_level_up_effect_key"):
		button.remove_meta("special_level_up_effect_key")
	var glow = button.get_node_or_null(SPECIAL_LEVEL_UP_GLOW_NODE_NAME)
	if glow:
		glow.visible = false
		glow.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _kill_special_level_up_tween(button: Button) -> void:
	if not button.has_meta("special_level_up_tween"):
		return

	var pulse = button.get_meta("special_level_up_tween")
	if pulse is Tween:
		(pulse as Tween).kill()
	button.remove_meta("special_level_up_tween")

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

	position = (_get_design_viewport_size() * 0.5 - popup_bounds.get_center() + POPUP_CENTER_OFFSET).round()

func _get_design_viewport_size() -> Vector2:
	return Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", DEFAULT_VIEWPORT_SIZE.x)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", DEFAULT_VIEWPORT_SIZE.y))
	)

func _get_option_button_text(option: Dictionary) -> String:
	var option_id = str(option.get("id", ""))
	var text = I18n.option_text(option_id, str(option.get("text", option.get("name", option_id))))
	text = _get_common_flat_option_text(option_id, _get_option_stat_multiplier(option), text)
	var display_prefix_key = str(option.get("display_prefix_key", ""))
	if display_prefix_key != "":
		text = I18n.t(display_prefix_key, [text])
	else:
		var slot = str(option.get("slot", ""))
		if slot != "" and slot != "new":
			text = "%s - %s" % [slot, text]
	if _is_special_level_up_option(option):
		return _get_special_level_up_text(text, _get_option_stat_multiplier(option))
	return text

func _get_option_tooltip(option: Dictionary) -> String:
	var option_id = str(option.get("id", ""))
	var tooltip = I18n.option_description(option_id, str(option.get("description", "")))
	if _is_special_level_up_option(option):
		var special_tooltip = _get_special_level_up_tooltip(option)
		return special_tooltip if tooltip == "" else "%s\n%s" % [tooltip, special_tooltip]
	return tooltip

func _get_special_level_up_tooltip(option: Dictionary) -> String:
	var tier = _get_special_level_up_tier(option)
	var option_id = str(option.get("id", ""))
	var localized_text = I18n.option_text(option_id, str(option.get("text", option.get("name", option_id))))
	var base_text = _get_common_flat_option_text(option_id, 1.0, localized_text)
	var final_values = _get_common_flat_option_text(
		option_id,
		_get_option_stat_multiplier(option),
		_get_special_level_up_text(localized_text, _get_option_stat_multiplier(option))
	)
	var final_values_line = "\n" + I18n.t("levelup.final_values", [final_values]) if final_values != base_text else ""
	if tier == SPECIAL_LEVEL_UP_LEGENDARY_TIER:
		return I18n.t("levelup.lucky_legendary_tooltip") + final_values_line
	return I18n.t("levelup.lucky_epic_tooltip") + final_values_line

func _get_common_flat_option_text(option_id: String, stat_multiplier: float, fallback_text: String) -> String:
	if player == null:
		return fallback_text
	if option_id == "option_2" and player.has_method("get_common_health_upgrade_amount"):
		var health_gain = float(player.get_common_health_upgrade_amount(stat_multiplier))
		return I18n.t("levelup.health_flat", [_format_common_flat_value(health_gain)])
	if option_id == "option_3" and player.has_method("get_common_attack_upgrade_amount"):
		var attack_gain = float(player.get_common_attack_upgrade_amount(stat_multiplier))
		return I18n.t("levelup.attack_flat", [_format_common_flat_value(attack_gain)])
	return fallback_text

func _format_common_flat_value(value: float) -> String:
	if abs(value - round(value)) < 0.001:
		return str(int(round(value)))
	if abs(value * 10.0 - round(value * 10.0)) < 0.001:
		return "%.1f" % value
	return "%.2f" % value

func _get_special_level_up_text(text: String, multiplier: float) -> String:
	var multiplier_text = _apply_special_level_up_multiplier_text(text, multiplier)
	return _apply_special_level_up_percent_text(multiplier_text, multiplier)

func _apply_special_level_up_percent_text(text: String, multiplier: float) -> String:
	var result = ""
	var last_end = 0
	for match_result in special_percent_regex.search_all(text):
		result += text.substr(last_end, match_result.get_start() - last_end)
		var groups = match_result.get_strings()
		if groups.size() < 3:
			last_end = match_result.get_end()
			continue
		var sign = groups[1]
		var value = float(groups[2]) * multiplier
		result += "%s%s%%" % [sign, _format_special_percent_value(value)]
		last_end = match_result.get_end()

	result += text.substr(last_end)
	return result

func _apply_special_level_up_multiplier_text(text: String, multiplier: float) -> String:
	var result = ""
	var last_end = 0
	for match_result in special_multiplier_regex.search_all(text):
		result += text.substr(last_end, match_result.get_start() - last_end)
		var groups = match_result.get_strings()
		if groups.size() < 2:
			last_end = match_result.get_end()
			continue
		var value = float(groups[1]) * multiplier
		result += "x%s" % _format_special_percent_value(value)
		last_end = match_result.get_end()

	result += text.substr(last_end)
	return result

func _format_special_percent_value(value: float) -> String:
	if abs(value - round(value)) < 0.01:
		return str(int(round(value)))
	if abs(value * 10.0 - round(value * 10.0)) < 0.01:
		return "%.1f" % value
	if abs(value * 100.0 - round(value * 100.0)) < 0.01:
		return "%.2f" % value
	return "%.1f" % value

func _is_special_level_up_option(option: Dictionary) -> bool:
	return bool(option.get("special_level_up", false))

func _has_legendary_special_level_up_option(options: Array) -> bool:
	for option in options:
		if option is Dictionary and _is_legendary_special_level_up_option(option):
			return true
	return false

func _is_legendary_special_level_up_option(option: Dictionary) -> bool:
	return _is_special_level_up_option(option) and _get_special_level_up_tier(option) == SPECIAL_LEVEL_UP_LEGENDARY_TIER

func _get_special_level_up_tier(option: Dictionary) -> String:
	return str(option.get("special_level_up_tier", SPECIAL_LEVEL_UP_LEGENDARY_TIER))

func _get_option_stat_multiplier(option: Dictionary) -> float:
	return max(float(option.get("stat_multiplier", 1.0)), 0.0)

func _get_special_level_up_color(option: Dictionary) -> Color:
	return SPECIAL_LEVEL_UP_LEGENDARY_GLOW_COLOR if _get_special_level_up_tier(option) == SPECIAL_LEVEL_UP_LEGENDARY_TIER else SPECIAL_LEVEL_UP_EPIC_GLOW_COLOR

func _get_color_for_rarity(rarity: String) -> Color:
	match rarity:
		"passive_common":
			return Color(0, 1, 0.1, 1)
		"passive_rare":
			return Color(0.1, 0.0, 1, 1.0)
		"passive_cursed":
			return Color(0.78, 0.05, 0.58, 1.0)
		"active_sin", "passive_sin":
			return Color(1.0, 0.28, 0.08, 1.0)
		_:
			return Color(1, 0, 0.1, 1)

func _get_option_text_color(option: Dictionary, is_blocked: bool) -> Color:
	var color = _get_color_for_rarity(str(option.get("rarity", "")))
	if is_blocked:
		return Color(color.r * 0.28, color.g * 0.28, color.b * 0.28, 0.78)
	return color

func _get_option_by_id(option_id: String) -> Dictionary:
	for pool in [Global.PASSIVE_UPGRADE_OPTIONS, Global.CURSED_PASSIVE_OPTIONS, Global.RARE_PASSIVE_OPTIONS, Global.BOSS_REWARD_OPTIONS]:
		for option in pool:
			if option["id"] == option_id:
				return option.duplicate()

	return { "id": option_id, "text": option_id, "description": I18n.t("levelup.unknown_upgrade"), "rarity": "passive_common" }

func _on_reroll_button_pressed(option_index: int) -> void:
	if is_rolling_options or current_mode != "level_up":
		return
	if option_index < 0 or option_index >= current_options.size():
		return
	var replacement = _roll_same_type_level_up_option_for_reroll(current_options[option_index], option_index)
	if replacement.is_empty():
		return
	if player == null or not player.has_method("consume_reroll_token") or not player.consume_reroll_token():
		return

	current_options[option_index] = replacement
	if option_index < saved_level_options.size():
		saved_level_options[option_index] = replacement

	_clear_special_level_up_confetti()
	_render_options(current_options, true)
	if _is_legendary_special_level_up_option(replacement):
		_spawn_special_level_up_confetti()

func _roll_same_type_level_up_option_for_reroll(current_option: Dictionary, option_index: int) -> Dictionary:
	var pool = _get_same_type_reroll_option_pool(current_option, option_index)
	if pool.is_empty():
		return {}

	_shuffle_array(pool)
	var rolled_options = _roll_special_level_up_options([pool[0]])
	if rolled_options.is_empty():
		return pool[0].duplicate(true)
	return rolled_options[0]

func _get_same_type_reroll_option_pool(current_option: Dictionary, option_index: int = -1) -> Array:
	var rarity = str(current_option.get("rarity", ""))
	var pool = []
	match rarity:
		"passive_common":
			pool = _get_available_passive_options()
		"passive_cursed":
			pool = _get_cursed_passive_options()
		"passive_rare":
			pool = _get_available_rare_options()
		"active_sin", "passive_sin":
			pool = _get_available_boss_reroll_options()
		_:
			pool = _get_available_passive_options()

	return _filter_reroll_pool(pool, str(current_option.get("id", "")), _get_current_option_ids_except(option_index))

func _get_available_boss_reroll_options() -> Array:
	var active_slots = player.get_active_ability_slots() if player and player.has_method("get_active_ability_slots") else {}
	var equipped_boss_passives = player.get_boss_passive_options() if player and player.has_method("get_boss_passive_options") else []
	var source_options = _get_boss_reward_options(current_popup_boss_pecado)
	if source_options.is_empty():
		source_options = Global.BOSS_REWARD_OPTIONS.duplicate(true)

	var pool = []
	for option in source_options:
		var option_id = str(option.get("id", ""))
		if option_id in blocked_level_option_ids:
			continue
		if option_id in equipped_boss_passives:
			continue
		if active_slots.values().has(option_id):
			continue
		pool.append(option.duplicate(true))

	return pool

func _get_current_option_ids_except(option_index: int) -> Array:
	var ids = []
	for i in range(current_options.size()):
		if i == option_index:
			continue

		var option = current_options[i]
		if option is Dictionary:
			var option_id = str(option.get("id", ""))
			if option_id != "" and option_id not in ids:
				ids.append(option_id)
	return ids

func _filter_reroll_pool(pool: Array, current_option_id: String, excluded_option_ids: Array = []) -> Array:
	var filtered_pool = []
	for option in pool:
		var option_id = str(option.get("id", ""))
		if option_id == current_option_id:
			continue
		if option_id in excluded_option_ids:
			continue
		if option_id in blocked_level_option_ids:
			continue
		filtered_pool.append(option.duplicate(true))
	return filtered_pool

func _on_option_button_pressed(index: int) -> void:
	if is_rolling_options:
		return
	if index >= current_options.size():
		return

	var option = current_options[index]
	if current_mode == "level_up" and str(option.get("id", "")) in blocked_level_option_ids:
		return

	_clear_special_level_up_confetti()

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

	if current_mode == "discard_boss_passive":
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

		emit_signal("boss_passive_discard_selected", discarded_option, pending_old_rare_option, pending_new_rare_option)
		if discarded_option == pending_new_rare_option:
			_block_level_option(pending_new_rare_option)
			_return_to_saved_level_options()
		else:
			_complete_level_up_choice()
		return

	emit_signal("option_selected", option.duplicate(true))
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
	_set_pause_stats_preview_visible(false)
	_clear_all_special_level_up_button_effects()
	_clear_special_level_up_confetti()
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

func _set_pause_stats_preview_visible(should_show: bool) -> void:
	if pause_control == null or not is_instance_valid(pause_control):
		pause_control = get_node_or_null(PAUSE_CONTROL_PATH)
	if pause_control != null and pause_control.has_method("set_level_up_stats_preview_visible"):
		pause_control.set_level_up_stats_preview_visible(should_show)

func _wrap_tooltip_text(text: String) -> String:
	return Global.wrap_tooltip_text(text)

func _clear_all_special_level_up_button_effects() -> void:
	var container = get_node_or_null("VBoxContainer")
	if container == null:
		return

	for child in container.get_children():
		if child is Button:
			_clear_special_level_up_button_effect(child as Button)

func _spawn_special_level_up_confetti() -> void:
	_clear_special_level_up_confetti()

	var viewport_size = _get_design_viewport_size()
	var confetti = CPUParticles2D.new()
	confetti.name = SPECIAL_LEVEL_UP_CONFETTI_NAME
	confetti.one_shot = false
	confetti.amount = CONFETTI_AMOUNT
	confetti.lifetime = CONFETTI_LIFETIME
	confetti.explosiveness = CONFETTI_EXPLOSIVENESS
	confetti.direction = Vector2.DOWN
	confetti.spread = 32.0
	confetti.gravity = Vector2(0.0, CONFETTI_GRAVITY)
	confetti.initial_velocity_min = CONFETTI_MIN_VELOCITY
	confetti.initial_velocity_max = CONFETTI_MAX_VELOCITY
	confetti.angular_velocity_min = -360.0
	confetti.angular_velocity_max = 360.0
	confetti.scale_amount_min = CONFETTI_SCALE_MIN
	confetti.scale_amount_max = CONFETTI_SCALE_MAX
	confetti.color = Color(1.0, 0.78, 0.12, 0.95)
	confetti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	confetti.emission_rect_extents = Vector2(viewport_size.x * CONFETTI_VIEWPORT_WIDTH_MULTIPLIER * 0.5, 10.0)
	confetti.position = Vector2(viewport_size.x * 0.5, CONFETTI_START_Y)
	confetti.z_index = z_index - 1
	confetti.z_as_relative = false

	var parent_node = get_parent()
	if parent_node == null:
		add_child(confetti)
	else:
		parent_node.add_child(confetti)
		parent_node.move_child(confetti, get_index())

	special_level_up_confetti = confetti
	confetti.emitting = true

func _clear_special_level_up_confetti() -> void:
	if is_instance_valid(special_level_up_confetti):
		special_level_up_confetti.queue_free()
	special_level_up_confetti = null
