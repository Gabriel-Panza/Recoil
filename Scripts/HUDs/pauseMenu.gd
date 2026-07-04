extends Control

const GAME_SCENE_PATH: NodePath = "/root/GameScene"
const PLAYER_PATH: NodePath = "/root/GameScene/Player"
const PAUSE_MENU_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/PauseControl/PauseMenu"
const OPTIONS_MENU_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/PauseControl/PauseMenu/OptionsMenu"
const HEALTH_LABEL_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/HBoxContainer/BarraLateralDireita/MarginContainer/VBoxContainer/HP_MaxHealth"
const ATTACK_LABEL_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/HBoxContainer/BarraLateralDireita/MarginContainer/VBoxContainer/Ataque"
const ATK_SPEED_LABEL_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/HBoxContainer/BarraLateralDireita/MarginContainer/VBoxContainer/Atk_Speed"
const RECOIL_LABEL_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/HBoxContainer/BarraLateralDireita/MarginContainer/VBoxContainer/Recoil"
const ACTIVE_SKILL_E_LABEL_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/HBoxContainer/BarraLateralDireita/MarginContainer/VBoxContainer/ActiveSkillE"
const ACTIVE_SKILL_R_LABEL_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/HBoxContainer/BarraLateralDireita/MarginContainer/VBoxContainer/ActiveSkillR"
const GAME_OVER_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/PauseControl/GameOver"
const GAME_WIN_PATH: NodePath = "/root/GameScene/Player/Camera2D/CanvasLayer/HUD/PauseControl/GameWin"

var game_scene
var player
var pause_menu: Panel
var options_menu: Panel
var health_label: Label
var attack_label: Label
var atk_speed_label: Label
var recoil_label: Label
var heal_after_wave_label: Label
var dash_cooldown_label: Label
var healing_received_label: Label
var active_skill_e_label: Label
var active_skill_r_label: Label
var game_over: Panel
var game_win: Panel
var death_recap_background: Panel
var death_recap_scroll: ScrollContainer
var death_recap_label: Label
var death_recap_updated: bool = false

var can_move: bool = true

func _ready() -> void:
	player = get_node_or_null(PLAYER_PATH)
	game_scene = get_node_or_null(GAME_SCENE_PATH)
	pause_menu = get_node_or_null(PAUSE_MENU_PATH)
	options_menu = get_node_or_null(OPTIONS_MENU_PATH)
	health_label = get_node_or_null(HEALTH_LABEL_PATH)
	attack_label = get_node_or_null(ATTACK_LABEL_PATH)
	atk_speed_label = get_node_or_null(ATK_SPEED_LABEL_PATH)
	recoil_label = get_node_or_null(RECOIL_LABEL_PATH)
	_setup_heal_after_wave_label()
	_setup_dash_cooldown_label()
	_setup_healing_received_label()
	active_skill_e_label = get_node_or_null(ACTIVE_SKILL_E_LABEL_PATH)
	active_skill_r_label = get_node_or_null(ACTIVE_SKILL_R_LABEL_PATH)
	game_over = get_node_or_null(GAME_OVER_PATH)
	game_win = get_node_or_null(GAME_WIN_PATH)

	if player:
		player.connect("stats_updated", Callable(self, "update_status_labels"))

func _setup_heal_after_wave_label() -> void:
	if recoil_label == null:
		return

	var stats_container = recoil_label.get_parent()
	if stats_container == null:
		return

	heal_after_wave_label = stats_container.get_node_or_null("HealAfterWave")
	if heal_after_wave_label == null:
		heal_after_wave_label = Label.new()
		heal_after_wave_label.name = "HealAfterWave"
		heal_after_wave_label.layout_mode = 2
		heal_after_wave_label.mouse_filter = Control.MOUSE_FILTER_STOP
		heal_after_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		heal_after_wave_label.add_theme_color_override("font_color", Color(1, 0.25882354, 0.2, 1))
		heal_after_wave_label.add_theme_constant_override("outline_size", 4)
		heal_after_wave_label.add_theme_font_size_override("font_size", 20)
		stats_container.add_child(heal_after_wave_label)
		stats_container.move_child(heal_after_wave_label, recoil_label.get_index() + 1)

	heal_after_wave_label.visible = false

