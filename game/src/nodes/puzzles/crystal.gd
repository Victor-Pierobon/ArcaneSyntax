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
## Só nos cristais mutáveis; o símbolo atual é o `element`, que o feitiço lê em `alvo.elemento`.
var rule: MutableCrystalRule


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
			light()
	elif required_element.is_empty() or required_element == attack_element:
		light()


func light() -> void:
	if lit:
		return
	lit = true
	_refresh_color()
	lit_changed.emit(true)


func _refresh_color() -> void:
	_body.color = LIT_COLOR if lit else SLEEP_COLOR


func _refresh_symbol() -> void:
	if rule:
		name_label.text = "%s %d/%d" % [rule.symbol, rule.charges, rule.needed]
