class_name SpellRequest
extends RefCounted
## Pedido de execução de um feitiço (spec EXE-protocolo).

const PROTOCOL_VERSION := 1

var code: String
## {"vida", "mana", "mana_max"}
var mago: Dictionary
## {"id", "elemento", "distancia"} (inimigos também com "vida" e "escudo") ou null quando não há alvo.
var target: Variant
## Ganhos de mana etc.; vazio usa os padrões do executor.
var rules: Dictionary
## Peças desbloqueadas (PackedStringArray) ou null para todas (spec EXE-desbloqueio).
var pieces: Variant
## O que a sala mostra ao feitiço, como {"runas": [4, 7]}; vazio não vai na requisição (EXE-protocolo, regra 7).
var room: Dictionary
## Inimigos no alcance, do mais perto para o mais longe; vazio não vai na requisição (EXE-protocolo, regra 8).
var enemies: Array


static func make(p_code: String, p_mago: Dictionary, p_target: Variant = null, p_rules: Dictionary = {},
		p_pieces: Variant = null, p_room: Dictionary = {}, p_enemies: Array = []) -> SpellRequest:
	var request := SpellRequest.new()
	request.code = p_code
	request.mago = p_mago
	request.target = p_target
	request.rules = p_rules
	request.pieces = p_pieces
	request.room = p_room
	request.enemies = p_enemies
	return request


func to_dict(id: int) -> Dictionary:
	var data := {
		"versao": PROTOCOL_VERSION,
		"id": id,
		"codigo": code,
		"mundo": {"mago": mago, "alvo": target},
	}
	if not room.is_empty():
		data["mundo"]["sala"] = room
	if not enemies.is_empty():
		data["mundo"]["inimigos"] = enemies
	if not rules.is_empty():
		data["regras"] = rules
	if pieces != null:
		data["pecas"] = Array(pieces)
	return data