func _setup_dash_cooldown_label() -> void:
	if recoil_label == null:
		return

	var stats_container = recoil_label.get_parent()
	if stats_container == null:
		return

	dash_cooldown_label = stats_container.get_node_or_null("DashCooldown")
	if dash_cooldown_label == null:
		dash_cooldown_label = Label.new()
		dash_cooldown_label.name = "DashCooldown"
		dash_cooldown_label.layout_mode = 2
		dash_cooldown_label.mouse_filter = Control.MOUSE_FILTER_STOP
		dash_cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		dash_cooldown_label.add_theme_color_override("font_color", Color(0.45, 0.74, 1.0, 1.0))
		dash_cooldown_label.add_theme_constant_override("outline_size", 4)
		dash_cooldown_label.add_theme_font_size_override("font_size", 20)
		stats_container.add_child(dash_cooldown_label)
		var insert_after = heal_after_wave_label if heal_after_wave_label != null else recoil_label
		stats_container.move_child(dash_cooldown_label, insert_after.get_index() + 1)

	dash_cooldown_label.visible = false

func _setup_healing_received_label() -> void:
	if recoil_label == null:
		return

	var stats_container = recoil_label.get_parent()
	if stats_container == null:
		return

	healing_received_label = stats_container.get_node_or_null("HealingReceived")
	if healing_received_label == null:
		healing_received_label = Label.new()
		healing_received_label.name = "HealingReceived"
		healing_received_label.layout_mode = 2
		healing_received_label.mouse_filter = Control.MOUSE_FILTER_STOP
		healing_received_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		healing_received_label.add_theme_color_override("font_color", Color(1.0, 0.259, 0.2, 1.0))
		healing_received_label.add_theme_constant_override("outline_size", 4)
		healing_received_label.add_theme_font_size_override("font_size", 20)
		stats_container.add_child(healing_received_label)
		var insert_after = dash_cooldown_label if dash_cooldown_label != null else heal_after_wave_label if heal_after_wave_label != null else recoil_label
		stats_container.move_child(healing_received_label, insert_after.get_index() + 1)
	
func _process(_delta: float) -> void:
	update_status_labels()
	if game_over and game_over.visible:
		_update_death_recap()
	if _is_end_screen_visible():
		return

	if Input.is_action_just_pressed("ui_cancel"):
		if not pause_menu.is_visible():
			_pause_game()
		else:
			_unpause_game()

func _pause_game() -> void:
	if _is_end_screen_visible():
		return

	pause_menu.show()
	$"../HBoxContainer".visible = true
	update_status_labels()
	get_tree().paused = true

func _unpause_game() -> void:
	if _is_end_screen_visible():
		return

	options_menu.hide()
	pause_menu.hide()
	$"../HBoxContainer".visible = false
	get_tree().paused = false

func _is_end_screen_visible() -> bool:
	return (game_over and game_over.visible) or (game_win and game_win.visible)

func _update_death_recap() -> void:
	if death_recap_updated:
		return

	_setup_death_recap_ui()
	if death_recap_label == null:
		return

	if player and player.has_method("get_death_recap_text"):
		death_recap_label.text = player.get_death_recap_text()
	else:
		death_recap_label.text = "RUN RECAP\nNo player recap data available."
	death_recap_updated = true

