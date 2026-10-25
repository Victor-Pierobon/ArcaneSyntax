extends Control
## Ferramenta de desenvolvimento: digitar um feitiço, executar no Python real e ver a resposta.
## Não faz parte do jogo; o grimório de verdade vem nas Sprints 4 e 5.

const EXAMPLE := """# Ctrl+Enter executa
print("mana antes:", mana)
while mana < mana_max:
    absorver_mana()
print("mana depois:", mana)

if alvo.elemento == "fogo":
    lancar(gelo, projetil, alvo)
"""

var _executor := PythonSpellExecutor.new()
var _editor := CodeEdit.new()
var _output := RichTextLabel.new()
var _mana := SpinBox.new()
var _target_element := OptionButton.new()


func _ready() -> void:
	add_child(_executor)
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var bar := HBoxContainer.new()
	root.add_child(bar)
	bar.add_child(_label("Mana inicial"))
	_mana.max_value = 20
	_mana.value = 2
	bar.add_child(_mana)
	bar.add_child(_label("Alvo"))
	for element in ["(nenhum)", "fogo", "gelo", "raio", "planta"]:
		_target_element.add_item(element)
	_target_element.select(1)
	bar.add_child(_target_element)
	var run_button := Button.new()
	run_button.text = "Executar"
	run_button.pressed.connect(_run)
	bar.add_child(run_button)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(split)
	_editor.text = EXAMPLE
	_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_editor.gutters_draw_line_numbers = true
	_editor.add_theme_font_size_override(&"font_size", 9)
	split.add_child(_editor)
	_output.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_output.bbcode_enabled = true
	_output.add_theme_font_size_override(&"normal_font_size", 9)
	split.add_child(_output)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and key.ctrl_pressed and key.keycode == KEY_ENTER:
		_run()


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


func _run() -> void:
	var target: Variant = null
	if _target_element.selected > 0:
		target = {"id": "alvo_1", "elemento": _target_element.get_item_text(_target_element.selected), "distancia": 3.0}
	var request := SpellRequest.make(_editor.text, {"vida": 10, "mana": int(_mana.value), "mana_max": 10}, target)
	_output.text = "executando…"
	var result: SpellResult = await _executor.execute(request)
	_show(result)


func _show(result: SpellResult) -> void:
	for line in _editor.get_line_count():
		_editor.set_line_background_color(line, Color(0, 0, 0, 0))
	var text := "[b]%s[/b]\n\n" % ("OK" if result.ok else "ERRO")
	if result.error:
		text += "[color=#ff7070]%s: %s (linha %s)[/color]\n\n" % [result.error.type, result.error.message, result.error.line]
		if result.error.line > 0:
			_editor.set_line_background_color(result.error.line - 1, Color(0.6, 0.1, 0.1, 0.5))
	text += "[b]Visões (print)[/b]\n"
	for output in result.outputs:
		text += "  linha %d: %s\n" % [output["linha"], output["texto"]]
	text += "\n[b]Ações[/b]\n"
	for action in result.actions:
		text += "  linha %d: %s\n" % [action["linha"], JSON.stringify(action)]
	text += "\n[b]Custo[/b]\n  %s de mana\n" % result.cost
	text += "\n[b]Mago no fim[/b]\n  %s\n" % JSON.stringify(result.mago)
	_output.text = text
