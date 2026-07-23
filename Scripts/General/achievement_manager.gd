extends Node

signal achievement_unlocked(achievement_id)
signal achievement_progress_changed(achievement_id, current, target)
signal steam_status_changed(connected)

const DEFINITIONS: Array[Dictionary] = [
	{"id":"sevenfold_penance", "steam_id":"ACH_SEVENFOLD_PENANCE", "stat_id":"", "hidden":false, "category":"story", "target":1},
	{"id":"no_amendments", "steam_id":"ACH_NO_AMENDMENTS", "stat_id":"", "hidden":false, "category":"challenge", "target":1},
	{"id":"read_fine_print", "steam_id":"ACH_READ_FINE_PRINT", "stat_id":"STAT_CONTRACT_STREAK", "hidden":false, "category":"challenge", "target":7},
	{"id":"recoil_purist", "steam_id":"ACH_RECOIL_PURIST", "stat_id":"", "hidden":false, "category":"challenge", "target":1},
	{"id":"untouchable_ego", "steam_id":"ACH_UNTOUCHABLE_EGO", "stat_id":"", "hidden":false, "category":"boss", "target":1},
	{"id":"eighth_sin", "steam_id":"ACH_EIGHTH_SIN", "stat_id":"STAT_ENDLESS_BOSSES", "hidden":false, "category":"endless", "target":8},
	{"id":"executive_decision", "steam_id":"ACH_EXECUTIVE_DECISION", "stat_id":"STAT_RETIRED_SCORE", "hidden":false, "category":"endless", "target":10000},
	{"id":"empty_chamber", "steam_id":"ACH_EMPTY_CHAMBER", "stat_id":"", "hidden":false, "category":"challenge", "target":1},
	{"id":"swift_sentence", "steam_id":"ACH_SWIFT_SENTENCE", "stat_id":"", "hidden":false, "category":"arms", "target":1},
	{"id":"heavy_verdict", "steam_id":"ACH_HEAVY_VERDICT", "stat_id":"", "hidden":false, "category":"arms", "target":1},
	{"id":"controlled_chaos", "steam_id":"ACH_CONTROLLED_CHAOS", "stat_id":"", "hidden":false, "category":"arms", "target":1},
	{"id":"arsenal_of_penance", "steam_id":"ACH_ARSENAL_OF_PENANCE", "stat_id":"STAT_STORY_ARMS_COMPLETED", "hidden":false, "category":"arms", "target":3},
	{"id":"return_to_sender", "steam_id":"ACH_RETURN_TO_SENDER", "stat_id":"", "hidden":true, "category":"discovery", "target":1},
	{"id":"between_rock_and_hell", "steam_id":"ACH_BETWEEN_ROCK_AND_HELL", "stat_id":"", "hidden":true, "category":"discovery", "target":1},
	{"id":"double_tap", "steam_id":"ACH_DOUBLE_TAP", "stat_id":"", "hidden":true, "category":"discovery", "target":1},
	{"id":"compound_interest", "steam_id":"ACH_COMPOUND_INTEREST", "stat_id":"", "hidden":true, "category":"boss", "target":1},
	{"id":"barely_worthy", "steam_id":"ACH_BARELY_WORTHY", "stat_id":"", "hidden":true, "category":"challenge", "target":1},
	{"id":"unholy_reunion", "steam_id":"ACH_UNHOLY_REUNION", "stat_id":"", "hidden":true, "category":"endless", "target":1},
	{"id":"house_always_loses", "steam_id":"ACH_HOUSE_ALWAYS_LOSES", "stat_id":"", "hidden":true, "category":"boss", "target":1},
	{"id":"personal_space", "steam_id":"ACH_PERSONAL_SPACE", "stat_id":"", "hidden":true, "category":"boss", "target":1},
]

var run_active: bool = false
var run_mode: String = "story"
var accepted_contracts: int = 0
var contract_streak: int = 0
var endless_bosses_this_run: int = 0
var boss_encounter_active: bool = false
var boss_dash_used: bool = false
var boss_damage_taken: bool = false
var greed_treasures_collected: int = 0
var last_boss_defeat_msec: int = -1
var split_kills_by_shot: Dictionary = {}
var run_finished: bool = false