func _setup_death_recap_ui() -> void:
	if game_over == null or death_recap_label != null:
		return

	death_recap_background = game_over.get_node_or_null("DeathRecapBackground")
	if death_recap_background == null:
		death_recap_background = Panel.new()
		death_recap_background.name = "DeathRecapBackground"
		death_recap_background.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		death_recap_background.z_index = 2
		death_recap_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		death_recap_background.offset_left = 42.0
		death_recap_background.offset_top = 58.0
		death_recap_background.offset_right = 724.0
		death_recap_background.offset_bottom = 560.0
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.0, 0.0, 0.0, 0.62)
		style.set_corner_radius_all(6)
		death_recap_background.add_theme_stylebox_override("panel", style)
		game_over.add_child(death_recap_background)

	death_recap_scroll = game_over.get_node_or_null("DeathRecapScroll")
	if death_recap_scroll == null:
		death_recap_scroll = ScrollContainer.new()
		death_recap_scroll.name = "DeathRecapScroll"
		death_recap_scroll.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		death_recap_scroll.z_index = 3
		death_recap_scroll.offset_left = 56.0
		death_recap_scroll.offset_top = 76.0
		death_recap_scroll.offset_right = 704.0
		death_recap_scroll.offset_bottom = 548.0
		game_over.add_child(death_recap_scroll)

	death_recap_label = death_recap_scroll.get_node_or_null("DeathRecapLabel")
	if death_recap_label == null:
		death_recap_label = Label.new()
		death_recap_label.name = "DeathRecapLabel"
		death_recap_label.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		death_recap_label.custom_minimum_size = Vector2(620.0, 0.0)
		death_recap_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		death_recap_label.add_theme_font_size_override("font_size", 16)
		death_recap_label.add_theme_color_override("font_color", Color(0.96, 0.88, 0.76, 1.0))
		death_recap_label.add_theme_constant_override("outline_size", 3)
		death_recap_scroll.add_child(death_recap_label)

func _on_options_button_pressed() -> void:
	options_menu.show()

func _on_back_button_pressed() -> void:
	options_menu.hide()

func _on_h_slider_value_changed(value: float) -> void:
	Global.music_volume_db = value
	for musica in get_tree().get_nodes_in_group(Global.GROUP_MUSIC):
		musica.set_volume_db(value)

func _on_h_slider_2_value_changed(value: float) -> void:
	Global.sfx_volume_db = value
	for som in get_tree().get_nodes_in_group(Global.GROUP_SFX):
		som.set_volume_db(value)

func _on_retry_button_pressed() -> void:
	_finish_current_run_if_end_screen_visible()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_button_pressed() -> void:
	_finish_current_run_if_end_screen_visible()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Cenas/HUDs/MainMenu.tscn")

func _finish_current_run_if_end_screen_visible() -> void:
	if not _is_end_screen_visible():
		return

	if game_scene and game_scene.has_method("finish_run"):
		if game_scene.finish_run():
			return

	Global.finish_current_run()

