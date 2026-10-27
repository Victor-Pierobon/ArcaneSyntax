class_name Crystal
extends TrainingTarget
## Cristal de puzzle: acende quando um feitiço o atinge (spec PUZ-validacao).
## O cajado não acende; um cristal pode exigir um elemento. O cristal mutável (Sprint 9) troca de
## símbolo e só aceita o elemento que o vence (PUZ-validacao, regra 8).

signal lit_changed(lit: bool)

const LIT_COLOR := Color("9ff6ff")
const SLEEP_COLOR := Color("4a5a78")

var required_element := ""
var lit := false
## Elemento do feitiço que acendeu, para a arte `cristal_aceso_<elemento>` (ART-esteira, regra 26).
var lit_element := ""
## Só nos cristais mutáveis; o símbolo atual é o `element`, que o feitiço lê em `alvo.elemento`.
var rule: MutableCrystalRule
## Luz na cor do elemento que o acendeu; apagado, desligada (ART-brilho, regra 2). Não é `light`: esse
## nome já é o de acender.
var glow: PointLight2D


## `spec`: "cristal", "cristal:<elemento>" ou "cristal:mutavel[:<cargas>]".
static func make_crystal(p_target_id: String, spec: String, rng: RandomNumberGenerator = null) -> Crystal:
	var crystal := Crystal.new()
	crystal.target_id = p_target_id
	crystal.element = "cristal"
	crystal.name = p_target_id
	var parts := spec.split(":")
	if parts.size() > 1 and parts[1] == "mutavel":
		crystal.rule = MutableCrystalRule.new(int(parts[2]) if parts.size() > 2 else 3, rng)
		crystal.element = crystal.rule.symbol
	else:
		crystal.required_element = parts[1] if parts.size() > 1 else ""
	return crystal


func _ready() -> void:
	super._ready()
	glow = Lighting.make(LIT_COLOR, 48)
	glow.position = Vector2(0, -body_size.y / 2)
	add_child(glow)
	_refresh_color()
	_refresh_symbol()


func hit(attack_element: String, form: String = "") -> void:
	super.hit(attack_element, form)
	if lit or attack_element == "cajado":
		return
	if rule:
		rule.hit(attack_element)
		element = rule.symbol
		_refresh_symbol()
		if rule.lit:
			light(attack_element)
	elif required_element.is_empty() or required_element == attack_element:
		light(attack_element)


func light(by_element := "") -> void:
	if lit:
		return
	lit = true
	lit_element = by_element if not by_element.is_empty() else required_element
	_refresh_color()
	if is_inside_tree():
		Fx.element_burst(self, Vector2(0, -body_size.y / 2), lit_element, 18)
	lit_changed.emit(true)


func _art() -> Array:
	var names := ["objetos", "cristal_apagado"]
	for spell_element: String in ElementTable.SPELL_ELEMENTS:
		names.append("cristal_aceso_" + spell_element)
	return names


func _refresh_color() -> void:
	_body.color = LIT_COLOR if lit else SLEEP_COLOR
	if glow:
		glow.enabled = lit
		glow.color = ELEMENT_COLORS.get(lit_element, LIT_COLOR)
	if art_sprite == null:
		return
	var anim := "cristal_apagado"
	if lit:
		anim = "cristal_aceso_" + lit_element
		if not art_sprite.sprite_frames.has_animation(anim):
			anim = _any_lit_animation()
	if anim.is_empty():
		# Sem arte do cristal aceso: volta para o retângulo.
		art_sprite.visible = false
		_body.visible = true
	elif art_sprite.animation != anim:
		art_sprite.play(anim)


func _any_lit_animation() -> String:
	for spell_element: String in ElementTable.SPELL_ELEMENTS:
		if art_sprite.sprite_frames.has_animation("cristal_aceso_" + spell_element):
			return "cristal_aceso_" + spell_element
	return ""


func _refresh_symbol() -> void:
	if rule:
		name_label.text = "%s %d/%d" % [rule.symbol, rule.charges, rule.needed]
