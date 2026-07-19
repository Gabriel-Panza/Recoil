extends Node

signal pecado_changed(new_pecado)
signal settings_changed
signal input_device_changed(using_gamepad)
signal codex_updated(category, entry_id)
signal story_completion_changed(completed)

const RANKING_FILE_NAME: String = "ranking_runs.json"
const RANKING_PATH: String = "user://ranking_runs.json"
const SETTINGS_PATH: String = "user://settings.cfg"
const PROGRESS_PATH: String = "user://progress.cfg"
const SETTINGS_VIDEO_SECTION: String = "video"
const SETTINGS_AUDIO_SECTION: String = "audio"
const SETTINGS_CONTROLS_SECTION: String = "controls"
const SETTINGS_CODEX_SECTION: String = "codex"
const SETTINGS_PROGRESS_SECTION: String = "progress"
const SETTINGS_ACHIEVEMENTS_SECTION: String = "achievements"
const GAME_MODE_STORY: String = "story"
const GAME_MODE_ENDLESS: String = "endless"
const CONTROLS_SCHEMA_VERSION: int = 2
const GROUP_MUSIC: String = "Music"
const GROUP_SFX: String = "SFX"
const GROUP_PLAYER: String = "Player"
const GROUP_ENEMY: String = "Enemy"
const GROUP_BOSS: String = "Boss"
const GROUP_PROJECTILE: String = "Projectile"
const GROUP_ENEMY_PROJECTILE: String = "EnemyProjectile"

const WALL_LAYER_MASK: int = 1
const PLAYER_LAYER_MASK: int = 2
const ENEMY_LAYER_MASK: int = 4
const ENEMY_COLLISION_MASK: int = ENEMY_LAYER_MASK
const ENEMY_BODY_COLLISION_SCALE: float = 0.7
const CHARACTER_RENDER_Z_INDEX: int = 20
const GROUND_AREA_VFX_LAYER_NAME: String = "GroundAreaVFX"
const GROUND_AREA_VFX_Z_INDEX: int = 10
const ENEMY_ATTACK_ACTIVE_COLOR_DARKENING: float = 0.3
const AREA_AURA_VFX_DARKENING: float = 0.15
const INTRO_CUTSCENE_RETURN_GAME: String = "game"
const INTRO_CUTSCENE_RETURN_GALLERY: String = "gallery"
const AUDIO_SLIDER_MIN_VALUE: float = 0.0
const AUDIO_SLIDER_MAX_VALUE: float = 100.0
const AUDIO_MUTE_DB: float = -80.0
const AUDIO_MAX_DB: float = 0.0
const AUDIO_BASE_VOLUME_META: String = "base_audio_volume_db"
const WEB_SFX_MAX_POLYPHONY: int = 1
const WEB_PARTICLE_AMOUNT_MULTIPLIER: float = 0.35
const DEFAULT_TOOLTIP_WRAP_CHARS: int = 62
const GRAPHICS_LOW: int = 0
const GRAPHICS_MEDIUM: int = 1
const GRAPHICS_HIGH: int = 2
const WINDOW_MODE_WINDOWED: int = 0
const WINDOW_MODE_FULLSCREEN: int = 1
const WINDOW_MODE_BORDERLESS: int = 2
const SUPPORTED_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1152, 648),
	Vector2i(1280, 720),
	Vector2i(1280, 800),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]
const REMAPPABLE_ACTIONS: Array[StringName] = [&"shoot", &"dash", &"active_e", &"active_r"]
const CONTROLLER_AIM_DEADZONE: float = 0.28
const WEB_SFX_VOICE_LIMITS = {
	"enemy_footstep": 0,
	"boss_footstep": 0,
	"player_shot": 2
}

var intro_cutscene_return_target: String = INTRO_CUTSCENE_RETURN_GAME
var open_cutscenes_gallery_on_menu_ready: bool = false
var selected_game_mode: String = GAME_MODE_STORY
var story_completed: bool = false
var endless_difficulty_index: int = 1
var endless_run_summary: Dictionary = {}
var limited_sfx_voice_counts: Dictionary = {}
var looping_audio_stream_cache: Dictionary = {}
var enemy_sprite_frames_cache: Dictionary = {}
var shader_cache: Dictionary = {}
var paused_music_watchdog_elapsed: float = 0.0
var window_mode: int = WINDOW_MODE_WINDOWED
var window_resolution: Vector2i = Vector2i(1280, 720)
var vsync_enabled: bool = true
var graphics_quality: int = GRAPHICS_HIGH
var last_input_is_gamepad: bool = false
var codex_discovered: Dictionary = {
	"enemies": [],
	"elites": [],
	"sins": [],
	"passives": [],
}
var unlocked_achievements: Array = []
var achievement_progress: Dictionary = {}

func wrap_tooltip_text(text: String, max_line_chars: int = DEFAULT_TOOLTIP_WRAP_CHARS) -> String:
	if text == "" or max_line_chars <= 0:
		return text

	var wrapped_lines := PackedStringArray()
	var normalized_text = text.replace("\r\n", "\n").replace("\r", "\n")
	for raw_line in normalized_text.split("\n", true):
		if raw_line.length() <= max_line_chars:
			wrapped_lines.append(raw_line)
			continue
		_append_wrapped_tooltip_line(wrapped_lines, raw_line, max_line_chars)

	return "\n".join(wrapped_lines)

func _append_wrapped_tooltip_line(wrapped_lines: PackedStringArray, raw_line: String, max_line_chars: int) -> void:
	var current_line = ""
	for word in raw_line.split(" ", false):
		var remaining_word = word
		while remaining_word.length() > max_line_chars:
			if current_line != "":
				wrapped_lines.append(current_line)
				current_line = ""
			wrapped_lines.append(remaining_word.substr(0, max_line_chars))
			remaining_word = remaining_word.substr(max_line_chars)

		if remaining_word == "":
			continue
		if current_line == "":
			current_line = remaining_word
		elif current_line.length() + remaining_word.length() + 1 <= max_line_chars:
			current_line += " " + remaining_word
		else:
			wrapped_lines.append(current_line)
			current_line = remaining_word

	if current_line != "":
		wrapped_lines.append(current_line)

