class_name DialogueBox
extends CanvasLayer
## A caixa de diálogo (spec NAR-dialogo, regra 6): no alto da tela, pausa o jogo enquanto aberta.
## Espaço, Enter ou E avançam; 1–3 escolhem a opção. Visual provisório.

signal finished

const SPEAKER_KEYS := {"serpente": "DIALOGO_SERPENTE", "mago": "DIALOGO_MAGO"}
## Topo da caixa: abaixo do HUD com o texto Normal; no alto da tela com texto maior, cobrindo o HUD
## enquanto está aberta (o jogo está pausado), para continuar acima da metade da tela (UI-menus, regra 6).
const TOP := 72.0
const TOP_LARGE_TEXT := 8.0
const HEIGHT := 76.0

var speaker_label := Label.new()
var text_label := Label.new()
var options_label := Label.new()

var _run: DialogueRun
var _root := PanelContainer.new()
var _hint := Label.new()


func _init() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false


## Tamanho do texto das opções (UI-menus, regras 5 e 6); a caixa cresce para baixo com o texto.
func set_text_delta(delta: int) -> void:
	FontScale.apply(self, delta)
	_root.offset_top = TOP if delta == 0 else TOP_LARGE_TEXT
	_root.offset_bottom = _root.offset_top + HEIGHT


func is_open() -> bool:
	return _root.visible


## Abre a cena e pausa o jogo.
func open(run: DialogueRun) -> void:
	if run == null or run.is_finished():
		return
	_run = run
	_root.visible = true
	get_tree().paused = true
	_show()


## Onde a caixa fica na tela.
func panel_rect() -> Rect2:
	return _root.get_global_rect()


func advance() -> void:
	if not is_open():
		return
	_run.advance()
	_show()


func choose(number: int) -> void:
	if not is_open():
		return
	_run.choose(number)
	_show()


func _show() -> void:
	if _run.is_finished():
		_close()
		return
	var line := _run.current()
	speaker_label.text = tr(SPEAKER_KEYS.get(line["quem"], "DIALOGO_SERPENTE"))
	text_label.text = line["texto"]
	var options := PackedStringArray()
	for i in line["opcoes"].size():
		options.append("%d. %s" % [i + 1, line["opcoes"][i]])
	options_label.text = "\n".join(options)
	options_label.visible = not options.is_empty()
	_hint.visible = options.is_empty()


func _close() -> void:
	_root.visible = false
	_run = null
	get_tree().paused = false
	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open() or not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"talk"):
		advance()
	else:
		for number in range(1, 4):
			if event.is_action_pressed(StringName("slot_%d" % number)):
				choose(number)
	# Nada passa para o jogo nem para o grimório com a caixa aberta.
	get_viewport().set_input_as_handled()


func _build() -> void:
	add_child(_root)
	# No alto, abaixo do HUD: embaixo, a caixa cobria o mago e a serpente, que ficam no chão,
	# perto do rodapé da tela (regressão, captura de tela).
	_root.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_root.offset_left = 40
	_root.offset_right = -40
	_root.offset_top = TOP
	_root.offset_bottom = TOP + HEIGHT
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1d1a26f2")
	style.border_color = Color("6fcf5a")
	style.set_border_width_all(2)
	style.set_content_margin_all(6)
	_root.add_theme_stylebox_override(&"panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 2)
	_root.add_child(column)
	speaker_label.add_theme_font_size_override(&"font_size", 9)
	speaker_label.add_theme_color_override(&"font_color", Color("6fcf5a"))
	column.add_child(speaker_label)
	text_label.add_theme_font_size_override(&"font_size", 9)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(text_label)
	options_label.add_theme_font_size_override(&"font_size", 9)
	options_label.add_theme_color_override(&"font_color", Color("ffd27a"))
	column.add_child(options_label)
	_hint.text = "DIALOGO_CONTINUAR"
	_hint.add_theme_font_size_override(&"font_size", 7)
	_hint.modulate = Color(1, 1, 1, 0.6)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(_hint)
