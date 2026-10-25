class_name TrainingTarget
extends Node2D
## Boneco de treino: um "alvo" com elemento, até os inimigos chegarem (spec MUN-alvos).
## Mostra o efeito dos golpes (spec MAG-elementos). A origem fica nos pés, como a do mago.

## Recebeu um golpe (o World toca o som; spec MAG-efeitos).
signal was_hit(attack_element: String, effect: ElementTable.Effect)

const GROUP := &"alvos"
const ELEMENT_COLORS := {
	"fogo": Color("ff7a3d"),
	"gelo": Color("6fd3ff"),
	"raio": Color("ffe14d"),
	"planta": Color("6fcf5a"),
	"cajado": Color("d8c8a8"),
}
const SIZE := Vector2(12, 24)

var target_id := ""
var element := ""
## Último golpe recebido (para os testes e, na Sprint 10, para o dano).
var last_hit_element := ""
var last_effect: ElementTable.Effect = ElementTable.Effect.NORMAL
var hits := 0
var effect_label := Label.new()
## Nome do elemento sobre o boneco (o cristal mutável troca o texto).
var name_label := Label.new()

var _body := ColorRect.new()


static func make(p_target_id: String, p_element: String) -> TrainingTarget:
	var target := TrainingTarget.new()
	target.target_id = p_target_id
	target.element = p_element
	target.name = p_target_id
	return target


func _ready() -> void:
	add_to_group(GROUP)
	_body.color = ELEMENT_COLORS.get(element, Color("9a96a8"))
	_body.size = SIZE
	_body.position = Vector2(-SIZE.x / 2, -SIZE.y)
	add_child(_body)
	name_label.text = element
	name_label.add_theme_font_size_override(&"font_size", 7)
	name_label.position = Vector2(-12, -34)
	add_child(name_label)
	effect_label.add_theme_font_size_override(&"font_size", 8)
	effect_label.position = Vector2(-16, -46)
	effect_label.modulate.a = 0.0
	add_child(effect_label)
	var hurtbox := Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = Projectile.HURTBOX_LAYER
	hurtbox.collision_mask = 0
	hurtbox.monitoring = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	shape.position = Vector2(0, -SIZE.y / 2)
	hurtbox.add_child(shape)
	add_child(hurtbox)


## Centro do corpo, para onde os projéteis miram.
func center() -> Vector2:
	return global_position + Vector2(0, -SIZE.y / 2)


func hit(attack_element: String) -> void:
	last_hit_element = attack_element
	last_effect = ElementTable.effect(attack_element, element)
	hits += 1
	effect_label.text = tr(ElementTable.LABEL_KEYS[last_effect])
	effect_label.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_property(effect_label, "modulate:a", 0.0, 0.8).set_delay(0.4)
	var flash := create_tween()
	_body.modulate = ELEMENT_COLORS.get(attack_element, Color.WHITE).lightened(0.5)
	flash.tween_property(_body, "modulate", Color.WHITE, 0.25)
	Fx.burst(self, Vector2(0, -SIZE.y / 2), ELEMENT_COLORS.get(attack_element, Color.WHITE))
	was_hit.emit(attack_element, last_effect)
