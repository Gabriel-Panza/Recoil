extends Panel

var player_path: NodePath = "/root/GameScene/Player"
var player
var game_scene_path: NodePath = "/root/GameScene"
var game_scene
var speedPlayer
var speedEnemy
var speedProjectile

var passive_options = [
	{ "id": "option_1", "text": "Recoil Force (+5%)", "description": "Increases the pushback force you receive after shooting, helping you move farther with each shot.", "rarity": "passive_common" },
	{ "id": "option_2", "text": "Health (+5%)", "description": "Increases your maximum health and heals you slightly based on your current health.", "rarity": "passive_common" },
	{ "id": "option_3", "text": "Attack (+15%)", "description": "Increases the damage dealt by your bullets and damage-based effects.", "rarity": "passive_common" },
	{ "id": "option_4", "text": "Atk-Speed (+5%)", "description": "+5% attack speed is additive from the original attack speed. Stops appearing at 0.25s shot cooldown.", "rarity": "passive_common" }
]

var cursed_passive_options = [
	{ "id": "glass_canon", "text": "Attack (+50%), Health (-25%)", "description": "Greatly increases damage, but lowers your maximum health. Strong if you can avoid hits.", "rarity": "passive_cursed" },
	{ "id": "tanky", "text": "Health (+25%), Attack (-50%)", "description": "Greatly increases survivability, but lowers your damage output.", "rarity": "passive_cursed" },
	{ "id": "deadly_slow", "text": "Recoil Force (-50%), Attack (+100%)", "description": "Greatly increases damage, but weakens your recoil movement by cutting pushback force.", "rarity": "passive_cursed" }
]

var rare_options = [
	{ "id": "Shield_Protection", "text": "Gain a one-hit shield", "description": "Grants a shield that blocks the next damage instance. Only one rare passive can be active at a time.", "rarity": "passive_rare" },
	{ "id": "Recoil_Explosion", "text": "Your recoil creates a small shockwave", "description": "Every shot creates a 180px shockwave that deals 35% of your attack damage. Only one rare passive can be active at a time.", "rarity": "passive_rare" },
	{ "id": "Double_Dash", "text": "You have two charges of dash", "description": "Gives you two dash charges. Each spent charge recharges one at a time. Only one rare passive can be active at a time.", "rarity": "passive_rare" },
	{ "id": "Offensive_Dash", "text": "Offensive Dash", "description": "Dashing blocks damage and releases a 180px shockwave at the end of the dash, dealing 75% of your attack damage. Only one rare passive can be active at a time.", "rarity": "passive_rare" }
]

var boss_options = [
	{ "id": "sloth_slow_aura", "name": "Slow Aura", "text": "Slow Aura", "description": "Enemies within 180px move at 70% speed.", "rarity": "passive_sin" },
	{ "id": "sloth_field", "name": "Sloth Field", "text": "Sloth Field", "description": "Create a 180px field near you for 5 seconds. Enemies inside drop to 35% speed, but your dash speed drops to 75% during the field.", "rarity": "active_sin" },
	{ "id": "gluttony_heal_kill", "name": "Blood Feast", "text": "Blood Feast", "description": "Killing an enemy releases green motes that heal 1% max health when they return.", "rarity": "passive_sin" },
	{ "id": "gluttony_devour", "name": "Devour", "text": "Devour", "description": "Consume up to two enemies within 180px. Green motes fly back and heal up to 12.5% max health when they arrive, but your dash speed is halved for 5 seconds.", "rarity": "active_sin" },
	{ "id": "envy_mirror_shot", "name": "Mirror Shot", "text": "Mirror Shot", "description": "Every shot fires a mirrored bullet for 50% damage.", "rarity": "passive_sin" },
	{ "id": "envy_mirror_clone", "name": "Mirror Clone", "text": "Mirror Clone", "description": "Summon a mirror clone that fires random risky shots with you for a short time. Clone bullets can hit anything, including you.", "rarity": "active_sin" },
	{ "id": "wrath_overheat", "name": "Overheat", "text": "Overheat", "description": "Every 4th shot deals double damage.", "rarity": "passive_sin" },
	{ "id": "wrath_burst", "name": "Wrath Burst", "text": "Wrath Burst", "description": "Fire 16 radial bullets for 110% attack damage each, then take 20 damage.", "rarity": "active_sin" },
	{ "id": "lust_for_vengeance", "name": "Vengeance", "text": "Vengeance", "description": "Deal 75% more damage while at full HP, but lose the bonus when hit.", "rarity": "passive_sin" },
	{ "id": "lust_for_perfection", "name": "Perfection", "text": "Perfection", "description": "Become invulnerable for 3 seconds, then take double damage for 5 seconds.", "rarity": "active_sin" },
	{ "id": "greed_cursed_level", "name": "Cursed Level", "text": "Cursed Level", "description": "Gain 1 bonus level per wave. Enemies move 25% faster.", "rarity": "passive_sin" },
	{ "id": "greed_treasure_rain", "name": "Treasure Rain", "text": "Treasure Rain", "description": "Rain golden projectiles from above. Each projectile deals 120% attack damage only when it collides, including with you.", "rarity": "active_sin" },
]

var boss_option_ids_by_pecado = {
	1: ["sloth_slow_aura", "sloth_field"],
	2: ["gluttony_heal_kill", "gluttony_devour"],
	3: ["envy_mirror_shot", "envy_mirror_clone"],
	4: ["wrath_overheat", "wrath_burst"],
	5: ["lust_for_vengeance", "lust_for_perfection"],
	6: ["greed_cursed_level", "greed_treasure_rain"],
}

