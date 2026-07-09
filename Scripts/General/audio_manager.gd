extends Node

@onready var music_player = $MusicPlayer

var musica_menu = preload("res://Soundtrack/Recoil Menu OST.mp3")
var musica_jogo = preload("res://Soundtrack/Recoil Base theme Song.mp3")

func _ready() -> void:
	Global.register_audio_player(music_player, Global.GROUP_MUSIC, 0.0)

func tocar_musica_menu():
	if music_player.stream == musica_menu and music_player.playing:
		return
		
	music_player.stream = musica_menu
	music_player.play()

func tocar_musica_jogo():
	if music_player.stream == musica_jogo and music_player.playing:
		return
		
	music_player.stream = musica_jogo
	music_player.play()
	
func parar_musica():
	music_player.stop()
