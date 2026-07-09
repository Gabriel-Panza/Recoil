extends Control

const GAME_SCENE_PATH: String = "res://Cenas/General/gameScene.tscn"
const CUTSCENE_FONT: FontFile = preload("res://Fonts/cg-pixel-4x5.otf")
const FRAME_TEXTURES: Array[Texture2D] = [
	preload("res://Sprites/Cutscene/Frame1.png"),
	preload("res://Sprites/Cutscene/Frame2.png"),
	preload("res://Sprites/Cutscene/Frame3.png"),
	preload("res://Sprites/Cutscene/Frame4.png"),
	preload("res://Sprites/Cutscene/Frame5.png")
]

const TYPE_SPEECH: String = "speech"
const TYPE_THOUGHT: String = "thought"
const TYPE_DEMON: String = "demon"
const KEEP_FRAME: int = -999
const HIDE_FRAME: int = -1

var frame_rect: TextureRect
var dialogue_panel: Panel
var dialogue_label: RichTextLabel
var advance_label: Label
var current_steps: Array = []
var current_step_index: int = -1
var is_transitioning: bool = false

func _ready() -> void:
	_build_ui()
	_load_steps_for_current_language()
	_show_next_step()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			_show_next_step()
			return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		get_viewport().set_input_as_handled()
		_show_next_step()
		return

	if event is InputEventKey:
		var key_event = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			get_viewport().set_input_as_handled()
			_show_next_step()

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var background = ColorRect.new()
	background.name = "Background"
	background.color = Color.BLACK
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	frame_rect = TextureRect.new()
	frame_rect.name = "Frame"
	frame_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	frame_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_rect.visible = false
	add_child(frame_rect)

	dialogue_panel = Panel.new()
	dialogue_panel.name = "DialoguePanel"
	dialogue_panel.anchor_left = 0.055
	dialogue_panel.anchor_top = 0.66
	dialogue_panel.anchor_right = 0.945
	dialogue_panel.anchor_bottom = 0.92
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_panel.add_theme_stylebox_override("panel", _make_dialogue_style())
	add_child(dialogue_panel)

	dialogue_label = RichTextLabel.new()
	dialogue_label.name = "DialogueLabel"
	dialogue_label.bbcode_enabled = true
	dialogue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_label.scroll_active = false
	dialogue_label.fit_content = false
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialogue_label.offset_left = 28.0
	dialogue_label.offset_top = 22.0
	dialogue_label.offset_right = -28.0
	dialogue_label.offset_bottom = -26.0
	dialogue_label.add_theme_font_override("normal_font", CUTSCENE_FONT)
	dialogue_label.add_theme_font_size_override("normal_font_size", 17)
	dialogue_label.add_theme_constant_override("line_separation", 4)
	dialogue_panel.add_child(dialogue_label)

	advance_label = Label.new()
	advance_label.name = "AdvanceLabel"
	advance_label.anchor_left = 0.60
	advance_label.anchor_top = 0.925
	advance_label.anchor_right = 0.945
	advance_label.anchor_bottom = 0.98
	advance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	advance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	advance_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	advance_label.add_theme_font_override("font", CUTSCENE_FONT)
	advance_label.add_theme_font_size_override("font_size", 18)
	advance_label.add_theme_color_override("font_color", Color(0.72, 0.66, 0.8, 0.9))
	advance_label.add_theme_color_override("font_outline_color", Color.BLACK)
	advance_label.add_theme_constant_override("outline_size", 3)
	add_child(advance_label)

func _make_dialogue_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.01, 0.014, 0.86)
	style.border_color = Color(0.74, 0.16, 0.09, 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(4)
	return style

func _load_steps_for_current_language() -> void:
	current_steps = _get_pt_steps() if I18n.get_language() == I18n.LANG_PT_BR else _get_en_steps()
	advance_label.text = "ESPACO / CLIQUE" if I18n.get_language() == I18n.LANG_PT_BR else "SPACE / CLICK"

func _show_next_step() -> void:
	if is_transitioning:
		return

	current_step_index += 1
	if current_step_index >= current_steps.size():
		get_tree().change_scene_to_file(GAME_SCENE_PATH)
		return

	_apply_step(current_steps[current_step_index])

func _apply_step(step: Dictionary) -> void:
	var frame_index = int(step.get("frame", KEEP_FRAME))
	if frame_index == HIDE_FRAME:
		frame_rect.texture = null
		frame_rect.visible = false
	elif frame_index >= 0 and frame_index < FRAME_TEXTURES.size():
		frame_rect.texture = FRAME_TEXTURES[frame_index]
		frame_rect.visible = true

	dialogue_label.clear()
	dialogue_label.append_text(_format_cutscene_text(str(step.get("type", TYPE_THOUGHT)), str(step.get("text", ""))))

func _format_cutscene_text(line_type: String, raw_text: String) -> String:
	match line_type:
		TYPE_SPEECH:
			return "[center][color=#f4f1e8][outline_size=4][outline_color=#000000]\"%s\"[/outline_color][/outline_size][/color][/center]" % _escape_bbcode(raw_text)
		TYPE_DEMON:
			return "[center][color=#ff3b2d][outline_size=5][outline_color=#140000]\"%s\"[/outline_color][/outline_size][/color][/center]" % _escape_bbcode(raw_text.to_upper())
		_:
			return "[center][color=#9fb5cc][outline_size=4][outline_color=#02040a]%s[/outline_color][/outline_size][/color][/center]" % _escape_bbcode(raw_text)

func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]").replace("]", "[rb]")

