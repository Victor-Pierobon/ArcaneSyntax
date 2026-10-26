class_name Boss
extends Enemy
## Chefe da Masmorra (spec COM-chefe): parado, troca de elemento na metade da vida e lança orbes
## no mago. As fases e o relógio dos orbes são do BossPhases.

## Um orbe acertou o mago; a Room repassa como `player_attacked`.
signal bolt_hit(from: Vector2, amount: int)
signal phase_changed(phase: int)

const BODY := Vector2(28, 36)
## Pisca 5 vezes por segundo na transição, entre a cor da fase velha e a da nova.
const BLINK_RATE := 10.0
## Do centro do mago até os pés.
const PLAYER_CENTER := Vector2(0, -15)

var phases := BossPhases.new()
## "Fase 2!" acima do texto do golpe, durante a transição.
var phase_label := Label.new()
var attack_range := Balance.number("chefe", "ataque_alcance_tiles") * RoomLayout.TILE

var _old_color := Color.WHITE
var _transition_clock := 0.0


static func make_boss(p_target_id: String) -> Boss:
	var boss := Boss.new()
	boss.setup(p_target_id, boss.phases.element(), Balance.integer("chefe", "vida"), BODY)
	return boss


func _ready() -> void:
	super._ready()
	phase_label.add_theme_font_size_override(&"font_size", 9)
	phase_label.add_theme_color_override(&"font_color", Color("ffd27a"))
	phase_label.position = Vector2(-20, effect_label.position.y - 12)
	phase_label.visible = false
	add_child(phase_label)


func _think(delta: float) -> void:
	var feet: Variant = _player_feet()
	var near: bool = feet != null and position.distance_to(feet) <= attack_range + 0.001
	var was_transition := phases.in_transition()
	if phases.tick(delta, near):
		_fire(feet + PLAYER_CENTER)
	if phases.in_transition():
		_transition_clock += delta
		var new_color := body_color_of(element)
		_body.color = _old_color if int(_transition_clock * BLINK_RATE) % 2 == 1 else new_color
	elif was_transition:
		_body.color = body_color_of(element)
		phase_label.visible = false


func hit(attack_element: String, form: String = "") -> void:
	super.hit(attack_element, form)
	if not is_defeated() and phases.after_damage(health.current):
		_start_transition()


func _resolve(attack_element: String, form: String) -> Dictionary:
	return phases.resolve(attack_element, form, health.current)


## A troca de cor e de nome acontece no começo da transição (regra 5).
func _start_transition() -> void:
	_old_color = _body.color
	_transition_clock = 0.0
	element = phases.element()
	name_label.text = element
	_body.color = body_color_of(element)
	phase_label.text = tr("CHEFE_FASE") % phases.phase
	phase_label.visible = true
	if get_parent():
		Fx.burst(get_parent(), position + Vector2(0, -body_size.y / 2), body_color_of(element), 32)
	phase_changed.emit(phases.phase)


func _fire(at: Vector2) -> void:
	if get_parent() == null:
		return
	var from := position + Vector2(0, -body_size.y / 2)
	var bolt := BossBolt.make(element, at - from)
	bolt.position = from
	bolt.hit_player.connect(bolt_hit.emit)
	get_parent().add_child(bolt)


func body_color() -> Color:
	return _body.color


static func body_color_of(p_element: String) -> Color:
	return ELEMENT_COLORS.get(p_element, Color("9a96a8"))
