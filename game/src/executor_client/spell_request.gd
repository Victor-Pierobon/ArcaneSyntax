class_name SpellRequest
extends RefCounted
## Pedido de execução de um feitiço (spec EXE-protocolo).

const PROTOCOL_VERSION := 1

var code: String
## {"vida", "mana", "mana_max"}
var mago: Dictionary
## {"id", "elemento", "distancia"} ou null quando não há alvo.
var target: Variant
## Ganhos de mana etc.; vazio usa os padrões do executor.
var rules: Dictionary


static func make(p_code: String, p_mago: Dictionary, p_target: Variant = null, p_rules: Dictionary = {}) -> SpellRequest:
	var request := SpellRequest.new()
	request.code = p_code
	request.mago = p_mago
	request.target = p_target
	request.rules = p_rules
	return request


func to_dict(id: int) -> Dictionary:
	var data := {
		"versao": PROTOCOL_VERSION,
		"id": id,
		"codigo": code,
		"mundo": {"mago": mago, "alvo": target},
	}
	if not rules.is_empty():
		data["regras"] = rules
	return data
