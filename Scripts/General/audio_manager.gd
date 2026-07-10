extends Node

const MENU_MUSIC_PATH: String = "res://Music&SFX/Music/Recoil Menu OST.mp3"
const MENU_MUSIC_WEB_PATH: String = "res://Music&SFX/Music/Recoil Menu OST.ogg"
const GAME_MUSIC_PATH: String = "res://Music&SFX/Music/Recoil Base theme Song.mp3"
const GAME_MUSIC_WEB_PATH: String = "res://Music&SFX/Music/Recoil Base theme Song.ogg"
const MENU_MUSIC_BASE_VOLUME_DB: float = -5.0
const GAME_MUSIC_BASE_VOLUME_DB: float = -4.0
const WEB_MUSIC_WATCHDOG_INTERVAL: float = 0.35

@onready var music_player: AudioStreamPlayer = $MusicPlayer

var musica_menu: AudioStream
var musica_jogo: AudioStream
var current_music_key: String = ""
var music_watchdog_elapsed: float = 0.0
var last_playback_position: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	Global.register_audio_player(music_player, Global.GROUP_MUSIC, 0.0)

func _process(delta: float) -> void:
	if current_music_key == "":
		return

	if music_player.playing:
		last_playback_position = music_player.get_playback_position()

	music_watchdog_elapsed += delta
	if music_watchdog_elapsed < WEB_MUSIC_WATCHDOG_INTERVAL:
		return

	music_watchdog_elapsed = 0.0
	_keep_music_alive()

func tocar_musica_menu() -> void:
	_play_music("menu", _get_menu_music(), MENU_MUSIC_BASE_VOLUME_DB)

func tocar_musica_jogo() -> void:
	_play_music("game", _get_game_music(), GAME_MUSIC_BASE_VOLUME_DB)

func parar_musica() -> void:
	current_music_key = ""
	last_playback_position = 0.0
	music_player.stop()

func _get_menu_music() -> AudioStream:
	if Global.is_web_build():
		if musica_menu == null:
			musica_menu = load(MENU_MUSIC_WEB_PATH) as AudioStream
		return musica_menu

	if musica_menu == null:
		musica_menu = load(MENU_MUSIC_PATH) as AudioStream
	return musica_menu

func _get_game_music() -> AudioStream:
	if Global.is_web_build():
		if musica_jogo == null:
			musica_jogo = load(GAME_MUSIC_WEB_PATH) as AudioStream
		return musica_jogo

	if musica_jogo == null:
		musica_jogo = load(GAME_MUSIC_PATH) as AudioStream
	return musica_jogo

func _play_music(music_key: String, stream: AudioStream, base_volume_db: float) -> void:
	if stream == null:
		return

	var looping_stream = Global.make_looping_audio_stream(stream)
	Global.register_audio_player(music_player, Global.GROUP_MUSIC, base_volume_db)
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.stream_paused = false

	if current_music_key == music_key and music_player.stream == looping_stream and music_player.playing:
		return

	current_music_key = music_key
	last_playback_position = 0.0
	music_player.stream = looping_stream
	music_player.play()

func _keep_music_alive() -> void:
	_resume_browser_audio_context()
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	if music_player.stream_paused:
		music_player.stream_paused = false
	if not music_player.playing and music_player.stream != null:
		music_player.play(max(last_playback_position, 0.0))

func _resume_browser_audio_context() -> void:
	if not Global.is_web_build():
		return

	JavaScriptBridge.eval("if (window.recoilResumeAudio) { window.recoilResumeAudio(); }", true)
