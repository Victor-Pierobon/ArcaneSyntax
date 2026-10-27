class_name BeamRule
extends RefCounted
## Geometria do feixe (spec MAG-feixe, regras 4, 5 e 7): onde ele termina e quais retângulos ele encosta.
## O que bloqueia (pedra, porta fechada) quem chama decide, por célula.

const MAX_LENGTH := 40.0 * RoomLayout.TILE
## Largura do feixe, em px.
const WIDTH := 8.0
## Passo da busca pela parede, em px.
const STEP := 2.0


## O ponto onde o feixe que sai de `origin` na direção `direction` para: antes da primeira célula em que
## `blocked.call(célula)` é true, ou a MAX_LENGTH.
static func end_point(origin: Vector2, direction: Vector2, blocked: Callable) -> Vector2:
	var unit := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	var travelled := 0.0
	while travelled < MAX_LENGTH:
		var next := travelled + STEP
		var point := origin + unit * next
		if blocked.call(Vector2i(floori(point.x / RoomLayout.TILE), floori(point.y / RoomLayout.TILE))):
			return origin + unit * travelled
		travelled = next
	return origin + unit * MAX_LENGTH


## Índices dos retângulos que o feixe de `start` a `end` encosta, com a largura WIDTH.
static func hits(start: Vector2, end: Vector2, rects: Array[Rect2]) -> Array[int]:
	var found: Array[int] = []
	var half := WIDTH / 2.0
	for i in rects.size():
		if _distance_to_rect(start, end, rects[i]) <= half + 0.001:
			found.append(i)
	return found


## Menor distância entre o segmento e o retângulo (0 se cruzam).
static func _distance_to_rect(a: Vector2, b: Vector2, rect: Rect2) -> float:
	if rect.has_point(a) or rect.has_point(b) or _crosses(a, b, rect):
		return 0.0
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	var best := INF
	for i in 4:
		var c: Vector2 = corners[i]
		var d: Vector2 = corners[(i + 1) % 4]
		best = minf(best, Geometry2D.get_closest_point_to_segment(c, a, b).distance_to(c))
		best = minf(best, Geometry2D.get_closest_point_to_segment(a, c, d).distance_to(a))
		best = minf(best, Geometry2D.get_closest_point_to_segment(b, c, d).distance_to(b))
	return best


static func _crosses(a: Vector2, b: Vector2, rect: Rect2) -> bool:
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i in 4:
		if Geometry2D.segment_intersects_segment(a, b, corners[i], corners[(i + 1) % 4]) != null:
			return true
	return false
