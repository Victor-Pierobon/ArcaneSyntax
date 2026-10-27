class_name CodeRune
extends Node2D
## Runa do código (spec ART-brilho, regra 9): cada ação do feitiço solta, acima do mago, uma runa com o
## número da linha que a gerou; ela sobe e some. Com a arte `magia/runa`, usa o desenho; sem ela, um
## losango com o número.

const GROUP := &"runas_codigo"
const LIFETIME := 0.8
const RISE := 16.0
## Cor das ações sem elemento.
const NEUTRAL := Color("b8a8ff")
const SIZE := 6.0

var line := 0
var color := NEUTRAL
var art_sprite: AnimatedSprite2D

var _label := Label.new()


static func make(p_line: int, p_element: String) -> CodeRune:
	var rune := CodeRune.new()
	rune.line = p_line
	rune.color = TrainingTarget.ELEMENT_COLORS.get(p_element, NEUTRAL)
	return rune


func _ready() -> void:
	add_to_group(GROUP)
	art_sprite = ArtLibrary.sprite("magia", ["runa"])
	if art_sprite:
		art_sprite.position = Vector2.ZERO
		art_sprite.modulate = color
		add_child(art_sprite)
	_label.text = str(line)
	Lighting.keep_readable(_label)
	_label.add_theme_font_size_override(&"font_size", 7)
	_label.add_theme_color_override(&"font_color", color.lightened(0.5))
	_label.position = Vector2(-3, -6)
	add_child(_label)
	add_child(Lighting.make(color, 16, 0.6))
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - RISE, LIFETIME)
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	if art_sprite:
		return
	var points := PackedVector2Array([Vector2(0, -SIZE), Vector2(SIZE, 0), Vector2(0, SIZE), Vector2(-SIZE, 0)])
	draw_colored_polygon(points, Color(color, 0.35))
	points.append(points[0])
	draw_polyline(points, color, 1.0)
