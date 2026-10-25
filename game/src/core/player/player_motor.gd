class_name PlayerMotor
extends RefCounted
## Regra pura do movimento do mago (spec MUN-movimento).

var walk_speed: float = 120.0
var gravity: float = 980.0
var jump_height: float = 48.0
var max_fall_speed: float = 400.0
var jump_cut: float = 0.5
var coyote_time: float = 0.1
var jump_buffer: float = 0.1
var dodge_speed: float = 280.0
var dodge_duration: float = 0.16
var dodge_cooldown: float = 0.35

## 1 = direita, -1 = esquerda.
var facing: int = 1

## Liberado a cada pulo; consumido quando o jogador solta o botão na subida.
var _jump_cut_available := false
var _coyote_left := 0.0
var _buffer_left := 0.0
var _dodge_left := 0.0
var _dodge_direction := 1
var _dodge_cooldown_left := 0.0
var _air_dodge_available := true


## Velocidade (positiva) que leva o mago exatamente a jump_height.
func jump_velocity() -> float:
	return sqrt(2.0 * gravity * jump_height)


func is_dodging() -> bool:
	return _dodge_left > 0.0


func is_invulnerable() -> bool:
	return is_dodging()


func step(velocity: Vector2, intent: PlayerIntent, on_floor: bool, delta: float) -> Vector2:
	if intent.move_x != 0.0:
		facing = 1 if intent.move_x > 0.0 else -1
	_update_timers(intent, on_floor, delta)

	if intent.dodge_pressed:
		_try_start_dodge(on_floor)
	if is_dodging():
		_dodge_left -= delta
		return Vector2(_dodge_direction * dodge_speed, 0.0)

	var v := velocity
	v.x = intent.move_x * walk_speed

	if _buffer_left > 0.0 and _coyote_left > 0.0:
		v.y = -jump_velocity()
		_buffer_left = 0.0
		_coyote_left = 0.0
		_jump_cut_available = true
	elif not on_floor:
		v.y = minf(v.y + gravity * delta, max_fall_speed)

	if _jump_cut_available and not intent.jump_held and v.y < 0.0:
		v.y *= jump_cut
		_jump_cut_available = false

	return v


func _update_timers(intent: PlayerIntent, on_floor: bool, delta: float) -> void:
	if on_floor:
		_coyote_left = coyote_time
		_air_dodge_available = true
	else:
		_coyote_left -= delta
	if intent.jump_pressed:
		_buffer_left = jump_buffer
	else:
		_buffer_left -= delta
	_dodge_cooldown_left -= delta


func _try_start_dodge(on_floor: bool) -> void:
	if is_dodging() or _dodge_cooldown_left > 0.0:
		return
	if not on_floor and not _air_dodge_available:
		return
	if not on_floor:
		_air_dodge_available = false
	_dodge_left = dodge_duration
	_dodge_direction = facing
	_dodge_cooldown_left = dodge_duration + dodge_cooldown