const STARTING_ARM_DATA = {
	"fast": {
		"name": "Fast Arm",
		"description": "Weak shots, high fire rate, and short recoil for tighter control.",
		"attack_damage": 33.0,
		"base_fire_rate": 0.5,
		"min_fire_rate": 0.3,
		"base_recoil_force": 390.0,
		"friction": 900.0,
		"attack_speed_upgrade_multiplier": 0.3,
		"unstable_projectiles": false
	},
	"heavy": {
		"name": "Heavy Arm",
		"description": "Slow shots with high damage and strong recoil for big repositioning plays.",
		"attack_damage": 90.0,
		"base_fire_rate": 2.15,
		"min_fire_rate": 1.75,
		"base_recoil_force": 750.0,
		"friction": 600.0,
		"attack_speed_upgrade_multiplier": 0.7,
		"unstable_projectiles": false
	},
	"unstable": {
		"name": "Unstable Arm",
		"description": "Projectiles pierce one target and ricochet once, but come back dangerous.",
		"attack_damage": 45.0,
		"base_fire_rate": 1.35,
		"min_fire_rate": 1.05,
		"base_recoil_force": 580.0,
		"friction": 750.0,
		"attack_speed_upgrade_multiplier": 0.5,
		"unstable_projectiles": true
	}
}

const STARTING_ARM_OPTIONS = [
	{
		"id": "fast",
		"name": "FAST ARM",
		"summary": "Weak shots",
		"details": "High control and short recoil."
	},
	{
		"id": "heavy",
		"name": "HEAVY ARM",
		"summary": "Heavy shots",
		"details": "Low control, strong recoil."
	},
	{
		"id": "unstable",
		"name": "UNSTABLE ARM",
		"summary": "Pierce and ricochet",
		"details": "Shots can come back at you."
	}
]

const PASSIVE_UPGRADE_OPTIONS = [
	{ "id": "option_1", "text": "Recoil Force (+5%)", "description": "+5% recoil force is additive from your base recoil, not your current recoil. Does not appear for the heavy arm and stops appearing at 8.0 recoil force.", "rarity": "passive_common" },
	{ "id": "option_2", "text": "Health (+5% base)", "description": "Adds 5% of your original maximum health as a fixed amount and restores health based on that amount. Healing Received modifiers apply.", "rarity": "passive_common" },
	{ "id": "option_3", "text": "Attack (+15% base)", "description": "Adds 15% of the chosen arm's original damage as a fixed amount.", "rarity": "passive_common" },
	{ "id": "option_4", "text": "Atk-Speed (+5%)", "description": "+5% attack speed before the chosen arm's tuning. Does not appear for the fast arm; heavy and unstable arms each have their own safe cooldown floor.", "rarity": "passive_common" },
	{ "id": "option_5", "text": "Bullet Size (+5%)", "description": "+5% bullet size for friendly projectiles. Bonus is additive and stops at 200% bullet size.", "rarity": "passive_common" },
	{ "id": "option_6", "text": "Heal After Wave (+3%)", "description": "Heal 3% max health after each enemy wave. This upgrade stops appearing at 15%.", "rarity": "passive_common" },
	{ "id": "option_7", "text": "Dash Cooldown (-5%)", "description": "Reduces dash recharge cooldown by 5%. This upgrade is uncommon and stops appearing at 40%.", "rarity": "passive_common" }
]

const CURSED_PASSIVE_OPTIONS = [
	{ "id": "glass_canon", "text": "Attack (+50%), Health (-30%)", "description": "Greatly increases damage, but lowers your maximum health. Strong if you can avoid hits.", "rarity": "passive_cursed" },
	{ "id": "tanky", "text": "Health (+50%), Attack (-30%)", "description": "Greatly increases survivability, but lowers your damage output.", "rarity": "passive_cursed" },
	{ "id": "deadly_slow", "text": "Recoil Force (-20%), Attack (+40%)", "description": "Greatly increases damage, but weakens your recoil movement by cutting pushback force.", "rarity": "passive_cursed" },
	{ "id": "fast_but_small", "text": "Bullet Size (-30%), Atk-Speed (+30%)", "description": "Adds +30% attack speed before the chosen arm's tuning, but reduces bullet size by 30%. Bullet size cannot drop below 50%.", "rarity": "passive_cursed" },
	{ "id": "blood_tax", "text": "Attack (+40%), Heal (-45%)", "description": "Greatly increases damage, but all healing you receive is reduced by 45%.", "rarity": "passive_cursed" },
	{ "id": "cursed_luck", "text": "Luck (x1.5), Damage Taken (+30%)", "description": "Luck multiplies your chance to roll lucky level ups, but all damage you take is increased by 30%.", "rarity": "passive_cursed" },
	{ "id": "thin_blood", "text": "Health (-40%), Heal (+100%)", "description": "Greatly lowers your maximum health, but increase all healing you receive.", "rarity": "passive_cursed" }
]

const RARE_PASSIVE_OPTIONS = [
	{ "id": "Shield_Protection", "text": "Gain a one-hit shield", "description": "Grants a shield that blocks the next damage instance. You can equip up to two rare passives.", "rarity": "passive_rare" },
	{ "id": "Recoil_Explosion", "text": "Recoil Explosion", "description": "Every shot creates a 180px shockwave that deals 35% of your attack damage. You can equip up to two rare passives.", "rarity": "passive_rare" },
	{ "id": "Double_Dash", "text": "Double Dash", "description": "Gives you two dash charges. Each spent charge recharges one at a time. You can equip up to two rare passives.", "rarity": "passive_rare" },
	{ "id": "Offensive_Dash", "text": "Offensive Dash", "description": "Dashing blocks damage and releases a 180px shockwave at the end of the dash, dealing 75% of your attack damage. You can equip up to two rare passives.", "rarity": "passive_rare" },
	{ "id": "Kinetic_Reload", "text": "Kinetic Reload", "description": "Recoil bounces against arena limits reduce 35% of your remaining shot cooldown. This can trigger once every 0.35 seconds. You can equip up to two rare passives.", "rarity": "passive_rare" },
	{ "id": "Splintered_Chamber", "text": "Splintered Chamber", "description": "Every 7th shot fires 2 side fragments, each dealing 35% of that shot's damage. Overheat damage applies to these fragments. You can equip up to two rare passives.", "rarity": "passive_rare" }
]

