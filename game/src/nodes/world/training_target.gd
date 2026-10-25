class_name TrainingTarget
extends Node2D
## Boneco de treino: um "alvo" com elemento, até os inimigos chegarem (spec MUN-alvos).
## A origem fica nos pés, como a do mago.

const GROUP := &"alvos"
const ELEMENT_COLORS := {
	"fogo": Color("ff7a3d"),
	"gelo": Color("6fd3ff"),
	"raio": Color("ffe14d"),
	"planta": Color("6fcf5a"),
}

var target_id := ""
var element := ""


static func make(p_target_id: String, p_element: String) -> TrainingTarget:
	var target := TrainingTarget.new()
	target.target_id = p_target_id
	target.element = p_element
	target.name = p_target_id
	return target


func _ready() -> void:
	add_to_group(GROUP)
	var body := ColorRect.new()
	body.color = ELEMENT_COLORS.get(element, Color("9a96a8"))
	body.size = Vector2(12, 24)
	body.position = Vector2(-6, -24)
	add_child(body)
	var label := Label.new()
	label.text = element
	label.add_theme_font_size_override(&"font_size", 7)
	label.position = Vector2(-12, -34)
	add_child(label)
