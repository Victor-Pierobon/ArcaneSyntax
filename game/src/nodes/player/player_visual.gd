class_name PlayerVisual
extends Node2D
## O visual do mago (spec ART-esteira, regras 9 a 11): a arte de `assets/mago/` ou, sem ela, um mago
## provisório desenhado por código com uma pose por animação. A origem fica nos pés.

const ANIMATIONS := ["parado", "andar", "pular", "cair", "esquivar", "conjurar", "meditar", "cajado", "dano", "morrer"]
const ROBE := Color("7a5cd9")
const ROBE_SHADE := Color("4f3a9e")
const SKIN := Color("f1c9a5")
const HAT := Color("3b2c7a")
const STAFF := Color("9a6a3c")
const GEM := Color("b8a8ff")
const OUTLINE := Color("1b1530")

## O sprite da arte; null quando o mago usa o provisório.
var sprite: AnimatedSprite2D
## A aura de meditar (`magia/meditar`, regra 22); null sem a arte.
var aura: AnimatedSprite2D
var shown_animation := "parado"
var facing := 1

var _time := 0.0


func _ready() -> void:
	sprite = ArtLibrary.sprite("mago", ANIMATIONS)
	if sprite:
		add_child(sprite)
	aura = ArtLibrary.sprite("magia", ["meditar"])
	if aura:
		aura.visible = false
		add_child(aura)


func show_animation(anim: String, p_facing: int) -> void:
	if anim != shown_animation:
		_time = 0.0
	shown_animation = anim
	facing = p_facing
	if aura:
		aura.visible = anim == "meditar"
	if sprite:
		sprite.flip_h = facing < 0
		if sprite.animation != anim and sprite.sprite_frames.has_animation(anim):
			sprite.play(anim)


func _process(delta: float) -> void:
	if sprite == null:
		_time += delta
		queue_redraw()


## O mago provisório: túnica, cabeça, chapéu pontudo e cajado, com uma pose simples por animação.
func _draw() -> void:
	if sprite:
		return
	var bob := 0.0
	var lean := 0.0
	var stretch := Vector2.ONE
	var staff_angle := -0.15
	var tint := Color.WHITE
	match shown_animation:
		"parado":
			bob = -0.5 - sin(_time * 3.0) * 0.5
		"andar":
			bob = -absf(sin(_time * 12.0)) * 1.5
			lean = 1.5
		"pular":
			stretch = Vector2(0.88, 1.1)
		"cair":
			stretch = Vector2(1.08, 0.94)
		"esquivar":
			stretch = Vector2(1.15, 0.85)
			lean = 4.0
			tint = Color(1, 1, 1, 0.6)
		"conjurar":
			staff_angle = -0.9
			lean = 1.0
		"meditar":
			bob = -3.0 - sin(_time * 4.0)
			staff_angle = 0.0
		"cajado":
			staff_angle = -1.5
			lean = 2.0
		"dano":
			tint = Color("ff8080")
			lean = -2.0 + sin(_time * 60.0)
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(stretch.x * facing, stretch.y))
	if shown_animation == "meditar" and aura == null:
		draw_circle(Vector2(0, -14), 15.0, Color(GEM, 0.18))
		draw_arc(Vector2(0, -14), 15.0, 0.0, TAU, 24, Color(GEM, 0.6), 1.0)
	var robe := PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(4 + lean, -18), Vector2(-4 + lean, -18)])
	draw_colored_polygon(robe, OUTLINE * tint)
	var inner := PackedVector2Array([Vector2(-5, -1), Vector2(5, -1), Vector2(3 + lean, -17), Vector2(-3 + lean, -17)])
	draw_colored_polygon(inner, ROBE * tint)
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -1), Vector2(-1, -1), Vector2(-3 + lean, -17)]), ROBE_SHADE * tint)
	draw_rect(Rect2(-4 + lean * 0.5, -9, 8, 2), HAT * tint)
	draw_rect(Rect2(-6 + lean * 0.5, -10, 3, 4), Color("e8c060") * tint)
	var head := Vector2(lean, -21)
	draw_circle(head, 4.5, OUTLINE * tint)
	draw_circle(head, 3.5, SKIN * tint)
	draw_rect(Rect2(head + Vector2(1.5, -1), Vector2(1, 1)), OUTLINE)
	var hat := PackedVector2Array([head + Vector2(-6, -2), head + Vector2(6, -2), head + Vector2(-1, -13)])
	draw_colored_polygon(hat, HAT * tint)
	draw_line(head + Vector2(-6, -2), head + Vector2(6, -2), OUTLINE * tint, 1.0)
	var hand := Vector2(5 + lean, -12)
	var tip := hand + Vector2(0, -16).rotated(-staff_angle)
	draw_line(hand + (hand - tip) * 0.4, tip, STAFF * tint, 1.5)
	var glow := 2.5 if shown_animation == "conjurar" else 1.5
	draw_circle(tip, glow, GEM * tint)
	draw_set_transform(Vector2.ZERO)
