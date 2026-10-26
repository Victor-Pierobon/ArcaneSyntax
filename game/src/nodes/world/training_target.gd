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
## Último golpe recebido (para os testes e para o dano dos inimigos, spec COM-dano).
var last_hit_element := ""
var last_form := ""
var last_effect: ElementTable.Effect = ElementTable.Effect.NORMAL
var hits := 0
var effect_label := Label.new()
## Nome do elemento sobre o boneco (o cristal mutável troca o texto).
var name_label := Label.new()
## Tamanho do corpo e da área que recebe golpes; os inimigos mudam antes de entrar na árvore.
var body_size := SIZE

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
	_body.size = body_size
	_body.position = Vector2(-body_size.x / 2, -body_size.y)
	add_child(_body)
	name_label.text = element
	name_label.add_theme_font_size_override(&"font_size", 7)
	name_label.position = Vector2(-12, -body_size.y - 10)
	add_child(name_label)
	effect_label.add_theme_font_size_override(&"font_size", 8)
	effect_label.position = Vector2(-16, -body_size.y - 22)
	effect_label.modulate.a = 0.0
	add_child(effect_label)
	var hurtbox := Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = Projectile.HURTBOX_LAYER
	hurtbox.collision_mask = 0
	hurtbox.monitoring = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = body_size
	shape.shape = rect
	shape.position = Vector2(0, -body_size.y / 2)
	hurtbox.add_child(shape)
	add_child(hurtbox)


## Centro do corpo, para onde os projéteis miram.
func center() -> Vector2:
	return global_position + Vector2(0, -body_size.y / 2)


## `form`: projetil, faisca ou vazio (cajado); os inimigos usam para o dano (COM-dano).
func hit(attack_element: String, form: String = "") -> void:
	last_hit_element = attack_element
	last_form = form
	last_effect = ElementTable.effect(attack_element, element)
	hits += 1
	_show_hit(attack_element, tr(ElementTable.LABEL_KEYS[last_effect]))
	was_hit.emit(attack_element, last_effect)


## Texto flutuante, piscada na cor do ataque e partículas.
func _show_hit(attack_element: String, text: String) -> void:
	effect_label.text = text
	effect_label.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_property(effect_label, "modulate:a", 0.0, 0.8).set_delay(0.4)
	var flash := create_tween()
	_body.modulate = ELEMENT_COLORS.get(attack_element, Color.WHITE).lightened(0.5)
	flash.tween_property(_body, "modulate", Color.WHITE, 0.25)
	Fx.burst(self, Vector2(0, -body_size.y / 2), ELEMENT_COLORS.get(attack_element, Color.WHITE))
