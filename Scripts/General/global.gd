extends Node

signal pecado_changed(new_pecado)

const RANKING_FILE_NAME: String = "ranking_runs.json"
const RANKING_PATH: String = "user://ranking_runs.json"

var pecado = 1:
	set(value):
		if value != pecado:
			pecado = value
			pecado_changed.emit(pecado)

var run_start_msec: int = -1
var current_run_saved: bool = false

var somSFX = 0
var somVolume = 0

func _ready() -> void:
	_reset_ranking_if_executable_changed()

func start_run_timer() -> void:
	run_start_msec = Time.get_ticks_msec()
	current_run_saved = false

func finish_current_run() -> void:
	if current_run_saved or run_start_msec < 0:
		return

	var elapsed_seconds = float(Time.get_ticks_msec() - run_start_msec) / 1000.0
	save_run(clampi(pecado - 1, 0, 7), elapsed_seconds)
	current_run_saved = true

func save_run(pecados_derrotados: int, tempo_segundos: float) -> void:
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
	_save_ranking_data(ranking_data)

func get_ranked_runs() -> Array:
	var runs: Array = _load_ranking_data().get("runs", [])
	var ranked_runs = runs.duplicate(true)
	ranked_runs.sort_custom(func(a, b): return _is_run_better(a, b))
	return ranked_runs

func format_pecados_derrotados(amount: int) -> String:
	var safe_amount = clampi(amount, 0, 7)
	if safe_amount == 1:
		return "1 pecado derrotado"
	return "%d pecados derrotados" % safe_amount

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

func _save_ranking_data(ranking_data: Dictionary) -> void:
	var file = FileAccess.open(RANKING_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_string(JSON.stringify(ranking_data, "\t"))

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
