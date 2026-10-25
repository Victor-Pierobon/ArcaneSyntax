class_name MutableCrystalRule
extends RefCounted
## Regra do cristal mutável (spec PUZ-validacao, regra 8): mostra um símbolo e só aceita o
## elemento que o vence. Acerto certo ganha uma carga; errado zera. O símbolo muda a cada acerto
## e nunca repete o anterior. O cajado não conta.

const SYMBOLS := ["planta", "fogo", "gelo"]

var symbol := "planta"
var charges := 0
var needed := 3
var lit := false

var _rng: RandomNumberGenerator


func _init(p_needed := 3, rng: RandomNumberGenerator = null) -> void:
	needed = p_needed
	_rng = rng if rng else RandomNumberGenerator.new()
	symbol = SYMBOLS[_rng.randi_range(0, SYMBOLS.size() - 1)]


## O elemento que vence o símbolo (MAG-elementos).
static func answer(p_symbol: String) -> String:
	for attack: String in ElementTable.STRONG_AGAINST:
		if ElementTable.STRONG_AGAINST[attack] == p_symbol:
			return attack
	return ""


func hit(attack_element: String) -> void:
	if lit or attack_element == "cajado":
		return
	if attack_element == answer(symbol):
		charges += 1
		lit = charges >= needed
	else:
		charges = 0
	if not lit:
		_change_symbol()


func _change_symbol() -> void:
	var others := SYMBOLS.filter(func(s: String) -> bool: return s != symbol)
	symbol = others[_rng.randi_range(0, others.size() - 1)]
