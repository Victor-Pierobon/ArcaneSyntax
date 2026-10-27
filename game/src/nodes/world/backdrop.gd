class_name Backdrop
extends Node2D
## O fundo atrás da sala (spec ART-esteira, regras 16 e 17): três camadas com paralaxe, da mais longe
## para a mais perto, sobre uma cor sólida. Cada camada usa `cenario/fundo_N.png` ou o provisório.

const PLACEHOLDER := "res://assets/placeholder/fundo_%d.png"
const FACTORS := [0.2, 0.45, 0.7]
const WIDTH := 640.0
const BASE_COLOR := Color("0d0b17")
## Quanto a moldura escura passa da sala para cada lado.
const VOID_MARGIN := 4000.0

var layers: Array[Parallax2D] = []
## De onde veio a imagem de cada camada.
var sources: Array[String] = []

## Moldura escura em volta da sala: fora dela não há fundo (regressão da Sprint 16, ART-031).
var _void: Array[ColorRect] = []


func _ready() -> void:
	z_index = -100
	var base := CanvasLayer.new()
	base.name = "Base"
	base.layer = -100
	var color := ColorRect.new()
	color.color = BASE_COLOR
	color.set_anchors_preset(Control.PRESET_FULL_RECT)
	color.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(color)
	add_child(base)
	for i in FACTORS.size():
		var file_name := "fundo_%d" % (i + 1)
		var texture := ArtLibrary.texture("cenario", file_name)
		var source := ArtLibrary.path_of("cenario", file_name)
		if texture == null:
			source = PLACEHOLDER % (i + 1)
			texture = load(source)
		var layer := Parallax2D.new()
		layer.name = "Camada%d" % (i + 1)
		layer.scroll_scale = Vector2(FACTORS[i], FACTORS[i])
		layer.repeat_size = Vector2(WIDTH, 0)
		layer.repeat_times = 3
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		layer.add_child(sprite)
		add_child(layer)
		layers.append(layer)
		sources.append(source)
	for i in 4:
		var rect := ColorRect.new()
		rect.name = "Vazio%d" % i
		rect.color = BASE_COLOR
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
		_void.append(rect)


## Põe a moldura escura em volta da sala (em coordenadas do mundo).
func fit(room: Rect2) -> void:
	var m := VOID_MARGIN
	var rects := [
		Rect2(room.position.x - m, room.position.y - m, m, room.size.y + 2 * m),
		Rect2(room.end.x, room.position.y - m, m, room.size.y + 2 * m),
		Rect2(room.position.x, room.position.y - m, room.size.x, m),
		Rect2(room.position.x, room.end.y, room.size.x, m),
	]
	for i in 4:
		_void[i].position = rects[i].position
		_void[i].size = rects[i].size


func covers_outside(point: Vector2) -> bool:
	for rect in _void:
		if Rect2(rect.position, rect.size).has_point(point):
			return true
	return false
