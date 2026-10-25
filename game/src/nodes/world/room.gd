class_name Room
extends Node2D
## Uma sala da torre, montada a partir do layout em texto (spec MUN-salas).

signal exit_touched(target_room: String, target_entry: String)
signal hazard_touched
signal safe_point_touched(feet: Vector2)

const TILESET := preload("res://assets/placeholder/tiles.tres")
const ATLAS_STONE := Vector2i(0, 0)
const ATLAS_PLATFORM := Vector2i(1, 0)
const ATLAS_SPIKES := Vector2i(2, 0)
const TILE := RoomLayout.TILE

@export var room_id: String = ""
@export_multiline var layout: String = ""
## Letra da saída → "sala:Entrada", ex.: {"b": "sala_02:A"}.
@export var exits: Dictionary = {}

var data: RoomLayout
var tiles: TileMapLayer
var errors: Array[String] = []

var _areas: Array[Area2D] = []


func _ready() -> void:
	data = RoomLayout.parse(layout)
	errors.append_array(data.errors)
	_build_tiles()
	_build_exits()
	for cell in data.spikes:
		_add_area(Rect2(cell.x * TILE + 2, cell.y * TILE + TILE / 2.0, TILE - 4, TILE / 2.0), hazard_touched.emit)
	for cell in data.safe_points:
		var feet := global_position + RoomLayout.cell_feet(cell)
		_add_area(Rect2(Vector2(cell * TILE), Vector2(TILE, TILE)), safe_point_touched.emit.bind(feet))
	for error in errors:
		push_warning("sala %s: %s" % [room_id, error])
	_activate_areas_after_first_frame()


## As áreas nascem desligadas: no quadro em que a sala entra, o servidor de física ainda
## pode ter o mago na posição da sala anterior e disparar espinhos ou saídas por engano.
func _activate_areas_after_first_frame() -> void:
	await get_tree().physics_frame
	for area in _areas:
		if is_instance_valid(area):
			area.set_deferred(&"monitoring", true)


func bounds() -> Rect2:
	return Rect2(global_position, data.size_px())


func has_entry(letter: String) -> bool:
	return data.entries.has(letter)


func first_entry() -> String:
	return "" if data.entries.is_empty() else data.entries.keys()[0]


func entry_feet(letter: String) -> Vector2:
	return global_position + RoomLayout.cell_feet(data.entries[letter])


func _build_tiles() -> void:
	tiles = TileMapLayer.new()
	tiles.name = "Tiles"
	tiles.tile_set = TILESET
	add_child(tiles)
	for cell in data.solids:
		tiles.set_cell(cell, 0, ATLAS_STONE)
	for cell in data.platforms:
		tiles.set_cell(cell, 0, ATLAS_PLATFORM)
	for cell in data.spikes:
		tiles.set_cell(cell, 0, ATLAS_SPIKES)


func _build_exits() -> void:
	for letter: String in data.exits:
		var target := str(exits.get(letter, ""))
		var parts := target.split(":")
		if parts.size() != 2:
			errors.append("saída '%s' sem destino válido (use \"sala:Entrada\")" % letter)
			continue
		for cell: Vector2i in data.exits[letter]:
			_add_area(Rect2(Vector2(cell * TILE), Vector2(TILE, TILE)), exit_touched.emit.bind(parts[0], parts[1]))


func _add_area(rect: Rect2, on_player_enter: Callable) -> void:
	var area := Area2D.new()
	area.monitorable = false
	area.monitoring = false
	_areas.append(area)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	shape.position = rect.get_center()
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(func(body: Node2D) -> void:
		if body is Player:
			on_player_enter.call()
	)
