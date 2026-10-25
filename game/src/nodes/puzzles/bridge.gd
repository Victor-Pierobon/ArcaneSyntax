class_name Bridge
extends StaticBody2D
## Vão de ponte (`~`): cada `construir_bloco()` põe o próximo bloco sólido, da esquerda para a
## direita e, no empate, de baixo para cima (spec PUZ-validacao, regra 11).

signal changed

const COLOR_BUILT := Color("8c7a5b")
const COLOR_GAP := Color(0.55, 0.48, 0.36, 0.18)

var cells: Array[Vector2i] = []

var _built := 0
var _shapes: Array[CollisionShape2D] = []
var _visuals: Array[ColorRect] = []


static func make(p_cells: Array[Vector2i]) -> Bridge:
	var bridge := Bridge.new()
	bridge.name = "Bridge"
	bridge.cells = p_cells.duplicate()
	bridge.cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y > b.y))
	for cell in bridge.cells:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(RoomLayout.TILE, RoomLayout.TILE)
		shape.shape = rect
		shape.position = RoomLayout.cell_center(cell)
		shape.disabled = true
		bridge.add_child(shape)
		bridge._shapes.append(shape)
		var visual := ColorRect.new()
		visual.color = COLOR_GAP
		visual.position = Vector2(cell * RoomLayout.TILE)
		visual.size = Vector2(RoomLayout.TILE, RoomLayout.TILE)
		bridge.add_child(visual)
		bridge._visuals.append(visual)
	return bridge


func total() -> int:
	return cells.size()


func built() -> int:
	return _built


func built_cells() -> Array[Vector2i]:
	return cells.slice(0, _built)


## Põe o próximo bloco; false se a ponte já está pronta.
func build_next() -> bool:
	if _built >= cells.size():
		return false
	_shapes[_built].set_deferred(&"disabled", false)
	_visuals[_built].color = COLOR_BUILT
	_built += 1
	changed.emit()
	return true


## Ponte de um puzzle já resolvido: todos os blocos, sem avisar.
func complete() -> void:
	while _built < cells.size():
		_shapes[_built].set_deferred(&"disabled", false)
		_visuals[_built].color = COLOR_BUILT
		_built += 1