var current_options: Array = []
var saved_level_options: Array = []
var blocked_level_option_ids: Array = []
var current_mode: String = "level_up"
var pending_active_option: String = ""
var pending_old_rare_option: String = ""
var pending_new_rare_option: String = ""
var title_label: Label
var skip_button: Button

signal option_selected(option)
signal active_discard_selected(discarded_slot, new_option)
signal rare_discard_selected(discarded_option, old_option, new_option)

func _ready() -> void:
	randomize()
	game_scene = get_node_or_null(game_scene_path)
	player = get_node_or_null(player_path)
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
		title_label.add_theme_font_size_override("font_size", 28)
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
		skip_button.add_theme_font_size_override("font_size", 20)
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

func show_popup(context: String = "normal", boss_pecado: int = 0):
	get_tree().paused = true
	await get_tree().create_timer(0.25, true).timeout

	current_mode = "level_up"
	pending_active_option = ""
	pending_old_rare_option = ""
	pending_new_rare_option = ""
	blocked_level_option_ids = []
	title_label.visible = false
	saved_level_options = _build_options(context, boss_pecado).duplicate(true)
	_render_options(saved_level_options, true)

func show_active_discard_popup(new_option: String, active_slots: Dictionary) -> void:
	get_tree().paused = true
	current_mode = "discard_active"
	pending_active_option = new_option
	pending_old_rare_option = ""
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

func show_rare_discard_popup(old_option: String, new_option: String) -> void:
	get_tree().paused = true
	current_mode = "discard_rare"
	pending_active_option = ""
	pending_old_rare_option = old_option
	pending_new_rare_option = new_option
	title_label.text = "Escolha 1 passiva rara para descartar"
	title_label.visible = true

	var old_option_data = _get_option_by_id(old_option).duplicate()
	old_option_data["discard_target"] = "old"
	old_option_data["text"] = "Descartar atual - %s" % _get_option_button_text(old_option_data)

	var new_option_data = _get_option_by_id(new_option).duplicate()
	new_option_data["discard_target"] = "new"
	new_option_data["text"] = "Recusar nova - %s" % _get_option_button_text(new_option_data)

	_render_options([old_option_data, new_option_data], false)

func _build_options(context: String, boss_pecado: int) -> Array:
	if context == "pre_boss":
		return _build_pre_boss_options()
	if context == "boss":
		return _build_boss_options(boss_pecado)
	return _build_normal_options()

func _build_normal_options() -> Array:
	var current_pool = _get_available_passive_options()
	current_pool.shuffle()
	return current_pool.slice(0, 3)

func _build_pre_boss_options() -> Array:
	var rare_pool = _get_available_rare_options()
	var passive_pool = _get_available_passive_options()
	rare_pool.shuffle()
	passive_pool.shuffle()

	var options = []
	if rare_pool.size() > 0:
		options.append(rare_pool[0])
	options.append_array(passive_pool.slice(0, 3 - options.size()))
	options.shuffle()
	return options

func _get_available_rare_options() -> Array:
	var available_options = []
	var current_rare_option = ""
	if player:
		current_rare_option = player.current_rare_option

	for option in rare_options:
		if option["id"] == current_rare_option:
			continue
		available_options.append(option.duplicate())

	return available_options

func _get_available_passive_options() -> Array:
	var available_options = []
	for option in passive_options:
		if option["id"] == "option_4" and player and player.has_method("can_upgrade_attack_speed") and not player.can_upgrade_attack_speed():
			continue
		available_options.append(option.duplicate())

	return available_options

func _build_boss_options(boss_pecado: int) -> Array:
	var options = []
	for option_id in boss_option_ids_by_pecado.get(boss_pecado, []):
		options.append(_get_option_by_id(option_id))

	var cursed_pool = cursed_passive_options.duplicate()
	cursed_pool.shuffle()
	if cursed_pool.size() > 0:
		options.append(cursed_pool[0])

	return options

func _render_options(options: Array, show_skip: bool) -> void:
	current_options = options.duplicate(true)
	visible = true
	if skip_button:
		skip_button.visible = show_skip
	var container = get_node_or_null("VBoxContainer")
	if container == null:
		return

	for i in range(3):
		var button = container.get_child(i)
		if i < current_options.size():
			var option = current_options[i]
			var option_id = str(option.get("id", ""))
			var is_blocked = current_mode == "level_up" and option_id in blocked_level_option_ids
			var tooltip = _get_option_tooltip(option)

			button.visible = true
			button.disabled = is_blocked
			button.get_child(0).text = _get_option_button_text(option)
			button.tooltip_text = tooltip
			if is_blocked:
				var blocked_tooltip = "Bloqueado neste level up porque voce recusou esta opcao."
				button.tooltip_text = blocked_tooltip if tooltip == "" else "%s\n%s" % [tooltip, blocked_tooltip]
			button.get_child(0).tooltip_text = button.tooltip_text
			button.self_modulate = _get_option_button_color(option, is_blocked)
		else:
			button.visible = false
			button.disabled = false
			button.tooltip_text = ""

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
	for pool in [passive_options, cursed_passive_options, rare_options, boss_options]:
		for option in pool:
			if option["id"] == option_id:
				return option.duplicate()

	return { "id": option_id, "text": option_id, "description": "Unknown upgrade effect.", "rarity": "passive_common" }

func _on_option_button_pressed(index: int) -> void:
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
		if discard_target == "old":
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
	if current_mode != "level_up":
		return

	_complete_level_up_choice()

func _return_to_saved_level_options() -> void:
	current_mode = "level_up"
	pending_active_option = ""
	pending_old_rare_option = ""
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
	hide()
	title_label.visible = false
	if skip_button:
		skip_button.visible = false
	get_tree().paused = false
