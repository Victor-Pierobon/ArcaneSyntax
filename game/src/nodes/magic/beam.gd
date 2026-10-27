class_name Beam
extends Node2D
## O feixe (spec MAG-feixe, regras 4 e 5): uma linha reta na cor do elemento que fica 0,3 s e some.
## Quem decide onde termina e quem acerta é o WorldActions, pela BeamRule; este nó só desenha.

const GROUP := &"feixes"
const LIFETIME := 0.3
## Uma luz a cada tantos px ao longo do feixe.
const LIGHT_SPACING := 48.0

var element := ""
var start := Vector2.ZERO
var end := Vector2.ZERO
## A arte (`magia/feixe_<elemento>`, esticada ao longo do feixe); null: a linha desenhada.
var art_sprite: AnimatedSprite2D


static func make(p_element: String, p_start: Vector2, p_end: Vector2) -> Beam:
	var beam := Beam.new()
	beam.element = p_element
	beam.start = p_start
	beam.end = p_end
	return beam


func _ready() -> void:
	add_to_group(GROUP)
	var color := _color()
	var length := start.distance_to(end)
	var count := maxi(1, int(length / LIGHT_SPACING))
	for i in count + 1:
		var light := Lighting.make(color, 28)
		light.position = start.lerp(end, float(i) / count)
		add_child(light)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


func _color() -> Color:
	return TrainingTarget.ELEMENT_COLORS.get(element, Color.WHITE)


func _draw() -> void:
	var color := _color()
	draw_line(start, end, Color(color, 0.35), BeamRule.WIDTH + 4.0)
	draw_line(start, end, color, BeamRule.WIDTH)
	draw_line(start, end, color.lightened(0.7), 2.0)
	draw_circle(start, BeamRule.WIDTH * 0.8, color.lightened(0.5))
