class_name ElementalBrain
extends RefCounted
## Para onde o elemental anda (spec COM-elemental, regras 3 e 4). Posições em px, pés do elemental.

const PATROL_RANGE := 3.0 * RoomLayout.TILE
const PATROL_SPEED := 30.0
const CHASE_SPEED := 45.0
const CHASE_RANGE_X := 6.0 * RoomLayout.TILE
const CHASE_RANGE_Y := 2.0 * RoomLayout.TILE
## Mais perto que isso do mago, para de virar de um lado para o outro.
const CHASE_DEAD_ZONE := 2.0

var home_x: float
var direction := 1
var chasing := false


func _init(p_home_x: float) -> void:
	home_x = p_home_x


## Velocidade horizontal deste quadro. `mago_pos`: pés do mago, ou null se não há mago.
## `ahead_free.call(direção)`: se dá para andar um passo nessa direção.
func velocity_x(pos: Vector2, mago_pos: Variant, ahead_free: Callable) -> float:
	chasing = mago_pos != null and absf(mago_pos.x - pos.x) <= CHASE_RANGE_X \
			and absf(mago_pos.y - pos.y) <= CHASE_RANGE_Y
	if chasing:
		var dx: float = mago_pos.x - pos.x
		if absf(dx) <= CHASE_DEAD_ZONE:
			return 0.0
		direction = 1 if dx > 0.0 else -1
		return CHASE_SPEED * direction if ahead_free.call(direction) else 0.0
	if pos.x >= home_x + PATROL_RANGE:
		direction = -1
	elif pos.x <= home_x - PATROL_RANGE:
		direction = 1
	if not ahead_free.call(direction):
		direction = -direction
		if not ahead_free.call(direction):
			return 0.0
	return PATROL_SPEED * direction


## Se o elemental com os pés em `feet` pode dar um passo em `step_direction` sem entrar
## numa parede nem sair do chão (regra 4).
static func can_walk(layout: RoomLayout, feet: Vector2, step_direction: int, half_width: float) -> bool:
	var probe_x := feet.x + step_direction * (half_width + 1.0)
	var cell := Vector2i(floori(probe_x / RoomLayout.TILE), floori((feet.y - 1.0) / RoomLayout.TILE))
	if cell in layout.solids or cell in layout.doors:
		return false
	var below := cell + Vector2i.DOWN
	return below in layout.solids or below in layout.platforms