const BOSS_REWARD_OPTIONS = [
	{ "id": "sloth_slow_aura", "name": "Slow Aura", "text": "Slow Aura", "description": "Enemies within 180px move at 65% speed.", "rarity": "passive_sin" },
	{ "id": "sloth_field", "name": "Sloth Field", "text": "Sloth Field", "description": "Create a 180px field near you for 5 seconds. Enemies inside drop to 35% speed, but your dash speed drops to 75% during the field.", "rarity": "active_sin" },
	{ "id": "gluttony_heal_kill", "name": "Blood Feast", "text": "Blood Feast", "description": "Killing an enemy releases green motes that heal 1% max health when they return.", "rarity": "passive_sin" },
	{ "id": "gluttony_devour", "name": "Devour", "text": "Devour", "description": "Consume up to two enemies within 180px. Green motes fly back and heal up to 12.5% max health when they arrive, but your dash speed is halved for 5 seconds.", "rarity": "active_sin" },
	{ "id": "envy_mirror_shot", "name": "Mirror Shot", "text": "Mirror Shot", "description": "Every shot fires a mirrored bullet for 50% damage.", "rarity": "passive_sin" },
	{ "id": "envy_mirror_clone", "name": "Mirror Clone", "text": "Mirror Clone", "description": "Summon a mirror clone that fires random risky shots with you for a short time. Clone bullets can hit anything, including you.", "rarity": "active_sin" },
	{ "id": "wrath_overheat", "name": "Overheat", "text": "Overheat", "description": "Every 4th shot deals double damage.", "rarity": "passive_sin" },
	{ "id": "wrath_burst", "name": "Wrath Burst", "text": "Wrath Burst", "description": "Fire 16 radial bullets for 120% attack damage each, then take 20 damage.", "rarity": "active_sin" },
	{ "id": "lust_for_vengeance", "name": "Vengeance", "text": "Vengeance", "description": "Deal 75% more damage while at full HP, but lose the bonus when hit.", "rarity": "passive_sin" },
	{ "id": "lust_for_perfection", "name": "Perfection", "text": "Perfection", "description": "Become invulnerable for 3 seconds, then take double damage for 5 seconds.", "rarity": "active_sin" },
	{ "id": "greed_cursed_level", "name": "Golden Debt", "text": "Golden Debt", "description": "Gain +20% attack and +10% attack speed, but pay 5% of your current health at the start of each wave.", "rarity": "passive_sin" },
	{ "id": "greed_treasure_rain", "name": "Treasure Rain", "text": "Treasure Rain", "description": "Rain golden projectiles from above. Each projectile deals 120% attack damage only when it collides, including with you.", "rarity": "active_sin" },
]

const BOSS_OPTION_IDS_BY_PECADO = {
	1: ["sloth_slow_aura", "sloth_field"],
	2: ["gluttony_heal_kill", "gluttony_devour"],
	3: ["envy_mirror_shot", "envy_mirror_clone"],
	4: ["wrath_overheat", "wrath_burst"],
	5: ["lust_for_vengeance", "lust_for_perfection"],
	6: ["greed_cursed_level", "greed_treasure_rain"],
}

const ACTIVE_ABILITY_DATA = {
	"sloth_field": {
		"name": "Sloth Field",
		"description": "Create a 180px field for 5 seconds. Enemies inside drop to 35% speed, but your dash speed drops to 75% during the field.",
		"cooldown": 20.0,
		"method": "activate_sloth_field"
	},
	"gluttony_devour": {
		"name": "Devour",
		"description": "Consume up to two enemies within 180px. Green motes fly back and heal up to 12.5% max health when they arrive, but your dash speed is halved for 5 seconds.",
		"cooldown": 45.0,
		"method": "activate_gluttony_devour"
	},
	"envy_mirror_clone": {
		"name": "Mirror Clone",
		"description": "Summon a mirror clone that fires random risky shots with you for a short time. Clone bullets can hit anything, including you.",
		"cooldown": 37.5,
		"method": "activate_envy_mirror_clone"
	},
	"wrath_burst": {
		"name": "Wrath Burst",
		"description": "Fire 16 radial bullets for 120% attack damage each, then take 20 damage.",
		"cooldown": 45.0,
		"method": "activate_wrath_burst"
	},
	"lust_for_perfection": {
		"name": "Perfection",
		"description": "Become invulnerable for 3 seconds, then take double damage for 5 seconds.",
		"cooldown": 60.0,
		"method": "activate_lust_for_perfection"
	},
	"greed_treasure_rain": {
		"name": "Treasure Rain",
		"description": "Rain golden projectiles from above. Each projectile deals 120% attack damage only when it collides, including with you.",
		"cooldown": 45.0,
		"method": "activate_greed_treasure_rain"
	},
}

const PASSIVE_STATUS_DATA = {
	"Shield_Protection": {
		"name": "One-hit Shield",
		"description": "Blocks the next damage instance, then refreshes after 12 seconds."
	},
	"Recoil_Explosion": {
		"name": "Recoil Explosion",
		"description": "Every shot creates a 180px shockwave that deals 35% of your attack damage."
	},
	"Double_Dash": {
		"name": "Double Dash",
		"description": "Gain two dash charges. Each spent charge recharges one at a time."
	},
	"Offensive_Dash": {
		"name": "Offensive Dash",
		"description": "Dashing blocks damage and releases a 180px shockwave for 75% attack damage."
	},
	"Kinetic_Reload": {
		"name": "Kinetic Reload",
		"description": "Recoil bounces against arena limits reduce 35% of your remaining shot cooldown."
	},
	"Splintered_Chamber": {
		"name": "Splintered Chamber",
		"description": "Every 7th shot fires 2 side fragments for 35% of that shot's damage."
	},
	"sloth_slow_aura": {
		"name": "Slow Aura",
		"description": "Enemies within 180px move at 65% speed."
	},
	"gluttony_heal_kill": {
		"name": "Blood Feast",
		"description": "Killing an enemy releases green motes that heal 1% max health when they return."
	},
	"envy_mirror_shot": {
		"name": "Mirror Shot",
		"description": "Every shot fires a mirrored bullet for 50% damage."
	},
	"wrath_overheat": {
		"name": "Overheat",
		"description": "Every 4th shot deals double damage."
	},
	"lust_for_vengeance": {
		"name": "Vengeance",
		"description": "At full HP, deal 75% more damage."
	},
	"greed_cursed_level": {
		"name": "Golden Debt",
		"description": "+20% attack and +10% attack speed. Pay 5% current health at each wave start."
	},
}

const RARE_OPTION_IDS = ["Shield_Protection", "Recoil_Explosion", "Double_Dash", "Offensive_Dash", "Kinetic_Reload", "Splintered_Chamber"]
const SIN_PASSIVE_IDS = [
	"sloth_slow_aura",
	"gluttony_heal_kill",
	"envy_mirror_shot",
	"wrath_overheat",
	"lust_for_vengeance",
	"greed_cursed_level"
]