func update_status_labels() -> void:
	if player:
		if health_label:
			health_label.text = "Health: %.2f/%d" % [player.current_health, player.max_health]
			health_label.tooltip_text = "Current HP over max HP. Reaching 0 ends the run."
		if attack_label:
			attack_label.text = "Attack: %.1f" % player.attack_damage
			attack_label.tooltip_text = "Damage dealt by bullets and most damage-based effects."
		if atk_speed_label:
			var attack_speed_percent = (1.0 / max(player.fire_rate, 0.001)) * 100.0
			if player.has_method("get_attack_speed_percent"):
				attack_speed_percent = player.get_attack_speed_percent()
			var shot_cooldown = player.get_shot_cooldown() if player.has_method("get_shot_cooldown") else player.fire_rate
			var base_shot_cooldown = player.get_base_shot_cooldown() if player.has_method("get_base_shot_cooldown") else 1.1
			var max_attack_speed_percent = player.get_max_attack_speed_percent() if player.has_method("get_max_attack_speed_percent") else attack_speed_percent
			var arm_upgrade_scale_percent = player.get_attack_speed_upgrade_scale_percent() if player.has_method("get_attack_speed_upgrade_scale_percent") else 100.0
			var arm_name = player.get_current_arm_name() if player.has_method("get_current_arm_name") else "Base"
			atk_speed_label.text = "Atk-Speed: %.2f%%" % attack_speed_percent
			atk_speed_label.tooltip_text = "%s shots per second compared to that arm's base speed. Base cooldown: %.2fs. Current cooldown: %.2fs. Arm upgrade scaling: %.0f%%. Max for this arm: %.2f%%." % [arm_name, base_shot_cooldown, shot_cooldown, arm_upgrade_scale_percent, max_attack_speed_percent]
		if recoil_label:
			recoil_label.text = "Recoil Force: %.1f" % (player.recoil_force/100)
			var max_recoil_force = player.get_max_recoil_force() if player.has_method("get_max_recoil_force") else 800.0
			recoil_label.tooltip_text = "Pushback after shooting. Upgrades add +5%% from base recoil. Max displayed force: %.1f." % (max_recoil_force / 100.0)
		if heal_after_wave_label:
			var heal_after_wave_percent = player.get_heal_after_wave_percent() if player.has_method("get_heal_after_wave_percent") else 0.0
			heal_after_wave_label.visible = heal_after_wave_percent > 0.0
			if heal_after_wave_label.visible:
				var max_heal_after_wave_percent = player.get_max_heal_after_wave_percent() if player.has_method("get_max_heal_after_wave_percent") else 15.0
				heal_after_wave_label.text = "Heal/Wave: %.1f%%" % heal_after_wave_percent
				heal_after_wave_label.tooltip_text = "Heals %.1f%% of max health after each enemy wave. Maximum: %.1f%%." % [heal_after_wave_percent, max_heal_after_wave_percent]
		if dash_cooldown_label:
			var dash_cooldown_reduction_percent = player.get_dash_cooldown_reduction_percent() if player.has_method("get_dash_cooldown_reduction_percent") else 0.0
			dash_cooldown_label.visible = dash_cooldown_reduction_percent > 0.0
			if dash_cooldown_label.visible:
				var max_dash_cooldown_reduction_percent = player.get_max_dash_cooldown_reduction_percent() if player.has_method("get_max_dash_cooldown_reduction_percent") else 40.0
				var base_dash_cooldown = player.get_base_dash_cooldown() if player.has_method("get_base_dash_cooldown") else 5.0
				var current_dash_cooldown = player.get_dash_cooldown() if player.has_method("get_dash_cooldown") else player.dash_cooldown
				dash_cooldown_label.text = "Dash CD: -%.1f%%" % dash_cooldown_reduction_percent
				dash_cooldown_label.tooltip_text = "Reduces dash recharge cooldown by %.1f%%. Base cooldown: %.2fs. Current cooldown: %.2fs. Maximum reduction: %.1f%%." % [dash_cooldown_reduction_percent, base_dash_cooldown, current_dash_cooldown, max_dash_cooldown_reduction_percent]
		if healing_received_label:
			var healing_received_percent = player.get_healing_received_percent() if player.has_method("get_healing_received_percent") else 100.0
			healing_received_label.text = "Heal Received: %.0f%%" % healing_received_percent
			healing_received_label.tooltip_text = "Multiplier applied to all healing received."
		_update_active_skill_labels()

func _update_active_skill_labels() -> void:
	_update_active_skill_slot_label(active_skill_e_label, "E")
	_update_active_skill_slot_label(active_skill_r_label, "R")

func _update_active_skill_slot_label(label: Label, slot: String) -> void:
	if not label:
		return

	if not player.has_method("get_active_ability_slots"):
		label.text = "%s: -" % slot
		label.tooltip_text = "No active skill equipped"
		return

	var active_slots = player.get_active_ability_slots()
	var ability_id = active_slots.get(slot, "")
	if ability_id == "":
		label.text = "%s: -" % slot
		label.tooltip_text = "No active skill equipped"
		return

	var skill_name = ability_id
	var skill_description = ability_id
	if player.has_method("get_active_ability_name"):
		skill_name = player.get_active_ability_name(ability_id)
	if player.has_method("get_active_ability_description"):
		skill_description = player.get_active_ability_description(ability_id)

	var cooldown = 0.0
	if player.has_method("get_active_slot_cooldown"):
		cooldown = player.get_active_slot_cooldown(slot)

	if cooldown > 0.0:
		label.text = "%s: %s (%.1fs)" % [slot, skill_name, cooldown]
	else:
		label.text = "%s: %s" % [slot, skill_name]

	label.tooltip_text = "%s\nCooldown: %.1fs" % [skill_description, cooldown]
