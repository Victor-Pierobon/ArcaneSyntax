class_name Shield
extends Node2D
## Escudo elemental em volta do mago (spec MAG-formas): dura 2 s ou até bloquear um ataque.

signal expired

const DURATION := 2.0

var element := ""
var time_left := DURATION


static func make(p_element: String) -> Shield:
	var shield := Shield.new()
	shield.name = "Shield"
	shield.element = p_element
	return shield


func _draw() -> void:
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