var steam = null
var steam_connected: bool = false
var steam_stats_ready: bool = false
var steam_sync_pending: bool = false
var toast_layer: CanvasLayer
var toast_queue: Array[String] = []
var toast_active: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_initialize_steam()

func _process(_delta: float) -> void:
	if steam_connected and steam != null and steam.has_method("run_callbacks"):
		steam.call("run_callbacks")

func get_definitions() -> Array:
	return DEFINITIONS.duplicate(true)

func get_definition(achievement_id: String) -> Dictionary:
	for definition in DEFINITIONS:
		if str(definition.get("id", "")) == achievement_id:
			return definition.duplicate(true)
	return {}

func is_unlocked(achievement_id: String) -> bool:
	return achievement_id in Global.unlocked_achievements

func get_progress(achievement_id: String) -> int:
	return int(Global.achievement_progress.get(achievement_id, 0))

func get_target(achievement_id: String) -> int:
	return int(get_definition(achievement_id).get("target", 1))

func get_unlocked_count() -> int:
	return Global.unlocked_achievements.size()

func start_run(mode: String) -> void:
	run_active = true
	run_finished = false
	run_mode = mode
	accepted_contracts = 0
	contract_streak = 0
	endless_bosses_this_run = 0
	boss_encounter_active = false
	boss_dash_used = false
	boss_damage_taken = false
	greed_treasures_collected = 0
	last_boss_defeat_msec = -1
	split_kills_by_shot.clear()

func record_contract_decision(accepted: bool) -> void:
	if not run_active:
		return
	if accepted:
		accepted_contracts += 1
		contract_streak += 1
		_set_progress_max("read_fine_print", contract_streak)
	else:
		contract_streak = 0

func start_boss_encounter(_sin_ids: Array) -> void:
	boss_encounter_active = true
	boss_dash_used = false
	boss_damage_taken = false
	greed_treasures_collected = 0

func record_dash_used() -> void:
	if boss_encounter_active:
		boss_dash_used = true

func record_player_damage(_damage_type: String = "") -> void:
	if not boss_encounter_active:
		return
	boss_damage_taken = true

func record_greed_treasure_collected() -> void:
	if boss_encounter_active:
		greed_treasures_collected += 1

func record_wave_completed(current_health: int) -> void:
	if current_health == 1:
		unlock("barely_worthy")

