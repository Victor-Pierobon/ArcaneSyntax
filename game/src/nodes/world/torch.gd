class_name Torch
extends Node2D
## Tocha de parede (spec ART-esteira, regra 28): só decoração, sem colisão e sem ser alvo.
## `objetos/tocha` em laço ou, sem a arte, uma chama provisória desenhada por código. A origem fica
## na base da célula, como a dos outros objetos.

const WOOD := Color("5a3a22")
const FLAME := Color("ff9a3d")
const CORE := Color("ffe08a")

## A arte da tocha; null: a chama desenhada.
var art_sprite: AnimatedSprite2D
## Luz da chama (ART-brilho, regra 2).
var light: PointLight2D

var _time := 0.0


func _ready() -> void:
	art_sprite = ArtLibrary.sprite("objetos", ["tocha"])
	if art_sprite:
		add_child(art_sprite)
	light = Lighting.make(Lighting.TORCH, 80)
	light.position = Vector2(0, -10)
	add_child(light)


func _process(delta: float) -> void:
	_time += delta
	# A chama cintila (sensação; não muda nada no jogo).
	light.energy = 1.0 + sin(_time * 9.0) * 0.08 + sin(_time * 23.0) * 0.05
	if art_sprite == null:
		queue_redraw()


func _draw() -> void:
	if art_sprite:
		return
	draw_rect(Rect2(-1, -8, 2, 6), WOOD)
	var flicker := sin(_time * 14.0) * 0.6
	draw_circle(Vector2(0, -10), 2.6 + flicker * 0.4, FLAME)
	draw_circle(Vector2(0, -10.5), 1.3, CORE)