const SIN_PASSIVE_FLAGS = {
	"sloth_slow_aura": "sloth_slow_aura_enabled",
	"gluttony_heal_kill": "gluttony_heal_kill_enabled",
	"envy_mirror_shot": "envy_mirror_shot_enabled",
	"wrath_overheat": "wrath_overheat_enabled",
	"lust_for_vengeance": "lust_for_vengeance_enabled",
	"greed_cursed_level": "greed_cursed_level_enabled"
}

var pecado = 1:
	set(value):
		if value != pecado:
			pecado = value
			pecado_changed.emit(pecado)

var run_start_msec: int = -1
var current_run_saved: bool = false

var sfx_volume_db: float = 0.0
var music_volume_db: float = 0.0
var sfx_volume_slider_value: float = AUDIO_SLIDER_MAX_VALUE
var music_volume_slider_value: float = AUDIO_SLIDER_MAX_VALUE

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_request_web_persistent_storage()
	_ensure_input_actions()
	_load_persistent_settings()
	_apply_video_settings()
	_reset_ranking_if_executable_changed()

func is_endless_mode() -> bool:
	return selected_game_mode == GAME_MODE_ENDLESS

func is_story_mode() -> bool:
	return not is_endless_mode()

func get_difficulty_index() -> int:
	return max(endless_difficulty_index, 1) if is_endless_mode() else clampi(pecado, 1, 7)

func set_endless_difficulty_index(value: int) -> void:
	endless_difficulty_index = max(value, 1)

func set_endless_run_summary(summary: Dictionary) -> void:
	endless_run_summary = summary.duplicate(true)

func mark_story_completed() -> void:
	if story_completed:
		return
	story_completed = true
	_save_persistent_progress()
	story_completion_changed.emit(true)

func _input(event: InputEvent) -> void:
	var using_gamepad = event is InputEventJoypadButton or event is InputEventJoypadMotion
	var using_pointer_or_keyboard = event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion
	if not using_gamepad and not using_pointer_or_keyboard:
		return
	if using_gamepad == last_input_is_gamepad:
		return
	last_input_is_gamepad = using_gamepad
	input_device_changed.emit(last_input_is_gamepad)

func _ensure_input_actions() -> void:
	_ensure_action(&"ui_accept", 0.5)
	_ensure_action(&"ui_cancel", 0.5)
	_ensure_action(&"pause", 0.5)
	_ensure_action(&"codex", 0.5)
	_ensure_action(&"shoot", 0.2)
	_ensure_action(&"dash", 0.2)
	_ensure_action(&"active_e", 0.2)
	_ensure_action(&"active_r", 0.2)
	_ensure_action(&"aim_left", CONTROLLER_AIM_DEADZONE)
	_ensure_action(&"aim_right", CONTROLLER_AIM_DEADZONE)
	_ensure_action(&"aim_up", CONTROLLER_AIM_DEADZONE)
	_ensure_action(&"aim_down", CONTROLLER_AIM_DEADZONE)
	_add_default_event_if_missing(&"ui_accept", _make_joy_button_event(JOY_BUTTON_A))
	_add_default_event_if_missing(&"ui_cancel", _make_joy_button_event(JOY_BUTTON_B))
	_add_default_event_if_missing(&"pause", _make_key_event(KEY_ESCAPE))
	_add_default_event_if_missing(&"pause", _make_joy_button_event(JOY_BUTTON_START))
	_add_default_event_if_missing(&"codex", _make_key_event(KEY_C))
	_add_default_event_if_missing(&"codex", _make_joy_button_event(JOY_BUTTON_BACK))

	_add_default_event_if_missing(&"shoot", _make_mouse_button_event(MOUSE_BUTTON_LEFT))
	_add_default_event_if_missing(&"shoot", _make_joy_motion_event(JOY_AXIS_TRIGGER_RIGHT, 1.0))
	_add_default_event_if_missing(&"shoot", _make_joy_button_event(JOY_BUTTON_A))
	_add_default_event_if_missing(&"dash", _make_key_event(KEY_SPACE))
	_add_default_event_if_missing(&"dash", _make_joy_button_event(JOY_BUTTON_B))
	_add_default_event_if_missing(&"active_e", _make_key_event(KEY_E))
	_add_default_event_if_missing(&"active_e", _make_joy_button_event(JOY_BUTTON_X))
	_add_default_event_if_missing(&"active_r", _make_key_event(KEY_R))
	_add_default_event_if_missing(&"active_r", _make_joy_button_event(JOY_BUTTON_Y))
	_add_default_event_if_missing(&"aim_left", _make_joy_motion_event(JOY_AXIS_RIGHT_X, -1.0))
	_add_default_event_if_missing(&"aim_right", _make_joy_motion_event(JOY_AXIS_RIGHT_X, 1.0))
	_add_default_event_if_missing(&"aim_up", _make_joy_motion_event(JOY_AXIS_RIGHT_Y, -1.0))
	_add_default_event_if_missing(&"aim_down", _make_joy_motion_event(JOY_AXIS_RIGHT_Y, 1.0))

func _ensure_action(action: StringName, deadzone: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, deadzone)
	else:
		InputMap.action_set_deadzone(action, deadzone)

func _add_default_event_if_missing(action: StringName, event: InputEvent) -> void:
	for existing_event in InputMap.action_get_events(action):
		if existing_event.is_match(event):
			return
	InputMap.action_add_event(action, event)

func _make_key_event(keycode: Key) -> InputEventKey:
	var event = InputEventKey.new()
	event.physical_keycode = keycode
	return event

func _make_mouse_button_event(button_index: MouseButton) -> InputEventMouseButton:
	var event = InputEventMouseButton.new()
	event.button_index = button_index
	return event

func _make_joy_button_event(button_index: JoyButton) -> InputEventJoypadButton:
	var event = InputEventJoypadButton.new()
	event.device = -1
	event.button_index = button_index
	return event

func _make_joy_motion_event(axis: JoyAxis, axis_value: float) -> InputEventJoypadMotion:
	var event = InputEventJoypadMotion.new()
	event.device = -1
	event.axis = axis
	event.axis_value = axis_value
	return event

func get_controller_aim_vector() -> Vector2:
	return Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", CONTROLLER_AIM_DEADZONE)

func get_action_binding_text(action: StringName, gamepad: bool) -> String:
	var labels: PackedStringArray = []
	for event in InputMap.action_get_events(action):
		if _is_gamepad_event(event) == gamepad:
			var label = _format_input_event(event)
			if label not in labels:
				labels.append(label)
	return " / ".join(labels) if not labels.is_empty() else "-"

