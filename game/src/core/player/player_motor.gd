class_name PlayerMotor
extends RefCounted
## Regra pura do movimento do mago (spec MUN-movimento).

var walk_speed: float = 120.0
var gravity: float = 980.0
var jump_height: float = 48.0
var max_fall_speed: float = 400.0
var jump_cut: float = 0.5

## Liberado a cada pulo; consumido quando o jogador solta o botão na subida.
var _jump_cut_available := false


## Velocidade (positiva) que leva o mago exatamente a jump_height.
func jump_velocity() -> float:
	return sqrt(2.0 * gravity * jump_height)


func step(velocity: Vector2, intent: PlayerIntent, on_floor: bool, delta: float) -> Vector2:
	var v := velocity
	v.x = intent.move_x * walk_speed

	if on_floor and intent.jump_pressed:
		v.y = -jump_velocity()
		_jump_cut_available = true
	elif not on_floor:
		v.y = minf(v.y + gravity * delta, max_fall_speed)

	if _jump_cut_available and not intent.jump_held and v.y < 0.0:
		v.y *= jump_cut
		_jump_cut_available = false

	return v
