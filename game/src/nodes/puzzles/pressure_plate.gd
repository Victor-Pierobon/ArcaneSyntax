class_name PressurePlate
extends Area2D
## Placa de pressão (`_`): fica pisada quando o mago está no chão dentro da célula, e continua
## pisada (spec PUZ-validacao, regra 12).

signal pressed

const COLOR_UP := Color("b08a4a")
const COLOR_DOWN := Color("ffd27a")

var is_pressed := false

var _visual := ColorRect.new()


static func make(cell: Vector2i) -> PressurePlate:
	var plate := PressurePlate.new()
	plate.position = Vector2(cell * RoomLayout.TILE)
	plate.monitorable = false
	plate.monitoring = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(RoomLayout.TILE - 4, RoomLayout.TILE / 2.0)
	shape.shape = rect
	shape.position = Vector2(RoomLayout.TILE / 2.0, RoomLayout.TILE * 0.75)
	plate.add_child(shape)
	return plate


func _ready() -> void:
	_visual.size = Vector2(RoomLayout.TILE - 4, 3)
	_visual.position = Vector2(2, RoomLayout.TILE - 3)
	_visual.color = COLOR_DOWN if is_pressed else COLOR_UP
	add_child(_visual)


func _physics_process(_delta: float) -> void:
	if is_pressed or not monitoring:
		return
	for body in get_overlapping_bodies():
		if body is Player and body.is_on_floor():
			press()
			return


func press() -> void:
	if is_pressed:
		return
	is_pressed = true
	_visual.color = COLOR_DOWN
	pressed.emit()