func set_action_binding(action: StringName, event: InputEvent, gamepad: bool) -> void:
	if action not in REMAPPABLE_ACTIONS or _is_gamepad_event(event) != gamepad:
		return
	for existing_event in InputMap.action_get_events(action):
		if _is_gamepad_event(existing_event) == gamepad:
			InputMap.action_erase_event(action, existing_event)
	var binding = event.duplicate()
	if binding is InputEventJoypadButton or binding is InputEventJoypadMotion:
		binding.device = -1
	InputMap.action_add_event(action, binding)
	_save_control_bindings()
	settings_changed.emit()

func reset_control_bindings() -> void:
	for action in REMAPPABLE_ACTIONS:
		InputMap.action_erase_events(action)
	InputMap.action_erase_events(&"aim_left")
	InputMap.action_erase_events(&"aim_right")
	InputMap.action_erase_events(&"aim_up")
	InputMap.action_erase_events(&"aim_down")
	_ensure_input_actions()
	_save_control_bindings()
	settings_changed.emit()

func _is_gamepad_event(event: InputEvent) -> bool:
	return event is InputEventJoypadButton or event is InputEventJoypadMotion

func _format_input_event(event: InputEvent) -> String:
	if event is InputEventMouseButton:
		return "Mouse %d" % int(event.button_index)
	if event is InputEventJoypadMotion:
		return "RT" if event.axis == JOY_AXIS_TRIGGER_RIGHT else "Axis %d" % int(event.axis)
	if event is InputEventJoypadButton:
		var button_labels = {
			JOY_BUTTON_A: "A",
			JOY_BUTTON_B: "B",
			JOY_BUTTON_X: "X",
			JOY_BUTTON_Y: "Y",
			JOY_BUTTON_BACK: "View",
			JOY_BUTTON_START: "Start",
			JOY_BUTTON_LEFT_SHOULDER: "LB",
			JOY_BUTTON_RIGHT_SHOULDER: "RB",
		}
		return str(button_labels.get(event.button_index, "Button %d" % int(event.button_index)))
	return event.as_text().replace(" (Physical)", "")

func set_window_mode(value: int) -> void:
	window_mode = clampi(value, WINDOW_MODE_WINDOWED, WINDOW_MODE_BORDERLESS)
	_apply_video_settings()
	_save_display_settings()

func set_window_resolution(value: Vector2i) -> void:
	if value not in SUPPORTED_RESOLUTIONS:
		return
	window_resolution = value
	_apply_video_settings()
	_save_display_settings()

func set_vsync_enabled(value: bool) -> void:
	vsync_enabled = value
	_apply_video_settings()
	_save_display_settings()

func set_graphics_quality(value: int) -> void:
	graphics_quality = clampi(value, GRAPHICS_LOW, GRAPHICS_HIGH)
	_save_display_settings()
	settings_changed.emit()

func get_scaled_particle_amount(default_amount: int) -> int:
	var multiplier = [0.45, 0.72, 1.0][graphics_quality]
	if is_web_build():
		multiplier = min(multiplier, WEB_PARTICLE_AMOUNT_MULTIPLIER)
	return max(1, int(round(float(default_amount) * multiplier)))

func discover_codex(category: String, entry_id: String) -> void:
	if entry_id == "" or not codex_discovered.has(category):
		return
	var entries: Array = codex_discovered[category]
	if entry_id in entries:
		return
	entries.append(entry_id)
	codex_discovered[category] = entries
	_save_codex_progress()
	codex_updated.emit(category, entry_id)

func is_codex_discovered(category: String, entry_id: String) -> bool:
	return entry_id in codex_discovered.get(category, [])

func discover_passive_option(option_id: String) -> void:
	discover_codex("passives", option_id)

func _load_persistent_settings() -> void:
	var config = ConfigFile.new()
	var settings_loaded = config.load(SETTINGS_PATH) == OK
	if settings_loaded:
		window_mode = int(config.get_value(SETTINGS_VIDEO_SECTION, "window_mode", window_mode))
		var stored_resolution = config.get_value(SETTINGS_VIDEO_SECTION, "resolution", window_resolution)
		if stored_resolution is Vector2i and stored_resolution in SUPPORTED_RESOLUTIONS:
			window_resolution = stored_resolution
		vsync_enabled = bool(config.get_value(SETTINGS_VIDEO_SECTION, "vsync", vsync_enabled))
		graphics_quality = clampi(int(config.get_value(SETTINGS_VIDEO_SECTION, "quality", graphics_quality)), GRAPHICS_LOW, GRAPHICS_HIGH)
		music_volume_slider_value = float(config.get_value(SETTINGS_AUDIO_SECTION, "music", music_volume_slider_value))
		sfx_volume_slider_value = float(config.get_value(SETTINGS_AUDIO_SECTION, "sfx", sfx_volume_slider_value))
		_load_control_bindings(config)
	music_volume_db = audio_slider_value_to_db(music_volume_slider_value)
	sfx_volume_db = audio_slider_value_to_db(sfx_volume_slider_value)
	_load_persistent_progress(config if settings_loaded else null)

func _load_persistent_progress(legacy_settings: ConfigFile = null) -> void:
	var progress = ConfigFile.new()
	var progress_loaded = progress.load(PROGRESS_PATH) == OK
	var source = progress if progress_loaded else legacy_settings
	if source == null:
		return
	story_completed = bool(source.get_value(SETTINGS_PROGRESS_SECTION, "story_completed", false))
	for category in codex_discovered.keys():
		var stored_entries = source.get_value(SETTINGS_CODEX_SECTION, category, [])
		if stored_entries is Array:
			codex_discovered[category] = stored_entries.duplicate()
	var stored_achievements = source.get_value(SETTINGS_ACHIEVEMENTS_SECTION, "unlocked", [])
	if stored_achievements is Array:
		unlocked_achievements = stored_achievements.duplicate()
	var stored_progress = source.get_value(SETTINGS_ACHIEVEMENTS_SECTION, "progress", {})
	if stored_progress is Dictionary:
		achievement_progress = stored_progress.duplicate(true)
	if not progress_loaded and legacy_settings != null:
		_save_persistent_progress()

func _apply_video_settings() -> void:
	if OS.has_feature("web"):
		return
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, window_mode == WINDOW_MODE_BORDERLESS)
	if window_mode == WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(window_resolution)
		var screen_size = DisplayServer.screen_get_size()
		DisplayServer.window_set_position((screen_size - window_resolution) / 2)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED)
	settings_changed.emit()

