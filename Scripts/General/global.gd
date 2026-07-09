extends Node

signal pecado_changed(new_pecado)

const RANKING_FILE_NAME: String = "ranking_runs.json"
const RANKING_PATH: String = "user://ranking_runs.json"
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

const STARTING_ARM_DATA = {
	"fast": {
		"name": "Fast Arm",
		"description": "Weak shots, high fire rate, and short recoil for tighter control.",
		"attack_damage": 30.0,
		"base_fire_rate": 0.52,
		"min_fire_rate": 0.3,
		"base_recoil_force": 380.0,
		"friction": 900.0,
		"attack_speed_upgrade_multiplier": 0.3,
		"unstable_projectiles": false
	},
	"heavy": {
		"name": "Heavy Arm",
		"description": "Slow shots with high damage and strong recoil for big repositioning plays.",
		"attack_damage": 70.0,
		"base_fire_rate": 2.0,
		"min_fire_rate": 1.65,
		"base_recoil_force": 750.0,
		"friction": 600.0,
		"attack_speed_upgrade_multiplier": 0.7,
		"unstable_projectiles": false
	},
	"unstable": {
		"name": "Unstable Arm",
		"description": "Projectiles pierce one target and ricochet once, but come back dangerous.",
		"attack_damage": 40.0,
		"base_fire_rate": 1.35,
		"min_fire_rate": 0.9,
		"base_recoil_force": 577.5,
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
	{ "id": "option_2", "text": "Health (+5%)", "description": "Increases your maximum health and heals you slightly based on your current health.", "rarity": "passive_common" },
	{ "id": "option_3", "text": "Attack (+12%)", "description": "Increases the damage dealt by your bullets and damage-based effects.", "rarity": "passive_common" },
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
	{ "id": "Splintered_Chamber", "text": "Splintered Chamber", "description": "Every 8th shot fires 2 side fragments, each dealing 35% of that shot's damage. Overheat damage applies to these fragments. You can equip up to two rare passives.", "rarity": "passive_rare" }
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
		"description": "Every 8th shot fires 2 side fragments for 35% of that shot's damage."
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

func _ready() -> void:
	_reset_ranking_if_executable_changed()

## Starts a new ranked run timer and marks the run as unsaved.
func start_run_timer() -> void:
	run_start_msec = Time.get_ticks_msec()
	current_run_saved = false

## Saves the active run once, using the current pecado progress and elapsed time.
func finish_current_run() -> bool:
	if current_run_saved:
		return true

	var elapsed_seconds = 0.0
	if run_start_msec >= 0:
		elapsed_seconds = float(Time.get_ticks_msec() - run_start_msec) / 1000.0
	else:
		push_warning("Ranking run finished without an active timer. Saving with 00:00 elapsed time.")

	if not save_run(clampi(pecado - 1, 0, 7), elapsed_seconds):
		return false

	current_run_saved = true
	run_start_msec = -1
	return true

## Stores one completed run in the local ranking file.
func save_run(pecados_derrotados: int, tempo_segundos: float) -> bool:
	var ranking_data = _load_ranking_data()
	var runs: Array = ranking_data.get("runs", [])

	var run_data = {
		"pecados_derrotados": clampi(pecados_derrotados, 0, 7),
		"pecados_texto": format_pecados_derrotados(pecados_derrotados),
		"tempo_segundos": max(tempo_segundos, 0.0),
		"tempo_formatado": format_run_time(tempo_segundos),
		"data": Time.get_datetime_string_from_system(false, true)
	}

	runs.append(run_data)
	ranking_data["runs"] = runs
	ranking_data["executable_signature"] = _get_executable_signature()
	return _save_ranking_data(ranking_data)

## Returns ranking entries sorted by defeated sins, then by fastest time.
func get_ranked_runs() -> Array:
	var runs: Array = _load_ranking_data().get("runs", [])
	var ranked_runs = runs.duplicate(true)
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
