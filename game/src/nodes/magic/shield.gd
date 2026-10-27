class_name Shield
extends Node2D
## Escudo elemental em volta do mago (spec MAG-formas): dura 2 s ou até bloquear um ataque.

signal expired

const DURATION := 2.0

var element := ""
var light: PointLight2D
var time_left := DURATION
## A arte (`magia/escudo_<elemento>`, ART-esteira, regra 8); null: o círculo desenhado.
var art_sprite: AnimatedSprite2D


static func make(p_element: String) -> Shield:
	var shield := Shield.new()
	shield.name = "Shield"
	shield.element = p_element
	return shield


func _ready() -> void:
	# Luz na cor do elemento (ART-brilho, regra 2).
	light = Lighting.make(TrainingTarget.ELEMENT_COLORS.get(element, Color.WHITE), 40)
	light.position = Vector2(0, -15)
	add_child(light)
	art_sprite = ArtLibrary.sprite("magia", ["escudo_" + element])
	if art_sprite:
		art_sprite.position = Vector2(0, -15)
		add_child(art_sprite)


func _draw() -> void:
	if art_sprite:
		return
	var color: Color = TrainingTarget.ELEMENT_COLORS.get(element, Color.WHITE)
	color.a = 0.35
	draw_circle(Vector2(0, -15), 20.0, color)
	color.a = 0.9
	draw_arc(Vector2(0, -15), 20.0, 0.0, TAU, 32, color, 1.0)


func _physics_process(delta: float) -> void:
	time_left -= delta
	if time_left <= 0.0:
		expire()


## Some agora (acabou o tempo ou bloqueou um ataque).
func expire() -> void:
	if is_queued_for_deletion():
		return
	expired.emit()
	get_parent().remove_child(self)
	queue_free()
