class_name Guardian
extends Enemy
## Guardião de escudo (spec COM-guardiao): parado, com um escudo que troca de elemento.
## Com escudo, só o elemento que vence o escudo passa.

const BODY := Vector2(20, 28)
const SHIELD_RADIUS := 20.0
## Pisca 4 vezes por segundo no último segundo do escudo.
const BLINK_RATE := 8.0

var shield := GuardianShield.new()
## O escudo desenhado (`guardiao/escudo_<elemento>`, ART-esteira, regra 25); null: o círculo.
var shield_sprite: AnimatedSprite2D


static func make_guardian(p_target_id: String) -> Guardian:
	var guardian := Guardian.new()
	guardian.setup(p_target_id, GuardianShield.BODY_ELEMENT, "guardiao", BODY)
	return guardian


func _ready() -> void:
	super._ready()
	shield_sprite = ArtLibrary.sprite("guardiao", GuardianShield.CYCLE.map(func(e: String) -> String: return "escudo_" + e))
	if shield_sprite:
		shield_sprite.position = Vector2(0, -body_size.y / 2)
		# Um pouco transparente, para o guardião aparecer atrás do escudo (como o círculo de antes).
		shield_sprite.modulate.a = 0.8
		add_child(shield_sprite)
	_refresh_shield()


func _art() -> Array:
	return ["guardiao", "andar", "morrer"]


func _think(delta: float) -> void:
	shield.tick(delta)
	var current := shield.current()
	name_label.text = current if not current.is_empty() else element
	_refresh_shield()
	queue_redraw()


## O escudo aparece com o elemento atual e some na brecha e nas piscadas.
func _shield_shown() -> bool:
	if shield.current().is_empty() or is_defeated():
		return false
	return not (shield.is_blinking() and int(shield.time * BLINK_RATE) % 2 == 1)


func _refresh_shield() -> void:
	if shield_sprite == null:
		return
	var anim := "escudo_" + shield.current()
	shield_sprite.visible = _shield_shown() and shield_sprite.sprite_frames.has_animation(anim)
	if shield_sprite.visible and shield_sprite.animation != anim:
		shield_sprite.play(anim)


## Sem a arte do escudo atual, o escudo é um círculo desenhado.
func draws_shield_circle() -> bool:
	return _shield_shown() and not (shield_sprite and shield_sprite.visible)


func _draw() -> void:
	if not draws_shield_circle():
		return
	var current := shield.current()
	var color: Color = ELEMENT_COLORS.get(current, Color.WHITE)
	var center := Vector2(0, -body_size.y / 2)
	draw_circle(center, SHIELD_RADIUS, Color(color, 0.25))
	draw_arc(center, SHIELD_RADIUS, 0.0, TAU, 32, color, 1.5)


func shield_element() -> Variant:
	var current := shield.current()
	return null if current.is_empty() else current


func _resolve(attack_element: String, form: String) -> Dictionary:
	return shield.resolve(attack_element, form)
