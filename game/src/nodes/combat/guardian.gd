class_name Guardian
extends Enemy
## Guardião de escudo (spec COM-guardiao): parado, com um escudo que troca de elemento.
## Com escudo, só o elemento que vence o escudo passa.

const BODY := Vector2(20, 28)
const SHIELD_RADIUS := 20.0
## Pisca 4 vezes por segundo no último segundo do escudo.
const BLINK_RATE := 8.0

var shield := GuardianShield.new()


static func make_guardian(p_target_id: String) -> Guardian:
	var guardian := Guardian.new()
	guardian.setup(p_target_id, GuardianShield.BODY_ELEMENT, Balance.integer("guardiao", "vida"), BODY)
	return guardian


func _think(delta: float) -> void:
	shield.tick(delta)
	var current := shield.current()
	name_label.text = current if not current.is_empty() else element
	queue_redraw()


func _draw() -> void:
	var current := shield.current()
	if current.is_empty() or is_defeated():
		return
	if shield.is_blinking() and int(shield.time * BLINK_RATE) % 2 == 1:
		return
	var color: Color = ELEMENT_COLORS.get(current, Color.WHITE)
	var center := Vector2(0, -body_size.y / 2)
	draw_circle(center, SHIELD_RADIUS, Color(color, 0.25))
	draw_arc(center, SHIELD_RADIUS, 0.0, TAU, 32, color, 1.5)


func shield_element() -> Variant:
	var current := shield.current()
	return null if current.is_empty() else current


func _resolve(attack_element: String, form: String) -> Dictionary:
	return shield.resolve(attack_element, form)
