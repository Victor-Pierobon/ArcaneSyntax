class_name PuzzleValidator
extends RefCounted
## Avalia as condições de um puzzle sobre uma foto do estado da sala (spec PUZ-validacao).
## Nunca olha o código do jogador: só o mundo decide.

const KNOWN := ["cristais_acesos"]


## `state`: {"cristais": {"<dígito>": aceso}}. Todas as condições precisam valer; lista vazia é falsa.
static func evaluate(conditions: Array, state: Dictionary) -> bool:
	if conditions.is_empty():
		return false
	for condition: Dictionary in conditions:
		if not _holds(condition, state):
			return false
	return true


static func authoring_errors(conditions: Array) -> Array[String]:
	var errors: Array[String] = []
	for condition: Variant in conditions:
		if not condition is Dictionary or not condition.get("tipo") in KNOWN:
			errors.append("condição de puzzle desconhecida: %s" % str(condition))
	return errors


static func _holds(condition: Dictionary, state: Dictionary) -> bool:
	match condition.get("tipo"):
		"cristais_acesos":
			var crystals: Dictionary = state.get("cristais", {})
			var ids: Array = condition.get("ids", crystals.keys())
			if ids.is_empty():
				return false
			for id: Variant in ids:
				if not crystals.get(str(id), false):
					return false
			return true
	return false
