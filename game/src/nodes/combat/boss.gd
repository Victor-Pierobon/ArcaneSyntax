class_name Boss
extends Enemy
## Chefe da Masmorra (spec COM-chefe): três fases, voa entre os pontos da arena e ataca com aviso
## (leque de orbes, pilares do chão, investida). O que fazer e quando é do BossBrain; este nó
## desenha, cria orbes e pilares e repassa os acertos.

## Um orbe ou um pilar acertou o mago; a Room repassa como `player_attacked`.
signal bolt_hit(from: Vector2, amount: int)
signal phase_changed(phase: int)

const BODY := Vector2(28, 36)
## Pisca 5 vezes por segundo na transição, entre a cor da fase velha e a da nova.
const BLINK_RATE := 10.0
## Do centro do mago até os pés.
const PLAYER_CENTER := Vector2(0, -15)
## Tremida da investida e brilho do aviso.
const SHAKE := 1.5
const STRIPE_HEIGHT := 2.0

var brain := BossBrain.new(Vector2.ZERO, [] as Array[Vector2], [] as Array[Vector2])
var phases: BossPhases:
	get:
		return brain.phases
## "Fase N!" acima do texto do golpe, durante a transição.
var phase_label := Label.new()
## Layout da sala, para os pilares acharem o chão; null: o chão é onde está o mago.
var layout: RoomLayout
## O ataque que está avisando ("leque" ou "investida"), ou vazio.
var warning := ""

var _old_color := Color.WHITE
var _clock := 0.0
var _pillars: Dictionary = {}
var _stripe: ColorRect


static func make_boss(p_target_id: String) -> Boss:
	var boss := Boss.new()
	boss.setup(p_target_id, boss.phases.element(), "chefe", BODY)
	# A arena é grande: o chefe é alvo a qualquer distância (regra 6).
	boss.any_distance = true
	return boss


## Pontos onde o chefe para no ar e pontos da investida, em coordenadas da sala (regra 7).
func arena(points: Array[Vector2], charge_points: Array[Vector2], p_layout: RoomLayout) -> void:
	brain.points = points
	brain.charge_points = charge_points
	layout = p_layout


func _ready() -> void:
	super._ready()
	brain.position = position
	if layout:
		brain.floor_finder = layout.floor_below
	phase_label.add_theme_font_size_override(&"font_size", 9)
	phase_label.add_theme_color_override(&"font_color", Color("ffd27a"))
	phase_label.position = Vector2(-20, effect_label.position.y - 12)
	phase_label.visible = false
	add_child(phase_label)


func _art() -> Array:
	var names: Array = ["chefe", "parado_" + element]
	for anim in ["parado", "mover", "orbe", "golpe"]:
		for each in Balance.list("chefe", "elementos"):
			names.append("%s_%s" % [anim, each])
	names.append_array(["troca", "morrer"])
	return names


func _think(delta: float) -> void:
	_clock += delta
	var feet: Variant = _player_feet()
	var target: Vector2 = feet + PLAYER_CENTER if feet != null else position
	for event in brain.tick(delta, target):
		_apply(event)
	position = brain.position
	_update_look()


func _apply(event: Dictionary) -> void:
	match event["tipo"]:
		"aviso":
			warning = event["ataque"]
			if warning == "investida":
				_show_stripe()
		"leque":
			warning = ""
			for direction: Vector2 in event["direcoes"]:
				_fire(direction)
		"marca":
			_add_pillar(event["id"], event["posicao"])
		"pilar":
			if _pillars.has(event["id"]):
				_pillars[event["id"]].rise()
		"pilar_fim":
			if _pillars.has(event["id"]):
				_pillars[event["id"]].queue_free()
				_pillars.erase(event["id"])
		"investida":
			warning = ""
		"mover", "cancelar":
			_clear_attacks()


