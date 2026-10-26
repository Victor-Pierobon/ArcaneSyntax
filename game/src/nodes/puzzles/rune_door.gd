class_name RuneDoor
extends StaticBody2D
## Porta de runas: sólida até o puzzle da sala ser resolvido (spec PUZ-validacao). Também é a porta de
## atalho (`%`, MUN-mapa), com outra cor.

signal opened

const COLOR_CLOSED := Color("6a4fb8")
const COLOR_SHORTCUT := Color("3f8f7a")

var is_open := false

var _visuals: Array[ColorRect] = []
var _shapes: Array[CollisionShape2D] = []


## Uma porta cobrindo as células do layout (`|`).
static func make(cells: Array[Vector2i], color := COLOR_CLOSED) -> RuneDoor:
	var door := RuneDoor.new()
	door.name = "RuneDoor"
	for cell in cells:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(RoomLayout.TILE, RoomLayout.TILE)
		shape.shape = rect
		shape.position = RoomLayout.cell_center(cell)
		door.add_child(shape)
		door._shapes.append(shape)
		var visual := ColorRect.new()
		visual.color = color
		visual.position = Vector2(cell * RoomLayout.TILE) + Vector2(3, 0)
		visual.size = Vector2(RoomLayout.TILE - 6, RoomLayout.TILE)
		door.add_child(visual)
		door._visuals.append(visual)
	return door


func open() -> void:
	if is_open:
		return
	is_open = true
	for shape in _shapes:
		shape.set_deferred(&"disabled", true)
	for visual in _visuals:
		var tween := visual.create_tween()
		tween.tween_property(visual, "modulate:a", 0.15, 0.4)
	opened.emit()
