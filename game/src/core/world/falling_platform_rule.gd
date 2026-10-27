class_name FallingPlatformRule
extends RefCounted
## Plataforma que cai (spec MUN-plataformas, regras 7 a 9): pisada, treme; depois cai e some; depois
## volta para o lugar.

enum State { STILL, SHAKING, FALLEN }

const SHAKE_TIME := 0.5
const BACK_TIME := 3.0
## Folga nas contas de tempo: a soma de passos de 1/60 s não fecha exata.
const EPSILON := 1e-6

var state := State.STILL

var _left := 0.0


## O mago pisou nela; só conta parada (tremendo, o tempo não muda).
func step_on() -> void:
	if state == State.STILL:
		state = State.SHAKING
		_left = SHAKE_TIME


## Avança o tempo; true no passo em que muda de estado.
func tick(delta: float) -> bool:
	if state == State.STILL:
		return false
	_left -= delta
	if _left > EPSILON:
		return false
	if state == State.SHAKING:
		state = State.FALLEN
		_left = BACK_TIME
	else:
		state = State.STILL
	return true


## Segura o mago (parada ou tremendo).
func solid() -> bool:
	return state != State.FALLEN
