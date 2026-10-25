class_name PuzzleValidator
extends RefCounted
## Avalia as condições de um puzzle sobre uma foto do estado da sala (spec PUZ-validacao).
## Nunca olha o código do jogador: só o mundo decide.

const KNOWN := ["cristais_acesos", "cadeados_abertos", "ponte_completa", "placas_pisadas"]
## Ações que só recuperam mana: conjurações só com elas não contam para as estrelas (regra 14).
const RECOVERY_ACTIONS := ["meditar", "absorver_mana"]


## `state`: {"cristais": {"<dígito>": aceso}, "cadeados": {"<dígito>": aberto},
## "ponte": {"feitos", "total"}, "placas": [pisada]}. Todas as condições precisam valer; lista vazia é falsa.
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


## Estrelas pela mana gasta (regra 14): 3 até o primeiro limite, 2 até o segundo, senão 1; sem limites, 0.
static func stars(limits: Array, spent: float) -> int:
	if limits.size() < 2:
		return 0
	# Meio décimo de folga: a mana anda em décimos e a soma de floats pode passar um tiquinho.
	if spent <= float(limits[0]) + 0.05:
		return 3
	if spent <= float(limits[1]) + 0.05:
		return 2
	return 1


## A conjuração conta para as estrelas se fez alguma coisa além de recuperar mana.
static func counts_for_stars(actions: Array) -> bool:
	for action: Dictionary in actions:
		if not action.get("tipo", "") in RECOVERY_ACTIONS:
			return true
	return false


static func _holds(condition: Dictionary, state: Dictionary) -> bool:
	match condition.get("tipo"):
		"cristais_acesos":
			var crystals: Dictionary = state.get("cristais", {})
			var ids: Array = condition.get("ids", crystals.keys())
			return _all_true(ids.map(func(id: Variant) -> bool: return crystals.get(str(id), false)))
		"cadeados_abertos":
			return _all_true(state.get("cadeados", {}).values())
		"ponte_completa":
			var bridge: Dictionary = state.get("ponte", {})
			return int(bridge.get("total", 0)) > 0 and int(bridge.get("feitos", 0)) >= int(bridge.get("total", 0))
		"placas_pisadas":
			return _all_true(state.get("placas", []))
	return false


## Verdadeiro se a lista não está vazia e tudo nela é verdadeiro.
static func _all_true(values: Array) -> bool:
	if values.is_empty():
		return false
	for value: Variant in values:
		if not value:
			return false
	return true
