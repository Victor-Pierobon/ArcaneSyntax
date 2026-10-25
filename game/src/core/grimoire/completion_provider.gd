class_name CompletionProvider
extends RefCounted
## Sugestões do autocompletar do grimório (spec GRI-autocompletar).

enum Group { GAME, BUILTIN, KEYWORD }

const GAME_FUNCTIONS := ["lancar", "mover", "levitar", "meditar", "absorver_mana", "inscrever", "construir_bloco"]
const GAME_CONSTANTS := ["fogo", "gelo", "raio", "projetil", "escudo"]
## Sentidos: sempre disponíveis (spec EXE-desbloqueio, regra 2).
const SENSES := ["mana", "mana_max", "vida_atual", "alvo"]
## Sentidos que são funções (Sprint 9, EXE-pecas regra 6).
const SENSE_FUNCTIONS := ["ler_runa"]


## Lista de {display, insert, group}, ordenada por grupo e nome.
## `unlocked`: Array ou PackedStringArray com as peças desbloqueadas.
static func suggest(prefix: String, unlocked: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if prefix.is_empty():
		return result
	var lowered := prefix.to_lower()
	var game: Array[Dictionary] = []
	for word in GAME_FUNCTIONS:
		if word in unlocked and word.begins_with(lowered):
			game.append({"display": word, "insert": word + "(", "group": Group.GAME})
	for word in GAME_CONSTANTS:
		if word in unlocked and word.begins_with(lowered):
			game.append({"display": word, "insert": word, "group": Group.GAME})
	for word in SENSES:
		if word.begins_with(lowered):
			game.append({"display": word, "insert": word, "group": Group.GAME})
	for word in SENSE_FUNCTIONS:
		if word.begins_with(lowered):
			game.append({"display": word, "insert": word + "(", "group": Group.GAME})
	var builtins: Array[Dictionary] = []
	for word: String in PythonHighlighter.BUILTINS:
		if word.begins_with(lowered):
			builtins.append({"display": word, "insert": word + "(", "group": Group.BUILTIN})
	var keywords: Array[Dictionary] = []
	for word: String in PythonHighlighter.KEYWORDS:
		if word.to_lower().begins_with(lowered):
			keywords.append({"display": word, "insert": word, "group": Group.KEYWORD})
	for group in [game, builtins, keywords]:
		group.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["display"] < b["display"])
		result.append_array(group)
	return result


## O nome que está sendo digitado antes do cursor; vazio dentro de comentário ou texto.
static func prefix_before_caret(line_before_caret: String) -> String:
	var in_string := ""
	for c in line_before_caret:
		if in_string.is_empty():
			if c == "#":
				return ""
			if c == "\"" or c == "'":
				in_string = c
		elif c == in_string:
			in_string = ""
	if not in_string.is_empty():
		return ""
	var regex := RegEx.create_from_string("[A-Za-z_][A-Za-z0-9_]*$")
	var found := regex.search(line_before_caret)
	return "" if found == null else found.get_string()