func _update_look() -> void:
	var visual: CanvasItem = art_sprite if art_sprite else _body
	if phases.in_transition():
		_body.color = _old_color if int(_clock * BLINK_RATE) % 2 == 1 else body_color_of(element)
	elif phase_label.visible:
		_body.color = body_color_of(element)
		phase_label.visible = false
	# Aviso: o chefe brilha na cor da fase; na investida também treme (regras 11 e 13).
	var glowing := warning != "" and int(_clock * BLINK_RATE) % 2 == 0
	visual.self_modulate = body_color_of(element).lightened(0.6) if glowing else Color.WHITE
	visual.position.x = (-body_size.x / 2 if visual == _body else 0.0) \
			+ (SHAKE * signf(sin(_clock * 60.0)) if warning == "investida" else 0.0)
	_play_art()


func _play_art() -> void:
	if art_sprite == null:
		return
	var anim := "parado"
	if phases.in_transition():
		anim = "troca"
	elif warning == "leque":
		anim = "orbe"
	elif brain.charging() or warning == "investida":
		anim = "golpe"
	elif brain.state == BossBrain.State.MOVE:
		anim = "mover"
	for name_try in ["%s_%s" % [anim, element], anim, "parado_" + element]:
		if art_sprite.sprite_frames.has_animation(name_try):
			if art_sprite.animation != name_try:
				art_sprite.play(name_try)
			return


func hit(attack_element: String, form: String = "") -> void:
	super.hit(attack_element, form)
	if not is_defeated() and brain.after_damage(health.current):
		_start_transition()


func _resolve(attack_element: String, form: String) -> Dictionary:
	return brain.resolve(attack_element, form, health.current)


## A troca de cor e de nome acontece no começo da transição (regra 5); o ataque é cancelado (regra 4).
func _start_transition() -> void:
	_clear_attacks()
	_old_color = _body.color
	element = phases.element()
	name_label.text = element
	_body.color = body_color_of(element)
	phase_label.text = tr("CHEFE_FASE") % phases.phase
	phase_label.visible = true
	if get_parent():
		Fx.burst(get_parent(), position + Vector2(0, -body_size.y / 2), body_color_of(element), 32)
	phase_changed.emit(phases.phase)


## Derrotado: somem as marcas, os pilares e os orbes (regra 15).
func _defeat() -> void:
	_clear_attacks()
	if is_inside_tree():
		for bolt in get_tree().get_nodes_in_group(BossBolt.GROUP):
			bolt.queue_free()
	super._defeat()


func _exit_tree() -> void:
	_clear_attacks()


func _clear_attacks() -> void:
	warning = ""
	for pillar: BossPillar in _pillars.values():
		if is_instance_valid(pillar):
			pillar.queue_free()
	_pillars.clear()
	if is_instance_valid(_stripe):
		_stripe.queue_free()
	_stripe = null


func _fire(direction: Vector2) -> void:
	if get_parent() == null:
		return
	var bolt := BossBolt.make(element, direction)
	bolt.position = position + Vector2(0, -body_size.y / 2)
	bolt.hit_player.connect(bolt_hit.emit)
	get_parent().add_child(bolt)


func _add_pillar(id: int, at: Vector2) -> void:
	if get_parent() == null:
		return
	var pillar := BossPillar.make(element)
	pillar.position = at
	pillar.hit_player.connect(bolt_hit.emit)
	_pillars[id] = pillar
	get_parent().add_child(pillar)


## A faixa no chão entre os dois pontos da investida (regra 13).
func _show_stripe() -> void:
	if get_parent() == null or brain.charge_points.size() < 2:
		return
	var left := minf(brain.charge_points[0].x, brain.charge_points[1].x)
	var right := maxf(brain.charge_points[0].x, brain.charge_points[1].x)
	_stripe = ColorRect.new()
	_stripe.color = Color(body_color_of(element), 0.6)
	_stripe.position = Vector2(left, brain.charge_points[0].y - STRIPE_HEIGHT)
	_stripe.size = Vector2(right - left, STRIPE_HEIGHT)
	get_parent().add_child(_stripe)


func body_color() -> Color:
	return _body.color


func pillars() -> Array[BossPillar]:
	var found: Array[BossPillar] = []
	for pillar: BossPillar in _pillars.values():
		found.append(pillar)
	return found


static func body_color_of(p_element: String) -> Color:
	return ELEMENT_COLORS.get(p_element, Color("9a96a8"))
