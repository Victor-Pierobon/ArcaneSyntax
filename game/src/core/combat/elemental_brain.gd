class_name ElementalBrain
extends RefCounted
## Para onde o elemental anda (spec COM-elemental, regras 3 e 4). Posições em px, pés do elemental.

## Mais perto que isso do mago, para de virar de um lado para o outro.
const CHASE_DEAD_ZONE := 2.0

var home_x: float
var direction := 1
var chasing := false

## Do balanceamento, seção `elemental` (spec BAL-valores).
var patrol_range := Balance.number("elemental", "patrulha_tiles") * RoomLayout.TILE
var patrol_speed := Balance.number("elemental", "velocidade_patrulha")
var chase_speed := Balance.number("elemental", "velocidade_perseguicao")
var chase_range_x := Balance.number("elemental", "perseguir_x_tiles") * RoomLayout.TILE
var chase_range_y := Balance.number("elemental", "perseguir_y_tiles") * RoomLayout.TILE


func _init(p_home_x: float) -> void:
	home_x = p_home_x


## Velocidade horizontal deste quadro. `mago_pos`: pés do mago, ou null se não há mago.
## `ahead_free.call(direção)`: se dá para andar um passo nessa direção.
func velocity_x(pos: Vector2, mago_pos: Variant, ahead_free: Callable) -> float:
	chasing = mago_pos != null and absf(mago_pos.x - pos.x) <= chase_range_x \
			and absf(mago_pos.y - pos.y) <= chase_range_y
	if chasing:
		var dx: float = mago_pos.x - pos.x
		if absf(dx) <= CHASE_DEAD_ZONE:
			return 0.0
		direction = 1 if dx > 0.0 else -1
		return chase_speed * direction if ahead_free.call(direction) else 0.0
	if pos.x >= home_x + patrol_range:
		direction = -1
	elif pos.x <= home_x - patrol_range:
		direction = 1
	if not ahead_free.call(direction):
		direction = -direction
		if not ahead_free.call(direction):
			return 0.0
	return patrol_speed * direction


## Se o elemental com os pés em `feet` pode dar um passo em `step_direction` sem entrar
## numa parede nem sair do chão (regra 4).
static func can_walk(layout: RoomLayout, feet: Vector2, step_direction: int, half_width: float) -> bool:
	var probe_x := feet.x + step_direction * (half_width + 1.0)
	var cell := Vector2i(floori(probe_x / RoomLayout.TILE), floori((feet.y - 1.0) / RoomLayout.TILE))
	if cell in layout.solids or cell in layout.doors:
		return false
	var below := cell + Vector2i.DOWN
	return below in layout.solids or below in layout.platforms