func _step(text: String, line_type: String = TYPE_THOUGHT, frame: int = KEEP_FRAME) -> Dictionary:
	return {
		"text": text,
		"type": line_type,
		"frame": frame
	}

func _get_pt_steps() -> Array:
	return [
		_step("...", TYPE_SPEECH),
		_step("Onde eu estou?", TYPE_SPEECH),
		_step("E tao quente aqui. Nao reconheco esse lugar, mas e bem, bem quente. De todos os sons que ouco a distancia, reconheco apenas os de liquido borbulhando e algumas vozes, apesar de nao fazer ideia do que esta sendo dito."),
		_step("A unica coisa que sei e que..."),
		_step("..."),
		_step("Eu mereco isso.", TYPE_SPEECH),
		_step("..."),
		_step("Tudo que vejo a minha frente e a escuridao, mas sinto uma luz vindo de tras, parcialmente bloqueada por aquilo em que encontro-me encostado. Minhas costas dizem que e algum tipo de rocha."),
		_step("Tento me virar um pouco para ver de onde vem essa luz."),
		_step("Isso e...", TYPE_SPEECH, 0),
		_step("E lava, algo que voce so esperaria encontrar se estivesse dentro de um vulcao. Espera, eu estou dentro de um vulcao?"),
		_step("Uma mistura de susto e confusao me levam a minha posicao inicial, virado para a escuridao novamente."),
		_step("Deve ser algum tipo de sonho. So pode ser.", TYPE_THOUGHT, HIDE_FRAME),
		_step("Esta muito escuro para tentar ver qualquer coisa a distancia. Nao sinto meu celular em meu bolso, entao a melhor aposta e me levantar e procurar outra fonte de luz."),
		_step("..."),
		_step("..."),
		_step("???"),
		_step("O que diabos aconteceu com as minhas pernas?"),
		_step("Faco o esforco para tentar move-las, mas e como se elas nao me obedecessem."),
		_step("Meus bracos tambem nao se movem. Meu corpo inteiro nao se move, somente a cabeca."),
		_step("O sonho bom."),
		_step("MORTAL.", TYPE_DEMON),
		_step("Ouco uma voz de repente. Parece bem proxima. Parece na verdade como se estivesse saindo da minha propria cabeca. E parece falar algo que consigo compreender."),
		_step("NAO SE PREOCUPE. NAO ESTOU AQUI PARA TE MACHUCAR.", TYPE_DEMON, 1),
		_step("Abaixo minha cabeca e vejo agora uma sombra, mais escura que a escuridao que a cerca. A silhueta e familiar. Sou eu?"),
		_step("DIGA-ME SEU NOME.", TYPE_DEMON),
		_step("Meu nome e... Meu nome e... Meu nome...", TYPE_SPEECH),
		_step("Mas o que?"),
		_step("Como nao consigo me lembrar do meu proprio nome?"),
		_step("VOCE NAO SE LEMBRA, NAO E? NAO E? RELAXA, ERA ISSO MESMO QUE EU ESPERAVA. AFINAL, VOCE TAMBEM NAO SE LEMBRA DO QUE VOCE FEZ, NAO E MESMO? NAO E MESMO?", TYPE_DEMON),
		_step("...do que eu fiz?", TYPE_SPEECH),
		_step("Aquele sentimento de que estou aqui porque mereco retorna."),
		_step("HEE HEE HEE HEE! INTERESSANTE.", TYPE_DEMON),
		_step("VOCE QUER SAIR DAQUI, NAO QUER? NAO QUER?", TYPE_DEMON),
		_step("QUE TAL EU TE DAR UMA MAOZINHA, ENTAO? AFINAL, MEUS OBJETIVOS CONVERGEM COM OS SEUS.", TYPE_DEMON),
		_step("Nao custa nada tentar... Tomara que isso faca o sonho acabar mais rapido."),
		_step("MORTAL.", TYPE_DEMON),
		_step("VOCE NAO CONSEGUE MOVER SEU CORPO, CERTO? CERTO? DEIXE-ME TORNAR O SEU BRACO, ENTAO. O RESTO VOCE APRENDE NA HORA.", TYPE_DEMON),
		_step("TEMOS UM ACORDO?", TYPE_DEMON),
		_step("Faz o que voce quiser.", TYPE_SPEECH),
		_step("HEE HEE HEE HEE! PERFEITO.", TYPE_DEMON),
		_step("VOCE E EU NOS TORNAREMOS UM AGORA, MAS SERA QUE EM ALGUM MOMENTO FOMOS REALMENTE DISTINTOS? SERA?", TYPE_DEMON, 2),
		_step("AFINAL, FOI ISSO QUE VOCE ESCOLHEU SER EM VIDA, MORTAL.", TYPE_DEMON),
		_step("UM DEMONIO.", TYPE_DEMON),
		_step("AAAAAAAH!", TYPE_SPEECH, 3),
		_step("...", TYPE_SPEECH, 4)
	]

