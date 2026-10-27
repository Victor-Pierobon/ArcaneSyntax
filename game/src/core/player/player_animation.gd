class_name PlayerAnimation
extends RefCounted
## Regra pura da animação do mago (spec ART-esteira, regra 9): escolhe a animação do quadro.

const HURT_TIME := 0.3
## Tempo de cada ação que não diz o seu.
const ACTION_TIMES := {"conjurar": 0.25, "cajado": 0.2}
const WALK_THRESHOLD := 10.0

var _hurt_left := 0.0
var _action := ""
var _action_left := 0.0


func hurt() -> void:
	_hurt_left = HURT_TIME


## `seconds` negativo usa o tempo padrão da ação.
func start_action(action: String, seconds: float = -1.0) -> void:
	_action = action
	_action_left = seconds if seconds >= 0.0 else float(ACTION_TIMES.get(action, 0.25))


func tick(delta: float) -> void:
	_hurt_left -= delta
	_action_left -= delta
	if _action_left <= 0.0:
		_action = ""


func pick(on_floor: bool, velocity: Vector2, dodging: bool, flying: bool) -> String:
	if _hurt_left > 0.0:
		return "dano"
	if dodging:
		return "esquivar"
	if not _action.is_empty():
		return _action
	if flying or (not on_floor and velocity.y < 0.0):
		return "pular"
	if not on_floor:
		return "cair"
	if absf(velocity.x) > WALK_THRESHOLD:
		return "andar"
	return "parado"
