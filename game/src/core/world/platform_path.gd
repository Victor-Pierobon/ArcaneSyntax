class_name PlatformPath
extends RefCounted
## Caminho da plataforma que se move (spec MUN-plataformas, regras 4 e 6): parada na partida, vai até o
## extremo, parada, volta, e repete. A posição só depende do tempo.

const SPEED := 48.0
const PAUSE := 0.5

var start: Vector2
var end: Vector2
var speed: float
var pause: float


func _init(p_start: Vector2, p_end: Vector2, p_speed := SPEED, p_pause := PAUSE) -> void:
	start = p_start
	end = p_end
	speed = p_speed
	pause = p_pause


func travel_time() -> float:
	return start.distance_to(end) / speed if speed > 0.0 else 0.0


## Ida e volta com as duas pausas.
func cycle() -> float:
	return 2.0 * (pause + travel_time())


func position_at(time: float) -> Vector2:
	var travel := travel_time()
	if travel <= 0.0:
		return start
	var t := fposmod(time, cycle())
	if t < pause:
		return start
	t -= pause
	if t < travel:
		return start.lerp(end, t / travel)
	t -= travel
	if t < pause:
		return end
	return end.lerp(start, (t - pause) / travel)
