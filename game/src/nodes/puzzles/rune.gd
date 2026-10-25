class_name Rune
extends Node2D
## Runa de puzzle: mostra um número que o feitiço lê com `ler_runa(n)` (spec PUZ-validacao, regra 9).
## Não é alvo: projéteis passam por ela.

const COLOR := Color("c9b8ff")

var value := 0


static func make(p_value: int) -> Rune:
	var rune := Rune.new()
	rune.value = p_value
	return rune


func _ready() -> void:
	var stone := ColorRect.new()
	stone.color = Color("3a3352")
	stone.size = Vector2(12, 14)
	stone.position = Vector2(-6, -14)
	add_child(stone)
	var label := Label.new()
	label.name = "Value"
	label.text = str(value)
	label.add_theme_font_size_override(&"font_size", 9)
	label.add_theme_color_override(&"font_color", COLOR)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(12, 14)
	label.position = Vector2(-6, -15)
	add_child(label)