func _save_display_settings() -> void:
	var config = _load_settings_file()
	config.set_value(SETTINGS_VIDEO_SECTION, "window_mode", window_mode)
	config.set_value(SETTINGS_VIDEO_SECTION, "resolution", window_resolution)
	config.set_value(SETTINGS_VIDEO_SECTION, "vsync", vsync_enabled)
	config.set_value(SETTINGS_VIDEO_SECTION, "quality", graphics_quality)
	_save_config_file(config, SETTINGS_PATH, "display settings")

func _save_audio_settings() -> void:
	var config = _load_settings_file()
	config.set_value(SETTINGS_AUDIO_SECTION, "music", music_volume_slider_value)
	config.set_value(SETTINGS_AUDIO_SECTION, "sfx", sfx_volume_slider_value)
	_save_config_file(config, SETTINGS_PATH, "audio settings")

func _save_control_bindings() -> void:
	var config = _load_settings_file()
	config.set_value(SETTINGS_CONTROLS_SECTION, "schema_version", CONTROLS_SCHEMA_VERSION)
	for action in REMAPPABLE_ACTIONS:
		var serialized: Array = []
		for event in InputMap.action_get_events(action):
			serialized.append(_serialize_input_event(event))
		config.set_value(SETTINGS_CONTROLS_SECTION, str(action), serialized)
	_save_config_file(config, SETTINGS_PATH, "control bindings")

func _load_control_bindings(config: ConfigFile) -> void:
	var schema_version = int(config.get_value(SETTINGS_CONTROLS_SECTION, "schema_version", 0))
	for action in REMAPPABLE_ACTIONS:
		if schema_version < CONTROLS_SCHEMA_VERSION and action in [&"shoot", &"dash"]:
			continue
		if not config.has_section_key(SETTINGS_CONTROLS_SECTION, str(action)):
			continue
		var serialized = config.get_value(SETTINGS_CONTROLS_SECTION, str(action), [])
		if not (serialized is Array) or serialized.is_empty():
			continue
		InputMap.action_erase_events(action)
		for event_data in serialized:
			var event = _deserialize_input_event(event_data)
			if event != null:
				InputMap.action_add_event(action, event)
	if schema_version < CONTROLS_SCHEMA_VERSION:
		_save_control_bindings()

func _serialize_input_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"type": "key", "physical": int(event.physical_keycode), "keycode": int(event.keycode)}
	if event is InputEventMouseButton:
		return {"type": "mouse", "button": int(event.button_index)}
	if event is InputEventJoypadButton:
		return {"type": "joy_button", "button": int(event.button_index)}
	if event is InputEventJoypadMotion:
		return {"type": "joy_motion", "axis": int(event.axis), "value": float(event.axis_value)}
	return {}

func _deserialize_input_event(data) -> InputEvent:
	if not (data is Dictionary):
		return null
	match str(data.get("type", "")):
		"key":
			var event = InputEventKey.new()
			event.physical_keycode = int(data.get("physical", 0)) as Key
			event.keycode = int(data.get("keycode", 0)) as Key
			return event
		"mouse":
			return _make_mouse_button_event(int(data.get("button", MOUSE_BUTTON_LEFT)) as MouseButton)
		"joy_button":
			return _make_joy_button_event(int(data.get("button", JOY_BUTTON_A)) as JoyButton)
		"joy_motion":
			return _make_joy_motion_event(int(data.get("axis", JOY_AXIS_TRIGGER_RIGHT)) as JoyAxis, float(data.get("value", 1.0)))
	return null

func _save_codex_progress() -> void:
	_save_persistent_progress()

func _save_persistent_progress() -> bool:
	var config = ConfigFile.new()
	config.load(PROGRESS_PATH)
	config.set_value(SETTINGS_PROGRESS_SECTION, "story_completed", story_completed)
	for category in codex_discovered.keys():
		config.set_value(SETTINGS_CODEX_SECTION, category, codex_discovered[category])
	config.set_value(SETTINGS_ACHIEVEMENTS_SECTION, "unlocked", unlocked_achievements)
	config.set_value(SETTINGS_ACHIEVEMENTS_SECTION, "progress", achievement_progress)
	return _save_config_file(config, PROGRESS_PATH, "persistent progress")

func save_persistent_progress() -> bool:
	return _save_persistent_progress()

func _load_settings_file() -> ConfigFile:
	var config = ConfigFile.new()
	config.load(SETTINGS_PATH)
	return config

func _save_config_file(config: ConfigFile, path: String, context: String) -> bool:
	_ensure_user_data_dir_exists()
	var save_error = config.save(path)
	if save_error != OK:
		push_error("Failed to save %s at %s: %s" % [context, ProjectSettings.globalize_path(path), error_string(save_error)])
		return false
	if is_web_build() and not OS.is_userfs_persistent():
		push_warning("Saved %s for this session, but the browser reports that user:// is not persistent. Private browsing or blocked site storage may erase it." % context)
	return true

func _process(delta: float) -> void:
	if get_tree() != null and get_tree().paused:
		paused_music_watchdog_elapsed += delta
		if paused_music_watchdog_elapsed < 0.5:
			return
		paused_music_watchdog_elapsed = 0.0
		_resume_music_players_during_pause()
	else:
		paused_music_watchdog_elapsed = 0.0

func configure_music_slider(slider: Range) -> void:
	_configure_volume_slider(slider, music_volume_slider_value)

func configure_sfx_slider(slider: Range) -> void:
	_configure_volume_slider(slider, sfx_volume_slider_value)

func set_music_volume_from_slider(value: float) -> void:
	music_volume_slider_value = _clamp_audio_slider_value(value)
	music_volume_db = audio_slider_value_to_db(music_volume_slider_value)
	_apply_group_volume(GROUP_MUSIC, music_volume_db)
	_save_audio_settings()

func set_sfx_volume_from_slider(value: float) -> void:
	sfx_volume_slider_value = _clamp_audio_slider_value(value)
	sfx_volume_db = audio_slider_value_to_db(sfx_volume_slider_value)
	_apply_group_volume(GROUP_SFX, sfx_volume_db)
	_save_audio_settings()

func audio_slider_value_to_db(value: float) -> float:
	var normalized = _clamp_audio_slider_value(value) / AUDIO_SLIDER_MAX_VALUE
	if normalized <= 0.0:
		return AUDIO_MUTE_DB

	return clampf(linear_to_db(normalized), AUDIO_MUTE_DB, AUDIO_MAX_DB)

