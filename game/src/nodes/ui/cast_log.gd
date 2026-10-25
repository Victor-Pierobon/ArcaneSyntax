class_name CastLog
extends CanvasLayer
## Registro de conjuração: as últimas linhas do que os feitiços fizeram (spec GRI-slots, regra 8).
## Até a Sprint 6, é aqui que o jogador vê as ações; depois vira apoio para depurar.

const MAX_LINES := 6

var _lines: PackedStringArray = []
var _label := Label.new()


func _init() -> void:
	_label.position = Vector2(332, 6)
	_label.size = Vector2(300, 120)
	_label.add_theme_font_size_override(&"font_size", 8)
	_label.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override(&"shadow_offset_x", 1)
	_label.add_theme_constant_override(&"shadow_offset_y", 1)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label)


func add_lines(lines: PackedStringArray) -> void:
	_lines.append_array(lines)
	if _lines.size() > MAX_LINES:
		_lines = _lines.slice(_lines.size() - MAX_LINES)
	_label.text = "\n".join(_lines)


func text() -> String:
	return _label.text
