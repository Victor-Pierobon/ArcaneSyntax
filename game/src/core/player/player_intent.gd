class_name PlayerIntent
extends RefCounted
## O que o jogador quer fazer neste quadro, independente de onde veio (teclado, teste, feitiço).

var move_x: float = 0.0
var jump_pressed: bool = false
var jump_held: bool = false


static func make(p_move_x: float = 0.0, p_jump_pressed: bool = false, p_jump_held: bool = false) -> PlayerIntent:
	var intent := PlayerIntent.new()
	intent.move_x = p_move_x
	intent.jump_pressed = p_jump_pressed
	intent.jump_held = p_jump_held
	return intent


static func from_input() -> PlayerIntent:
	return make(
		Input.get_axis(&"move_left", &"move_right"),
		Input.is_action_just_pressed(&"jump"),
		Input.is_action_pressed(&"jump"),
	)
