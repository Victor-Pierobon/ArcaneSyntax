class_name SwarmBugBrain
extends RefCounted
## Onde um bicho do enxame voa (spec COM-enxame, regra 4). Posições em px, centro do bicho.

enum State { HOVER, DIVE, RETREAT }

## Distância em que o recuo chega no ponto da volta.
const ARRIVED := 1.0

var home: Vector2
var phase: float
var state := State.HOVER

## Do balanceamento, seção `enxame` (spec BAL-valores).
var orbit_radius := Balance.number("enxame", "orbita_raio_tiles") * RoomLayout.TILE
var orbit_period := Balance.number("enxame", "orbita_periodo_s")
var dive_range := Balance.number("enxame", "mergulho_tiles") * RoomLayout.TILE
var speed := Balance.number("enxame", "velocidade")
var bite_cooldown := Balance.number("enxame", "recarga_mordida_s")

## O relógio da volta só anda pairando: no recuo, o ponto de chegada fica parado.
var _orbit_time := 0.0
var _cooldown := 0.0


func _init(p_home: Vector2, p_phase: float = 0.0) -> void:
	home = p_home
	phase = p_phase


func start_position() -> Vector2:
	return orbit_point()


func orbit_point() -> Vector2:
	var angle := phase + _orbit_time * TAU / orbit_period
	return home + Vector2(cos(angle), sin(angle)) * orbit_radius


## Próxima posição do bicho. `mago_pos`: centro do mago, ou null se não há mago.
func step(pos: Vector2, mago_pos: Variant, delta: float) -> Vector2:
	_cooldown = maxf(_cooldown - delta, 0.0)
	var mago_near: bool = mago_pos != null and home.distance_to(mago_pos) <= dive_range
	match state:
		State.HOVER:
			if mago_near and _cooldown == 0.0:
				state = State.DIVE
			else:
				_orbit_time += delta
				return orbit_point()
		State.RETREAT:
			var target := orbit_point()
			var next := pos.move_toward(target, speed * delta)
			if next.distance_to(target) <= ARRIVED:
				state = State.HOVER
				return target
			return next
	if not mago_near:
		state = State.RETREAT
		return pos.move_toward(orbit_point(), speed * delta)
	return pos.move_toward(mago_pos, speed * delta)


## Mordeu o mago: volta para casa e espera antes de mergulhar de novo.
func bite() -> void:
	state = State.RETREAT
	_cooldown = bite_cooldown