func record_enemy_killed(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	if bool(enemy.get_meta("achievement_hit_after_ricochet", false)):
		unlock("return_to_sender")
	if bool(enemy.get_meta("achievement_hit_by_heavy_shard", false)):
		unlock("between_rock_and_hell")
	if bool(enemy.get_meta("achievement_hit_by_split_trigger", false)):
		var shot_id = str(enemy.get_meta("achievement_split_shot_id", ""))
		if shot_id != "":
			var killed_targets: Array = split_kills_by_shot.get(shot_id, [])
			var enemy_id = enemy.get_instance_id()
			if enemy_id not in killed_targets:
				killed_targets.append(enemy_id)
			split_kills_by_shot[shot_id] = killed_targets
			if killed_targets.size() >= 2:
				unlock("double_tap")

func record_boss_defeated(sin_id: int, player: Node) -> void:
	if not run_active:
		return
	if not boss_dash_used:
		unlock("recoil_purist")
	if sin_id == 7 and not boss_damage_taken:
		unlock("untouchable_ego")
	if sin_id == 5 and not boss_damage_taken:
		unlock("personal_space")
	if sin_id == 6:
		if greed_treasures_collected >= 3:
			unlock("compound_interest")
		if is_instance_valid(player) and int(player.get("reroll_tokens")) >= 7:
			unlock("house_always_loses")

	if run_mode == Global.GAME_MODE_ENDLESS:
		endless_bosses_this_run += 1
		_set_progress_max("eighth_sin", endless_bosses_this_run)
		var now_msec = Time.get_ticks_msec()
		if last_boss_defeat_msec >= 0 and now_msec - last_boss_defeat_msec <= 5000:
			unlock("unholy_reunion")
		last_boss_defeat_msec = now_msec

func finish_run(outcome: String, player: Node, endless_summary: Dictionary = {}) -> void:
	if run_finished:
		return
	run_finished = true
	run_active = false
	boss_encounter_active = false
	var normalized_outcome = outcome.to_lower()
	if normalized_outcome == "victory" and run_mode == Global.GAME_MODE_STORY:
		unlock("sevenfold_penance")
		if accepted_contracts == 0:
			unlock("no_amendments")
		if _has_empty_chamber(player):
			unlock("empty_chamber")
		_record_story_arm_victory(player)
	if normalized_outcome == "retired" and run_mode == Global.GAME_MODE_ENDLESS:
		_set_progress_max("executive_decision", int(endless_summary.get("score", 0)))

func _record_story_arm_victory(player: Node) -> void:
	if not is_instance_valid(player):
		return
	var achievement_id = ""
	match str(player.get("current_arm_id")):
		"fast":
			achievement_id = "swift_sentence"
		"heavy":
			achievement_id = "heavy_verdict"
		"unstable":
			achievement_id = "controlled_chaos"
	if achievement_id != "":
		unlock(achievement_id)
	var completed_arms = 0
	for arm_achievement in ["swift_sentence", "heavy_verdict", "controlled_chaos"]:
		if is_unlocked(arm_achievement):
			completed_arms += 1
	_set_progress_max("arsenal_of_penance", completed_arms)

func _has_empty_chamber(player: Node) -> bool:
	if not is_instance_valid(player):
		return false
	var rare_options: Array = player.get_rare_passive_options() if player.has_method("get_rare_passive_options") else []
	var boss_options: Array = player.get_boss_passive_options() if player.has_method("get_boss_passive_options") else []
	var active_slots: Dictionary = player.get_active_ability_slots() if player.has_method("get_active_ability_slots") else {}
	if not rare_options.is_empty() or not boss_options.is_empty():
		return false
	for ability_id in active_slots.values():
		if str(ability_id) != "":
			return false
	return true

func unlock(achievement_id: String, show_notification: bool = true, sync_to_steam: bool = true) -> bool:
	var definition = get_definition(achievement_id)
	if definition.is_empty() or is_unlocked(achievement_id):
		return false
	Global.unlocked_achievements.append(achievement_id)
	Global.achievement_progress[achievement_id] = int(definition.get("target", 1))
	Global.save_persistent_progress()
	achievement_unlocked.emit(achievement_id)
	achievement_progress_changed.emit(achievement_id, get_progress(achievement_id), get_target(achievement_id))
	if show_notification:
		_queue_toast(achievement_id)
	if sync_to_steam:
		_push_achievement_to_steam(definition)
	return true

func _set_progress_max(achievement_id: String, value: int) -> void:
	if is_unlocked(achievement_id):
		return
	var target = get_target(achievement_id)
	var new_value = clampi(max(get_progress(achievement_id), value), 0, target)
	if new_value == get_progress(achievement_id):
		return
	Global.achievement_progress[achievement_id] = new_value
	Global.save_persistent_progress()
	achievement_progress_changed.emit(achievement_id, new_value, target)
	_push_stat_to_steam(get_definition(achievement_id), new_value)
	if new_value >= target:
		unlock(achievement_id)

func _initialize_steam() -> void:
	if OS.has_feature("web") or not Engine.has_singleton("Steam"):
		return
	steam = Engine.get_singleton("Steam")
	if steam == null:
		return
	var init_method = _first_steam_method(["steamInitEx", "steamInit"])
	if init_method == "":
		return
	var init_result = steam.call(init_method)
	if not _steam_init_succeeded(init_result):
		steam = null
		return
	steam_connected = true
	steam_status_changed.emit(true)
	if steam.has_signal("current_stats_received"):
		steam.connect("current_stats_received", Callable(self, "_on_steam_stats_received"))
	if steam.has_method("requestCurrentStats"):
		steam.call("requestCurrentStats")
		steam_sync_pending = true
	else:
		steam_stats_ready = true
		_sync_steam_achievements()
	if steam.has_method("isCloudEnabledForAccount") and steam.has_method("setCloudEnabledForApp"):
		if bool(steam.call("isCloudEnabledForAccount")):
			steam.call("setCloudEnabledForApp", true)

func _on_steam_stats_received(_game_id = 0, _result = 0, _user_id = 0) -> void:
	steam_stats_ready = true
	steam_sync_pending = false
	_sync_steam_achievements()

func _sync_steam_achievements() -> void:
	if not steam_connected or not steam_stats_ready:
		return
	for definition in DEFINITIONS:
		var achievement_id = str(definition.get("id", ""))
		var steam_id = str(definition.get("steam_id", ""))
		var remote_progress = _get_remote_stat(str(definition.get("stat_id", "")))
		if remote_progress > get_progress(achievement_id):
			_set_progress_max(achievement_id, remote_progress)
		var remote_unlocked = _get_remote_achievement(steam_id)
		if remote_unlocked and not is_unlocked(achievement_id):
			unlock(achievement_id, false, false)
		elif is_unlocked(achievement_id):
			_push_achievement_to_steam(definition, false)
		else:
			_push_stat_to_steam(definition, get_progress(achievement_id), false)
	_store_steam_stats()

func _get_remote_achievement(steam_id: String) -> bool:
	if steam_id == "" or steam == null or not steam.has_method("getAchievement"):
		return false
	var result = steam.call("getAchievement", steam_id)
	return bool(result.get("achieved", false)) if result is Dictionary else false

func _get_remote_stat(stat_id: String) -> int:
	if stat_id == "" or steam == null or not steam.has_method("getStatInt"):
		return 0
	var result = steam.call("getStatInt", stat_id)
	if result is Dictionary:
		return int(result.get("stat", result.get("value", 0)))
	if result is int or result is float:
		return int(result)
	return 0

func _steam_init_succeeded(result) -> bool:
	if result is Dictionary:
		return int(result.get("status", 0)) == 0
	if result is bool:
		return result
	if result is int:
		return int(result) == 0
	return true

func _push_achievement_to_steam(definition: Dictionary, store: bool = true) -> void:
	if not steam_connected or not steam_stats_ready or steam == null:
		return
	var steam_id = str(definition.get("steam_id", ""))
	if steam_id != "" and steam.has_method("setAchievement"):
		steam.call("setAchievement", steam_id)
	if store:
		_store_steam_stats()

func _push_stat_to_steam(definition: Dictionary, value: int, store: bool = true) -> void:
	if not steam_connected or not steam_stats_ready or steam == null:
		return
	var stat_id = str(definition.get("stat_id", ""))
	if stat_id != "" and steam.has_method("setStatInt"):
		steam.call("setStatInt", stat_id, value)
	if store:
		_store_steam_stats()

func _store_steam_stats() -> void:
	if steam != null and steam.has_method("storeStats"):
		steam.call("storeStats")

func _first_steam_method(candidates: Array[String]) -> String:
	for method_name in candidates:
		if steam.has_method(method_name):
			return method_name
	return ""

func is_steam_connected() -> bool:
	return steam_connected

func is_steam_cloud_available() -> bool:
	if not steam_connected or steam == null:
		return false
	if not steam.has_method("isCloudEnabledForAccount") or not steam.has_method("isCloudEnabledForApp"):
		return false
	return bool(steam.call("isCloudEnabledForAccount")) and bool(steam.call("isCloudEnabledForApp"))

func _queue_toast(achievement_id: String) -> void:
	toast_queue.append(achievement_id)
	if not toast_active:
		_show_next_toast()

func _show_next_toast() -> void:
	if toast_queue.is_empty():
		toast_active = false
		return
	toast_active = true
	var achievement_id = toast_queue.pop_front()
	if toast_layer == null:
		toast_layer = CanvasLayer.new()
		toast_layer.layer = 245
		toast_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(toast_layer)
	var panel = PanelContainer.new()
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.position = Vector2(-250.0, 24.0)
	panel.size = Vector2(500.0, 88.0)
	panel.modulate.a = 0.0
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.018, 0.03, 0.98)
	style.border_color = Color(1.0, 0.5, 0.16)
	style.set_border_width_all(3)
	style.set_corner_radius_all(5)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	toast_layer.add_child(panel)
	var label = Label.new()
	label.text = "%s\n%s" % [I18n.t("achievement.unlocked"), I18n.t("achievement.%s.name" % achievement_id)]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.42))
	label.add_theme_constant_override("outline_size", 4)
	panel.add_child(label)
	var tween = create_tween().bind_node(panel)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	tween.tween_interval(3.0)
	tween.tween_property(panel, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func():
		panel.queue_free()
		_show_next_toast()
	)
