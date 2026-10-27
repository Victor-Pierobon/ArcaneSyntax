class_name RuneLock
extends Node2D
## Cadeado de runas: abre quando recebe, por `inscrever`, a soma das runas da sala
## (spec PUZ-validacao, regra 10). Não é alvo.

signal opened

## Até onde a inscrição alcança, em tiles.
const REACH_TILES := 3.0
const COLOR_CLOSED := Color("8a6fd8")
const COLOR_OPEN := Color("9ff6ff")
const COLOR_WRONG := Color("ff6b6b")

var is_open := false
var last_value: Variant = null

var _body := ColorRect.new()


static func make() -> RuneLock:
	return RuneLock.new()


func _ready() -> void:
	_body.size = Vector2(12, 16)
	_body.position = Vector2(-6, -16)
	_body.color = COLOR_OPEN if is_open else COLOR_CLOSED
	add_child(_body)
	var label := Label.new()
	label.text = "Σ"
	Lighting.keep_readable(label)
	label.add_theme_font_size_override(&"font_size", 9)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(12, 16)
	label.position = Vector2(-6, -17)
	add_child(label)


## Recebe um valor; abre se for o esperado. Errado: pisca e continua fechado.
func inscribe(value: float, expected: int) -> bool:
	last_value = value
	if is_open:
		return true
	if is_equal_approx(value, float(expected)):
		open()
		return true
	_body.color = COLOR_WRONG
	var tween := create_tween()
	tween.tween_property(_body, "color", COLOR_CLOSED, 0.4)
	return false


func open() -> void:
	if is_open:
		return
	is_open = true
	_body.color = COLOR_OPEN
	opened.emit()
