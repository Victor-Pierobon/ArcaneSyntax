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
## A arte do personagem (spec ART-esteira, regra 8); null quando ele usa o retângulo provisório.
var art_sprite: AnimatedSprite2D

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
	var outline := ColorRect.new()
	outline.name = "Contorno"
	outline.color = Color("15121f")
	outline.position = Vector2(-1, -1)
	outline.size = body_size + Vector2(2, 2)
	outline.show_behind_parent = true
	_body.add_child(outline)
	var art := _art()
	if not art.is_empty():
		art_sprite = ArtLibrary.sprite(art[0], art.slice(1))
		# Só a arte das outras animações (sem a principal) não basta: fica o retângulo.
		if art_sprite and not art_sprite.sprite_frames.has_animation(art[1]):
			art_sprite = null
		if art_sprite:
			_body.visible = false
			add_child(art_sprite)
	name_label.text = element
	name_label.add_theme_font_size_override(&"font_size", 7)
	name_label.position = Vector2(-12, -top_height() - 10)
	add_child(name_label)
	effect_label.add_theme_font_size_override(&"font_size", 8)
	effect_label.position = Vector2(-16, -top_height() - 22)
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


## [pasta, animação, outras animações...] da arte deste personagem (toca a primeira), ou vazio para
## ficar no retângulo (os inimigos e o cristal trocam).
func _art() -> Array:
	return []


## Altura do personagem acima dos pés, para o nome e a barra de vida ficarem acima dele: o corpo ou,
## com arte, o pixel mais alto do desenho (regressão da primeira leva de arte).
func top_height() -> float:
	if art_sprite == null:
		return body_size.y
	return maxf(body_size.y, ArtLibrary.drawn_height(art_sprite))


func body_visible() -> bool:
	return _body.visible


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
	var visual: CanvasItem = art_sprite if art_sprite else _body
	visual.modulate = ELEMENT_COLORS.get(attack_element, Color.WHITE).lightened(0.5)
	flash.tween_property(visual, "modulate", Color.WHITE, 0.25)
	Fx.burst(self, Vector2(0, -body_size.y / 2), ELEMENT_COLORS.get(attack_element, Color.WHITE))
