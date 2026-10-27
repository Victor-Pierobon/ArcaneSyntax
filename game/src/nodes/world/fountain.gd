class_name Fountain
extends Node2D
## Fonte que enche vida e mana (spec MUN-vida, regra 9): mostra "E: beber" com o mago perto, e o World
## faz o resto. Visual provisório, desenhado por código. A origem fica nos pés.

const REACH := 2.0 * RoomLayout.TILE
const COLOR_STONE := Color("7d7a8c")
const COLOR_WATER := Color("8fd8ff")

## O mago, para mostrar o aviso; o World passa pela Room antes de entrar na árvore.
var player: Node2D
## Luz azul da água (ART-brilho, regra 2).
var light: PointLight2D

var _prompt := Label.new()
var _time := 0.0


func _ready() -> void:
	light = Lighting.make(Lighting.FOUNTAIN, 48)
	light.position = Vector2(0, -12)
	add_child(light)
	_prompt.text = "FONTE_BEBER"
	Lighting.keep_readable(_prompt)
	_prompt.add_theme_font_size_override(&"font_size", 8)
	_prompt.add_theme_color_override(&"font_color", Color("ffd27a"))
	# Acima da cabeça do mago, como o aviso da serpente.
	_prompt.position = Vector2(-18, -44)
	_prompt.visible = false
	add_child(_prompt)


func _physics_process(delta: float) -> void:
	_time += delta
	_prompt.visible = in_reach()
	queue_redraw()


func in_reach() -> bool:
	return player != null and is_instance_valid(player) \
			and player.global_position.distance_to(global_position) <= REACH + 0.001


func prompt_visible() -> bool:
	return in_reach()


## Bacia de pedra com água que sobe e desce.
func _draw() -> void:
	draw_rect(Rect2(-8, -6, 16, 6), COLOR_STONE)
	draw_rect(Rect2(-2, -14, 4, 8), COLOR_STONE)
	var rise := 2.0 + sin(_time * 3.0)
	draw_circle(Vector2(0, -14 - rise), 2.5, COLOR_WATER)
	draw_rect(Rect2(-6, -7, 12, 2), COLOR_WATER)
