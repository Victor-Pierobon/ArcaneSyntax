class_name TileShape
extends RefCounted
## A forma de cada tile de pedra pela vizinhança (spec ART-esteira, regras 12 e 13).

const UP := 1
const RIGHT := 2
const DOWN := 4
const LEFT := 8
const COLUMNS := 4
const PLATFORM := Vector2i(0, 4)
const SPIKES := Vector2i(1, 4)
## Tamanho do atlas em tiles (4 colunas × 5 linhas).
const ATLAS_SIZE := Vector2i(4, 5)


## Número de 4 bits das pedras vizinhas de `cell`; fora da sala (`size` em tiles) conta como pedra.
static func mask(solids: Dictionary, cell: Vector2i, size: Vector2i) -> int:
	var value := 0
	for side: Array in [[Vector2i.UP, UP], [Vector2i.RIGHT, RIGHT], [Vector2i.DOWN, DOWN], [Vector2i.LEFT, LEFT]]:
		var neighbor: Vector2i = cell + side[0]
		var outside := neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= size.x or neighbor.y >= size.y
		if outside or solids.has(neighbor):
			value |= side[1]
	return value


static func atlas(shape_mask: int) -> Vector2i:
	return Vector2i(shape_mask % COLUMNS, shape_mask / COLUMNS)