func _get_en_steps() -> Array:
	return [
		_step("...", TYPE_SPEECH),
		_step("Where am I?", TYPE_SPEECH),
		_step("It's so hot in here. I don't know what this place is, but it's really, really hot. Out of every sound I hear from afar, I can't recognize any but the sound of bubbling liquid and some voices, albeit I have no idea of what's being said."),
		_step("The only thing I know is..."),
		_step("..."),
		_step("This is what I deserve.", TYPE_SPEECH),
		_step("..."),
		_step("I can only see darkness in front of me, but I feel some light coming from the back, partially blocked by whatever I'm resting my back on. That same back tells me it's some kind of rock."),
		_step("I try to turn around to see where that light is coming from."),
		_step("That's...", TYPE_SPEECH, 0),
		_step("It's lava, something you'd only expect to find if you were inside a volcano. There's no way I'm inside one, right?"),
		_step("A mix of scare and confusion get me back to my initial position, facing the darkness once again."),
		_step("This must be some kind of dream. It must be.", TYPE_THOUGHT, HIDE_FRAME),
		_step("It's too dark to attempt to see anything too far. My phone doesn't seem to be in my pocket, so my best bet is to get up and look for another light source."),
		_step("..."),
		_step("..."),
		_step("???"),
		_step("What the hell happened to my legs?"),
		_step("I make an effort to move them, but it's like they're not obeying me."),
		_step("My arms also don't move. My whole body doesn't move, only the head."),
		_step("What a fun dream."),
		_step("MORTAL.", TYPE_DEMON),
		_step("I suddenly hear a voice. It seems really close. It seems, in fact, like it's coming out of my own head. And it seems to be saying something I can comprehend."),
		_step("DO NOT WORRY. I AM NOT HERE TO HURT YOU.", TYPE_DEMON, 1),
		_step("I lean my head down and see a shadow in my vicinity, even darker than the darkness that surrounds it. The profile is familiar. Is that me?"),
		_step("DO TELL ME YOUR NAME.", TYPE_DEMON),
		_step("My name is... My name's... My name...", TYPE_SPEECH),
		_step("What?"),
		_step("How can I not remember my own name?"),
		_step("YOU DO NOT REMEMBER IT, DO YOU? DO YOU? RELAX. THAT IS EXACTLY WHAT I EXPECTED. AFTER ALL, YOU ALSO DO NOT REMEMBER WHAT YOU HAVE DONE, DO YOU? DO YOU?", TYPE_DEMON),
		_step("...what I've done?", TYPE_SPEECH),
		_step("The feeling that I'm here because I deserve to be returns."),
		_step("HEE HEE HEE HEE! INTERESTING.", TYPE_DEMON),
		_step("YOU DO WANT TO LEAVE THIS PLACE, DO YOU NOT? DO YOU NOT?", TYPE_DEMON),
		_step("HOW ABOUT I LEND YOU A HAND, THEN? AFTER ALL, MY GOALS DO CONVERGE WITH YOURS.", TYPE_DEMON),
		_step("Doesn't hurt to try. I hope this makes this dream end faster."),
		_step("MORTAL.", TYPE_DEMON),
		_step("YOU CANNOT MOVE YOUR BODY, RIGHT? RIGHT? DO LET ME BECOME YOUR ARM, THEN. YOU WILL LEARN THE REST WHEN WE GET TO IT.", TYPE_DEMON),
		_step("DO WE HAVE A DEAL?", TYPE_DEMON),
		_step("Do whatever you want.", TYPE_SPEECH),
		_step("HEE HEE HEE HEE! PERFECT.", TYPE_DEMON),
		_step("YOU AND I WILL BECOME ONE, BUT HAVE WE EVER BEEN SEPARATE TO BEGIN WITH? HAVE WE?", TYPE_DEMON, 2),
		_step("AFTER ALL, THAT IS WHAT YOU CHOSE TO BE IN LIFE, MORTAL.", TYPE_DEMON),
		_step("A DEMON.", TYPE_DEMON),
		_step("AAAAAAAH!", TYPE_SPEECH, 3),
		_step("...", TYPE_SPEECH, 4)
	]
