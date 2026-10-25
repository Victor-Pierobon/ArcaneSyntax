class_name StepView
extends CanvasLayer
## Painel do passo a passo: o código do feitiço com a linha da ação atual destacada
## (spec PUZ-passo-a-passo). Visual provisório.

const LINE_COLOR := Color(0.95, 0.8, 0.3, 0.35)
const HIDE_AFTER := 1.0

## Linhas destacadas desde o último `show_code`, para testes.
var highlighted_lines: Array[int] = []

var _panel := PanelContainer.new()
var _editor := CodeEdit.new()
var _speed_label := Label.new()
var _current_line := -1
var _hide_serial := 0


func _init() -> void:
	layer = 5
	# No alto, entre o HUD e o registro: embaixo ele cobria o mago e o puzzle (regressão PUZ-012).
	_panel.position = Vector2(100, 8)
	_panel.size = Vector2(226, 110)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("14121cdd")
	style.border_color = Color("8a6d3b")
	style.set_border_width_all(1)
	style.set_content_margin_all(4)
	_panel.add_theme_stylebox_override(&"panel", style)
	add_child(_panel)
	var column := VBoxContainer.new()
	_panel.add_child(column)
	_speed_label.add_theme_font_size_override(&"font_size", 7)
	column.add_child(_speed_label)
	_editor.editable = false
	_editor.custom_minimum_size = Vector2(218, 90)
	_editor.gutters_draw_line_numbers = true
	_editor.syntax_highlighter = PythonHighlighter.build()
	_editor.add_theme_font_size_override(&"font_size", 7)
	_editor.focus_mode = Control.FOCUS_NONE
	_editor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_editor)
	_panel.visible = false
	set_speed(1.0)


func panel_rect() -> Rect2:
	return _panel.get_global_rect()


func is_showing() -> bool:
	return _panel.visible


func code_text() -> String:
	return _editor.text


func speed_text() -> String:
	return _speed_label.text


func set_speed(speed: float) -> void:
	_speed_label.text = tr("PASSO_VELOCIDADE") % _speed_name(speed)


func show_code(code: String) -> void:
	_hide_serial += 1
	highlighted_lines.clear()
	_current_line = -1
	_editor.text = code
	_panel.visible = true


func highlight(line: int) -> void:
	if _current_line > 0 and _current_line <= _editor.get_line_count():
		_editor.set_line_background_color(_current_line - 1, Color(0, 0, 0, 0))
	_current_line = line
	highlighted_lines.append(line)
	if line > 0 and line <= _editor.get_line_count():
		_editor.set_line_background_color(line - 1, LINE_COLOR)
		_editor.set_caret_line(line - 1)


## Esconde o painel um pouco depois das ações terminarem.
func finish() -> void:
	_hide_serial += 1
	var serial := _hide_serial
	await get_tree().create_timer(HIDE_AFTER, false).timeout
	if serial == _hide_serial:
		_panel.visible = false


static func _speed_name(speed: float) -> String:
	return str(int(speed)) if is_equal_approx(speed, roundf(speed)) else str(speed)
