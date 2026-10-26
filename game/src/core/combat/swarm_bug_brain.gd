class_name SwarmBugBrain
extends RefCounted
## Onde um bicho do enxame voa (spec COM-enxame, regra 4). Posições em px, centro do bicho.

enum State { HOVER, DIVE, RETREAT }

const ORBIT_RADIUS := 1.5 * RoomLayout.TILE
const ORBIT_PERIOD := 2.0
const DIVE_RANGE := 7.0 * RoomLayout.TILE
const SPEED := 70.0
const BITE_COOLDOWN := 1.5
## Distância em que o recuo chega no ponto da volta.
const ARRIVED := 1.0

var home: Vector2
var phase: float
var state := State.HOVER

## O relógio da volta só anda pairando: no recuo, o ponto de chegada fica parado.
var _orbit_time := 0.0
var _cooldown := 0.0


func _init(p_home: Vector2, p_phase: float = 0.0) -> void:
	home = p_home
	phase = p_phase


func start_position() -> Vector2:
	return orbit_point()


func orbit_point() -> Vector2:
	var angle := phase + _orbit_time * TAU / ORBIT_PERIOD
	return home + Vector2(cos(angle), sin(angle)) * ORBIT_RADIUS


## Próxima posição do bicho. `mago_pos`: centro do mago, ou null se não há mago.
func step(pos: Vector2, mago_pos: Variant, delta: float) -> Vector2:
	_cooldown = maxf(_cooldown - delta, 0.0)
	var mago_near: bool = mago_pos != null and home.distance_to(mago_pos) <= DIVE_RANGE
	match state:
		State.HOVER:
			if mago_near and _cooldown == 0.0:
				state = State.DIVE
			else:
				_orbit_time += delta
				return orbit_point()
		State.RETREAT:
			var target := orbit_point()
			var next := pos.move_toward(target, SPEED * delta)
			if next.distance_to(target) <= ARRIVED:
				state = State.HOVER
				return target
			return next
	if not mago_near:
		state = State.RETREAT
		return pos.move_toward(orbit_point(), SPEED * delta)
	return pos.move_toward(mago_pos, SPEED * delta)


## Mordeu o mago: volta para casa e espera antes de mergulhar de novo.
func bite() -> void:
	state = State.RETREAT
	_cooldown = BITE_COOLDOWN
