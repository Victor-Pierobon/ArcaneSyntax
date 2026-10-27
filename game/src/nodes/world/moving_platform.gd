class_name MovingPlatform
extends AnimatableBody2D
## Plataforma que se move (spec MUN-plataformas, regras 3 a 6): vai e volta pelo PlatformPath e leva
## quem está em pé nela. Atravessável por baixo, como `=`. A posição é a da célula de partida mais o
## caminho; a pausa do jogo congela o tempo.

const THICKNESS := 4.0
## Runas acesas por cima da madeira: diferencia da plataforma fixa.
const GLOW := Color("8fd3ff")

var width := 1
var path: PlatformPath
## O desenho de uma célula de plataforma (do tileset da sala); null: retângulo.
var tile_texture: Texture2D
var tile_region := Rect2()

## Canto de cima à esquerda da primeira célula na partida, em coordenadas da sala.
var origin := Vector2.ZERO

var _time := 0.0


## `start` e `end`: canto de cima à esquerda da primeira célula, em coordenadas da sala.
static func make(start: Vector2, end: Vector2, p_width: int) -> MovingPlatform:
	var platform := MovingPlatform.new()
	platform.width = p_width
	platform.origin = start
	platform.path = PlatformPath.new(Vector2.ZERO, end - start)
	platform.position = start
	return platform


func _ready() -> void:
	sync_to_physics = true
	collision_layer = Room.PLATFORM_LAYER
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width * RoomLayout.TILE, THICKNESS)
	shape.shape = rect
	shape.position = Vector2(width * RoomLayout.TILE / 2.0, THICKNESS / 2.0)
	shape.one_way_collision = true
	add_child(shape)


func _physics_process(delta: float) -> void:
	_time += delta
	position = origin + path.position_at(_time)


func _draw() -> void:
	for i in width:
		var cell := Rect2(i * RoomLayout.TILE, 0, RoomLayout.TILE, RoomLayout.TILE)
		if tile_texture:
			draw_texture_rect_region(tile_texture, cell, tile_region)
		else:
			draw_rect(Rect2(cell.position, Vector2(RoomLayout.TILE, THICKNESS)), Color("8a6a44"))
		draw_rect(Rect2(cell.position + Vector2(6, 1), Vector2(4, 2)), GLOW)
