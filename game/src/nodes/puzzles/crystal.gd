class_name Crystal
extends TrainingTarget
## Cristal de puzzle: acende quando um feitiço o atinge (spec PUZ-validacao).
## O cajado não acende; um cristal pode exigir um elemento.

signal lit_changed(lit: bool)

const LIT_COLOR := Color("9ff6ff")
const SLEEP_COLOR := Color("4a5a78")

var required_element := ""
var lit := false


## `spec`: "cristal" ou "cristal:<elemento>".
static func make_crystal(p_target_id: String, spec: String) -> Crystal:
	var crystal := Crystal.new()
	crystal.target_id = p_target_id
	crystal.element = "cristal"
	crystal.name = p_target_id
	var parts := spec.split(":")
	crystal.required_element = parts[1] if parts.size() > 1 else ""
	return crystal


func _ready() -> void:
	super._ready()
	_refresh_color()


func hit(attack_element: String) -> void:
	super.hit(attack_element)
	if lit or attack_element == "cajado":
		return
	if required_element.is_empty() or required_element == attack_element:
		light()


func light() -> void:
	if lit:
		return
	lit = true
	_refresh_color()
	lit_changed.emit(true)


func _refresh_color() -> void:
	_body.color = LIT_COLOR if lit else SLEEP_COLOR