func register_audio_player(player: Node, group_name: String, base_volume_db: float = 0.0) -> void:
	if not is_instance_valid(player):
		return

	if group_name == GROUP_MUSIC:
		_configure_music_player_for_pause(player)
	elif group_name == GROUP_SFX:
		_configure_sfx_player_for_web(player)
	if not player.is_in_group(group_name):
		player.add_to_group(group_name)
	player.set_meta(AUDIO_BASE_VOLUME_META, base_volume_db)
	_apply_audio_player_volume(player, music_volume_db if group_name == GROUP_MUSIC else sfx_volume_db)

func keep_music_playing_during_pause() -> void:
	_resume_music_players_during_pause()

func apply_audio_volumes() -> void:
	_apply_group_volume(GROUP_MUSIC, music_volume_db)
	_apply_group_volume(GROUP_SFX, sfx_volume_db)

func make_looping_audio_stream(stream: AudioStream) -> AudioStream:
	if stream == null:
		return null

	var cache_key = stream.resource_path if stream.resource_path != "" else str(stream.get_instance_id())
	if looping_audio_stream_cache.has(cache_key):
		return looping_audio_stream_cache[cache_key]

	var looping_stream = stream.duplicate() as AudioStream
	if looping_stream is AudioStreamMP3:
		(looping_stream as AudioStreamMP3).loop = true
	elif looping_stream is AudioStreamOggVorbis:
		(looping_stream as AudioStreamOggVorbis).loop = true
	elif looping_stream is AudioStreamWAV:
		(looping_stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	looping_audio_stream_cache[cache_key] = looping_stream
	return looping_stream

func try_acquire_limited_sfx_voice(voice_key: String, max_voices: int) -> bool:
	var effective_max_voices = get_limited_sfx_voice_limit(voice_key, max_voices)
	if effective_max_voices <= 0:
		return false

	var active_count = int(limited_sfx_voice_counts.get(voice_key, 0))
	if active_count >= effective_max_voices:
		return false

	limited_sfx_voice_counts[voice_key] = active_count + 1
	return true

func release_limited_sfx_voice(voice_key: String) -> void:
	var active_count = int(limited_sfx_voice_counts.get(voice_key, 0))
	if active_count <= 1:
		limited_sfx_voice_counts.erase(voice_key)
		return

	limited_sfx_voice_counts[voice_key] = active_count - 1

func get_limited_sfx_voice_limit(voice_key: String, default_limit: int) -> int:
	if not is_web_build():
		return default_limit

	return min(default_limit, int(WEB_SFX_VOICE_LIMITS.get(voice_key, default_limit)))

func get_sfx_polyphony_limit(default_limit: int) -> int:
	if not is_web_build():
		return default_limit

	return min(default_limit, WEB_SFX_MAX_POLYPHONY)

func get_web_particle_amount(default_amount: int) -> int:
	return get_scaled_particle_amount(default_amount)

func should_skip_web_hit_particles() -> bool:
	return is_web_build()

func is_web_build() -> bool:
	return OS.has_feature("web")

func _request_web_persistent_storage() -> void:
	if not is_web_build():
		return
	JavaScriptBridge.eval(
		"if (navigator.storage && navigator.storage.persist) { navigator.storage.persist(); }",
		true
	)

func _configure_sfx_player_for_web(audio_player: Node) -> void:
	if not is_web_build() or not is_instance_valid(audio_player):
		return
	if not (audio_player is AudioStreamPlayer or audio_player is AudioStreamPlayer2D or audio_player is AudioStreamPlayer3D):
		return

	var current_polyphony = int(audio_player.get("max_polyphony"))
	audio_player.set("max_polyphony", get_sfx_polyphony_limit(max(current_polyphony, 1)))

func _configure_volume_slider(slider: Range, value: float) -> void:
	if slider == null:
		return

	slider.set_block_signals(true)
	slider.min_value = AUDIO_SLIDER_MIN_VALUE
	slider.max_value = AUDIO_SLIDER_MAX_VALUE
	slider.step = 1.0
	slider.value = _clamp_audio_slider_value(value)
	slider.set_block_signals(false)

func _clamp_audio_slider_value(value: float) -> float:
	return clampf(value, AUDIO_SLIDER_MIN_VALUE, AUDIO_SLIDER_MAX_VALUE)

func _apply_group_volume(group_name: String, volume_db: float) -> void:
	var tree = get_tree()
	if tree == null:
		return

	for audio_player in tree.get_nodes_in_group(group_name):
		_apply_audio_player_volume(audio_player, volume_db)

func _apply_audio_player_volume(audio_player: Node, volume_db: float) -> void:
	if not is_instance_valid(audio_player):
		return
	if not (audio_player is AudioStreamPlayer or audio_player is AudioStreamPlayer2D or audio_player is AudioStreamPlayer3D):
		return

	if audio_player.is_in_group(GROUP_MUSIC):
		_configure_music_player_for_pause(audio_player)
	var base_volume = float(audio_player.get_meta(AUDIO_BASE_VOLUME_META, 0.0))
	audio_player.set("volume_db", clampf(volume_db + base_volume, AUDIO_MUTE_DB, AUDIO_MAX_DB))

func _resume_music_players_during_pause() -> void:
	var tree = get_tree()
	if tree == null:
		return

	for audio_player in tree.get_nodes_in_group(GROUP_MUSIC):
		_configure_music_player_for_pause(audio_player)

func _configure_music_player_for_pause(audio_player: Node) -> void:
	if not is_instance_valid(audio_player):
		return

	if audio_player.process_mode != Node.PROCESS_MODE_ALWAYS:
		audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
	if audio_player is AudioStreamPlayer:
		var stream_player = audio_player as AudioStreamPlayer
		if stream_player.stream_paused:
			stream_player.stream_paused = false
	elif audio_player is AudioStreamPlayer2D:
		var stream_player_2d = audio_player as AudioStreamPlayer2D
		if stream_player_2d.stream_paused:
			stream_player_2d.stream_paused = false
	elif audio_player is AudioStreamPlayer3D:
		var stream_player_3d = audio_player as AudioStreamPlayer3D
		if stream_player_3d.stream_paused:
			stream_player_3d.stream_paused = false

## Starts a new ranked run timer and marks the run as unsaved.
func start_run_timer() -> void:
	run_start_msec = Time.get_ticks_msec()
	current_run_saved = false
	endless_run_summary = {}

## Saves the active run once, using the current pecado progress and elapsed time.
func finish_current_run(outcome: String = "") -> bool:
	if current_run_saved:
		return true

	var elapsed_seconds = 0.0
	if run_start_msec >= 0:
		elapsed_seconds = float(Time.get_ticks_msec() - run_start_msec) / 1000.0
	else:
		push_warning("Ranking run finished without an active timer. Saving with 00:00 elapsed time.")

	if not save_run(clampi(pecado - 1, 0, 7), elapsed_seconds, outcome):
		return false

	current_run_saved = true
	run_start_msec = -1
	return true

## Stores one completed run in the local ranking file.
func save_run(pecados_derrotados: int, tempo_segundos: float, outcome: String = "") -> bool:
	var ranking_data = _load_ranking_data()
	var runs: Array = ranking_data.get("runs", [])
	if is_endless_mode() and endless_run_summary.has("elapsed_seconds"):
		tempo_segundos = float(endless_run_summary["elapsed_seconds"])

	var run_data = {
		"mode": selected_game_mode,
		"pecados_derrotados": clampi(pecados_derrotados, 0, 7),
		"pecados_texto": format_pecados_derrotados(pecados_derrotados),
		"tempo_segundos": max(tempo_segundos, 0.0),
		"tempo_formatado": format_run_time(tempo_segundos),
		"data": Time.get_datetime_string_from_system(false, true),
		"outcome": outcome,
	}
	if is_endless_mode():
		for key in endless_run_summary.keys():
			run_data[key] = endless_run_summary[key]

	runs.append(run_data)
	ranking_data["runs"] = runs
	ranking_data["executable_signature"] = _get_executable_signature()
	return _save_ranking_data(ranking_data)

## Returns ranking entries sorted by defeated sins, then by fastest time.
func get_ranked_runs(mode: String = GAME_MODE_STORY) -> Array:
	var runs: Array = _load_ranking_data().get("runs", [])
	var ranked_runs: Array = []
	for run in runs:
		var run_mode = str(run.get("mode", GAME_MODE_STORY))
		if run_mode == mode:
			ranked_runs.append(run.duplicate(true))
	if mode == GAME_MODE_ENDLESS:
		ranked_runs.sort_custom(func(a, b): return _is_endless_run_better(a, b))
	else:
		ranked_runs.sort_custom(func(a, b): return _is_run_better(a, b))
	return ranked_runs

## Formats the defeated sin count for ranking UI.
func format_pecados_derrotados(amount: int) -> String:
	return I18n.defeated_sins(amount)

## Formats elapsed run seconds as MM:SS for ranking UI.
func format_run_time(seconds: float) -> String:
	var total_seconds = int(round(max(seconds, 0.0)))
	var minutes = int(total_seconds / 60)
	var remaining_seconds = total_seconds % 60
	return "%02d:%02d" % [minutes, remaining_seconds]

func _is_run_better(a: Dictionary, b: Dictionary) -> bool:
	var a_pecados = int(a.get("pecados_derrotados", 0))
	var b_pecados = int(b.get("pecados_derrotados", 0))
	if a_pecados != b_pecados:
		return a_pecados > b_pecados

	return float(a.get("tempo_segundos", 0.0)) < float(b.get("tempo_segundos", 0.0))

func _is_endless_run_better(a: Dictionary, b: Dictionary) -> bool:
	var a_score = float(a.get("score", 0.0))
	var b_score = float(b.get("score", 0.0))
	if not is_equal_approx(a_score, b_score):
		return a_score > b_score
	var a_bosses = int(a.get("bosses_defeated", 0))
	var b_bosses = int(b.get("bosses_defeated", 0))
	if a_bosses != b_bosses:
		return a_bosses > b_bosses
	return float(a.get("tempo_segundos", 0.0)) > float(b.get("tempo_segundos", 0.0))

func _load_ranking_data() -> Dictionary:
	var ranking_data = {
		"executable_signature": _get_executable_signature(),
		"runs": []
	}

	if not FileAccess.file_exists(RANKING_PATH):
		return ranking_data

	var file = FileAccess.open(RANKING_PATH, FileAccess.READ)
	if file == null:
		return ranking_data

	var parsed_data = JSON.parse_string(file.get_as_text())
	if parsed_data is Dictionary:
		ranking_data = parsed_data
	elif parsed_data is Array:
		ranking_data["runs"] = parsed_data

	if not ranking_data.has("runs") or not (ranking_data["runs"] is Array):
		ranking_data["runs"] = []

	return ranking_data

func _save_ranking_data(ranking_data: Dictionary) -> bool:
	_ensure_user_data_dir_exists()
	var file = FileAccess.open(RANKING_PATH, FileAccess.WRITE)
	if file == null:
		var open_error = FileAccess.get_open_error()
		push_error("Failed to open ranking file for writing at %s: %s" % [ProjectSettings.globalize_path(RANKING_PATH), error_string(open_error)])
		return false

	file.store_string(JSON.stringify(ranking_data, "\t"))
	file.flush()
	return true

func _ensure_user_data_dir_exists() -> void:
	var user_data_dir = OS.get_user_data_dir()
	if user_data_dir == "":
		return

	var result = DirAccess.make_dir_recursive_absolute(user_data_dir)
	if result != OK:
		push_warning("Could not ensure user data directory exists at %s: %s" % [user_data_dir, error_string(result)])

func _reset_ranking_if_executable_changed() -> void:
	if not FileAccess.file_exists(RANKING_PATH):
		return

	var ranking_data = _load_ranking_data()
	var current_signature = _get_executable_signature()
	var stored_signature = str(ranking_data.get("executable_signature", ""))

	if stored_signature == "":
		ranking_data["executable_signature"] = current_signature
		_save_ranking_data(ranking_data)
		return

	if stored_signature != current_signature:
		_delete_ranking_file()

func _delete_ranking_file() -> void:
	var user_dir = DirAccess.open("user://")
	if user_dir != null:
		user_dir.remove(RANKING_FILE_NAME)

func _get_executable_signature() -> String:
	var executable_path = OS.get_executable_path()
	if executable_path == "":
		return "unknown-executable"

	if not FileAccess.file_exists(executable_path):
		return executable_path

	var executable_hash = FileAccess.get_md5(executable_path)
	if executable_hash != "":
		return "%s|%s" % [executable_path, executable_hash]

	var executable_size = 0
	var executable_file = FileAccess.open(executable_path, FileAccess.READ)
	if executable_file != null:
		executable_size = executable_file.get_length()

	return "%s|%d|%d" % [
		executable_path,
		FileAccess.get_modified_time(executable_path),
		executable_size
	]
